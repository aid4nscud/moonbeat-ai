import SwiftUI
import AVKit

// Make URL identifiable for fullScreenCover item binding
extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

struct DreamDetailView: View {
    let dream: DreamDTO
    var onDelete: (() -> Void)? = nil  // Callback for parent to handle dismissal after delete

    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var purchaseService: PurchaseService
    @StateObject private var videoService = VideoService.shared
    @StateObject private var interpretationService = DreamInterpretationService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isEditing = false
    @State private var editedTitle: String = ""
    @State private var editedTranscript: String = ""
    @State private var videoJobs: [VideoJobDTO] = []
    @State private var isLoadingJobs = false
    @State private var isGeneratingVideo = false
    @State private var error: Error?
    @State private var showError = false
    @State private var showPaywall = false
    @State private var videoURL: URL?

    // AI Interpretation state
    @State private var interpretation: String?
    @State private var isLoadingInterpretation = false
    @State private var isInterpretationExpanded = false

    // Section entrance animation
    @State private var sectionsAppeared = false

    // Video celebration
    @State private var showVideoCelebration = false
    @State private var previousCompletedCount = 0

    var body: some View {
        mainContent
            .background(MBColors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .toolbarBackground(MBColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .task { await loadData() }
            .onAppear { triggerEntranceAnimation() }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(error?.localizedDescription ?? "An error occurred")
            }
            .sheet(isPresented: $isEditing) { editSheet }
            .sheet(isPresented: $showPaywall) { CustomSubscriptionView() }
            .fullScreenCover(item: $videoURL) { url in VideoPlayerView(url: url) }
            .videoCelebration(isActive: $showVideoCelebration)
            .onChange(of: videoJobs) { oldJobs, newJobs in
                checkForVideoCompletion(oldJobs: oldJobs, newJobs: newJobs)
            }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(MBColors.textMuted)
            }
        }
        ToolbarItem(placement: .principal) {
            Text("Dream")
                .font(MBTypography.headline())
                .foregroundStyle(MBColors.textPrimary)
        }
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button {
                    isEditing = true
                    editedTitle = dream.title ?? ""
                    editedTranscript = dream.transcript
                } label: {
                    Label("Edit", systemImage: "pencil")
                }

