import Foundation
import FBSDKCoreKit
import AppTrackingTransparency
import AdSupport

/// Service for Meta (Facebook) Ads conversion tracking
/// Tracks all key conversion events for campaign optimization
@MainActor
final class MetaAnalyticsService: ObservableObject {
    static let shared = MetaAnalyticsService()

    @Published private(set) var trackingAuthorized = false
    @Published private(set) var hasRequestedTracking = false

    private init() {
        checkTrackingStatus()
    }

    // MARK: - Tracking Authorization

    /// Check current ATT authorization status
    func checkTrackingStatus() {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            trackingAuthorized = status == .authorized
            hasRequestedTracking = status != .notDetermined
        } else {
            trackingAuthorized = true
            hasRequestedTracking = true
        }
    }

    /// Request App Tracking Transparency permission
    /// Should be called after a short delay from app launch for better approval rates
    func requestTrackingAuthorization() async -> Bool {
        guard #available(iOS 14, *) else {
            trackingAuthorized = true
            return true
        }

        let status = await ATTrackingManager.requestTrackingAuthorization()
        hasRequestedTracking = true
        trackingAuthorized = status == .authorized

        // Update Facebook SDK with tracking status
        Settings.shared.isAdvertiserTrackingEnabled = trackingAuthorized

        return trackingAuthorized
    }

    // MARK: - Standard Events

    /// Track app activation (called automatically by SDK if configured)
    func trackAppActivated() {
        AppEvents.shared.activateApp()
        logEvent(.init("AppActivated"))
    }

    /// Track user registration/sign up
    func trackRegistration(method: String = "Apple") {
        AppEvents.shared.logEvent(
            .completedRegistration,
            parameters: [
                .registrationMethod: method
            ]
        )
        logEvent(.init("CompleteRegistration"), parameters: ["method": method])
    }

    /// Track when user completes onboarding
    func trackOnboardingComplete() {
        logEvent(.init("OnboardingComplete"))
    }

    /// Track when user views subscription options
    func trackPaywallViewed(source: String) {
        logEvent(
            .init("PaywallViewed"),
            parameters: ["source": source]
        )
    }

    /// Track subscription start (trial or paid)
    func trackStartTrial(productId: String, price: Decimal, currency: String = "USD") {
        AppEvents.shared.logEvent(
            .startTrial,
            valueToSum: Double(truncating: price as NSNumber),
            parameters: [
                .contentID: productId,
                .currency: currency
            ]
        )
        logEvent(
            .init("StartTrial"),
            parameters: [
                "product_id": productId,
                "value": "\(price)",
                "currency": currency
            ]
        )
    }

    /// Track subscription purchase (most important conversion event)
    func trackSubscription(
        productId: String,
        price: Decimal,
        currency: String = "USD",
        subscriptionType: String,
        isTrialConversion: Bool = false
    ) {
        let value = Double(truncating: price as NSNumber)

        // Primary purchase event
        AppEvents.shared.logEvent(
            .subscribe,
            valueToSum: value,
            parameters: [
                .contentID: productId,
                .currency: currency,
                .init("subscription_type"): subscriptionType,
                .init("is_trial_conversion"): isTrialConversion ? "true" : "false"
            ]
        )

        // Also log as standard purchase for broader matching
        AppEvents.shared.logEvent(
            .purchased,
            valueToSum: value,
            parameters: [
                .contentID: productId,
                .currency: currency,
                .contentType: "subscription"
            ]
        )

        logEvent(
            .init("Subscribe"),
            parameters: [
                "product_id": productId,
                "value": "\(price)",
                "currency": currency,
                "subscription_type": subscriptionType,
                "is_trial_conversion": isTrialConversion ? "true" : "false"
            ]
        )
    }

    /// Track lifetime purchase
    func trackLifetimePurchase(productId: String, price: Decimal, currency: String = "USD") {
        let value = Double(truncating: price as NSNumber)

        AppEvents.shared.logEvent(
            .purchased,
            valueToSum: value,
            parameters: [
                .contentID: productId,
                .currency: currency,
                .contentType: "lifetime"
            ]
        )

        logEvent(
            .init("LifetimePurchase"),
            parameters: [
                "product_id": productId,
                "value": "\(price)",
                "currency": currency
            ]
        )
    }

    /// Track in-app purchase (video credits, etc.)
    func trackInAppPurchase(productId: String, price: Decimal, currency: String = "USD") {
        AppEvents.shared.logEvent(
            .purchased,
            valueToSum: Double(truncating: price as NSNumber),
            parameters: [
                .contentID: productId,
                .currency: currency,
                .contentType: "consumable"
            ]
        )
    }

    // MARK: - Custom Events for Optimization

    /// Track first dream recorded (key engagement milestone)
    func trackFirstDreamRecorded() {
        logEvent(.init("FirstDreamRecorded"))
    }

    /// Track dream recorded
    func trackDreamRecorded(dreamCount: Int) {
        logEvent(
            .init("DreamRecorded"),
            parameters: ["dream_count": "\(dreamCount)"]
        )
    }

    /// Track video generation started
    func trackVideoGenerationStarted() {
        logEvent(.init("VideoGenerationStarted"))
    }

    /// Track video generation completed
    func trackVideoGenerationCompleted() {
        logEvent(.init("VideoGenerationCompleted"))
    }

    /// Track feature usage for engagement metrics
    func trackFeatureUsed(feature: String) {
        logEvent(
            .init("FeatureUsed"),
            parameters: ["feature_name": feature]
        )
    }

    /// Track day N retention
    func trackRetention(day: Int) {
        logEvent(
            .init("Retention"),
            parameters: ["day": "\(day)"]
        )
    }

    /// Track streak milestone achieved
    func trackStreakMilestone(days: Int) {
        logEvent(
            .init("StreakMilestone"),
            parameters: ["streak_days": "\(days)"]
        )
    }

    // MARK: - User Properties

    /// Set user properties for better audience targeting
    func setUserProperties(
        isPro: Bool,
        dreamCount: Int? = nil,
        streak: Int? = nil
    ) {
        AppEvents.shared.setUserData(isPro ? "pro" : "free", forType: .externalId)

        if let dreamCount = dreamCount {
            AppEvents.shared.setUserData("\(dreamCount)", forType: .init("dream_count"))
        }

        if let streak = streak {
            AppEvents.shared.setUserData("\(streak)", forType: .init("streak"))
        }
    }

    /// Set user ID for cross-device tracking (when authorized)
    func setUserId(_ userId: String?) {
        if let userId = userId {
            AppEvents.shared.userID = userId
        } else {
            AppEvents.shared.userID = nil
        }
    }

    // MARK: - Helper

    private func logEvent(_ event: AppEvents.Name, parameters: [String: String] = [:]) {
        let fbParameters = parameters.reduce(into: [AppEvents.ParameterName: Any]()) { result, pair in
            result[.init(pair.key)] = pair.value
        }
        AppEvents.shared.logEvent(event, parameters: fbParameters)

        #if DEBUG
        print("📊 Meta Event: \(event.rawValue) - \(parameters)")
        #endif
    }
}

// MARK: - Conversion Value for SKAdNetwork

extension MetaAnalyticsService {
    /// Update SKAdNetwork conversion value based on user actions
    /// This helps with attribution even without IDFA
    func updateConversionValue(for action: ConversionAction) {
        guard #available(iOS 14, *) else { return }

        // SKAdNetwork conversion values (0-63)
        // Higher values = more valuable user
        let value: Int

        switch action {
        case .installed:
            value = 0
        case .registered:
            value = 5
        case .onboardingComplete:
            value = 10
        case .firstDream:
            value = 20
        case .paywallViewed:
            value = 25
        case .trialStarted:
            value = 40
        case .subscribed:
            value = 55
        case .lifetimePurchased:
            value = 63
        }

        // Update via Facebook SDK (handles SKAdNetwork automatically)
        AppEvents.shared.logEvent(
            .init("fb_mobile_purchase"),
            valueToSum: Double(value),
            parameters: [:]
        )
    }

    enum ConversionAction {
        case installed
        case registered
        case onboardingComplete
        case firstDream
        case paywallViewed
        case trialStarted
        case subscribed
        case lifetimePurchased
    }
}
