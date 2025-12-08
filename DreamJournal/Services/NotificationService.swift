import Foundation
import UserNotifications

// MARK: - Notification Preferences

struct NotificationPreferences: Codable {
    var morningReminderEnabled: Bool = true
    var morningReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    var streakAlertsEnabled: Bool = true
    var streakMilestonesEnabled: Bool = true
    var weeklyDigestEnabled: Bool = true

    static let defaultPreferences = NotificationPreferences()
}

// MARK: - Streak Milestones

enum StreakMilestone: Int, CaseIterable {
    case week = 7
    case twoWeeks = 14
    case month = 30
    case twoMonths = 60
    case quarter = 90
    case halfYear = 180
    case year = 365

    var celebration: String {
        switch self {
        case .week: return "One week of dreams! You're building a great habit."
        case .twoWeeks: return "Two weeks strong! Your dream journal is growing."
        case .month: return "A full month! You're a dedicated dreamer."
        case .twoMonths: return "Two months of insights! Your patterns are emerging."
        case .quarter: return "90 days! You're unlocking deep dream wisdom."
        case .halfYear: return "Half a year! You're a true dream explorer."
        case .year: return "ONE YEAR! You've mastered the art of dream journaling!"
        }
    }

    var emoji: String {
        switch self {
        case .week: return "🌙"
        case .twoWeeks: return "✨"
        case .month: return "🌟"
        case .twoMonths: return "💫"
        case .quarter: return "🏆"
        case .halfYear: return "👑"
        case .year: return "🎆"
        }
    }
}