                Button(role: .destructive) {
                    deleteDream()
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(MBColors.textSecondary)
            }
        }
    }

    private var editSheet: some View {
        EditDreamSheet(
            title: $editedTitle,
            transcript: $editedTranscript,
            onSave: saveEdits
        )
    }

    private func loadData() async {
        await loadVideoJobs()
        if let existingInterpretation = dream.interpretation, !existingInterpretation.isEmpty {
            interpretation = existingInterpretation
        }
    }

    private func triggerEntranceAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sectionsAppeared = true
        }
    }

    private func checkForVideoCompletion(oldJobs: [VideoJobDTO], newJobs: [VideoJobDTO]) {
        let oldCompletedCount = oldJobs.filter { $0.status == .completed }.count
        let newCompletedCount = newJobs.filter { $0.status == .completed }.count
        if newCompletedCount > oldCompletedCount {
            showVideoCelebration = true
        }
    }

    // MARK: - Main Content

    @ViewBuilder
    private var mainContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: MBSpacing.lg) {
                // Header
                headerSection
                    .offset(y: sectionsAppeared ? 0 : 20)
                    .opacity(sectionsAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.0), value: sectionsAppeared)

                // Analysis
                if !dream.themes.isEmpty {
                    analysisSection(themes: dream.themes, emotions: dream.emotions)
                        .offset(y: sectionsAppeared ? 0 : 20)
                        .opacity(sectionsAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.08), value: sectionsAppeared)
                }

                // AI Insights (Pro feature)
                aiInsightsSection
                    .offset(y: sectionsAppeared ? 0 : 20)
                    .opacity(sectionsAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.16), value: sectionsAppeared)

                // Transcript
                transcriptSection
                    .offset(y: sectionsAppeared ? 0 : 20)
                    .opacity(sectionsAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.24), value: sectionsAppeared)

                // Video Generation
                videoSection
                    .offset(y: sectionsAppeared ? 0 : 20)
                    .opacity(sectionsAppeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.32), value: sectionsAppeared)

                // Generated Videos
                if !videoJobs.isEmpty {
                    generatedVideosSection
                        .offset(y: sectionsAppeared ? 0 : 20)
                        .opacity(sectionsAppeared ? 1 : 0)
                        .animation(.easeOut(duration: 0.4).delay(0.4), value: sectionsAppeared)
                }

                Spacer()
                    .frame(height: MBSpacing.xl)
            }
            .padding(.horizontal, MBSpacing.md)
            .padding(.top, MBSpacing.md)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            Text(dream.title ?? "Untitled Dream")
                .font(MBTypography.titleMedium())
                .foregroundStyle(MBColors.textPrimary)

            HStack(spacing: MBSpacing.md) {
                HStack(spacing: MBSpacing.xxs) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text(formattedDate)
                }

                HStack(spacing: MBSpacing.xxs) {
                    Image(systemName: "clock")
                        .font(.system(size: 12))
                    Text(formattedTime)
                }
            }
            .font(MBTypography.caption())
            .foregroundStyle(MBColors.textTertiary)
        }
        .padding(MBSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MBColors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.lg)
                .stroke(MBColors.border, lineWidth: 1)
        )
    }

    private func analysisSection(themes: [String], emotions: [String]) -> some View {
        VStack(alignment: .leading, spacing: MBSpacing.md) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MBColors.secondary, MBColors.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Analysis")
                    .font(MBTypography.headline())
                    .foregroundStyle(MBColors.textPrimary)
            }

            if !themes.isEmpty {
                VStack(alignment: .leading, spacing: MBSpacing.xs) {
                    Text("Themes")
                        .font(MBTypography.caption(.semibold))
                        .foregroundStyle(MBColors.textTertiary)

                    MBFlowLayout(spacing: MBSpacing.xs) {
                        ForEach(themes, id: \.self) { theme in
                            Text(theme)
                                .mbTag(color: MBColors.primary)
                        }
                    }
                }
            }

            if !emotions.isEmpty {
                VStack(alignment: .leading, spacing: MBSpacing.xs) {
                    Text("Emotions")
                        .font(MBTypography.caption(.semibold))
                        .foregroundStyle(MBColors.textTertiary)

                    MBFlowLayout(spacing: MBSpacing.xs) {
                        ForEach(emotions, id: \.self) { emotion in
                            Text(emotion)
                                .mbTag(color: MBColors.secondary)
                        }
                    }
                }
            }
        }
        .padding(MBSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                // Glassmorphic base
                MBColors.backgroundCard
                // Subtle gradient overlay
                LinearGradient(
                    colors: [MBColors.secondary.opacity(0.05), MBColors.primary.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [MBColors.secondary.opacity(0.3), MBColors.primary.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: MBColors.secondary.opacity(0.15), radius: 8, y: 4)
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            HStack {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 16))
                    .foregroundStyle(MBColors.primary.opacity(0.8))
                Text("Dream")
                    .font(MBTypography.headline())
                    .foregroundStyle(MBColors.textPrimary)
            }

            Text(dream.transcript)
                .font(.system(size: 16, weight: .regular, design: .serif))
                .foregroundStyle(MBColors.textSecondary)
                .lineSpacing(6)
                .italic()
        }
        .padding(MBSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                // Paper-like texture background
                MBColors.backgroundElevated
                // Subtle paper grain
                Color.white.opacity(0.02)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.lg)
                .stroke(MBColors.border.opacity(0.7), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    @ViewBuilder
    private var aiInsightsSection: some View {
        // Use purchaseService.isPro for instant reactivity after purchase
        let isPro = purchaseService.isPro

        VStack(alignment: .leading, spacing: MBSpacing.md) {
            // Section header with Pro badge
            HStack {
                Image(systemName: "sparkles.rectangle.stack")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MBColors.primary, MBColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("AI Insights")
                    .font(MBTypography.headline())
                    .foregroundStyle(MBColors.textPrimary)

                Spacer()

                // Pro badge
                Text("PRO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, MBSpacing.xs)
                    .padding(.vertical, 2)
                    .background(
                        LinearGradient(
                            colors: [MBColors.primary, MBColors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
            }

            if !isPro {
                // Not Pro - show upgrade prompt
                proUpgradePrompt
            } else if isLoadingInterpretation {
                // Loading state with skeleton
                interpretationLoadingView
            } else if let interpretation = interpretation {
                // Show interpretation
                interpretationContentView(interpretation)
            } else {
                // No interpretation yet - show generate button
                generateInterpretationView
            }
        }
        .padding(MBSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MBRadius.lg)
                .fill(MBColors.backgroundCard)
                .overlay(
                    RoundedRectangle(cornerRadius: MBRadius.lg)
                        .stroke(
                            LinearGradient(
                                colors: [MBColors.primary.opacity(0.3), MBColors.secondary.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private var proUpgradePrompt: some View {
        VStack(spacing: MBSpacing.md) {
            HStack(spacing: MBSpacing.sm) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(MBColors.textMuted)

                VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                    Text("Unlock AI Dream Analysis")
                        .font(MBTypography.body(.medium))
                        .foregroundStyle(MBColors.textPrimary)
                    Text("Get personalized insights about your dreams")
                        .font(MBTypography.caption())
                        .foregroundStyle(MBColors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showPaywall = true
            } label: {
                HStack(spacing: MBSpacing.xs) {
                    Image(systemName: "star.fill")
                    Text("Upgrade to Pro")
                }
            }
            .buttonStyle(.mbPrimary)
        }
    }

    private var interpretationLoadingView: some View {
        VStack(alignment: .leading, spacing: MBSpacing.md) {
            HStack(spacing: MBSpacing.sm) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: MBColors.primary))
                    .scaleEffect(0.8)
                Text("Analyzing your dream...")
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textSecondary)
            }

            // Skeleton loading lines
            VStack(alignment: .leading, spacing: MBSpacing.xs) {
                ForEach(0..<4, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(MBColors.backgroundElevated)
                        .frame(height: 12)
                        .frame(maxWidth: index == 3 ? 200 : .infinity)
                        .shimmer()
                }
            }

            Text("This usually takes 10-20 seconds")
                .font(MBTypography.caption())
                .foregroundStyle(MBColors.textMuted)
        }
    }

    private var generateInterpretationView: some View {
        VStack(spacing: MBSpacing.md) {
            HStack(spacing: MBSpacing.sm) {
                Image(systemName: "brain")
                    .font(.system(size: 20))
                    .foregroundStyle(MBColors.textMuted)
                    .symbolEffect(.pulse, isActive: isLoadingInterpretation)

                VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                    Text("Dream Interpretation")
                        .font(MBTypography.body(.medium))
                        .foregroundStyle(MBColors.textPrimary)
                    Text(isLoadingInterpretation ? "Analyzing your dream..." : "Discover the deeper meaning of your dream")
                        .font(MBTypography.caption())
                        .foregroundStyle(MBColors.textTertiary)
                }

                Spacer()
            }

            Button {
                generateInterpretation()
            } label: {
                HStack(spacing: MBSpacing.xs) {
                    if !isLoadingInterpretation {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isLoadingInterpretation ? "Generating..." : "Generate Interpretation")
                }
            }
            .buttonStyle(.mbPrimary(isLoading: isLoadingInterpretation))
            .disabled(isLoadingInterpretation)
        }
    }

    private func interpretationContentView(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            // Expandable text content
            Text(text)
                .font(MBTypography.body())
                .foregroundStyle(MBColors.textSecondary)
                .lineSpacing(4)
                .lineLimit(isInterpretationExpanded ? nil : 6)
                .animation(.easeInOut(duration: 0.2), value: isInterpretationExpanded)

            // Expand/collapse button
            if text.count > 300 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isInterpretationExpanded.toggle()
                    }
                    HapticManager.shared.impact(style: .light)
                } label: {
                    HStack(spacing: MBSpacing.xxs) {
                        Text(isInterpretationExpanded ? "Show less" : "Read more")
                            .font(MBTypography.caption(.semibold))
                        Image(systemName: isInterpretationExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundStyle(MBColors.primary)
                }
            }
        }
    }

    // MARK: - Interpretation Actions

    private func generateInterpretation() {
        Task {
            isLoadingInterpretation = true
            HapticManager.shared.impact(style: .medium)

            do {
                let result = try await interpretationService.getInterpretation(for: dream)
                withAnimation(.easeInOut(duration: 0.3)) {
                    interpretation = result
                }
                HapticManager.shared.notification(type: .success)
            } catch {
                self.error = error
                self.showError = true
                HapticManager.shared.notification(type: .error)
            }

            isLoadingInterpretation = false
        }
    }

    private var videoSection: some View {
        // Check if a completed video already exists for this dream
        let hasCompletedVideo = videoJobs.contains { $0.status == .completed }
        let hasActiveJob = videoJobs.contains { $0.status == .pending || $0.status == .processing }

        return VStack(alignment: .leading, spacing: MBSpacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MBColors.accent, MBColors.accentAlt],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                Text("Visualize")
                    .font(MBTypography.headline())
                    .foregroundStyle(MBColors.textPrimary)
            }

            if hasCompletedVideo {
                // Video already exists - show success state
                videoGeneratedView
            } else if hasActiveJob {
                // Video is being generated
                videoInProgressView
            } else if let profile = authService.userProfile {
                if profile.canGenerateVideo {
                    VStack(spacing: MBSpacing.sm) {
                        Button {
                            generateVideo()
                        } label: {
                            HStack(spacing: MBSpacing.xs) {
                                if !isGeneratingVideo {
                                    Image(systemName: "wand.and.stars")
                                        .symbolEffect(.bounce, value: isGeneratingVideo)
                                }
                                Text(isGeneratingVideo ? "Starting generation..." : "Generate Dream Video")
                            }
                        }
                        .buttonStyle(.mbCTA(isLoading: isGeneratingVideo))
                        .disabled(isGeneratingVideo || videoService.hasActiveGenerations)

                        if !isGeneratingVideo {
                            // Show quota/credits info
                            quotaInfoView(profile: profile)
                        }

                        // Tip about async generation
                        if !isGeneratingVideo && !videoService.hasActiveGenerations {
                            Text("You can leave this screen while your video generates. We'll notify you when it's ready!")
                                .font(MBTypography.caption())
                                .foregroundStyle(MBColors.textMuted)
                                .multilineTextAlignment(.center)
                        }
                    }
                } else {
                    // User cannot generate - show appropriate message
                    quotaExceededView(profile: profile)
                }
            }
        }
        .padding(MBSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                MBColors.backgroundCard
                // Subtle magical overlay
                LinearGradient(
                    colors: [MBColors.accent.opacity(0.03), MBColors.accentAlt.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.lg)
                .stroke(
                    LinearGradient(
                        colors: [MBColors.accent.opacity(0.4), MBColors.accentAlt.opacity(0.2), MBColors.accent.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: MBColors.accent.opacity(0.1), radius: 10, y: 4)
    }

    private var videoGeneratedView: some View {
        HStack(spacing: MBSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundStyle(MBColors.success)

            VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                Text("Video Generated")
                    .font(MBTypography.body(.medium))
                    .foregroundStyle(MBColors.textPrimary)
                Text("Your dream video is ready below")
                    .font(MBTypography.caption())
                    .foregroundStyle(MBColors.textTertiary)
            }

            Spacer()
        }
    }

    private var videoInProgressView: some View {
        HStack(spacing: MBSpacing.sm) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: MBColors.primary))

            VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                Text("Generating Video")
                    .font(MBTypography.body(.medium))
                    .foregroundStyle(MBColors.textPrimary)
                Text("This usually takes 1-2 minutes")
                    .font(MBTypography.caption())
                    .foregroundStyle(MBColors.textTertiary)
            }

            Spacer()
        }
    }

    private var generatedVideosSection: some View {
        VStack(alignment: .leading, spacing: MBSpacing.md) {
            HStack {
                Image(systemName: "video.fill")
                    .foregroundStyle(MBColors.accent)
                Text("Generated Videos")
                    .font(MBTypography.headline())
                    .foregroundStyle(MBColors.textPrimary)
            }

            VStack(spacing: MBSpacing.sm) {
                ForEach(videoJobs) { job in
                    VideoJobRow(job: job) {
                        playVideo(job: job)
                    }
                }
            }
        }
        .padding(MBSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MBColors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.lg)
                .stroke(MBColors.border, lineWidth: 1)
        )
    }

    // MARK: - Quota/Credits Views

    @ViewBuilder
    private func quotaInfoView(profile: UserProfileDTO) -> some View {
        if profile.subscriptionTier == .pro, let quota = profile.proQuotaStatus {
            // Pro user with quota info
            HStack(spacing: MBSpacing.xxs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                Text("\(quota.videosRemaining) of \(quota.quotaLimit) videos this month")
            }
            .font(MBTypography.caption())
            .foregroundStyle(ProQuotaUrgency.from(quota: quota).color)
        } else if profile.subscriptionTier == .free {
            // Free user with credits
            HStack(spacing: MBSpacing.xxs) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                Text("\(profile.creditsRemaining) free videos remaining")
            }
            .font(MBTypography.caption())
            .foregroundStyle(MBColors.textTertiary)
        }
    }

    @ViewBuilder
    private func quotaExceededView(profile: UserProfileDTO) -> some View {
        if profile.subscriptionTier == .pro, let quota = profile.proQuotaStatus {
            // Pro user hit monthly limit
            VStack(spacing: MBSpacing.md) {
                HStack(spacing: MBSpacing.sm) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 20))
                        .foregroundStyle(MBColors.warning)

                    VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                        Text("Monthly limit reached")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textPrimary)
                        Text("Resets \(quota.resetDateFormatted)")
                            .font(MBTypography.caption())
                            .foregroundStyle(MBColors.textTertiary)
                    }
                }
            }
        } else {
            // Free user with no credits
            VStack(spacing: MBSpacing.md) {
                HStack(spacing: MBSpacing.sm) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(MBColors.warning)

                    Text("No video credits remaining")
                        .font(MBTypography.body())
                        .foregroundStyle(MBColors.textSecondary)
                }

                Button {
                    showPaywall = true
                } label: {
                    HStack(spacing: MBSpacing.xs) {
                        Image(systemName: "star.fill")
                        Text("Upgrade to Pro")
                    }
                }
                .buttonStyle(.mbPrimary)
            }
        }
    }

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dream.createdAt)
    }

    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: dream.createdAt)
    }

    private func loadVideoJobs() async {
        isLoadingJobs = true
        defer { isLoadingJobs = false }

        do {
            videoJobs = try await videoService.fetchJobs(for: dream.id)
        } catch {
            print("Error loading video jobs: \(error)")
        }
    }

    private func generateVideo() {
        Task {
            isGeneratingVideo = true

            // Generate prompt from dream analysis
            let analysis = DreamAnalysisService.shared.analyzeDream(dream.transcript)
            let prompt = DreamAnalysisService.shared.generateVideoPrompt(from: analysis, transcript: dream.transcript)

            do {
                let job = try await videoService.generateVideo(for: dream, prompt: prompt)
                videoJobs.insert(job, at: 0)

                // Brief delay to show the job was added
                try? await Task.sleep(nanoseconds: 500_000_000)
                isGeneratingVideo = false

                // Provide haptic feedback
                HapticManager.shared.videoGenerationStarted()
            } catch {
                isGeneratingVideo = false
                self.error = error
                self.showError = true
                HapticManager.shared.error()
            }
        }
    }

    private func playVideo(job: VideoJobDTO) {
        HapticManager.shared.itemSelected()
        Task {
            do {
                print("DreamDetailView: Playing video for job \(job.id)")
                // Refetch job to get latest data (including video_url)
                let freshJob = try await videoService.fetchJob(id: job.id)
                print("DreamDetailView: Fresh job status: \(freshJob.status), videoPath: \(freshJob.videoPath ?? "nil"), videoUrl: \(freshJob.videoUrl ?? "nil")")
                let url = try await videoService.getVideoURL(for: freshJob)
                print("DreamDetailView: Got video URL: \(url)")
                videoURL = url
            } catch {
                print("DreamDetailView: Error playing video: \(error)")
                self.error = error
                self.showError = true
                HapticManager.shared.error()
            }
        }
    }

    private func saveEdits() {
        Task {
            do {
                _ = try await DreamService.shared.updateDream(
                    id: dream.id,
                    title: editedTitle.isEmpty ? nil : editedTitle,
                    transcript: editedTranscript
                )
                isEditing = false
                HapticManager.shared.success()
            } catch {
                self.error = error
                self.showError = true
                HapticManager.shared.error()
            }
        }
    }

    private func deleteDream() {
        HapticManager.shared.deleteAction()
        Task {
            do {
                try await DreamService.shared.deleteDream(id: dream.id)
                HapticManager.shared.success()
                // Use callback if provided (preferred for sheet dismissal)
                // Otherwise fall back to dismiss()
                if let onDelete = onDelete {
                    onDelete()
                } else {
                    dismiss()
                }
            } catch {
                self.error = error
                self.showError = true
                HapticManager.shared.error()
            }
        }
    }
}

