import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Entitlement Check View Modifier

/// View modifier to gate content behind a paywall
struct RequiresProModifier: ViewModifier {
    @EnvironmentObject var purchaseService: PurchaseService
    @State private var showPaywall = false

    let action: () -> Void

    func body(content: Content) -> some View {
        content
            .onTapGesture {
                if purchaseService.isPro {
                    action()
                } else {
                    showPaywall = true
                }
            }
            .sheet(isPresented: $showPaywall) {
                CustomSubscriptionView()
            }
    }
}

extension View {
    /// Require pro subscription before allowing action
    func requiresPro(action: @escaping () -> Void) -> some View {
        modifier(RequiresProModifier(action: action))
    }
}

// MARK: - Pro Feature Lock Overlay

/// Overlay that shows a lock icon for non-pro users
struct ProFeatureLock: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @State private var showPaywall = false

    var body: some View {
        if !purchaseService.isPro {
            ZStack {
                Color.black.opacity(0.6)

                VStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .font(.largeTitle)
                        .foregroundColor(.white)

                    Text("Pro Feature")
                        .font(.headline)
                        .foregroundColor(.white)

                    Button("Unlock") {
                        showPaywall = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)
                }
            }
            .sheet(isPresented: $showPaywall) {
                CustomSubscriptionView()
            }
        }
    }
}

// MARK: - Conditional Pro Content

/// Shows content only for pro users, otherwise shows upgrade prompt
struct ProOnlyContent<ProContent: View, FreeContent: View>: View {
    @EnvironmentObject var purchaseService: PurchaseService

    let proContent: () -> ProContent
    let freeContent: () -> FreeContent

    init(
        @ViewBuilder proContent: @escaping () -> ProContent,
        @ViewBuilder freeContent: @escaping () -> FreeContent
    ) {
        self.proContent = proContent
        self.freeContent = freeContent
    }

    var body: some View {
        if purchaseService.isPro {
            proContent()
        } else {
            freeContent()
        }
    }
}

// MARK: - Upgrade Prompt Button