@MainActor
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var isAuthorized = false
    @Published var preferences: NotificationPreferences {
        didSet { savePreferences() }
    }

    private let preferencesKey = "notification_preferences"
    private let lastStreakCheckKey = "last_streak_check_date"
    private let celebratedMilestonesKey = "celebrated_milestones"

    private init() {
        self.preferences = Self.loadPreferences()
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Preferences Persistence

    private static func loadPreferences() -> NotificationPreferences {
        guard let data = UserDefaults.standard.data(forKey: "notification_preferences"),
              let prefs = try? JSONDecoder().decode(NotificationPreferences.self, from: data) else {
            return NotificationPreferences.defaultPreferences
        }
        return prefs
    }

    private func savePreferences() {
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: preferencesKey)
        }
        // Reschedule notifications when preferences change
        Task {
            await rescheduleAllNotifications()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Video Notifications

    func scheduleVideoReadyNotification(dreamTitle: String?, jobId: UUID) {
        let content = UNMutableNotificationContent()
        content.title = "Your dream video is ready!"
        content.body = dreamTitle != nil
            ? "Your video for \"\(dreamTitle!)\" is ready to watch."
            : "Your dream video has finished generating."
        content.sound = .default
        content.userInfo = ["jobId": jobId.uuidString, "type": "video_ready"]

        // Deliver immediately (1 second delay for reliability)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "video-ready-\(jobId.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    func scheduleVideoFailedNotification(dreamTitle: String?, jobId: UUID) {
        let content = UNMutableNotificationContent()
        content.title = "Video generation failed"
        content.body = dreamTitle != nil
            ? "We couldn't generate a video for \"\(dreamTitle!)\". Your credit has been refunded."
            : "Video generation failed. Your credit has been refunded."
        content.sound = .default
        content.userInfo = ["jobId": jobId.uuidString, "type": "video_failed"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "video-failed-\(jobId.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    // MARK: - Cancel Notifications

    func cancelVideoNotification(jobId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "video-ready-\(jobId.uuidString)",
                "video-failed-\(jobId.uuidString)"
            ]
        )
    }

    // MARK: - Morning Reminder

    /// Schedule daily morning reminder notification
    func scheduleMorningReminder() {
        guard preferences.morningReminderEnabled else {
            cancelMorningReminder()
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Good morning! Did you dream last night?"
        content.body = "Take a moment to capture your dreams before they fade away."
        content.sound = .default
        content.userInfo = ["type": "morning_reminder"]

        // Extract hour and minute from preference
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: preferences.morningReminderTime)

        var trigger = DateComponents()
        trigger.hour = components.hour
        trigger.minute = components.minute

        let notificationTrigger = UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)

        let request = UNNotificationRequest(
            identifier: "morning-reminder",
            content: content,
            trigger: notificationTrigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule morning reminder: \(error)")
            }
        }
    }

    func cancelMorningReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["morning-reminder"]
        )
    }

    // MARK: - Streak Protection Alert

    /// Schedule evening streak protection alert (if user hasn't recorded today)
    func scheduleStreakProtectionAlert(currentStreak: Int, hasRecordedToday: Bool) {
        guard preferences.streakAlertsEnabled, currentStreak > 0, !hasRecordedToday else {
            cancelStreakProtectionAlert()
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Don't lose your \(currentStreak)-day streak!"
        content.body = "Record a dream before midnight to keep your streak going."
        content.sound = .default
        content.userInfo = ["type": "streak_protection", "streak": currentStreak]

        // Schedule for 8 PM today
        var trigger = DateComponents()
        trigger.hour = 20
        trigger.minute = 0

        let notificationTrigger = UNCalendarNotificationTrigger(dateMatching: trigger, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak-protection",
            content: content,
            trigger: notificationTrigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule streak protection: \(error)")
            }
        }
    }

    func cancelStreakProtectionAlert() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["streak-protection"]
        )
    }

    // MARK: - Streak Milestone Celebration

    /// Check and celebrate streak milestones
    func checkStreakMilestone(currentStreak: Int) {
        guard preferences.streakMilestonesEnabled else { return }

        // Get already celebrated milestones
        let celebratedMilestones = UserDefaults.standard.array(forKey: celebratedMilestonesKey) as? [Int] ?? []

        // Find milestone that matches current streak
        if let milestone = StreakMilestone(rawValue: currentStreak),
           !celebratedMilestones.contains(currentStreak) {

            // Send celebration notification
            scheduleStreakMilestoneNotification(milestone: milestone)

            // Mark as celebrated
            var updatedMilestones = celebratedMilestones
            updatedMilestones.append(currentStreak)
            UserDefaults.standard.set(updatedMilestones, forKey: celebratedMilestonesKey)

            // Trigger haptic
            HapticManager.shared.streakMilestone()
        }
    }

    private func scheduleStreakMilestoneNotification(milestone: StreakMilestone) {
        let content = UNMutableNotificationContent()
        content.title = "\(milestone.emoji) \(milestone.rawValue)-Day Streak!"
        content.body = milestone.celebration
        content.sound = .default
        content.userInfo = ["type": "streak_milestone", "days": milestone.rawValue]

        // Deliver immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak-milestone-\(milestone.rawValue)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule milestone notification: \(error)")
            }
        }
    }

    // MARK: - Weekly Digest

    /// Schedule weekly digest notification for Sunday evening
    func scheduleWeeklyDigest(dreamCount: Int, topTheme: String?) {
        guard preferences.weeklyDigestEnabled else {
            cancelWeeklyDigest()
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Your Week in Dreams"

        if dreamCount > 0 {
            if let theme = topTheme {
                content.body = "You recorded \(dreamCount) dreams this week. Your top theme was \"\(theme)\"."
            } else {
                content.body = "You recorded \(dreamCount) dreams this week. Keep exploring your subconscious!"
            }
        } else {
            content.body = "Start your dream journey! Record your first dream this week."
        }

        content.sound = .default
        content.userInfo = ["type": "weekly_digest"]

        // Schedule for Sunday at 7 PM
        var trigger = DateComponents()
        trigger.weekday = 1  // Sunday
        trigger.hour = 19
        trigger.minute = 0

        let notificationTrigger = UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)

        let request = UNNotificationRequest(
            identifier: "weekly-digest",
            content: content,
            trigger: notificationTrigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule weekly digest: \(error)")
            }
        }
    }

    func cancelWeeklyDigest() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["weekly-digest"]
        )
    }

    // MARK: - Reschedule All

    /// Reschedule all notifications based on current preferences
    func rescheduleAllNotifications() async {
        guard isAuthorized else { return }

        // Cancel existing scheduled notifications (except video ones)
        cancelMorningReminder()
        cancelStreakProtectionAlert()
        cancelWeeklyDigest()

        // Reschedule based on preferences
        if preferences.morningReminderEnabled {
            scheduleMorningReminder()
        }

        if preferences.weeklyDigestEnabled {
            // Schedule with placeholder values - will be updated on app foreground
            scheduleWeeklyDigest(dreamCount: 0, topTheme: nil)
        }
    }

    /// Called when app becomes active - update streak alerts
    func updateEngagementNotifications(currentStreak: Int, hasRecordedToday: Bool, weeklyDreamCount: Int, topTheme: String?) {
        guard isAuthorized else { return }

        // Update streak protection
        if preferences.streakAlertsEnabled && currentStreak > 0 && !hasRecordedToday {
            scheduleStreakProtectionAlert(currentStreak: currentStreak, hasRecordedToday: hasRecordedToday)
        } else {
            cancelStreakProtectionAlert()
        }

        // Update weekly digest
        if preferences.weeklyDigestEnabled {
            scheduleWeeklyDigest(dreamCount: weeklyDreamCount, topTheme: topTheme)
        }

        // Check milestone
        if hasRecordedToday {
            checkStreakMilestone(currentStreak: currentStreak)
        }
    }
}