// MARK: - Video Job Row

struct VideoJobRow: View {
    let job: VideoJobDTO
    let onPlay: () -> Void

    var body: some View {
        HStack(spacing: MBSpacing.md) {
            statusIcon

            VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                Text(statusText)
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textPrimary)

                Text(formattedDate)
                    .font(MBTypography.caption())
                    .foregroundStyle(MBColors.textTertiary)
            }

            Spacer()

            if job.status == .completed {
                Button(action: onPlay) {
                    HStack(spacing: MBSpacing.xxs) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                        Text("Play")
                            .font(MBTypography.label())
                    }
                    .foregroundStyle(MBColors.accent)
                    .padding(.horizontal, MBSpacing.sm)
                    .padding(.vertical, MBSpacing.xs)
                    .background(MBColors.accent.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(MBSpacing.sm)
        .background(MBColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch job.status {
        case .pending:
            MBVideoStatusBadge(status: .pending)
        case .processing:
            MBVideoStatusBadge(status: .processing)
        case .completed:
            MBVideoStatusBadge(status: .completed)
        case .failed:
            MBVideoStatusBadge(status: .failed)
        }
    }

    private var statusText: String {
        switch job.status {
        case .pending: return "Queued"
        case .processing: return "Generating..."
        case .completed: return "Ready to watch"
        case .failed: return job.errorMessage ?? "Generation failed"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: job.createdAt)
    }
}

// MARK: - Edit Dream Sheet

struct EditDreamSheet: View {
    @Binding var title: String
    @Binding var transcript: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                MBColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: MBSpacing.lg) {
                        // Title field
                        VStack(alignment: .leading, spacing: MBSpacing.xs) {
                            Text("Title")
                                .font(MBTypography.headline())
                                .foregroundStyle(MBColors.textPrimary)

                            TextField("Dream title", text: $title)
                                .font(MBTypography.body())
                                .foregroundStyle(MBColors.textPrimary)
                                .padding(MBSpacing.md)
                                .background(MBColors.backgroundCard)
                                .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: MBRadius.md)
                                        .stroke(MBColors.border, lineWidth: 1)
                                )
                        }

