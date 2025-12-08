import Foundation
import Supabase

// MARK: - Video Service Errors

enum VideoServiceError: LocalizedError {
    case noCredits
    case quotaExceeded(videosUsed: Int, quotaLimit: Int, resetsAt: Date)
    case notAuthenticated
    case generationFailed(Error)
    case fetchFailed(Error)
    case videoNotReady
    case downloadFailed(Error)
    case timedOut

    var errorDescription: String? {
        switch self {
        case .noCredits:
            return "No video credits remaining. Upgrade to Pro for unlimited videos."
        case .quotaExceeded(let used, let limit, let resets):
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d"
            let resetDate = formatter.string(from: resets)
            return "You've used all \(limit) videos for this month. Your quota resets on \(resetDate)."
        case .notAuthenticated:
            return "You must be signed in to generate videos."
        case .generationFailed(let error):
            return "Video generation failed: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch video status: \(error.localizedDescription)"
        case .videoNotReady:
            return "Video is not ready yet."
        case .downloadFailed(let error):
            return "Failed to download video: \(error.localizedDescription)"
        case .timedOut:
            return "Video generation timed out. Please try again."
        }
    }
}

// MARK: - Video Service Constants

private enum VideoServiceConstants {
    /// Maximum time to wait for video generation (10 minutes)
    static let maxPollingDuration: TimeInterval = 10 * 60
    /// Polling interval in seconds
    static let pollingInterval: UInt64 = 5_000_000_000 // 5 seconds in nanoseconds
}

// MARK: - Video Generation Info

struct VideoGenerationInfo: Identifiable {
    let id: UUID
    let dreamTitle: String?
    var status: VideoStatus
    var progress: Double // 0.0 to 1.0
    let startedAt: Date
}

// MARK: - Video Service

@MainActor
final class VideoService: ObservableObject {
    static let shared = VideoService()

    @Published private(set) var activeJobs: [UUID: VideoJobDTO] = [:]
    @Published private(set) var activeGenerations: [UUID: VideoGenerationInfo] = [:]
    @Published private(set) var isGenerating = false

    /// Number of videos currently being generated
    var generatingCount: Int { activeGenerations.count }

    /// Whether any videos are currently generating
    var hasActiveGenerations: Bool { !activeGenerations.isEmpty }

    private let supabase = SupabaseService.shared.client
    private var pollingTasks: [UUID: Task<Void, Never>] = [:]
    private var dreamTitles: [UUID: String?] = [:] // Track dream titles for notifications

    private init() {}

    // MARK: - Generate Video

    func generateVideo(for dream: DreamDTO, prompt: String) async throws -> VideoJobDTO {
        guard let userId = AuthService.shared.currentUser?.id else {
            throw VideoServiceError.notAuthenticated
        }

        // Check credits/quota
        guard let profile = AuthService.shared.userProfile else {
            throw VideoServiceError.notAuthenticated
        }

        if !profile.canGenerateVideo {
            // Throw appropriate error based on subscription tier
            if profile.subscriptionTier == .pro, let quota = profile.proQuotaStatus {
                throw VideoServiceError.quotaExceeded(
                    videosUsed: quota.videosUsed,
                    quotaLimit: quota.quotaLimit,
                    resetsAt: quota.resetsAt
                )
            } else {
                throw VideoServiceError.noCredits
            }
        }

        isGenerating = true
        defer { isGenerating = false }

        // Call Edge Function to start generation
        let request = CreateVideoJobRequest(dreamId: dream.id, prompt: prompt)

        do {
            let result: VideoGenerationResponse = try await supabase.functions
                .invoke(
                    SupabaseFunction.generateVideo.rawValue,
                    options: FunctionInvokeOptions(body: request)
                )

            // Fetch the created job
            let job = try await fetchJob(replicateId: result.jobId)

            // Start polling for completion (with dream title for notifications)
            startPolling(for: job, dreamTitle: dream.title)

            // Refresh credits
            await AuthService.shared.refreshCredits()

            return job
        } catch {
            throw VideoServiceError.generationFailed(error)
        }
    }

    // MARK: - Fetch Jobs

