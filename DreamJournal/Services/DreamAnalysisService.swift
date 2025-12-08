import Foundation
import NaturalLanguage

// MARK: - Dream Analysis Result

struct DreamAnalysis: Sendable {
    let themes: [String]
    let emotions: [String]
    let keywords: [String]
    let sentiment: DreamSentiment
}

enum DreamSentiment: String, Sendable {
    case positive
    case negative
    case neutral
    case mixed
}

// MARK: - Common Dream Themes

private let dreamThemeKeywords: [String: [String]] = [
    "Flying": ["fly", "flying", "soar", "float", "air", "wings", "above", "sky"],
    "Falling": ["fall", "falling", "drop", "plunge", "descend", "cliff"],
    "Chase": ["chase", "chasing", "run", "running", "pursue", "escape", "flee", "hiding"],
    "Water": ["water", "ocean", "sea", "swim", "swimming", "wave", "drown", "river", "lake"],
    "Death": ["death", "dead", "die", "dying", "funeral", "grave", "kill"],
    "Lost": ["lost", "maze", "confused", "wander", "searching", "can't find"],
    "Teeth": ["teeth", "tooth", "falling out", "crumbling", "dental"],
    "Naked": ["naked", "nude", "exposed", "embarrassed", "undressed"],
    "Late": ["late", "missing", "deadline", "hurry", "rushing", "time"],
    "Test": ["test", "exam", "unprepared", "school", "fail", "study"],
    "Animals": ["animal", "dog", "cat", "snake", "spider", "bird", "lion", "wolf"],
    "Flying Vehicle": ["plane", "airplane", "helicopter", "spaceship", "rocket"],
    "Relationship": ["love", "partner", "ex", "marriage", "wedding", "breakup", "romance"],
    "Family": ["mother", "father", "parent", "child", "brother", "sister", "family"],
    "House": ["house", "home", "room", "building", "door", "window", "basement", "attic"]
]

// MARK: - Dream Analysis Service

final class DreamAnalysisService: Sendable {
    static let shared = DreamAnalysisService()

    private init() {}

    // MARK: - Analyze Dream

    func analyzeDream(_ text: String) -> DreamAnalysis {
        let lowercasedText = text.lowercased()

        let themes = detectThemes(in: lowercasedText)
        let emotions = detectEmotions(in: text)
        let keywords = extractKeywords(from: text)
        let sentiment = analyzeSentiment(of: text)

        return DreamAnalysis(
            themes: themes,
            emotions: emotions,
            keywords: keywords,
            sentiment: sentiment
        )
    }

    // MARK: - Theme Detection