                        // Transcript field
                        VStack(alignment: .leading, spacing: MBSpacing.xs) {
                            Text("Dream")
                                .font(MBTypography.headline())
                                .foregroundStyle(MBColors.textPrimary)

                            TextEditor(text: $transcript)
                                .font(MBTypography.body())
                                .foregroundStyle(MBColors.textPrimary)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 250)
                                .padding(MBSpacing.md)
                                .background(MBColors.backgroundCard)
                                .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
                                .overlay(
                                    RoundedRectangle(cornerRadius: MBRadius.md)
                                        .stroke(MBColors.border, lineWidth: 1)
                                )
                        }
                    }
                    .padding(MBSpacing.md)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Edit Dream")
                        .font(MBTypography.headline())
                        .foregroundStyle(MBColors.textPrimary)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textSecondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onSave()
                    } label: {
                        Text("Save")
                            .font(MBTypography.label())
                            .foregroundStyle(MBColors.primary)
                    }
                }
            }
            .toolbarBackground(MBColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Flow Layout (Keep for backwards compatibility)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            size = CGSize(width: width, height: y + lineHeight)
        }
    }
}

#Preview {
    NavigationStack {
        DreamDetailView(dream: DreamDTO(
            id: UUID(),
            userId: UUID(),
            title: "Flying Over the City",
            transcript: "I was flying high above the city, looking down at all the buildings and cars. The feeling of freedom was incredible, and I could see for miles in every direction. The sun was setting, painting the sky in beautiful shades of orange and pink.",
            themes: ["Flying", "Freedom", "Adventure"],
            emotions: ["Joy", "Wonder", "Peace"],
            audioPath: nil,
            videoUrl: nil,
            videoPath: nil,
            interpretation: nil,
            createdAt: Date()
        ))
    }
    .environmentObject(AuthService.shared)
}
