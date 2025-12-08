import Foundation

// MARK: - Insights Data Models

/// Aggregated statistics about the user's dreams
struct DreamInsights: Sendable {
    let totalDreams: Int
    let dreamsThisWeek: Int
    let dreamsThisMonth: Int
    let averageDreamsPerWeek: Double
    let currentStreak: Int
    let longestStreak: Int
    let lastDreamDate: Date?
    let themeFrequency: [ThemeFrequency]
    let emotionFrequency: [EmotionFrequency]
    let emotionTrend: [EmotionTrendPoint]
    let dreamsByDayOfWeek: [DayOfWeekCount]
    let averageTranscriptLength: Int
}

/// Theme frequency data for charts
struct ThemeFrequency: Identifiable, Sendable {
    let id = UUID()
    let theme: String
    let count: Int
    let percentage: Double
}

/// Emotion frequency data for charts
struct EmotionFrequency: Identifiable, Sendable {
    let id = UUID()
    let emotion: String
    let count: Int
    let percentage: Double
    let sentiment: MBEmotions.Sentiment
}

/// Emotional trend over time for line charts
struct EmotionTrendPoint: Identifiable, Sendable {
    let id = UUID()
    let date: Date
    let positiveScore: Double  // 0-1 ratio of positive emotions
    let dominantEmotion: String?
    let hasDreams: Bool  // Whether there were dreams on this day (for chart styling)

    init(date: Date, positiveScore: Double, dominantEmotion: String?, hasDreams: Bool = true) {
        self.date = date
        self.positiveScore = positiveScore
        self.dominantEmotion = dominantEmotion
        self.hasDreams = hasDreams
    }
}

/// Dreams per day of week for pattern analysis
struct DayOfWeekCount: Identifiable, Sendable {
    let id = UUID()
    let dayOfWeek: Int  // 1 = Sunday, 7 = Saturday
    let dayName: String
    let count: Int
}

/// Streak information
struct StreakInfo: Sendable {
    let currentStreak: Int
    let longestStreak: Int
    let isActiveToday: Bool
    let lastRecordedDate: Date?
}

// MARK: - Insights Service

@MainActor
final class InsightsService: ObservableObject {
    static let shared = InsightsService()

    @Published private(set) var insights: DreamInsights?
    @Published private(set) var recentDreams: [DreamDTO] = []
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let dreamService = DreamService.shared

    private init() {}

    // MARK: - Generate Insights

    // Store all dreams for trend calculations
    private var allDreams: [DreamDTO] = []

