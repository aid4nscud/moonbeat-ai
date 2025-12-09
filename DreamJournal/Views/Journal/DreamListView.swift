import SwiftUI

struct DreamListView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var tabController: TabController
    @State private var dreams: [DreamDTO] = []
    @State private var isLoading = true
    @State private var error: Error?
    @State private var showError = false
    @State private var selectedDream: DreamDTO?
    @State private var appeared = false

    // Search and filter state
    @State private var searchText = ""
    @State private var selectedThemes: Set<String> = []
    @State private var selectedEmotions: Set<String> = []
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                MBColors.background
                    .ignoresSafeArea()

                Group {
                    if isLoading {
                        MBDreamListSkeleton(count: 4)
                    } else if dreams.isEmpty {
                        emptyStateView
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.95)
                            .animation(.easeOut(duration: 0.4), value: appeared)
                    } else {
                        dreamListContent
                    }
                }
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    appeared = true
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Dreams")
                        .font(MBTypography.headline())
                        .foregroundStyle(MBColors.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    creditsView
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .refreshable {
                HapticManager.shared.pullToRefresh()
                await fetchDreams()
            }
        }
        .task {
            await fetchDreams()
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
        .sheet(item: $selectedDream) { dream in
            NavigationStack {
                DreamDetailView(dream: dream) {
                    // Handle deletion by clearing selection and refreshing
                    selectedDream = nil
                    Task {
                        await fetchDreams()
                    }
                }
            }
        }
    }

    // MARK: - Views

    private var loadingView: some View {
        MBLoadingView(message: "Loading dreams...")
    }

    private var emptyStateView: some View {
        MBEmptyState(
            icon: "moon.zzz.fill",
            title: "No Dreams Yet",
            message: "Start recording your dreams using the Record tab below.",
            actionTitle: "Record Dream"
        ) {
            tabController.switchToRecord()
        }
    }

    private var dreamListContent: some View {
        ScrollView {
            LazyVStack(spacing: MBSpacing.lg) {
                // Search and filter bar
                VStack(spacing: MBSpacing.sm) {
                    MBSearchBar(text: $searchText, placeholder: "Search dreams...")

                    if !availableThemes.isEmpty || !availableEmotions.isEmpty {
                        MBFilterBar(
                            themes: availableThemes,
                            emotions: availableEmotions,
                            selectedThemes: $selectedThemes,
                            selectedEmotions: $selectedEmotions
                        )
                    }
                }
                .padding(.horizontal, MBSpacing.md)

                // Dream sections
                ForEach(Array(groupedFilteredDreams.enumerated()), id: \.element.0) { sectionIndex, section in
                    let (date, sectionDreams) = section
                    VStack(alignment: .leading, spacing: MBSpacing.sm) {
                        // Enhanced section header with moon phase
                        MBDateSectionHeader(date: date, dreamCount: sectionDreams.count)
                            .padding(.horizontal, MBSpacing.md)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.easeOut(duration: 0.3).delay(Double(sectionIndex) * 0.1), value: appeared)

                        // Dream cards with staggered animation
                        VStack(spacing: MBSpacing.sm) {
                            ForEach(Array(sectionDreams.enumerated()), id: \.element.id) { dreamIndex, dream in
                                let globalIndex = sectionIndex * 10 + dreamIndex
                                EnhancedDreamRow(
                                    dream: dream,
                                    index: globalIndex,
                                    onDelete: {
                                        deleteDream(dream)
                                    },
                                    onShare: {
                                        shareDream(dream)
                                    }
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    HapticManager.shared.cardPressed()
                                    selectedDream = dream
                                }
                                .contextMenu {
                                    Button {
                                        HapticManager.shared.selection()
                                        shareDream(dream)
                                    } label: {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                    }

                                    Button(role: .destructive) {
                                        HapticManager.shared.deleteAction()
                                        deleteDream(dream)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }

                // Empty search results
                if groupedFilteredDreams.isEmpty && !dreams.isEmpty {
                    VStack(spacing: MBSpacing.md) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(MBColors.textMuted)
                        Text("No dreams match your search")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textSecondary)
                        Button("Clear Filters") {
                            searchText = ""
                            selectedThemes.removeAll()
                            selectedEmotions.removeAll()
                        }
                        .font(MBTypography.bodyBold())
                        .foregroundStyle(MBColors.primary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MBSpacing.xxl)
                }
            }
            .padding(.vertical, MBSpacing.md)
        }
        .scrollContentBackground(.hidden)
    }

    private var creditsView: some View {
        Group {
            if let profile = authService.userProfile {
                MBCreditsBadge(
                    credits: profile.creditsRemaining,
                    isPro: purchaseService.isPro  // Use purchaseService for instant reactivity
                )
            }
        }
    }

    // MARK: - Data

    /// All available themes from the user's dreams for filtering
    private var availableThemes: [String] {
        let allThemes = dreams.flatMap { $0.themes }
        return Array(Set(allThemes)).sorted()
    }

    /// All available emotions from the user's dreams for filtering
    private var availableEmotions: [String] {
        let allEmotions = dreams.flatMap { $0.emotions }
        return Array(Set(allEmotions)).sorted()
    }

    /// Dreams filtered by search text and selected filters
    private var filteredDreams: [DreamDTO] {
        dreams.filter { dream in
            // Search text filter
            let matchesSearch = searchText.isEmpty ||
                (dream.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                dream.transcript.localizedCaseInsensitiveContains(searchText)

            // Theme filter
            let matchesThemes = selectedThemes.isEmpty ||
                dream.themes.contains(where: { selectedThemes.contains($0) })

            // Emotion filter
            let matchesEmotions = selectedEmotions.isEmpty ||
                dream.emotions.contains(where: { selectedEmotions.contains($0) })

            return matchesSearch && matchesThemes && matchesEmotions
        }
    }

    /// Grouped filtered dreams by date
    private var groupedFilteredDreams: [(Date, [DreamDTO])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredDreams) { dream in
            calendar.startOfDay(for: dream.createdAt)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private var groupedDreams: [(String, [DreamDTO])] {
        let grouped = Dictionary(grouping: dreams) { dream in
            formatDate(dream.createdAt)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    private func formatDate(_ date: Date) -> String {
        MBDateFormatter.relativeDateString(for: date)
    }

    private func fetchDreams() async {
        guard let userId = authService.currentUser?.id else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            dreams = try await DreamService.shared.fetchDreams(for: userId)
        } catch {
            self.error = error
            self.showError = true
        }
    }

    private func deleteDream(_ dream: DreamDTO) {
        Task {
            do {
                try await DreamService.shared.deleteDream(id: dream.id)
                await fetchDreams()
            } catch {
                self.error = error
                self.showError = true
            }
        }
    }

    private func deleteDreams(at offsets: IndexSet, from dreams: [DreamDTO]) {
        Task {
            for index in offsets {
                let dream = dreams[index]
                do {
                    try await DreamService.shared.deleteDream(id: dream.id)
                    await fetchDreams()
                } catch {
                    self.error = error
                    self.showError = true
                }
            }
        }
    }

    private func shareDream(_ dream: DreamDTO) {
        let title = dream.title ?? "Dream"
        let date = MBDateFormatter.relativeDateString(for: dream.createdAt)
        let themes = dream.themes.joined(separator: ", ")
        let emotions = dream.emotions.joined(separator: ", ")

        var shareText = "🌙 \(title)\n\n"
        shareText += "\(dream.transcript)\n\n"
        if !themes.isEmpty {
            shareText += "Themes: \(themes)\n"
        }
        if !emotions.isEmpty {
            shareText += "Emotions: \(emotions)\n"
        }
        shareText += "\nRecorded on \(date) with Moonbeat AI"

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Handle iPad popover
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Enhanced Dream Row

struct EnhancedDreamRow: View {
    let dream: DreamDTO
    var index: Int = 0
    var onDelete: (() -> Void)?
    var onShare: (() -> Void)?

    @State private var isPressed = false
    @State private var hasAppeared = false
    @State private var swipeOffset: CGFloat = 0
    @State private var showDeleteConfirm = false

    /// Dominant emotion determines the sentiment bar color
    private var dominantEmotion: String? {
        dream.emotions.first
    }

    /// Determine overall sentiment from emotions
    private var sentiment: MBEmotions.Sentiment {
        guard let emotion = dominantEmotion else { return .neutral }
        return MBEmotions.sentiment(for: emotion)
    }

    /// Color for sentiment indicator
    private var sentimentColor: Color {
        guard let emotion = dominantEmotion else { return MBColors.textMuted }
        return MBEmotions.color(for: emotion)
    }

    /// Check if dream has video
    private var hasVideo: Bool {
        dream.videoUrl != nil
    }

    /// Dynamic shadow based on press state
    private var cardShadow: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        if isPressed {
            return (Color.black.opacity(0.05), 2, 0, 1)
        } else {
            return (Color.black.opacity(0.12), 8, 0, 4)
        }
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Swipe action background
            swipeActionBackground

            // Main card content
            cardContent
                .offset(x: swipeOffset)
                .gesture(swipeGesture)
        }
        .padding(.horizontal, MBSpacing.md)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05)) {
                hasAppeared = true
            }
        }
        .alert("Delete Dream?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {
                withAnimation(.spring(response: 0.3)) {
                    swipeOffset = 0
                }
            }
            Button("Delete", role: .destructive) {
                HapticManager.shared.deleteAction()
                onDelete?()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Card Content

    private var cardContent: some View {
        HStack(spacing: 0) {
            // Left sentiment bar with gradient
            sentimentBar

            // Main content
            VStack(alignment: .leading, spacing: MBSpacing.sm) {
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: MBSpacing.xxs) {
                        HStack(spacing: MBSpacing.xs) {
                            Text(dream.title ?? "Untitled Dream")
                                .font(MBTypography.headline())
                                .foregroundStyle(MBColors.textPrimary)
                                .lineLimit(2)

                            // Video indicator
                            if hasVideo {
                                MBVideoIndicator()
                            }
                        }

                        HStack(spacing: MBSpacing.xs) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(MBDateFormatter.timeString(for: dream.createdAt))

                            if let emotion = dominantEmotion {
                                Text("•")
                                Image(systemName: MBEmotions.icon(for: emotion))
                                    .font(.system(size: 10))
                                    .foregroundStyle(MBEmotions.color(for: emotion))
                            }
                        }
                        .font(MBTypography.caption())
                        .foregroundStyle(MBColors.textTertiary)
                    }

                    Spacer()

                    // Moon phase icon with subtle glow
                    Image(systemName: MBMoonPhase.icon(for: dream.createdAt))
                        .font(.system(size: 16))
                        .foregroundStyle(MBColors.primary.opacity(0.7))
                        .shadow(color: MBColors.primary.opacity(0.3), radius: 4, x: 0, y: 0)
                }

                // Transcript preview
                Text(dream.transcript)
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textSecondary)
                    .lineLimit(2)

                // Enhanced tags with theme icons
                if !dream.themes.isEmpty {
                    MBFlowLayout(spacing: MBSpacing.xxs) {
                        ForEach(dream.themes.prefix(3), id: \.self) { theme in
                            HStack(spacing: 2) {
                                Image(systemName: MBThemes.icon(for: theme))
                                    .font(.system(size: 9))
                                Text(theme)
                            }
                            .mbTag(color: MBThemes.color(for: theme))
                        }

                        if !dream.emotions.isEmpty {
                            ForEach(dream.emotions.prefix(2), id: \.self) { emotion in
                                HStack(spacing: 2) {
                                    Image(systemName: MBEmotions.icon(for: emotion))
                                        .font(.system(size: 9))
                                    Text(emotion)
                                }
                                .mbTag(color: MBEmotions.color(for: emotion))
                            }
                        }

                        // Show count of remaining tags
                        let remainingCount = (dream.themes.count - 3) + (dream.emotions.count - 2)
                        if remainingCount > 0 {
                            Text("+\(max(0, remainingCount))")
                                .mbTag(color: MBColors.textMuted)
                        }
                    }
                }
            }
            .padding(MBSpacing.md)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                MBColors.backgroundCard
                // Subtle gradient overlay for depth
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.03),
                        Color.clear
                    ],
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
                        colors: [
                            MBColors.border.opacity(0.8),
                            MBColors.border.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        // Dynamic shadow system
        .shadow(color: cardShadow.color, radius: cardShadow.radius, x: cardShadow.x, y: cardShadow.y)
        // Subtle inner highlight
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.lg)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
                .padding(1)
        )
        // Press effect
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
    }

    // MARK: - Sentiment Bar

    private var sentimentBar: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [
                        sentimentColor,
                        sentimentColor.opacity(0.6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4)
            .padding(.vertical, MBSpacing.sm)
            .shadow(color: sentimentColor.opacity(0.4), radius: 4, x: 0, y: 0)
    }

    // MARK: - Swipe Actions

    private var swipeActionBackground: some View {
        HStack(spacing: 0) {
            Spacer()

            // Share button
            Button {
                HapticManager.shared.selection()
                withAnimation(.spring(response: 0.3)) {
                    swipeOffset = 0
                }
                onShare?()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: .infinity)
                    .background(MBColors.secondary)
            }

            // Delete button
            Button {
                HapticManager.shared.warning()
                showDeleteConfirm = true
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 60, height: .infinity)
                    .background(MBColors.error)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
        .opacity(swipeOffset < -20 ? 1 : 0)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onChanged { value in
                let translation = value.translation.width
                // Only allow left swipe
                if translation < 0 {
                    // Add resistance as user swipes further
                    let resistance: CGFloat = 0.6
                    swipeOffset = translation * resistance
                }
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.width

                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    // If swiped far enough or with enough velocity, snap to reveal actions
                    if swipeOffset < -60 || velocity < -500 {
                        swipeOffset = -120
                        HapticManager.shared.impact(style: .medium)
                    } else {
                        swipeOffset = 0
                    }
                }
            }
    }

    // MARK: - Press Handler

    func handlePress(_ pressed: Bool) {
        isPressed = pressed
        if pressed {
            HapticManager.shared.impact(style: .light)
        }
    }
}

// MARK: - Legacy Dream Row (kept for compatibility)

struct DreamRow: View {
    let dream: DreamDTO

    var body: some View {
        EnhancedDreamRow(dream: dream)
    }

    private var timeString: String {
        MBDateFormatter.timeString(for: dream.createdAt)
    }
}

extension DreamDTO: Hashable {
    static func == (lhs: DreamDTO, rhs: DreamDTO) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

#Preview {
    DreamListView()
        .environmentObject(AuthService.shared)
        .environmentObject(TabController.shared)
}
