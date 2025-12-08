import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - Modern Paywall View

/// Uses RevenueCat's built-in PaywallView for a remotely configurable paywall
/// Configure your paywall design in the RevenueCat Dashboard
struct SubscriptionView: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { customerInfo in
                print("Purchase completed: \(customerInfo.entitlements)")
                dismiss()
            }
            .onRestoreCompleted { customerInfo in
                print("Restore completed: \(customerInfo.entitlements)")
                if customerInfo.entitlements[PurchaseConfig.proEntitlement]?.isActive == true {
                    dismiss()
                }
            }
    }
}

// MARK: - Custom Premium Paywall

struct CustomSubscriptionView: View {
    @EnvironmentObject var purchaseService: PurchaseService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @State private var error: Error?
    @State private var showError = false
    @State private var animateGlow = false
    @State private var animateBadge = false

    // Calculate savings percentage for annual plan
    private var annualSavingsPercent: Int {
        guard let monthly = purchaseService.allPackages.first(where: { $0.packageType == .monthly }),
              let annual = purchaseService.allPackages.first(where: { $0.packageType == .annual }) else {
            return 50 // Default fallback
        }
        let monthlyYearCost = monthly.storeProduct.price * 12
        let annualCost = annual.storeProduct.price
        let savings = ((monthlyYearCost - annualCost) / monthlyYearCost) * 100
        return Int(NSDecimalNumber(decimal: savings).doubleValue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Premium gradient background
                LinearGradient(
                    colors: [
                        MBColors.background,
                        MBColors.primary.opacity(0.05),
                        MBColors.background
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero with social proof
                        heroSection
                            .padding(.top, 16)
                            .padding(.bottom, 28)

                        // Social proof badge
                        socialProofSection
                            .padding(.bottom, 24)

                        // Features
                        featuresSection
                            .padding(.bottom, 28)

                        // Pricing
                        if purchaseService.currentOffering != nil {
                            pricingSection
                                .padding(.bottom, 20)
                        } else {
                            ProgressView()
                                .tint(MBColors.primary)
                                .padding(.vertical, 40)
                        }

                        // Trust indicators
                        trustSection
                            .padding(.bottom, 16)

                        // Legal
                        legalSection
                            .padding(.bottom, 32)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(MBColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(MBColors.backgroundElevated)
                            .clipShape(Circle())
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .overlay {
                if isPurchasing {
                    loadingOverlay
                }
            }
        }
        .task {
            await purchaseService.fetchOfferings()
            // Auto-select annual as default (best value)
            if selectedPackage == nil {
                selectedPackage = purchaseService.allPackages.first { $0.packageType == .annual }
                    ?? purchaseService.allPackages.first
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).repeatForever(autoreverses: true).delay(0.5)) {
                animateBadge = true
            }
        }
        .alert("Unable to Complete", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(error?.localizedDescription ?? "Please try again.")
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 12) {
            // Animated icon with glow
            ZStack {
                // Glow effect
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(MBColors.primary)
                    .blur(radius: animateGlow ? 20 : 10)
                    .opacity(animateGlow ? 0.6 : 0.3)

                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [MBColors.primary, MBColors.primary.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Title
            Text("Unlock Your Dreams")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(MBColors.textPrimary)

            // Benefit-focused subtitle
            Text("Transform every dream into\na cinematic experience")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(MBColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    // MARK: - Social Proof Section

    private var socialProofSection: some View {
        HStack(spacing: 8) {
            // Star rating
            HStack(spacing: 2) {
                ForEach(0..<5) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.yellow)
                }
            }

            Text("Loved by dreamers")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(MBColors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(MBColors.backgroundCard)
        .clipShape(Capsule())
    }

    // MARK: - Features Section

    private var featuresSection: some View {
        VStack(spacing: 14) {
            FeatureRowEnhanced(icon: "infinity", title: "Unlimited dream videos", subtitle: "No limits, ever")
            FeatureRowEnhanced(icon: "waveform", title: "60-second visualizations", subtitle: "Longer, richer videos")
            FeatureRowEnhanced(icon: "chart.line.uptrend.xyaxis", title: "Emotional insights", subtitle: "Track your patterns")
            FeatureRowEnhanced(icon: "bolt.fill", title: "Priority processing", subtitle: "Skip the queue")
        }
        .padding(20)
        .background(MBColors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: 12) {
            // Sort packages: annual first (best value), then monthly, then lifetime
            let sortedPackages = purchaseService.allPackages.sorted { p1, p2 in
                let order: [PackageType: Int] = [.annual: 0, .monthly: 1, .lifetime: 2]
                return (order[p1.packageType] ?? 3) < (order[p2.packageType] ?? 3)
            }

            ForEach(sortedPackages) { package in
                PricingOptionRowEnhanced(
                    package: package,
                    isSelected: selectedPackage?.identifier == package.identifier,
                    savingsPercent: package.packageType == .annual ? annualSavingsPercent : nil,
                    allPackages: purchaseService.allPackages
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPackage = package
                        HapticManager.shared.selection()
                    }
                }
            }

            // CTA Button with glow
            Button {
                HapticManager.shared.impact(style: .medium)
                purchase()
            } label: {
                HStack(spacing: 8) {
                    Text(ctaButtonText)
                        .font(.system(size: 18, weight: .bold))

                    if !isPurchasing {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    ZStack {
                        // Glow
                        if selectedPackage != nil {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(MBColors.primary)
                                .blur(radius: animateGlow ? 12 : 8)
                                .opacity(animateGlow ? 0.6 : 0.4)
                                .scaleEffect(animateGlow ? 1.02 : 1.0)
                        }

                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                selectedPackage != nil
                                    ? LinearGradient(
                                        colors: [MBColors.primary, MBColors.primary.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [MBColors.textMuted, MBColors.textMuted],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                    }
                )
            }
            .disabled(selectedPackage == nil || isPurchasing)
            .padding(.top, 8)

            // Restore
            Button {
                restorePurchases()
            } label: {
                Text("Restore Purchases")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MBColors.textSecondary)
            }
            .padding(.top, 4)
        }
    }

    private var ctaButtonText: String {
        guard let package = selectedPackage else { return "Continue" }
        switch package.packageType {
        case .lifetime:
            return "Get Lifetime Access"
        case .annual:
            return "Start Your Journey"
        default:
            return "Continue"
        }
    }

    // MARK: - Trust Section

    private var trustSection: some View {
        HStack(spacing: 20) {
            TrustBadge(icon: "lock.shield.fill", text: "Secure")
            TrustBadge(icon: "xmark.circle", text: "Cancel Anytime")
            TrustBadge(icon: "arrow.clockwise", text: "Restore")
        }
    }

    // MARK: - Legal Section

    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("Payment will be charged to your Apple ID. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.")
                .font(.system(size: 11))
                .foregroundStyle(MBColors.textMuted)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Link("Terms of Use", destination: URL(string: "https://yourapp.com/terms")!)
                Link("Privacy Policy", destination: URL(string: "https://yourapp.com/privacy")!)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(MBColors.textSecondary)
        }
    }

    // MARK: - Loading Overlay

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.3)

                Text("Processing...")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Actions

    private func purchase() {
        guard let package = selectedPackage else { return }

        Task {
            isPurchasing = true
            defer { isPurchasing = false }

            do {
                try await purchaseService.purchase(package: package)
                HapticManager.shared.success()
                dismiss()
            } catch PurchaseError.userCancelled {
                // User cancelled
            } catch {
                HapticManager.shared.error()
                self.error = error
                self.showError = true
            }
        }
    }

    private func restorePurchases() {
        Task {
            isPurchasing = true
            defer { isPurchasing = false }

            do {
                try await purchaseService.restorePurchases()
                if purchaseService.isPro {
                    HapticManager.shared.success()
                    dismiss()
                }
            } catch {
                HapticManager.shared.error()
                self.error = error
                self.showError = true
            }
        }
    }
}

// MARK: - Trust Badge

private struct TrustBadge: View {
    let icon: String
    let text: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(MBColors.textMuted)

            Text(text)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(MBColors.textMuted)
        }
    }
}

// MARK: - Feature Row Enhanced

private struct FeatureRowEnhanced: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            // Icon with subtle background
            ZStack {
                Circle()
                    .fill(MBColors.primary.opacity(0.1))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MBColors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(MBColors.textPrimary)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(MBColors.textMuted)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundStyle(MBColors.primary.opacity(0.7))
        }
    }
}

// MARK: - Feature Row (Legacy)

private struct FeatureRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(MBColors.primary)
                .frame(width: 24)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(MBColors.textPrimary)

