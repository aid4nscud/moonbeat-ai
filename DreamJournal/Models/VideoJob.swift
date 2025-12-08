import Foundation

enum VideoStatus: String, Codable, Sendable {
    case pending
    case processing
    case completed
    case failed
}

struct VideoJobDTO: Codable, Identifiable, Sendable, Equatable {
    let id: UUID
    let dreamId: UUID
    let userId: UUID
    var status: VideoStatus
    var replicateId: String?
    var videoPath: String?
    var videoUrl: String?
    var errorMessage: String?
    let createdAt: Date
    var completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case dreamId = "dream_id"
        case userId = "user_id"
        case status
        case replicateId = "replicate_id"
        case videoPath = "video_path"
        case videoUrl = "video_url"
        case errorMessage = "error_message"
        case createdAt = "created_at"
        case completedAt = "completed_at"
    }
}

struct CreateVideoJobRequest: Codable, Sendable {
    let dreamId: UUID
    let prompt: String

    enum CodingKeys: String, CodingKey {
        case dreamId = "dream_id"
        case prompt
    }
}

struct VideoGenerationResponse: Codable, Sendable {
    let jobId: String
}

struct CheckVideoStatusRequest: Codable, Sendable {
    let replicateId: String

    enum CodingKeys: String, CodingKey {
        case replicateId = "replicate_id"
    }
}

struct CheckVideoStatusResponse: Codable, Sendable {
    let status: String
    let videoPath: String?
    let videoUrl: String?
    let error: String?
}

struct VideoGenerationError: Codable, Sendable {
    let error: String
}
