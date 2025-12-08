import Foundation
import AuthenticationServices
import Supabase

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case invalidCredential
    case missingIdentityToken
    case signInFailed(Error)
    case signOutFailed(Error)
    case profileCreationFailed(Error)
    case profileFetchFailed(Error)
    case quotaFetchFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid Apple credential received."
        case .missingIdentityToken:
            return "Could not retrieve identity token from Apple."
        case .signInFailed(let error):
            return "Sign in failed: \(error.localizedDescription)"
        case .signOutFailed(let error):
            return "Sign out failed: \(error.localizedDescription)"
        case .profileCreationFailed(let error):
            return "Failed to create profile: \(error.localizedDescription)"
        case .profileFetchFailed(let error):
            return "Failed to load profile: \(error.localizedDescription)"
        case .quotaFetchFailed(let error):
            return "Failed to load video quota: \(error.localizedDescription)"
        }
    }
}

// MARK: - Auth Service

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published private(set) var currentUser: User?
    @Published private(set) var userProfile: UserProfileDTO?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published var profileError: AuthError?

    private let supabase = SupabaseService.shared.client

    private init() {}

    // MARK: - Session Check

    func checkExistingSession() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            isAuthenticated = true
            await fetchUserProfile()
            await PurchaseService.shared.configure(userId: session.user.id.uuidString)
        } catch {
            // No existing session
            isAuthenticated = false
            currentUser = nil
        }
    }

    // MARK: - Development Sign In (Simulator Only)

    #if DEBUG
    /// Development-only sign in for testing in simulator
    /// Uses Supabase anonymous auth - remove before production
    func devSignIn() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            let session = try await supabase.auth.signInAnonymously()
            currentUser = session.user
            isAuthenticated = true

            await createProfileIfNeeded(userId: session.user.id)
            await fetchUserProfile()
            await PurchaseService.shared.configure(userId: session.user.id.uuidString)
        } catch {
            throw AuthError.signInFailed(error)
        }
    }
    #endif

    // MARK: - Sign In with Apple

    /// Sign in using an authorization result from SignInWithAppleButton
    func signInWithApple(authorization: ASAuthorization) async throws {
        isLoading = true
        defer { isLoading = false }

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }

        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.missingIdentityToken
        }

        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: tokenString
                )
            )

            currentUser = session.user
            isAuthenticated = true

            // Create profile if first sign in
            await createProfileIfNeeded(userId: session.user.id)
            await fetchUserProfile()

            // Configure RevenueCat
            await PurchaseService.shared.configure(userId: session.user.id.uuidString)
        } catch {
            throw AuthError.signInFailed(error)
        }
    }

    // MARK: - Sign Out

    func signOut() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await supabase.auth.signOut()
            currentUser = nil
            userProfile = nil
            isAuthenticated = false
        } catch {
            throw AuthError.signOutFailed(error)
        }
    }

    // MARK: - Profile Management

    private func createProfileIfNeeded(userId: UUID) async {
        // Clear any previous profile error
        profileError = nil

        do {
            // Check if profile exists
            let existingProfile: UserProfileDTO? = try? await supabase
                .from(SupabaseTable.profiles.rawValue)
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            if existingProfile == nil {
                // Create new profile with 3 free credits
                let newProfile = CreateProfileRequest(id: userId)
                try await supabase
                    .from(SupabaseTable.profiles.rawValue)
                    .insert(newProfile)
                    .execute()
            }
        } catch {
            print("Error creating profile: \(error)")
            profileError = .profileCreationFailed(error)
        }
    }

    func fetchUserProfile() async {
        guard let userId = currentUser?.id else { return }

        do {
            userProfile = try await supabase
                .from(SupabaseTable.profiles.rawValue)
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            // Clear any previous profile error on success
            profileError = nil

            // Fetch quota status for Pro users
            if userProfile?.subscriptionTier == .pro {
                await fetchProQuotaStatus()
            }
        } catch {
            print("Error fetching profile: \(error)")
            profileError = .profileFetchFailed(error)
        }
    }

    /// Fetch Pro user's monthly quota status via RPC
    func fetchProQuotaStatus() async {
        guard let userId = currentUser?.id,
              userProfile?.subscriptionTier == .pro else { return }

        do {
            let quotaResults: [ProQuotaStatus] = try await supabase
                .rpc("can_pro_user_generate_video", params: ["user_uuid": userId.uuidString])
                .execute()
                .value

            if let quotaStatus = quotaResults.first {
                userProfile?.proQuotaStatus = quotaStatus
            }
        } catch {
            print("Error fetching Pro quota status: \(error)")
            // Set error but don't block the user - quota is supplementary info
            profileError = .quotaFetchFailed(error)
        }
    }

    func refreshCredits() async {
        await fetchUserProfile()
    }

    /// Retry loading profile after an error
    func retryProfileLoad() async {
        guard let userId = currentUser?.id else { return }
        profileError = nil
        await createProfileIfNeeded(userId: userId)
        await fetchUserProfile()
    }

    /// Clear the current profile error
    func clearProfileError() {
        profileError = nil
    }
}