            Spacer()

            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(MBColors.textMuted)
        }
    }
}

// MARK: - Pricing Option Row

private struct PricingOptionRow: View {
    let package: Package
    let isSelected: Bool
    let action: () -> Void

    private var isPopular: Bool {
        package.packageType == .annual
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Selection indicator
                Circle()
                    .strokeBorder(
                        isSelected ? MBColors.primary : MBColors.border,
                        lineWidth: isSelected ? 6 : 2
                    )
                    .frame(width: 22, height: 22)

                // Plan info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(planName)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(MBColors.textPrimary)

                        if isPopular {
                            Text("Popular")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(MBColors.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(MBColors.primary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }

                    Text(planDescription)
                        .font(.system(size: 14))
                        .foregroundStyle(MBColors.textSecondary)
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(package.storeProduct.localizedPriceString)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(MBColors.textPrimary)

                    if let perMonth = monthlyEquivalent {
                        Text(perMonth)
                            .font(.system(size: 13))
                            .foregroundStyle(MBColors.textMuted)
                    }
                }
            }
            .padding(16)
            .background(
                isSelected
                    ? MBColors.primary.opacity(0.08)
                    : MBColors.backgroundCard
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? MBColors.primary : MBColors.border,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var planName: String {
        switch package.packageType {
        case .monthly: return "Monthly"
        case .annual: return "Yearly"
        case .lifetime: return "Lifetime"
        default: return package.storeProduct.localizedTitle
        }
    }

    private var planDescription: String {
        switch package.packageType {
        case .monthly: return "Billed monthly"
        case .annual: return "Billed annually"
        case .lifetime: return "One-time purchase"
        default: return ""
        }
    }

    private var monthlyEquivalent: String? {
        guard package.packageType == .annual else { return nil }
        let price = package.storeProduct.price
        let monthly = price / 12
        // Extract currency symbol from localized price string
        let localizedPrice = package.storeProduct.localizedPriceString
        let currencySymbol = localizedPrice.first { !$0.isNumber && $0 != "." && $0 != "," } ?? "$"
        return "\(currencySymbol)\(String(format: "%.2f", NSDecimalNumber(decimal: monthly).doubleValue))/mo"
    }
}

// MARK: - Enhanced Pricing Option Row

private struct PricingOptionRowEnhanced: View {
    let package: Package
    let isSelected: Bool
    let savingsPercent: Int?
    let allPackages: [Package]
    let action: () -> Void

    private var isBestValue: Bool {
        package.packageType == .annual
    }

    private var isLifetime: Bool {
        package.packageType == .lifetime
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                // Best value badge for annual
                if isBestValue {
                    HStack {
                        Spacer()
                        Text("BEST VALUE")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [MBColors.primary, MBColors.primary.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        Spacer()
                    }
                    .offset(y: 10)
                    .zIndex(1)
                }

                HStack(spacing: 14) {
                    // Selection indicator
                    ZStack {
                        Circle()
                            .strokeBorder(
                                isSelected ? MBColors.primary : MBColors.border,
                                lineWidth: 2
                            )
                            .frame(width: 24, height: 24)

                        if isSelected {
                            Circle()
                                .fill(MBColors.primary)
                                .frame(width: 14, height: 14)
                        }
                    }

                    // Plan info
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(planName)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(MBColors.textPrimary)

                            if let savings = savingsPercent, savings > 0 {
                                Text("SAVE \(savings)%")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.green)
                                    )
                            }

                            if isLifetime {
                                Text("FOREVER")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundStyle(MBColors.primary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .strokeBorder(MBColors.primary, lineWidth: 1)
                                    )
                            }
                        }

                        Text(planDescription)
                            .font(.system(size: 13))
                            .foregroundStyle(MBColors.textSecondary)
                    }

                    Spacer()

                    // Price
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(package.storeProduct.localizedPriceString)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(MBColors.textPrimary)

                        if let perMonth = monthlyEquivalent {
                            Text(perMonth)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(MBColors.primary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, isBestValue ? 18 : 16)
                .padding(.top, isBestValue ? 4 : 0)
                .background(
                    ZStack {
                        if isBestValue && isSelected {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(MBColors.primary.opacity(0.05))
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(MBColors.backgroundCard)
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected
                                ? MBColors.primary
                                : (isBestValue ? MBColors.primary.opacity(0.3) : MBColors.border),
                            lineWidth: isSelected ? 2.5 : 1
                        )
                )
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private var planName: String {
        switch package.packageType {
        case .monthly: return "Monthly"
        case .annual: return "Yearly"
        case .lifetime: return "Lifetime"
        default: return package.storeProduct.localizedTitle
        }
    }

    private var planDescription: String {
        switch package.packageType {
        case .monthly: return "Billed monthly"
        case .annual: return "Billed once per year"
        case .lifetime: return "Pay once, own forever"
        default: return ""
        }
    }

    private var monthlyEquivalent: String? {
        guard package.packageType == .annual else { return nil }
        let price = package.storeProduct.price
        let monthly = price / 12
        let localizedPrice = package.storeProduct.localizedPriceString
        let currencySymbol = localizedPrice.first { !$0.isNumber && $0 != "." && $0 != "," } ?? "$"
        return "Just \(currencySymbol)\(String(format: "%.2f", NSDecimalNumber(decimal: monthly).doubleValue))/mo"
    }
}

// MARK: - Paywall Presentation Modifier

extension View {
    /// Present paywall when user doesn't have pro entitlement
    func presentPaywallIfNeeded() -> some View {
        self.presentPaywallIfNeeded(
            requiredEntitlementIdentifier: PurchaseConfig.proEntitlement
        )
    }
}

#Preview {
    CustomSubscriptionView()
        .environmentObject(PurchaseService.shared)
}