    /// Generate comprehensive insights from dreams
    func generateInsights(for userId: UUID) async {
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let dreams = try await dreamService.fetchDreams(for: userId)
            allDreams = dreams  // Store for trend calculations
            insights = calculateInsights(from: dreams)
            // Store the 3 most recent dreams for preview
            recentDreams = Array(dreams.prefix(3))
        } catch {
            self.error = error
        }
    }

    /// Get emotion trend for a specific time period (Pro feature)
    func getEmotionTrend(days: Int) -> [EmotionTrendPoint] {
        let calendar = Calendar.current
        return calculateEmotionTrend(dreams: allDreams, days: days, calendar: calendar)
    }

    /// Calculate all insights from dream data
    private func calculateInsights(from dreams: [DreamDTO]) -> DreamInsights {
        let calendar = Calendar.current
        let now = Date()

        // Basic counts
        let totalDreams = dreams.count

        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now)!

        let dreamsThisWeek = dreams.filter { $0.createdAt >= weekAgo }.count
        let dreamsThisMonth = dreams.filter { $0.createdAt >= monthAgo }.count

        // Average per week
        let averageDreamsPerWeek = calculateAveragePerWeek(dreams: dreams, calendar: calendar)

        // Streak calculation
        let streakInfo = calculateStreak(dreams: dreams, calendar: calendar)

        // Theme frequency
        let themeFrequency = calculateThemeFrequency(dreams: dreams)

        // Emotion frequency
        let emotionFrequency = calculateEmotionFrequency(dreams: dreams)

        // Emotion trend (last 30 days)
        let emotionTrend = calculateEmotionTrend(dreams: dreams, days: 30, calendar: calendar)

        // Dreams by day of week
        let dreamsByDayOfWeek = calculateDreamsByDayOfWeek(dreams: dreams, calendar: calendar)

        // Average transcript length
        let averageTranscriptLength = dreams.isEmpty ? 0 :
            dreams.reduce(0) { $0 + $1.transcript.count } / dreams.count

        return DreamInsights(
            totalDreams: totalDreams,
            dreamsThisWeek: dreamsThisWeek,
            dreamsThisMonth: dreamsThisMonth,
            averageDreamsPerWeek: averageDreamsPerWeek,
            currentStreak: streakInfo.currentStreak,
            longestStreak: streakInfo.longestStreak,
            lastDreamDate: dreams.first?.createdAt,
            themeFrequency: themeFrequency,
            emotionFrequency: emotionFrequency,
            emotionTrend: emotionTrend,
            dreamsByDayOfWeek: dreamsByDayOfWeek,
            averageTranscriptLength: averageTranscriptLength
        )
    }

    // MARK: - Calculation Helpers

    private func calculateAveragePerWeek(dreams: [DreamDTO], calendar: Calendar) -> Double {
        guard !dreams.isEmpty else { return 0 }
        guard let oldestDream = dreams.last else { return 0 }

        let daysSinceFirst = calendar.dateComponents([.day], from: oldestDream.createdAt, to: Date()).day ?? 1
        let weeks = max(1, Double(daysSinceFirst) / 7.0)

        return Double(dreams.count) / weeks
    }

    private func calculateStreak(dreams: [DreamDTO], calendar: Calendar) -> StreakInfo {
        guard !dreams.isEmpty else {
            return StreakInfo(currentStreak: 0, longestStreak: 0, isActiveToday: false, lastRecordedDate: nil)
        }

        // Get unique days with dreams
        let dreamDays = Set(dreams.map { calendar.startOfDay(for: $0.createdAt) })
        let sortedDays = dreamDays.sorted(by: >)  // Most recent first

        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        // Check if streak is active (dreamed today or yesterday)
        let isActiveToday = dreamDays.contains(today)
        let hasRecentDream = dreamDays.contains(today) || dreamDays.contains(yesterday)

        // Calculate current streak
        var currentStreak = 0
        if hasRecentDream {
            var checkDate = isActiveToday ? today : yesterday
            while dreamDays.contains(checkDate) {
                currentStreak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = previousDay
            }
        }

        // Calculate longest streak
        var longestStreak = 0
        var tempStreak = 0
        var previousDay: Date?

        for day in sortedDays.reversed() {  // Oldest first for longest streak
            if let prev = previousDay {
                let daysDiff = calendar.dateComponents([.day], from: prev, to: day).day ?? 0
                if daysDiff == 1 {
                    tempStreak += 1
                } else {
                    longestStreak = max(longestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }
            previousDay = day
        }
        longestStreak = max(longestStreak, tempStreak)

        return StreakInfo(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            isActiveToday: isActiveToday,
            lastRecordedDate: sortedDays.first
        )
    }

    private func calculateThemeFrequency(dreams: [DreamDTO]) -> [ThemeFrequency] {
        var themeCounts: [String: Int] = [:]

        for dream in dreams {
            for theme in dream.themes {
                themeCounts[theme, default: 0] += 1
            }
        }

        let totalThemes = themeCounts.values.reduce(0, +)

        return themeCounts
            .map { ThemeFrequency(
                theme: $0.key,
                count: $0.value,
                percentage: totalThemes > 0 ? Double($0.value) / Double(totalThemes) * 100 : 0
            )}
            .sorted { $0.count > $1.count }
    }

    private func calculateEmotionFrequency(dreams: [DreamDTO]) -> [EmotionFrequency] {
        var emotionCounts: [String: Int] = [:]

        for dream in dreams {
            for emotion in dream.emotions {
                emotionCounts[emotion, default: 0] += 1
            }
        }

        let totalEmotions = emotionCounts.values.reduce(0, +)

        return emotionCounts
            .map { EmotionFrequency(
                emotion: $0.key,
                count: $0.value,
                percentage: totalEmotions > 0 ? Double($0.value) / Double(totalEmotions) * 100 : 0,
                sentiment: MBEmotions.sentiment(for: $0.key)
            )}
            .sorted { $0.count > $1.count }
    }

    private func calculateEmotionTrend(dreams: [DreamDTO], days: Int, calendar: Calendar) -> [EmotionTrendPoint] {
        let now = Date()
        var trendPoints: [EmotionTrendPoint] = []
        var lastValidScore: Double = 0.5  // Default neutral score

        for dayOffset in (0..<days).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

            let dayDreams = dreams.filter { $0.createdAt >= dayStart && $0.createdAt < dayEnd }

            if dayDreams.isEmpty {
                // Include day with interpolated/carried-forward score to avoid gaps in chart
                trendPoints.append(EmotionTrendPoint(
                    date: dayStart,
                    positiveScore: lastValidScore,
                    dominantEmotion: nil,
                    hasDreams: false
                ))
                continue
            }

            // Calculate positive emotion ratio
            var positiveCount = 0
            var totalCount = 0
            var emotionCounts: [String: Int] = [:]

            for dream in dayDreams {
                for emotion in dream.emotions {
                    emotionCounts[emotion, default: 0] += 1
                    totalCount += 1
                    if MBEmotions.sentiment(for: emotion) == .positive {
                        positiveCount += 1
                    }
                }
            }

            let positiveScore = totalCount > 0 ? Double(positiveCount) / Double(totalCount) : 0.5
            lastValidScore = positiveScore  // Save for gap filling
            let dominantEmotion = emotionCounts.max(by: { $0.value < $1.value })?.key

            trendPoints.append(EmotionTrendPoint(
                date: dayStart,
                positiveScore: positiveScore,
                dominantEmotion: dominantEmotion,
                hasDreams: true
            ))
        }

        return trendPoints
    }

    private func calculateDreamsByDayOfWeek(dreams: [DreamDTO], calendar: Calendar) -> [DayOfWeekCount] {
        var counts: [Int: Int] = [:]
        let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

        for dream in dreams {
            let weekday = calendar.component(.weekday, from: dream.createdAt)
            counts[weekday, default: 0] += 1
        }

        return (1...7).map { day in
            DayOfWeekCount(
                dayOfWeek: day,
                dayName: dayNames[day],
                count: counts[day] ?? 0
            )
        }
    }

    // MARK: - Quick Stats

    /// Get quick stats without full insights calculation (for badges, etc.)
    func getQuickStats(for userId: UUID) async -> (streak: Int, total: Int, thisWeek: Int)? {
        do {
            let dreams = try await dreamService.fetchDreams(for: userId)
            let calendar = Calendar.current
            let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

            let streakInfo = calculateStreak(dreams: dreams, calendar: calendar)
            let thisWeek = dreams.filter { $0.createdAt >= weekAgo }.count

            return (streakInfo.currentStreak, dreams.count, thisWeek)
        } catch {
            return nil
        }
    }

    // MARK: - Pro Features

    /// Check if a feature requires Pro (for gating)
    func requiresPro(for feature: InsightsFeature) -> Bool {
        switch feature {
        case .basicStats, .themePreview, .emotionPreview:
            return false
        case .fullThemeBreakdown, .fullEmotionBreakdown, .emotionTrend, .patterns, .yearInDreams:
            return true
        }
    }
}

// MARK: - Insights Feature Enum

enum InsightsFeature {
    case basicStats
    case themePreview  // Top 3 themes
    case emotionPreview  // Top 3 emotions
    case fullThemeBreakdown  // Pro
    case fullEmotionBreakdown  // Pro
    case emotionTrend  // Pro - 30/90/365 day trends
    case patterns  // Pro - correlations
    case yearInDreams  // Pro - annual recap
}