/// A button that shows upgrade prompt for non-pro users
struct UpgradePromptButton: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @State private var showPaywall = false

    let title: String
    let proAction: () -> Void

    var body: some View {
        Button {
            if purchaseService.isPro {
                proAction()
            } else {
                showPaywall = true
            }
        } label: {
            HStack {
                Text(title)
                if !purchaseService.isPro {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            CustomSubscriptionView()
        }
    }
}

// MARK: - Pro Badge

/// Shows a pro badge next to content
struct ProBadge: View {
    var body: some View {
        Text("PRO")
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                LinearGradient(
                    colors: [.purple, .pink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .clipShape(Capsule())
    }
}

// MARK: - Usage Examples

/*
 USAGE EXAMPLES:

 1. Gate a feature behind paywall:

    Button("Generate Video") {
        // This action only happens if user is Pro
    }
    .requiresPro {
        generateVideo()
    }

 2. Show different content for Pro vs Free users:

    ProOnlyContent {
        // Content for Pro users
        UnlimitedVideosView()
    } freeContent: {
        // Content for Free users
        LimitedVideosView()
    }

 3. Show lock overlay on premium content:

    ZStack {
        PremiumFeatureView()
        ProFeatureLock()
    }

 4. Button with crown indicator:

    UpgradePromptButton(title: "HD Export") {
        exportInHD()
    }

 5. Check entitlement programmatically:

    if purchaseService.isPro {
        // Allow unlimited videos
    } else {
        // Check credits remaining
    }

 6. Present paywall automatically when needed:

    .presentPaywallIfNeeded()

 7. Present paywall with custom logic:

    .presentPaywallIfNeeded { customerInfo in
        !customerInfo.entitlements["Moonbeat AI Pro"]?.isActive ?? false
    }

 8. Show subscription status in UI:

    Text(purchaseService.subscriptionStatus)
    // Outputs: "Free", "Pro (Lifetime)", "Pro (renews Jan 1, 2025)"

 9. Get detailed subscription info:

    let details = purchaseService.subscriptionDetails
    print(details.tier)           // "Moonbeat AI Pro" or "Free"
    print(details.status)         // "Active", "Cancelling", "Lifetime"
    print(details.expirationInfo) // "Renews on Jan 1, 2025" or nil

 10. Listen for purchase changes (happens automatically via customerInfoStream):

     The PurchaseService automatically updates when purchases change.
     Just observe purchaseService.isPro in your views.
*/

// MARK: - Credit Check Helper

extension PurchaseService {
    /// Check if user can use a video credit (Pro users always can, Free users need credits)
    func canUseVideoCredit(creditsRemaining: Int) -> Bool {
        return isPro || creditsRemaining > 0
    }

    /// Get the reason why user can't generate video
    func videoBlockedReason(creditsRemaining: Int) -> String? {
        if isPro {
            return nil
        }
        if creditsRemaining <= 0 {
            return "No credits remaining. Upgrade to Pro for 30 videos per month."
        }
        return nil
    }
}

// MARK: - Credit Urgency Levels

enum CreditUrgency: Equatable {
    case normal      // 3+ credits
    case low         // 2 credits
    case critical    // 1 credit
    case depleted    // 0 credits

    static func from(credits: Int, isPro: Bool) -> CreditUrgency {
        if isPro { return .normal }
        switch credits {
        case 0: return .depleted
        case 1: return .critical
        case 2: return .low
        default: return .normal
        }
    }

    var color: Color {
        switch self {
        case .normal: return MBColors.textMuted
        case .low: return .orange
        case .critical: return MBColors.error
        case .depleted: return MBColors.error
        }
    }

    var shouldShowWarning: Bool {
        switch self {
        case .normal: return false
        case .low, .critical, .depleted: return true
        }
    }

    var shouldPulse: Bool {
        return self == .critical
    }
}

// MARK: - Pro Quota Urgency Levels

enum ProQuotaUrgency: Equatable {
    case normal      // 50%+ remaining
    case low         // 25-50% remaining
    case critical    // <25% remaining
    case depleted    // 0 remaining

    static func from(quota: ProQuotaStatus) -> ProQuotaUrgency {
        let percentRemaining = Double(quota.videosRemaining) / Double(quota.quotaLimit)
        switch percentRemaining {
        case 0: return .depleted
        case 0..<0.25: return .critical
        case 0.25..<0.5: return .low
        default: return .normal
        }
    }

    var color: Color {
        switch self {
        case .normal: return MBColors.textMuted
        case .low: return .orange
        case .critical, .depleted: return MBColors.error
        }
    }
}

// MARK: - Pro Quota Status View

/// Shows Pro user's monthly quota status with progress bar
struct ProQuotaStatusView: View {
    let quota: ProQuotaStatus

    var urgency: ProQuotaUrgency {
        ProQuotaUrgency.from(quota: quota)
    }

    var body: some View {
        VStack(spacing: MBSpacing.xs) {
            HStack {
                Text("\(quota.videosRemaining)")
                    .font(MBTypography.titleMedium())
                    .foregroundStyle(urgency.color)
                Text("of \(quota.quotaLimit) videos remaining")
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textSecondary)
            }

            Text("Resets \(quota.resetDateFormatted)")
                .font(MBTypography.caption())
                .foregroundStyle(MBColors.textTertiary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MBColors.backgroundElevated)
                        .frame(height: 6)

                    Capsule()
                        .fill(urgency.color)
                        .frame(width: geometry.size.width * CGFloat(quota.videosRemaining) / CGFloat(quota.quotaLimit), height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Pro Quota Limit Sheet

/// Sheet shown when Pro user hits their monthly limit
struct ProQuotaLimitSheet: View {
    let quota: ProQuotaStatus
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: MBSpacing.xl) {
            // Header
            VStack(spacing: MBSpacing.sm) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 48))
                    .foregroundStyle(MBColors.warning)

                Text("Monthly Limit Reached")
                    .font(MBTypography.title())
                    .foregroundStyle(MBColors.textPrimary)

                Text("You've used all \(quota.quotaLimit) videos for this month")
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Reset info
            VStack(spacing: MBSpacing.xs) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 24))
                    .foregroundStyle(MBColors.primary)

                Text("Your quota resets on \(quota.resetDateFormatted)")
                    .font(MBTypography.bodyBold())
                    .foregroundStyle(MBColors.textPrimary)
            }
            .padding(MBSpacing.lg)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))

            Button {
                dismiss()
            } label: {
                Text("Got It")
                    .font(MBTypography.bodyBold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MBSpacing.md)
                    .background(MBColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
            }
        }
        .padding(MBSpacing.xl)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Credit Warning Sheet

/// Soft upsell sheet shown at 2 credits after video generation
struct CreditWarningSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    let creditsRemaining: Int

    var body: some View {
        VStack(spacing: MBSpacing.xl) {
            // Header
            VStack(spacing: MBSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 48))
                    .foregroundStyle(MBColors.accent)

                Text("Love Your Videos?")
                    .font(MBTypography.title())
                    .foregroundStyle(MBColors.textPrimary)

                Text("You have \(creditsRemaining) free videos left")
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textSecondary)
            }

            // Benefits
            VStack(alignment: .leading, spacing: MBSpacing.sm) {
                benefitRow(icon: "sparkles", text: "30 dream videos per month")
                benefitRow(icon: "chart.line.uptrend.xyaxis", text: "Full emotional insights")
                benefitRow(icon: "sparkle.magnifyingglass", text: "AI dream interpretation")
                benefitRow(icon: "bolt.fill", text: "Priority video generation")
            }
            .padding(MBSpacing.lg)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))

            // CTA
            VStack(spacing: MBSpacing.sm) {
                Button {
                    HapticManager.shared.paywallPresented()
                    showPaywall = true
                } label: {
                    Text("Upgrade to Pro")
                        .font(MBTypography.bodyBold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MBSpacing.md)
                        .background(MBGradients.primary)
                        .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
                }

                Button {
                    dismiss()
                } label: {
                    Text("Maybe Later")
                        .font(MBTypography.body())
                        .foregroundStyle(MBColors.textMuted)
                }
            }
        }
        .padding(MBSpacing.xl)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showPaywall) {
            CustomSubscriptionView()
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: MBSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(MBColors.primary)
                .frame(width: 24)

            Text(text)
                .font(MBTypography.body())
                .foregroundStyle(MBColors.textPrimary)
        }
    }
}

