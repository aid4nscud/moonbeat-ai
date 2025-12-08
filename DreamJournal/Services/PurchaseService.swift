import Foundation
import RevenueCat
import RevenueCatUI
import Supabase

// MARK: - Purchase Configuration

enum PurchaseConfig {
    /// RevenueCat Public API Key for Moonbeat AI
    #if DEBUG
    static let apiKey = "test_bGcSQrpULeEMyqKxJZgvZSRsTCn"  // Test Store (sandbox)
    #else
    static let apiKey = "appl_YTJzZUkjZPslkPdJTklLlWsMoYn"  // App Store (production)
    #endif

    /// Entitlement identifier for Moonbeat AI Pro
    static let proEntitlement = "Moonbeat AI Pro"

    /// Product identifiers (App Store Connect)
    enum ProductID {
        static let monthly = "com.moonbeat.ai.monthly"
        static let yearly = "com.moonbeat.ai.yearly"
        static let lifetime = "com.moonbeat.ai.lifetime"
    }
}

// MARK: - Purchase Service Errors

enum PurchaseError: LocalizedError {
    case purchaseFailed(Error)
    case restoreFailed(Error)
    case noOfferings
    case notConfigured
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .purchaseFailed(let error):
            return "Purchase failed: \(error.localizedDescription)"
        case .restoreFailed(let error):
            return "Restore failed: \(error.localizedDescription)"
        case .noOfferings:
            return "No subscription options available."
        case .notConfigured:
            return "Purchase service not configured."
        case .userCancelled:
            return "Purchase was cancelled."
        }
    }
}

// MARK: - Subscription Type

enum SubscriptionType: String, CaseIterable {
    case monthly = "monthly"
    case yearly = "yearly"
    case lifetime = "lifetime"

    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }
}

// MARK: - Purchase Service

@MainActor
final class PurchaseService: ObservableObject {
    static let shared = PurchaseService()

    @Published private(set) var offerings: Offerings?
    @Published private(set) var customerInfo: CustomerInfo?
    @Published private(set) var isPro = false
    @Published private(set) var isLoading = false
    @Published private(set) var hasLifetime = false

    private let supabase = SupabaseService.shared.client
    private var isConfigured = false
    private var customerInfoTask: Task<Void, Never>?

    private init() {}

    // MARK: - Configuration

    func configure(userId: String) async {
        guard !isConfigured else { return }

        Purchases.configure(
            with: .init(withAPIKey: PurchaseConfig.apiKey)
                .with(appUserID: userId)
        )

        #if DEBUG
        Purchases.logLevel = .debug
        #endif

        isConfigured = true

        // Set up customer info listener for real-time updates
        startListeningForCustomerInfoUpdates()

        await fetchOfferings()
        await refreshCustomerInfo()
    }

    /// Start listening for CustomerInfo updates in real-time
    private func startListeningForCustomerInfoUpdates() {
        customerInfoTask?.cancel()
        customerInfoTask = Task {
            for await customerInfo in Purchases.shared.customerInfoStream {
                await MainActor.run {
                    self.updateCustomerInfo(customerInfo)
                }
            }
        }
    }

    /// Update customer info and sync state
    private func updateCustomerInfo(_ info: CustomerInfo) {
        self.customerInfo = info
        self.isPro = info.entitlements[PurchaseConfig.proEntitlement]?.isActive == true
        self.hasLifetime = info.entitlements[PurchaseConfig.proEntitlement]?.expirationDate == nil
            && self.isPro

        Task {
            await syncSubscriptionToSupabase()
        }
    }

    /// Clean up resources
    func cleanup() {
        customerInfoTask?.cancel()
        customerInfoTask = nil
    }

    // MARK: - Offerings

