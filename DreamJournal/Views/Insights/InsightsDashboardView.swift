import SwiftUI
import Charts

// MARK: - Insights Dashboard View

/// Time period options for emotion trend chart
enum EmotionTrendPeriod: Int, CaseIterable {
    case thirtyDays = 30
    case ninetyDays = 90
    case oneYear = 365

    var label: String {
        switch self {
        case .thirtyDays: return "30d"
        case .ninetyDays: return "90d"
        case .oneYear: return "1y"
        }
    }
}

struct InsightsDashboardView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var tabController: TabController
    @StateObject private var insightsService = InsightsService.shared
    @State private var showPaywall = false
    @State private var selectedTrendPeriod: EmotionTrendPeriod = .thirtyDays

    private var userName: String {
        authService.userProfile?.displayName ?? "Dreamer"
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<21: return "Good Evening"
        default: return "Sweet Dreams"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                MBColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MBSpacing.lg) {
                        // Header with greeting and streak
                        headerSection

                        if insightsService.isLoading {
                            dashboardSkeleton
                        } else if let insights = insightsService.insights {
                            // Quick stats
                            quickStatsSection(insights: insights)

                            // Theme chart
                            themeChartSection(insights: insights)

                            // Emotion chart
                            emotionChartSection(insights: insights)

                            // Day of week patterns
                            dayOfWeekSection(insights: insights)

                            // Emotional trend (Pro teaser)
                            emotionTrendSection(insights: insights)

                            // Recent dreams preview
                            recentDreamsSection

                            // Pro upsell card
                            if !purchaseService.isPro {
                                proUpsellCard
                            }
                        } else {
                            emptyStateView
                        }
                    }
                    .padding(.vertical, MBSpacing.md)
                }
                .refreshable {
                    HapticManager.shared.pullToRefresh()
                    await loadInsights()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Insights")
                        .font(MBTypography.headline())
                        .foregroundStyle(MBColors.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    creditsView
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .task {
            await loadInsights()
        }
        .sheet(isPresented: $showPaywall) {
            CustomSubscriptionView()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: MBSpacing.xxs) {
                Text(greeting + ",")
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textSecondary)

                Text(userName)
                    .font(MBTypography.largeTitle())
                    .foregroundStyle(MBColors.textPrimary)
            }

            Spacer()

            // Streak badge
            if let insights = insightsService.insights, insights.currentStreak > 0 {
                StreakBadge(streak: insights.currentStreak)
            }
        }
        .padding(.horizontal, MBSpacing.md)
    }

    // MARK: - Quick Stats Section

    private func quickStatsSection(insights: DreamInsights) -> some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            Text("YOUR JOURNEY")
                .font(MBTypography.overline())
                .foregroundStyle(MBColors.textMuted)
                .padding(.horizontal, MBSpacing.md)

            HStack(spacing: MBSpacing.sm) {
                StatCard(
                    title: "Total",
                    value: "\(insights.totalDreams)",
                    icon: "moon.stars.fill",
                    color: MBColors.primary
                )

                StatCard(
                    title: "This Week",
                    value: "\(insights.dreamsThisWeek)",
                    icon: "calendar",
                    color: MBColors.secondary
                )

                StatCard(
                    title: "Avg/Week",
                    value: String(format: "%.1f", insights.averageDreamsPerWeek),
                    icon: "chart.line.uptrend.xyaxis",
                    color: MBColors.accent
                )
            }
            .padding(.horizontal, MBSpacing.md)
        }
    }

    // MARK: - Theme Chart Section

    private func themeChartSection(insights: DreamInsights) -> some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            HStack {
                Text("YOUR DREAM THEMES")
                    .font(MBTypography.overline())
                    .foregroundStyle(MBColors.textMuted)

                Spacer()

                if !purchaseService.isPro && insights.themeFrequency.count > 3 {
                    Button {
                        HapticManager.shared.paywallPresented()
                        showPaywall = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text("See All")
                                .font(MBTypography.caption())
                        }
                        .foregroundStyle(MBColors.primary)
                    }
                }
            }
            .padding(.horizontal, MBSpacing.md)

            // Theme bar chart
            let displayThemes = purchaseService.isPro ?
                Array(insights.themeFrequency.prefix(8)) :
                Array(insights.themeFrequency.prefix(3))

            if !displayThemes.isEmpty {
                VStack(spacing: MBSpacing.xs) {
                    ForEach(displayThemes) { theme in
                        ThemeBarRow(theme: theme, maxCount: displayThemes.first?.count ?? 1)
                    }
                }
                .padding(MBSpacing.md)
                .background(MBColors.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: MBRadius.lg)
                        .stroke(MBColors.border, lineWidth: 1)
                )
                .padding(.horizontal, MBSpacing.md)
            } else {
                EmptyChartPlaceholder(message: "Record more dreams to see your themes")
                    .padding(.horizontal, MBSpacing.md)
            }
        }
    }

    // MARK: - Emotion Chart Section

    private func emotionChartSection(insights: DreamInsights) -> some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            HStack {
                Text("EMOTIONAL LANDSCAPE")
                    .font(MBTypography.overline())
                    .foregroundStyle(MBColors.textMuted)

                Spacer()

                if !purchaseService.isPro && insights.emotionFrequency.count > 3 {
                    Button {
                        HapticManager.shared.paywallPresented()
                        showPaywall = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                            Text("Full Breakdown")
                                .font(MBTypography.caption())
                        }
                        .foregroundStyle(MBColors.primary)
                    }
                }
            }
            .padding(.horizontal, MBSpacing.md)

            // Emotion distribution
            let displayEmotions = purchaseService.isPro ?
                Array(insights.emotionFrequency.prefix(6)) :
                Array(insights.emotionFrequency.prefix(3))

            if !displayEmotions.isEmpty {
                HStack(spacing: MBSpacing.sm) {
                    ForEach(displayEmotions) { emotion in
                        EmotionBubble(emotion: emotion)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(MBSpacing.md)
                .background(MBColors.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: MBRadius.lg)
                        .stroke(MBColors.border, lineWidth: 1)
                )
                .padding(.horizontal, MBSpacing.md)
            } else {
                EmptyChartPlaceholder(message: "Your emotional journey will appear here")
                    .padding(.horizontal, MBSpacing.md)
            }
        }
    }

    // MARK: - Emotion Trend Section (Pro Feature)

    private func emotionTrendSection(insights: DreamInsights) -> some View {
        let trendData = insightsService.getEmotionTrend(days: selectedTrendPeriod.rawValue)
        let strideCount = selectedTrendPeriod == .oneYear ? 30 : 7

        return VStack(alignment: .leading, spacing: MBSpacing.sm) {
            HStack {
                Text("EMOTIONAL TREND")
                    .font(MBTypography.overline())
                    .foregroundStyle(MBColors.textMuted)

                Spacer()

                if !purchaseService.isPro {
                    HStack(spacing: 4) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                        Text("PRO")
                            .font(MBTypography.overline())
                    }
                    .foregroundStyle(MBColors.accent)
                }
            }
            .padding(.horizontal, MBSpacing.md)

            // Time period selector (Pro only)
            if purchaseService.isPro {
                Picker("Period", selection: $selectedTrendPeriod) {
                    ForEach(EmotionTrendPeriod.allCases, id: \.self) { period in
                        Text(period.label).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, MBSpacing.md)
                .onChange(of: selectedTrendPeriod) { _, _ in
                    HapticManager.shared.selection()
                }
            }

            ZStack {
                if purchaseService.isPro && !trendData.isEmpty {
                    // Real chart for Pro users
                    Chart(trendData) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Positivity", point.positiveScore)
                        )
                        .foregroundStyle(MBColors.primary.gradient)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Positivity", point.positiveScore)
                        )
                        .foregroundStyle(MBColors.primary.opacity(0.2).gradient)
                        .interpolationMethod(.catmullRom)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day, count: strideCount)) { _ in
                            AxisGridLine()
                            AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        }
                    }
                    .frame(height: 150)
                    .animation(.easeInOut(duration: 0.3), value: selectedTrendPeriod)
                } else if purchaseService.isPro && trendData.isEmpty {
                    // Empty state for Pro users with no data
                    VStack(spacing: MBSpacing.sm) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 32))
                            .foregroundStyle(MBColors.textMuted)
                        Text("No emotion data for this period")
                            .font(MBTypography.caption())
                            .foregroundStyle(MBColors.textMuted)
                    }
                    .frame(height: 150)
                    .frame(maxWidth: .infinity)
                } else {
                    // Blurred preview for free users
                    ProFeatureTeaser(
                        title: "Emotional Journey",
                        description: "Track how your emotions evolve over time",
                        icon: "chart.line.uptrend.xyaxis"
                    ) {
                        showPaywall = true
                    }
                }
            }
            .padding(MBSpacing.md)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.border, lineWidth: 1)
            )
            .padding(.horizontal, MBSpacing.md)
        }
    }

    // MARK: - Day of Week Section

    private func dayOfWeekSection(insights: DreamInsights) -> some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            Text("DREAM PATTERNS")
                .font(MBTypography.overline())
                .foregroundStyle(MBColors.textMuted)
                .padding(.horizontal, MBSpacing.md)

            let maxCount = insights.dreamsByDayOfWeek.map(\.count).max() ?? 1

            if maxCount > 0 {
                HStack(spacing: MBSpacing.xs) {
                    ForEach(insights.dreamsByDayOfWeek) { day in
                        DayOfWeekBar(day: day, maxCount: maxCount)
                    }
                }
                .padding(MBSpacing.md)
                .background(MBColors.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: MBRadius.lg)
                        .stroke(MBColors.border, lineWidth: 1)
                )
                .padding(.horizontal, MBSpacing.md)
            } else {
                EmptyChartPlaceholder(message: "Record more dreams to see patterns")
                    .padding(.horizontal, MBSpacing.md)
            }
        }
    }

    // MARK: - Recent Dreams Section

    private var recentDreamsSection: some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            HStack {
                Text("RECENT DREAMS")
                    .font(MBTypography.overline())
                    .foregroundStyle(MBColors.textMuted)

                Spacer()

                NavigationLink {
                    DreamListView()
                } label: {
                    Text("See All")
                        .font(MBTypography.caption())
                        .foregroundStyle(MBColors.primary)
                }
            }
            .padding(.horizontal, MBSpacing.md)

            if insightsService.recentDreams.isEmpty {
                Text("No dreams recorded yet")
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(MBSpacing.lg)
                    .background(MBColors.backgroundCard)
                    .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
                    .padding(.horizontal, MBSpacing.md)
            } else {
                VStack(spacing: MBSpacing.sm) {
                    ForEach(insightsService.recentDreams) { dream in
                        NavigationLink {
                            DreamDetailView(dream: dream)
                        } label: {
                            RecentDreamRow(dream: dream)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(MBSpacing.md)
                .background(MBColors.backgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: MBRadius.lg)
                        .stroke(MBColors.border, lineWidth: 1)
                )
                .padding(.horizontal, MBSpacing.md)
            }
        }
    }

    // MARK: - Pro Upsell Card

    private var proUpsellCard: some View {
        Button {
            HapticManager.shared.paywallPresented()
            showPaywall = true
        } label: {
            HStack(spacing: MBSpacing.md) {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundStyle(MBColors.accent)

                VStack(alignment: .leading, spacing: MBSpacing.xxs) {
                    Text("Unlock Deep Insights")
                        .font(MBTypography.headline())
                        .foregroundStyle(MBColors.textPrimary)

                    Text("Full analytics, patterns, and emotional journey tracking")
                        .font(MBTypography.caption())
                        .foregroundStyle(MBColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(MBColors.textMuted)
            }
            .padding(MBSpacing.md)
            .background(
                LinearGradient(
                    colors: [MBColors.primary.opacity(0.1), MBColors.accent.opacity(0.1)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.primary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, MBSpacing.md)
    }

    // MARK: - Supporting Views

    private var creditsView: some View {
        Group {
            if let profile = authService.userProfile {
                MBCreditsBadge(
                    credits: profile.creditsRemaining,
                    isPro: profile.subscriptionTier == .pro
                )
            }
        }
    }

    private var dashboardSkeleton: some View {
        VStack(spacing: MBSpacing.lg) {
            // Stats skeleton
            HStack(spacing: MBSpacing.sm) {
                ForEach(0..<3, id: \.self) { _ in
                    MBSkeletonRectangle(width: nil, height: 80)
                }
            }
            .padding(.horizontal, MBSpacing.md)

            // Chart skeleton
            MBSkeletonRectangle(width: nil, height: 200)
                .padding(.horizontal, MBSpacing.md)

            MBSkeletonRectangle(width: nil, height: 100)
                .padding(.horizontal, MBSpacing.md)
        }
        .mbShimmer()
    }

    private var emptyStateView: some View {
        MBEmptyState(
            icon: "chart.bar.xaxis",
            title: "No Insights Yet",
            message: "Record your first dream to start building your personal dream profile.",
            actionTitle: "Record Dream"
        ) {
            tabController.switchToRecord()
        }
    }

    // MARK: - Actions

    private func loadInsights() async {
        guard let userId = authService.currentUser?.id else { return }
        await insightsService.generateInsights(for: userId)
    }
}

// MARK: - Supporting Components

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: MBSpacing.xxs) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16))
                .foregroundStyle(MBColors.warning)

            Text("\(streak)")
                .font(MBTypography.headline())
                .foregroundStyle(MBColors.textPrimary)
        }
        .padding(.horizontal, MBSpacing.sm)
        .padding(.vertical, MBSpacing.xs)
        .background(MBColors.backgroundCard)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(MBColors.warning.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: MBSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)

            Text(value)
                .font(MBTypography.title())
                .foregroundStyle(MBColors.textPrimary)

            Text(title)
                .font(MBTypography.caption())
                .foregroundStyle(MBColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(MBSpacing.md)
        .background(MBColors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.lg)
                .stroke(MBColors.border, lineWidth: 1)
        )
    }
}