// MARK: - Last Credit Confirmation Dialog

/// Confirmation dialog shown when user is about to use their last credit
struct LastCreditConfirmationView: View {
    let onConfirm: () -> Void
    let onUpgrade: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: MBSpacing.lg) {
            // Warning icon
            ZStack {
                Circle()
                    .fill(MBColors.error.opacity(0.15))
                    .frame(width: 80, height: 80)

                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(MBColors.error)
            }

            // Title and message
            VStack(spacing: MBSpacing.xs) {
                Text("Last Free Video")
                    .font(MBTypography.title())
                    .foregroundStyle(MBColors.textPrimary)

                Text("This is your final free video credit. After this, you'll need Pro to create more dream videos.")
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Actions
            VStack(spacing: MBSpacing.sm) {
                Button {
                    HapticManager.shared.paywallPresented()
                    onUpgrade()
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text("Get Pro - 30 Videos/Month")
                    }
                    .font(MBTypography.bodyBold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MBSpacing.md)
                    .background(MBGradients.primary)
                    .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
                }

                Button {
                    onConfirm()
                    dismiss()
                } label: {
                    Text("Use My Last Credit")
                        .font(MBTypography.body())
                        .foregroundStyle(MBColors.textMuted)
                        .padding(.vertical, MBSpacing.sm)
                }
            }
        }
        .padding(MBSpacing.xl)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - No Credits Paywall

/// Hard paywall shown when user has 0 credits
struct NoCreditsPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: MBSpacing.xl) {
            // Header
            VStack(spacing: MBSpacing.md) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(MBColors.primary)

                VStack(spacing: MBSpacing.xs) {
                    Text("No Credits Remaining")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(MBColors.textPrimary)

                    Text("Upgrade to Pro for 30 dream videos per month")
                        .font(.system(size: 15))
                        .foregroundStyle(MBColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }

            // Features
            VStack(alignment: .leading, spacing: MBSpacing.sm) {
                featureRow("sparkles", "30 dream videos per month")
                featureRow("chart.line.uptrend.xyaxis", "Full emotional analytics")
                featureRow("sparkle.magnifyingglass", "AI dream interpretation")
                featureRow("bolt", "Priority generation")
            }
            .padding(MBSpacing.lg)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))

            // CTA
            Button {
                HapticManager.shared.paywallPresented()
                showPaywall = true
            } label: {
                Text("View Plans")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(MBColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                dismiss()
            } label: {
                Text("Not Now")
                    .font(.system(size: 15))
                    .foregroundStyle(MBColors.textMuted)
            }
        }
        .padding(MBSpacing.xl)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showPaywall) {
            CustomSubscriptionView()
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: MBSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(MBColors.primary)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MBColors.textPrimary)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MBColors.textMuted)
        }
    }
}

// MARK: - Credit Status View Modifier

/// View modifier to handle credit status and show appropriate warnings
struct CreditAwareModifier: ViewModifier {
    let credits: Int
    let isPro: Bool
    @Binding var showWarningSheet: Bool
    @Binding var showLastCreditConfirmation: Bool
    @Binding var showNoCreditsPaywall: Bool

    var urgency: CreditUrgency {
        CreditUrgency.from(credits: credits, isPro: isPro)
    }

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showWarningSheet) {
                CreditWarningSheet(creditsRemaining: credits)
            }
            .sheet(isPresented: $showLastCreditConfirmation) {
                LastCreditConfirmationView(
                    onConfirm: { },
                    onUpgrade: {
                        showLastCreditConfirmation = false
                    }
                )
            }
            .sheet(isPresented: $showNoCreditsPaywall) {
                NoCreditsPaywallView()
            }
    }
}

extension View {
    func creditAware(
        credits: Int,
        isPro: Bool,
        showWarningSheet: Binding<Bool>,
        showLastCreditConfirmation: Binding<Bool>,
        showNoCreditsPaywall: Binding<Bool>
    ) -> some View {
        modifier(CreditAwareModifier(
            credits: credits,
            isPro: isPro,
            showWarningSheet: showWarningSheet,
            showLastCreditConfirmation: showLastCreditConfirmation,
            showNoCreditsPaywall: showNoCreditsPaywall
        ))
    }
}
