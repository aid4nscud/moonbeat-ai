import Foundation
import Supabase

// MARK: - Dream Service Errors

enum DreamServiceError: LocalizedError {
    case notAuthenticated
    case fetchFailed(Error)
    case createFailed(Error)
    case updateFailed(Error)
    case deleteFailed(Error)
    case uploadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to manage dreams."
        case .fetchFailed(let error):
            return "Failed to fetch dreams: \(error.localizedDescription)"
        case .createFailed(let error):
            return "Failed to create dream: \(error.localizedDescription)"
        case .updateFailed(let error):
            return "Failed to update dream: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete dream: \(error.localizedDescription)"
        case .uploadFailed(let error):
            return "Failed to upload audio: \(error.localizedDescription)"
        }
    }
}

// MARK: - Dream Service

final class DreamService: Sendable {
    static let shared = DreamService()

    private let supabase = SupabaseService.shared.client

    private init() {}

    // MARK: - Fetch Dreams

    func fetchDreams(for userId: UUID) async throws -> [DreamDTO] {
        do {
            let dreams: [DreamDTO] = try await supabase
                .from(SupabaseTable.dreams.rawValue)
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value

            return dreams
        } catch {
            throw DreamServiceError.fetchFailed(error)
        }
    }

    func fetchDream(id: UUID) async throws -> DreamDTO {
        do {
            let dream: DreamDTO = try await supabase
                .from(SupabaseTable.dreams.rawValue)
                .select()
                .eq("id", value: id.uuidString)
                .single()
                .execute()
                .value

            return dream
        } catch {
            throw DreamServiceError.fetchFailed(error)
        }
    }

    // MARK: - Create Dream

    func createDream(
        userId: UUID,
        title: String?,
        transcript: String,
        themes: [String],
        emotions: [String],
        audioURL: URL? = nil
    ) async throws -> DreamDTO {
        var audioPath: String? = nil

        // Upload audio if provided (with retry logic)
        if let audioURL = audioURL {
            audioPath = try await uploadAudioWithRetry(from: audioURL, userId: userId)
        }

        let request = CreateDreamRequest(
            userId: userId,
            title: title,
            transcript: transcript,
            themes: themes.isEmpty ? nil : themes,
            emotions: emotions.isEmpty ? nil : emotions,
            audioPath: audioPath
        )

        do {
            let dream: DreamDTO = try await supabase
                .from(SupabaseTable.dreams.rawValue)
                .insert(request)
                .select()
                .single()
                .execute()
                .value

            return dream
        } catch {
            throw DreamServiceError.createFailed(error)
        }
    }

    // MARK: - Update Dream

    func updateDream(id: UUID, title: String?, transcript: String?) async throws -> DreamDTO {
        var updates = UpdateDreamRequest()
        updates.title = title
        updates.transcript = transcript

        do {
            let dream: DreamDTO = try await supabase
                .from(SupabaseTable.dreams.rawValue)
                .update(updates)
                .eq("id", value: id.uuidString)
                .select()
                .single()
                .execute()
                .value

            return dream
        } catch {
            throw DreamServiceError.updateFailed(error)
        }
    }

    func updateDreamAnalysis(id: UUID, themes: [String], emotions: [String]) async throws {
        var updates = UpdateDreamRequest()
        updates.themes = themes
        updates.emotions = emotions

        do {
            try await supabase
                .from(SupabaseTable.dreams.rawValue)
                .update(updates)
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            throw DreamServiceError.updateFailed(error)
        }
    }

    // MARK: - Delete Dream

    func deleteDream(id: UUID) async throws {
        do {
            try await supabase
                .from(SupabaseTable.dreams.rawValue)
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            throw DreamServiceError.deleteFailed(error)
        }
    }

    // MARK: - Audio Upload

    /// Maximum number of upload retry attempts
    private let maxRetryAttempts = 3

    /// Upload audio with exponential backoff retry logic
    private func uploadAudioWithRetry(from url: URL, userId: UUID, attempt: Int = 1) async throws -> String {
        // Read audio data from file
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw DreamServiceError.uploadFailed(NSError(
                domain: "DreamService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Failed to read audio file: \(error.localizedDescription)"]
            ))
        }

        // Validate data size (max 50MB)
        guard data.count > 0 else {
            throw DreamServiceError.uploadFailed(NSError(
                domain: "DreamService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Audio file is empty"]
            ))
        }

        guard data.count < 50 * 1024 * 1024 else {
            throw DreamServiceError.uploadFailed(NSError(
                domain: "DreamService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Audio file is too large (max 50MB)"]
            ))
        }

        // Use lowercase UUIDs to match Supabase auth.uid() format (case-sensitive comparison in RLS)
        let fileName = "\(userId.uuidString.lowercased())/\(UUID().uuidString.lowercased()).m4a"

        do {
            try await supabase.storage
                .from(SupabaseBucket.audio.rawValue)
                .upload(
                    path: fileName,
                    file: data,
                    options: FileOptions(contentType: "audio/mp4")
                )

            return fileName
        } catch {
            // Retry with exponential backoff
            if attempt < maxRetryAttempts {
                let delay = Double(attempt) * 2.0 // 2s, 4s, 6s
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await uploadAudioWithRetry(from: url, userId: userId, attempt: attempt + 1)
            }

            throw DreamServiceError.uploadFailed(NSError(
                domain: "DreamService",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Upload failed after \(maxRetryAttempts) attempts. Please check your connection and try again."]
            ))
        }
    }

    // MARK: - Audio URL

    func getAudioURL(path: String) async throws -> URL {
        try await supabase.storage
            .from(SupabaseBucket.audio.rawValue)
            .createSignedURL(path: path, expiresIn: 3600)
    }
}