struct ThemeBarRow: View {
    let theme: ThemeFrequency
    let maxCount: Int

    var body: some View {
        HStack(spacing: MBSpacing.sm) {
            Image(systemName: MBThemes.icon(for: theme.theme))
                .font(.system(size: 14))
                .foregroundStyle(MBThemes.color(for: theme.theme))
                .frame(width: 20)

            Text(theme.theme.capitalized)
                .font(MBTypography.body())
                .foregroundStyle(MBColors.textPrimary)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(MBThemes.color(for: theme.theme))
                    .frame(width: geometry.size.width * CGFloat(theme.count) / CGFloat(maxCount))
            }
            .frame(height: 12)

            Text("\(theme.count)")
                .font(MBTypography.caption())
                .foregroundStyle(MBColors.textMuted)
                .frame(width: 30, alignment: .trailing)
        }
    }
}

struct EmotionBubble: View {
    let emotion: EmotionFrequency

    var body: some View {
        VStack(spacing: MBSpacing.xxs) {
            Image(systemName: MBEmotions.icon(for: emotion.emotion))
                .font(.system(size: 20))
                .foregroundStyle(MBEmotions.color(for: emotion.emotion))

            Text(emotion.emotion.capitalized)
                .font(MBTypography.caption())
                .foregroundStyle(MBColors.textSecondary)

            Text("\(Int(emotion.percentage))%")
                .font(MBTypography.overline())
                .foregroundStyle(MBColors.textMuted)
        }
        .frame(maxWidth: .infinity)
    }
}

