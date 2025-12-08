import Foundation

// MARK: - Dream Interpretation Service

/// Service for generating AI-powered dream interpretations using Replicate LLM
@MainActor
final class DreamInterpretationService: ObservableObject {
    static let shared = DreamInterpretationService()

    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?

    private let supabase = SupabaseService.shared

    private init() {}

    // MARK: - Interpretation Response

    struct InterpretationResponse: Codable {
        let interpretation: String
        let cached: Bool?
    }

    struct InterpretationError: Codable {
        let error: String
        let code: String?
        let message: String?
    }

    // MARK: - Public Methods

    /// Generate or retrieve AI interpretation for a dream
    /// - Parameter dream: The dream to interpret
    /// - Returns: The interpretation text
    func getInterpretation(for dream: DreamDTO) async throws -> String {
        // Return cached interpretation if available
        if let existing = dream.interpretation, !existing.isEmpty {
            return existing
        }

        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            // Use the typed invoke that returns the response directly
            let result: InterpretationResponse = try await supabase.client.functions.invoke(
                "analyze-dream",
                options: .init(
                    body: ["dream_id": dream.id.uuidString]
                )
            )
            return result.interpretation

        } catch let apiError as InterpretationServiceError {
            self.error = apiError
            throw apiError
        } catch {
            let wrappedError = InterpretationServiceError.networkError(error)
            self.error = wrappedError
            throw wrappedError
        }
    }

    /// Check if user can access AI interpretations (Pro feature)
    func canAccessInterpretations(profile: UserProfileDTO?) -> Bool {
        guard let profile = profile else { return false }
        return profile.subscriptionTier == .pro
    }
}

// MARK: - Errors

enum InterpretationServiceError: LocalizedError {
    case requiresPro
    case apiError(String)
    case networkError(Error)
    case noInterpretation

    var errorDescription: String? {
        switch self {
        case .requiresPro:
            return "AI Dream Interpretation is a Pro feature. Upgrade to unlock personalized insights."
        case .apiError(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noInterpretation:
            return "Unable to generate interpretation. Please try again."
        }
    }
}