    private func detectThemes(in text: String) -> [String] {
        var detectedThemes: [(theme: String, count: Int)] = []

        for (theme, keywords) in dreamThemeKeywords {
            let matchCount = keywords.filter { text.contains($0) }.count
            if matchCount > 0 {
                detectedThemes.append((theme, matchCount))
            }
        }

        // Sort by match count and return top themes
        return detectedThemes
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0.theme }
    }

    // MARK: - Emotion Detection

    private func detectEmotions(in text: String) -> [String] {
        let emotionKeywords: [String: [String]] = [
            "Fear": ["scared", "afraid", "terrified", "fear", "frightened", "panic", "anxious", "worry"],
            "Joy": ["happy", "joy", "excited", "wonderful", "amazing", "beautiful", "love", "peaceful"],
            "Sadness": ["sad", "crying", "tears", "grief", "loss", "lonely", "depressed", "melancholy"],
            "Anger": ["angry", "furious", "rage", "mad", "frustrated", "annoyed", "irritated"],
            "Confusion": ["confused", "strange", "weird", "bizarre", "surreal", "unclear", "uncertain"],
            "Anxiety": ["nervous", "stressed", "tense", "worried", "uneasy", "restless"],
            "Peace": ["calm", "serene", "tranquil", "relaxed", "comfortable", "safe"],
            "Wonder": ["amazed", "curious", "fascinated", "mysterious", "magical", "supernatural"]
        ]

        let lowercasedText = text.lowercased()
        var detectedEmotions: [(emotion: String, count: Int)] = []

        for (emotion, keywords) in emotionKeywords {
            let matchCount = keywords.filter { lowercasedText.contains($0) }.count
            if matchCount > 0 {
                detectedEmotions.append((emotion, matchCount))
            }
        }

        return detectedEmotions
            .sorted { $0.count > $1.count }
            .prefix(3)
            .map { $0.emotion }
    }

    // MARK: - Keyword Extraction

    private func extractKeywords(from text: String) -> [String] {
        let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass])
        tagger.string = text

        var keywords: [String] = []
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: options) { tag, tokenRange in
            if let tag = tag {
                let word = String(text[tokenRange])

                // Extract nouns and verbs as keywords
                if tag == .noun || tag == .verb {
                    if word.count > 3 && !keywords.contains(word.lowercased()) {
                        keywords.append(word.lowercased())
                    }
                }
            }
            return true
        }

        // Also extract named entities
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .nameType, options: options) { tag, tokenRange in
            if tag != nil {
                let word = String(text[tokenRange])
                if !keywords.contains(word.lowercased()) {
                    keywords.append(word.lowercased())
                }
            }
            return true
        }

        return Array(keywords.prefix(10))
    }

    // MARK: - Sentiment Analysis

    private func analyzeSentiment(of text: String) -> DreamSentiment {
        let tagger = NLTagger(tagSchemes: [.sentimentScore])
        tagger.string = text

        var scores: [Double] = []

        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .paragraph, scheme: .sentimentScore, options: []) { tag, _ in
            if let tag = tag, let score = Double(tag.rawValue) {
                scores.append(score)
            }
            return true
        }

        guard !scores.isEmpty else { return .neutral }

        let averageScore = scores.reduce(0, +) / Double(scores.count)
        let hasPositive = scores.contains { $0 > 0.3 }
        let hasNegative = scores.contains { $0 < -0.3 }

        if hasPositive && hasNegative {
            return .mixed
        } else if averageScore > 0.3 {
            return .positive
        } else if averageScore < -0.3 {
            return .negative
        } else {
            return .neutral
        }
    }

    // MARK: - Generate Video Prompt

    func generateVideoPrompt(from analysis: DreamAnalysis, transcript: String) -> String {
        var promptParts: [String] = []

        // Style prefix
        promptParts.append("dreamlike surreal artistic visualization")

        // Add primary theme
        if let primaryTheme = analysis.themes.first {
            promptParts.append("featuring \(primaryTheme.lowercased()) imagery")
        }

        // Add emotional atmosphere
        if let primaryEmotion = analysis.emotions.first {
            let atmosphere: String
            switch primaryEmotion {
            case "Fear": atmosphere = "dark ominous atmosphere"
            case "Joy": atmosphere = "bright warm glowing atmosphere"
            case "Sadness": atmosphere = "melancholic misty atmosphere"
            case "Anger": atmosphere = "intense fiery atmosphere"
            case "Confusion": atmosphere = "abstract swirling atmosphere"
            case "Anxiety": atmosphere = "tense shadowy atmosphere"
            case "Peace": atmosphere = "serene ethereal atmosphere"
            case "Wonder": atmosphere = "magical sparkling atmosphere"
            default: atmosphere = "mysterious atmosphere"
            }
            promptParts.append(atmosphere)
        }

        // Add key visual elements from keywords
        let visualKeywords = analysis.keywords.prefix(3).joined(separator: ", ")
        if !visualKeywords.isEmpty {
            promptParts.append("with elements of \(visualKeywords)")
        }

        // Summarize the dream content (first 100 chars)
        let summary = String(transcript.prefix(100))
        promptParts.append("depicting: \(summary)")

        return promptParts.joined(separator: ", ")
    }
}
