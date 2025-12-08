import Foundation

enum SubscriptionTier: String, Codable, Sendable {
    case free
    case pro
}

/// Pro user's monthly video quota status
struct ProQuotaStatus: Codable, Sendable {
    let canGenerate: Bool
    let videosUsed: Int
    let videosRemaining: Int
    let quotaLimit: Int
    let resetsAt: Date

    enum CodingKeys: String, CodingKey {
        case canGenerate = "can_generate"
        case videosUsed = "videos_used"
        case videosRemaining = "videos_remaining"
        case quotaLimit = "quota_limit"
        case resetsAt = "resets_at"
    }

    /// Custom decoding with validation to ensure values are non-negative
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        canGenerate = try container.decode(Bool.self, forKey: .canGenerate)

        let rawVideosUsed = try container.decode(Int.self, forKey: .videosUsed)
        let rawVideosRemaining = try container.decode(Int.self, forKey: .videosRemaining)
        let rawQuotaLimit = try container.decode(Int.self, forKey: .quotaLimit)

        // Ensure non-negative values (clamp invalid data)
        videosUsed = max(0, rawVideosUsed)
        videosRemaining = max(0, rawVideosRemaining)
        quotaLimit = max(1, rawQuotaLimit) // At least 1 to avoid division by zero

        resetsAt = try container.decode(Date.self, forKey: .resetsAt)
    }

    /// Direct initializer for testing/previews
    init(canGenerate: Bool, videosUsed: Int, videosRemaining: Int, quotaLimit: Int, resetsAt: Date) {
        self.canGenerate = canGenerate
        self.videosUsed = max(0, videosUsed)
        self.videosRemaining = max(0, videosRemaining)
        self.quotaLimit = max(1, quotaLimit)
        self.resetsAt = resetsAt
    }

    var resetDateFormatted: String {
        MBDateFormatter.relativeDateString(for: resetsAt)
    }
}

struct UserProfileDTO: Codable, Identifiable, Sendable {
    let id: UUID
    var creditsRemaining: Int
    var subscriptionTier: SubscriptionTier
    var displayName: String?
    let createdAt: Date

    /// Pro user's monthly quota status (fetched separately via RPC)
    var proQuotaStatus: ProQuotaStatus?

    enum CodingKeys: String, CodingKey {
        case id
        case creditsRemaining = "credits_remaining"
        case subscriptionTier = "subscription_tier"
        case displayName = "display_name"
        case createdAt = "created_at"
        // proQuotaStatus is not in the profiles table, fetched separately
    }

    var canGenerateVideo: Bool {
        switch subscriptionTier {
        case .pro:
            // Pro users: check quota (fallback to true if not loaded yet)
            return proQuotaStatus?.canGenerate ?? true
        case .free:
            return creditsRemaining > 0
        }
    }

    var videoQuotaDescription: String {
        switch subscriptionTier {
        case .pro:
            if let quota = proQuotaStatus {
                return "\(quota.videosRemaining) of \(quota.quotaLimit) videos remaining this month"
            }
            return "Loading quota..."
        case .free:
            return "\(creditsRemaining) free videos remaining"
        }
    }
}

struct CreateProfileRequest: Codable, Sendable {
    let id: UUID
    let creditsRemaining: Int
    let subscriptionTier: String

    enum CodingKeys: String, CodingKey {
        case id
        case creditsRemaining = "credits_remaining"
        case subscriptionTier = "subscription_tier"
    }

    init(id: UUID, creditsRemaining: Int = 3, subscriptionTier: SubscriptionTier = .free) {
        self.id = id
        self.creditsRemaining = creditsRemaining
        self.subscriptionTier = subscriptionTier.rawValue
    }
}

struct UpdateProfileRequest: Codable, Sendable {
    var creditsRemaining: Int?
    var subscriptionTier: String?

    enum CodingKeys: String, CodingKey {
        case creditsRemaining = "credits_remaining"
        case subscriptionTier = "subscription_tier"
    }
}
