import Foundation
import SwiftData

// MARK: - Supabase Models (Codable for API)

struct DreamDTO: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    var title: String?
    var transcript: String
    var themes: [String]
    var emotions: [String]
    var audioPath: String?
    var videoUrl: String?
    var videoPath: String?
    var interpretation: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case transcript
        case themes
        case emotions
        case audioPath = "audio_path"
        case videoUrl = "video_url"
        case videoPath = "video_path"
        case interpretation
        case createdAt = "created_at"
    }

    /// Custom decoding to handle null arrays from database as empty arrays
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        transcript = try container.decode(String.self, forKey: .transcript)
        themes = try container.decodeIfPresent([String].self, forKey: .themes) ?? []
        emotions = try container.decodeIfPresent([String].self, forKey: .emotions) ?? []
        audioPath = try container.decodeIfPresent(String.self, forKey: .audioPath)
        videoUrl = try container.decodeIfPresent(String.self, forKey: .videoUrl)
        videoPath = try container.decodeIfPresent(String.self, forKey: .videoPath)
        interpretation = try container.decodeIfPresent(String.self, forKey: .interpretation)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }

    /// Direct initializer for testing/previews
    init(
        id: UUID,
        userId: UUID,
        title: String? = nil,
        transcript: String,
        themes: [String] = [],
        emotions: [String] = [],
        audioPath: String? = nil,
        videoUrl: String? = nil,
        videoPath: String? = nil,
        interpretation: String? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.transcript = transcript
        self.themes = themes
        self.emotions = emotions
        self.audioPath = audioPath
        self.videoUrl = videoUrl
        self.videoPath = videoPath
        self.interpretation = interpretation
        self.createdAt = createdAt
    }
}

struct CreateDreamRequest: Codable, Sendable {
    let userId: UUID
    let title: String?
    let transcript: String
    let themes: [String]?
    let emotions: [String]?
    let audioPath: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case title
        case transcript
        case themes
        case emotions
        case audioPath = "audio_path"
    }
}

struct UpdateDreamRequest: Codable, Sendable {
    var title: String?
    var transcript: String?
    var themes: [String]?
    var emotions: [String]?
}

// MARK: - SwiftData Local Cache

@Model
final class Dream {
    @Attribute(.unique) var id: UUID
    var userId: UUID
    var title: String?
    var transcript: String
    var themes: [String]
    var emotions: [String]
    var audioPath: String?
    var createdAt: Date
    var isSynced: Bool

    init(
        id: UUID = UUID(),
        userId: UUID,
        title: String? = nil,
        transcript: String,
        themes: [String] = [],
        emotions: [String] = [],
        audioPath: String? = nil,
        createdAt: Date = Date(),
        isSynced: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.transcript = transcript
        self.themes = themes
        self.emotions = emotions
        self.audioPath = audioPath
        self.createdAt = createdAt
        self.isSynced = isSynced
    }

    convenience init(from dto: DreamDTO) {
        self.init(
            id: dto.id,
            userId: dto.userId,
            title: dto.title,
            transcript: dto.transcript,
            themes: dto.themes,
            emotions: dto.emotions,
            audioPath: dto.audioPath,
            createdAt: dto.createdAt,
            isSynced: true
        )
    }
}