    func fetchJobs(for dreamId: UUID) async throws -> [VideoJobDTO] {
        do {
            let jobs: [VideoJobDTO] = try await supabase
                .from(SupabaseTable.videoJobs.rawValue)
                .select()
                .eq("dream_id", value: dreamId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            return jobs
        } catch {
            throw VideoServiceError.fetchFailed(error)
        }
    }

    func fetchJob(id: UUID) async throws -> VideoJobDTO {
        do {
            let job: VideoJobDTO = try await supabase
                .from(SupabaseTable.videoJobs.rawValue)
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value

            return job
        } catch {
            throw VideoServiceError.fetchFailed(error)
        }
    }

    private func fetchJob(replicateId: String) async throws -> VideoJobDTO {
        do {
            let job: VideoJobDTO = try await supabase
                .from(SupabaseTable.videoJobs.rawValue)
                .select()
                .eq("replicate_id", value: replicateId)
                .single()
                .execute()
                .value

            activeJobs[job.id] = job
            return job
        } catch {
            throw VideoServiceError.fetchFailed(error)
        }
    }

    // MARK: - Check Video Status

    /// Calls the check-video-status Edge Function to check and complete pending jobs
    private func checkVideoStatus(replicateId: String) async throws -> CheckVideoStatusResponse {
        let request = CheckVideoStatusRequest(replicateId: replicateId)
        let response: CheckVideoStatusResponse = try await supabase.functions
            .invoke(
                SupabaseFunction.checkVideoStatus.rawValue,
                options: FunctionInvokeOptions(body: request)
            )
        return response
    }

    // MARK: - Polling

    private func startPolling(for job: VideoJobDTO, dreamTitle: String?) {
        let jobId = job.id
        let replicateId = job.replicateId
        dreamTitles[jobId] = dreamTitle

        // Add to active generations
        activeGenerations[jobId] = VideoGenerationInfo(
            id: jobId,
            dreamTitle: dreamTitle,
            status: job.status,
            progress: 0.1, // Initial progress
            startedAt: Date()
        )

        pollingTasks[jobId] = Task {
            var currentStatus: VideoStatus = job.status
            var pollCount = 0
            let startTime = Date()

            while currentStatus == .pending || currentStatus == .processing {
                try? await Task.sleep(nanoseconds: VideoServiceConstants.pollingInterval)
                pollCount += 1

                if Task.isCancelled { break }

                // Check for timeout (10 minutes max)
                let elapsedTime = Date().timeIntervalSince(startTime)
                if elapsedTime > VideoServiceConstants.maxPollingDuration {
                    print("Video generation timed out after \(Int(elapsedTime)) seconds")
                    currentStatus = .failed
                    activeGenerations[jobId]?.status = .failed

                    // Send timeout notification
                    NotificationService.shared.scheduleVideoFailedNotification(
                        dreamTitle: dreamTitle,
                        jobId: jobId
                    )
                    break
                }

                // Check status via Edge Function (which also completes the job)
                if let replicateId = replicateId {
                    do {
                        let statusResponse = try await checkVideoStatus(replicateId: replicateId)

                        // Map string status to VideoStatus
                        if let status = VideoStatus(rawValue: statusResponse.status) {
                            currentStatus = status
                        }

                        // Update progress (simulate based on time, max 90% until complete)
                        let estimatedProgress = min(0.9, Double(pollCount) * 0.05 + 0.1)
                        activeGenerations[jobId]?.status = currentStatus
                        activeGenerations[jobId]?.progress = estimatedProgress

                        // If completed or failed, fetch the full job to update local state
                        if currentStatus == .completed || currentStatus == .failed {
                            if let updatedJob = try? await fetchJob(id: jobId) {
                                activeJobs[jobId] = updatedJob
                            }
                        }
                    } catch {
                        print("Error checking video status: \(error)")
                        // Continue polling, don't break
                    }
                } else {
                    // Fallback to database polling if no replicate ID
                    do {
                        let updatedJob = try await fetchJob(id: jobId)
                        activeJobs[jobId] = updatedJob
                        currentStatus = updatedJob.status

                        let estimatedProgress = min(0.9, Double(pollCount) * 0.05 + 0.1)
                        activeGenerations[jobId]?.status = currentStatus
                        activeGenerations[jobId]?.progress = estimatedProgress
                    } catch {
                        break
                    }
                }
            }

            // Video completed or failed - send notification
            if currentStatus == .completed {
                activeGenerations[jobId]?.progress = 1.0
                activeGenerations[jobId]?.status = .completed

                // Send notification
                NotificationService.shared.scheduleVideoReadyNotification(
                    dreamTitle: dreamTitle,
                    jobId: jobId
                )
            } else if currentStatus == .failed {
                activeGenerations[jobId]?.status = .failed

                // Send failure notification
                NotificationService.shared.scheduleVideoFailedNotification(
                    dreamTitle: dreamTitle,
                    jobId: jobId
                )
            }

            // Clean up after a short delay so UI can show completion
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            activeGenerations.removeValue(forKey: jobId)
            dreamTitles.removeValue(forKey: jobId)
            pollingTasks[jobId] = nil
        }
    }

    func stopPolling(for jobId: UUID) {
        pollingTasks[jobId]?.cancel()
        pollingTasks[jobId] = nil
    }

    // MARK: - Video URL

    func getVideoURL(for job: VideoJobDTO) async throws -> URL {
        guard job.status == .completed else {
            throw VideoServiceError.videoNotReady
        }

        print("Getting video URL for job \(job.id)")
        print("  - videoPath: \(job.videoPath ?? "nil")")
        print("  - videoUrl: \(job.videoUrl ?? "nil")")

        // Prefer Supabase Storage path (permanent) over direct URL (temporary)
        if let path = job.videoPath {
            do {
                let signedURL = try await supabase.storage
                    .from(SupabaseBucket.videos.rawValue)
                    .createSignedURL(path: path, expiresIn: 3600)
                print("  - Created signed URL: \(signedURL)")
                return signedURL
            } catch {
                print("  - Failed to get signed URL: \(error)")
                // Continue to fallback
            }
        }

        // Fallback to direct URL from Replicate (may expire)
        if let urlString = job.videoUrl, let url = URL(string: urlString) {
            print("  - Using fallback Replicate URL: \(urlString)")
            return url
        }

        print("  - No video URL available")
        throw VideoServiceError.videoNotReady
    }

    // MARK: - Download Video

    func downloadVideo(from url: URL) async throws -> URL {
        let (data, _) = try await URLSession.shared.data(from: url)

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localURL = documentsPath.appendingPathComponent("\(UUID().uuidString).mp4")

        try data.write(to: localURL)
        return localURL
    }
}