    func fetchOfferings() async {
        guard isConfigured else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            print("Error fetching offerings: \(error)")
        }
    }

    var currentOffering: Offering? {
        offerings?.current
    }

    var monthlyPackage: Package? {
        currentOffering?.availablePackages.first { $0.packageType == .monthly }
    }

    var annualPackage: Package? {
        currentOffering?.availablePackages.first { $0.packageType == .annual }
    }

    var lifetimePackage: Package? {
        currentOffering?.availablePackages.first { $0.packageType == .lifetime }
    }

    /// Get all available packages sorted by recommended order (yearly, monthly, lifetime)
    var allPackages: [Package] {
        guard let offering = currentOffering else { return [] }
        return offering.availablePackages.sorted { lhs, rhs in
            let order: [PackageType: Int] = [.annual: 0, .monthly: 1, .lifetime: 2]
            return (order[lhs.packageType] ?? 99) < (order[rhs.packageType] ?? 99)
        }
    }

    /// Get package by subscription type
    func package(for type: SubscriptionType) -> Package? {
        switch type {
        case .monthly: return monthlyPackage
        case .yearly: return annualPackage
        case .lifetime: return lifetimePackage
        }
    }

    // MARK: - Customer Info

    func refreshCustomerInfo() async {
        guard isConfigured else { return }

        do {
            let info = try await Purchases.shared.customerInfo()
            updateCustomerInfo(info)
        } catch {
            print("Error fetching customer info: \(error)")
        }
    }

    /// Check if user has access to pro features
    func hasProAccess() -> Bool {
        return isPro
    }

    /// Check entitlement status with detailed info
    func getEntitlementInfo() -> (isActive: Bool, expirationDate: Date?, willRenew: Bool) {
        guard let entitlement = customerInfo?.entitlements[PurchaseConfig.proEntitlement] else {
            return (false, nil, false)
        }
        return (entitlement.isActive, entitlement.expirationDate, entitlement.willRenew)
    }

    // MARK: - Purchase

    func purchase(package: Package) async throws {
        guard isConfigured else {
            throw PurchaseError.notConfigured
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)

            // Check if user cancelled
            if result.userCancelled {
                throw PurchaseError.userCancelled
            }

            updateCustomerInfo(result.customerInfo)
        } catch let error as PurchaseError {
            throw error
        } catch {
            // Check for specific RevenueCat errors
            if let rcError = error as? RevenueCat.ErrorCode {
                switch rcError {
                case .purchaseCancelledError:
                    throw PurchaseError.userCancelled
                default:
                    throw PurchaseError.purchaseFailed(error)
                }
            }
            throw PurchaseError.purchaseFailed(error)
        }
    }

    /// Purchase a specific subscription type
    func purchase(subscriptionType: SubscriptionType) async throws {
        guard let package = package(for: subscriptionType) else {
            throw PurchaseError.noOfferings
        }
        try await purchase(package: package)
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        guard isConfigured else {
            throw PurchaseError.notConfigured
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let info = try await Purchases.shared.restorePurchases()
            updateCustomerInfo(info)
        } catch {
            throw PurchaseError.restoreFailed(error)
        }
    }

    // MARK: - Subscription Status

    var subscriptionStatus: String {
        guard let entitlement = customerInfo?.entitlements[PurchaseConfig.proEntitlement] else {
            return "Free"
        }

        if entitlement.isActive {
            // Lifetime purchase (no expiration date)
            if entitlement.expirationDate == nil {
                return "Pro (Lifetime)"
            }

            // Check if subscription will renew
            if let expirationDate = entitlement.expirationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium

                if entitlement.willRenew {
                    return "Pro (renews \(formatter.string(from: expirationDate)))"
                } else {
                    return "Pro (expires \(formatter.string(from: expirationDate)))"
                }
            }
            return "Pro"
        }

        return "Free"
    }

    /// Get detailed subscription info for UI display
    var subscriptionDetails: (tier: String, status: String, expirationInfo: String?) {
        guard let entitlement = customerInfo?.entitlements[PurchaseConfig.proEntitlement],
              entitlement.isActive else {
            return ("Free", "Not subscribed", nil)
        }

        let tier = "Moonbeat AI Pro"

        if entitlement.expirationDate == nil {
            return (tier, "Lifetime", nil)
        }

        guard let expirationDate = entitlement.expirationDate else {
            return (tier, "Active", nil)
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .long

        let status = entitlement.willRenew ? "Active" : "Cancelling"
        let expirationInfo = entitlement.willRenew
            ? "Renews on \(formatter.string(from: expirationDate))"
            : "Expires on \(formatter.string(from: expirationDate))"

        return (tier, status, expirationInfo)
    }

    // MARK: - Sync to Supabase

    private func syncSubscriptionToSupabase() async {
        guard let userId = AuthService.shared.currentUser?.id else { return }

        let tier: SubscriptionTier = isPro ? .pro : .free

        do {
            try await supabase
                .from(SupabaseTable.profiles.rawValue)
                .update(["subscription_tier": tier.rawValue])
                .eq("id", value: userId.uuidString)
                .execute()

            // Refresh local profile
            await AuthService.shared.fetchUserProfile()
        } catch {
            print("Error syncing subscription: \(error)")
        }
    }
}