struct EmptyChartPlaceholder: View {
    let message: String

    var body: some View {
        VStack(spacing: MBSpacing.sm) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundStyle(MBColors.textMuted)

            Text(message)
                .font(MBTypography.body())
                .foregroundStyle(MBColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(MBSpacing.xl)
        .background(MBColors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.lg)
                .stroke(MBColors.border, lineWidth: 1)
        )
    }
}

struct ProFeatureTeaser: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: MBSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(MBColors.primary)

                VStack(spacing: MBSpacing.xxs) {
                    Text(title)
                        .font(MBTypography.headline())
                        .foregroundStyle(MBColors.textPrimary)

                    Text(description)
                        .font(MBTypography.caption())
                        .foregroundStyle(MBColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                    Text("Unlock with Pro")
                        .font(MBTypography.bodyBold())
                }
                .foregroundStyle(MBColors.accent)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
        }
        .buttonStyle(.plain)
    }
}

struct DayOfWeekBar: View {
    let day: DayOfWeekCount
    let maxCount: Int

    var body: some View {
        VStack(spacing: MBSpacing.xxs) {
            // Bar
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 4)
                        .fill(day.count > 0 ? MBColors.primary : MBColors.textMuted.opacity(0.2))
                        .frame(height: maxCount > 0 ? geometry.size.height * CGFloat(day.count) / CGFloat(maxCount) : 0)
                }
            }
            .frame(height: 60)

            // Count
            Text("\(day.count)")
                .font(MBTypography.caption())
                .foregroundStyle(day.count > 0 ? MBColors.textPrimary : MBColors.textMuted)

            // Day name
            Text(day.dayName)
                .font(MBTypography.overline())
                .foregroundStyle(MBColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecentDreamRow: View {
    let dream: DreamDTO

    private var formattedDate: String {
        MBDateFormatter.abbreviatedRelativeTime(for: dream.createdAt)
    }

    private var primaryEmotion: String? {
        dream.emotions.first
    }

    var body: some View {
        HStack(spacing: MBSpacing.sm) {
            // Emotion indicator
            if let emotion = primaryEmotion {
                Image(systemName: MBEmotions.icon(for: emotion))
                    .font(.system(size: 20))
                    .foregroundStyle(MBEmotions.color(for: emotion))
                    .frame(width: 32, height: 32)
                    .background(MBEmotions.color(for: emotion).opacity(0.15))
                    .clipShape(Circle())
            } else {
                Image(systemName: "moon.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(MBColors.primary)
                    .frame(width: 32, height: 32)
                    .background(MBColors.primary.opacity(0.15))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                Text(dream.title ?? "Untitled Dream")
                    .font(MBTypography.body(.medium))
                    .foregroundStyle(MBColors.textPrimary)
                    .lineLimit(1)

                Text(formattedDate)
                    .font(MBTypography.caption())
                    .foregroundStyle(MBColors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(MBColors.textMuted)
        }
        .padding(MBSpacing.sm)
        .background(MBColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
    }
}

// MARK: - Preview

#Preview {
    InsightsDashboardView()
        .environmentObject(AuthService.shared)
        .environmentObject(PurchaseService.shared)
        .environmentObject(TabController.shared)
}
