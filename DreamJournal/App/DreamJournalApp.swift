import SwiftUI
import Supabase
import RevenueCat

// MARK: - Tab Controller

@MainActor
class TabController: ObservableObject {
    static let shared = TabController()
    @Published var selectedTab: Int = 0

    // Tab indices
    static let homeTab = 0
    static let dreamsTab = 1
    static let recordTab = 2
    static let settingsTab = 3

    func switchToHome() {
        HapticManager.shared.tabChanged()
        selectedTab = Self.homeTab
    }

    func switchToDreams() {
        HapticManager.shared.tabChanged()
        selectedTab = Self.dreamsTab
    }

    func switchToRecord() {
        HapticManager.shared.tabChanged()
        selectedTab = Self.recordTab
    }

    func switchToSettings() {
        HapticManager.shared.tabChanged()
        selectedTab = Self.settingsTab
    }
}

@main
struct DreamJournalApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var purchaseService = PurchaseService.shared
    @StateObject private var tabController = TabController.shared

    init() {
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(purchaseService)
                .environmentObject(tabController)
                .preferredColorScheme(.dark)
                .task {
                    await authService.checkExistingSession()

                    // Configure RevenueCat when user is authenticated
                    if let userId = authService.currentUser?.id.uuidString {
                        await purchaseService.configure(userId: userId)
                    }
                }
                .onChange(of: authService.isAuthenticated) { _, isAuthenticated in
                    Task {
                        if isAuthenticated, let userId = authService.currentUser?.id.uuidString {
                            await purchaseService.configure(userId: userId)
                        } else {
                            purchaseService.cleanup()
                        }
                    }
                }
        }
    }

    private func configureAppearance() {
        // Tab Bar Appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(MBColors.backgroundElevated)
        tabBarAppearance.shadowColor = UIColor(MBColors.border)

        // Unselected tab items
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(MBColors.textMuted)
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(MBColors.textMuted),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        // Selected tab items
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(MBColors.primary)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(MBColors.primary),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Navigation Bar Appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(MBColors.background)
        navBarAppearance.shadowColor = UIColor(MBColors.border.opacity(0.5))
        navBarAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(MBColors.textPrimary),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navBarAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(MBColors.textPrimary),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().tintColor = UIColor(MBColors.primary)
    }
}

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            if authService.isAuthenticated {
                if hasCompletedOnboarding {
                    MainTabView()
                        .transition(MBTransition.scaleWithFade)
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .transition(MBTransition.slideUp)
                }
            } else {
                SignInView()
                    .transition(MBTransition.scaleWithFade)
            }
        }
        .animation(MBAnimation.modalPresent, value: authService.isAuthenticated)
        .animation(MBAnimation.modalPresent, value: hasCompletedOnboarding)
    }
}

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var purchaseService: PurchaseService
    @EnvironmentObject var tabController: TabController
    @StateObject private var videoService = VideoService.shared
    @StateObject private var insightsService = InsightsService.shared

    @State private var showStreakCelebration = false
    @State private var celebratingMilestone: StreakMilestone?
    @State private var previousTab = 0
    @State private var showProfileError = false

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $tabController.selectedTab) {
                // Home/Insights Dashboard - Primary tab
                InsightsDashboardView()
                    .tabItem {
                        Label("Home", systemImage: tabController.selectedTab == TabController.homeTab ? "house.fill" : "house")
                    }
                    .tag(TabController.homeTab)

                // Dream Journal List
                DreamListView()
                    .tabItem {
                        Label("Dreams", systemImage: tabController.selectedTab == TabController.dreamsTab ? "moon.stars.fill" : "moon.stars")
                    }
                    .tag(TabController.dreamsTab)

                // Record New Dream
                RecordDreamView()
                    .tabItem {
                        Label("Record", systemImage: tabController.selectedTab == TabController.recordTab ? "mic.circle.fill" : "mic.circle")
                    }
                    .tag(TabController.recordTab)

                // Settings & Account
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: tabController.selectedTab == TabController.settingsTab ? "gearshape.fill" : "gearshape")
                    }
                    .tag(TabController.settingsTab)
            }
            .tint(MBColors.primary)
            .animation(MBAnimation.tabSwitch, value: tabController.selectedTab)

            // Floating video generation banner
            VideoGenerationBanner()
                .padding(.top, 50) // Below the nav bar
                .transition(MBTransition.slideUp)
        }
        .streakCelebration(isActive: $showStreakCelebration, milestone: celebratingMilestone)
        .onChange(of: tabController.selectedTab) { oldTab, newTab in
            previousTab = oldTab
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await updateEngagementNotifications()
                }
            }
        }
        .task {
            await updateEngagementNotifications()
        }
        .onChange(of: authService.profileError != nil) { _, hasError in
            if hasError {
                showProfileError = true
            }
        }
        .alert(
            "Profile Error",
            isPresented: $showProfileError,
            presenting: authService.profileError
        ) { error in
            Button("Retry") {
                Task {
                    await authService.retryProfileLoad()
                }
            }
            Button("Dismiss", role: .cancel) {
                authService.clearProfileError()
            }
        } message: { error in
            Text(error.localizedDescription)
        }
    }

    private func updateEngagementNotifications() async {
        guard let userId = authService.currentUser?.id else { return }

        // Get current stats
        if let stats = await insightsService.getQuickStats(for: userId) {
            let insights = insightsService.insights
            let topTheme = insights?.themeFrequency.first?.theme

            // Check if today's dream triggered a milestone
            let calendar = Calendar.current
            let hasRecordedToday = insights?.lastDreamDate.map {
                calendar.isDateInToday($0)
            } ?? false

            // Update notifications
            NotificationService.shared.updateEngagementNotifications(
                currentStreak: stats.streak,
                hasRecordedToday: hasRecordedToday,
                weeklyDreamCount: stats.thisWeek,
                topTheme: topTheme
            )

            // Check for celebration (only when recorded today)
            if hasRecordedToday, let milestone = StreakMilestone(rawValue: stats.streak) {
                let celebrated = UserDefaults.standard.array(forKey: "celebrated_milestones") as? [Int] ?? []
                if !celebrated.contains(stats.streak) {
                    celebratingMilestone = milestone
                    showStreakCelebration = true
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService.shared)
        .environmentObject(PurchaseService.shared)
        .environmentObject(TabController.shared)
}
