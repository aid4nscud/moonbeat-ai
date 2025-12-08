import SwiftUI
import RevenueCat
import RevenueCatUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var purchaseService: PurchaseService
    @ObservedObject private var notificationService = NotificationService.shared

    @State private var showSubscription = false
    @State private var showCustomerCenter = false
    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showDeleteAccountFinalConfirmation = false
    @State private var error: Error?
    @State private var showError = false
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                MBColors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: MBSpacing.lg) {
                        accountSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                        subscriptionSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.05), value: appeared)
                        notificationsSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.075), value: appeared)
                        appSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.1), value: appeared)
                        aboutSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
                        signOutSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                        deleteAccountSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)
                            .animation(.easeOut(duration: 0.4).delay(0.25), value: appeared)
                    }
                    .padding(.horizontal, MBSpacing.md)
                    .padding(.vertical, MBSpacing.md)
                    .animation(.easeOut(duration: 0.4), value: appeared)
                }
            }
            .onAppear {
                withAnimation {
                    appeared = true
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Settings")
                        .font(MBTypography.titleSmall())
                        .foregroundStyle(MBColors.textPrimary)
                }
            }
            .toolbarBackground(MBColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .sheet(isPresented: $showSubscription) {
            CustomSubscriptionView()
        }
        .presentCustomerCenter(
            isPresented: $showCustomerCenter,
            customerCenterActionHandler: handleCustomerCenterAction
        )
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirmation) {
            Button("Sign Out", role: .destructive) {
                signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .confirmationDialog("Delete Account", isPresented: $showDeleteAccountConfirmation) {
            Button("Delete Account", role: .destructive) {
                showDeleteAccountFinalConfirmation = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete your account and all your dreams. This action cannot be undone.")
        }
        .alert("Are you absolutely sure?", isPresented: $showDeleteAccountFinalConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete Forever", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("All your dreams, videos, and account data will be permanently deleted. This cannot be undone.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(spacing: MBSpacing.sm) {
            HStack(spacing: MBSpacing.md) {
                // Avatar with glow effect
                ZStack {
                    Circle()
                        .fill(MBGradients.primary)
                        .frame(width: 56, height: 56)
                        .shadow(color: MBColors.primary.opacity(0.4), radius: 8, x: 0, y: 4)

                    if let email = authService.currentUser?.email,
                       let initial = email.first?.uppercased() {
                        Text(initial)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white)
                    }
                }

                VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                    HStack(spacing: MBSpacing.xs) {
                        Text("Account")
                            .font(MBTypography.headline())
                            .foregroundStyle(MBColors.textPrimary)

                        if purchaseService.isPro {
                            Text("PRO")
                                .mbProBadge()
                        }
                    }

                    if let email = authService.currentUser?.email {
                        Text(email)
                            .font(MBTypography.bodySmall())
                            .foregroundStyle(MBColors.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .padding(MBSpacing.md)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Subscription Section

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            Text("Subscription")
                .font(MBTypography.caption(.semibold))
                .foregroundStyle(MBColors.textTertiary)
                .padding(.leading, MBSpacing.xs)

            VStack(spacing: 0) {
                // Main subscription button
                Button {
                    HapticManager.shared.itemSelected()
                    if purchaseService.isPro {
                        showCustomerCenter = true
                    } else {
                        showSubscription = true
                    }
                } label: {
                    HStack(spacing: MBSpacing.md) {
                        Image(systemName: purchaseService.isPro ? "star.fill" : "star")
                            .font(.system(size: 18))
                            .foregroundStyle(MBColors.gold)
                            .frame(width: 32, height: 32)
                            .background(MBColors.gold.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                        VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                            Text("Subscription Status")
                                .font(MBTypography.body())
                                .foregroundStyle(MBColors.textPrimary)

                            Text(purchaseService.subscriptionStatus)
                                .font(MBTypography.caption())
                                .foregroundStyle(MBColors.textTertiary)
                        }

                        Spacer()

                        if !purchaseService.isPro {
                            Text("Upgrade")
                                .font(MBTypography.captionSmall(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, MBSpacing.xs)
                                .padding(.vertical, MBSpacing.xxs)
                                .background(MBGradients.primary)
                                .clipShape(Capsule())
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(MBColors.textMuted)
                    }
                    .padding(MBSpacing.md)
                }
                .buttonStyle(.plain)

                // Free credits or subscription details
                if let profile = authService.userProfile {
                    if profile.subscriptionTier == .free {
                        MBDivider()
                            .padding(.horizontal, MBSpacing.md)

                        HStack(spacing: MBSpacing.md) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 18))
                                .foregroundStyle(MBColors.primary)
                                .frame(width: 32, height: 32)
                                .background(MBColors.primary.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                            Text("Free Credits")
                                .font(MBTypography.body())
                                .foregroundStyle(MBColors.textPrimary)

                            Spacer()

                            Text("\(profile.creditsRemaining) remaining")
                                .font(MBTypography.body())
                                .foregroundStyle(MBColors.textSecondary)
                        }
                        .padding(MBSpacing.md)
                    }
                }

                // Subscription details for Pro users
                if purchaseService.isPro {
                    let details = purchaseService.subscriptionDetails
                    if let expirationInfo = details.expirationInfo {
                        MBDivider()
                            .padding(.horizontal, MBSpacing.md)

                        HStack(spacing: MBSpacing.md) {
                            Image(systemName: "calendar")
                                .font(.system(size: 18))
                                .foregroundStyle(MBColors.info)
                                .frame(width: 32, height: 32)
                                .background(MBColors.info.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                            Text(expirationInfo)
                                .font(MBTypography.body())
                                .foregroundStyle(MBColors.textSecondary)

                            Spacer()
                        }
                        .padding(MBSpacing.md)
                    }

                    // Monthly quota display for Pro users
                    if let quota = authService.userProfile?.proQuotaStatus {
                        MBDivider()
                            .padding(.horizontal, MBSpacing.md)

                        HStack(spacing: MBSpacing.md) {
                            Image(systemName: "film.stack")
                                .font(.system(size: 18))
                                .foregroundStyle(MBColors.accent)
                                .frame(width: 32, height: 32)
                                .background(MBColors.accent.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                            VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                                Text("Monthly Videos")
                                    .font(MBTypography.body())
                                    .foregroundStyle(MBColors.textPrimary)

                                Text("Resets \(quota.resetDateFormatted)")
                                    .font(MBTypography.caption())
                                    .foregroundStyle(MBColors.textTertiary)
                            }

                            Spacer()

                            Text("\(quota.videosRemaining)/\(quota.quotaLimit)")
                                .font(MBTypography.bodyBold())
                                .foregroundStyle(ProQuotaUrgency.from(quota: quota).color)
                        }
                        .padding(MBSpacing.md)
                    }

                    MBDivider()
                        .padding(.horizontal, MBSpacing.md)

                    // Manage subscription button
                    Button {
                        showCustomerCenter = true
                    } label: {
                        HStack(spacing: MBSpacing.md) {
                            Image(systemName: "gearshape.2.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(MBColors.secondary)
                                .frame(width: 32, height: 32)
                                .background(MBColors.secondary.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                            Text("Manage Subscription")
                                .font(MBTypography.body())
                                .foregroundStyle(MBColors.textPrimary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(MBColors.textMuted)
                        }
                        .padding(MBSpacing.md)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            Text("Notifications")
                .font(MBTypography.caption(.semibold))
                .foregroundStyle(MBColors.textTertiary)
                .padding(.leading, MBSpacing.xs)

            VStack(spacing: 0) {
                // Morning Reminder Toggle
                HStack(spacing: MBSpacing.md) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(MBColors.gold)
                        .frame(width: 32, height: 32)
                        .background(MBColors.gold.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                    VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                        Text("Morning Reminder")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textPrimary)

                        Text("Daily reminder to record dreams")
                            .font(MBTypography.caption())
                            .foregroundStyle(MBColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $notificationService.preferences.morningReminderEnabled)
                        .labelsHidden()
                        .tint(MBColors.primary)
                        .onChange(of: notificationService.preferences.morningReminderEnabled) { _, _ in
                            HapticManager.shared.toggleChanged()
                        }
                }
                .padding(MBSpacing.md)

                // Time picker (show when enabled)
                if notificationService.preferences.morningReminderEnabled {
                    MBDivider()
                        .padding(.horizontal, MBSpacing.md)

                    HStack(spacing: MBSpacing.md) {
                        Image(systemName: "clock")
                            .font(.system(size: 18))
                            .foregroundStyle(MBColors.textSecondary)
                            .frame(width: 32, height: 32)

                        Text("Reminder Time")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textPrimary)

                        Spacer()

                        DatePicker(
                            "",
                            selection: $notificationService.preferences.morningReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .tint(MBColors.primary)
                    }
                    .padding(MBSpacing.md)
                }

                MBDivider()
                    .padding(.horizontal, MBSpacing.md)

                // Streak Alerts Toggle
                HStack(spacing: MBSpacing.md) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(MBColors.error)
                        .frame(width: 32, height: 32)
                        .background(MBColors.error.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                    VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                        Text("Streak Protection")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textPrimary)

                        Text("Alert when streak is at risk")
                            .font(MBTypography.caption())
                            .foregroundStyle(MBColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $notificationService.preferences.streakAlertsEnabled)
                        .labelsHidden()
                        .tint(MBColors.primary)
                        .onChange(of: notificationService.preferences.streakAlertsEnabled) { _, _ in
                            HapticManager.shared.toggleChanged()
                        }
                }
                .padding(MBSpacing.md)

                MBDivider()
                    .padding(.horizontal, MBSpacing.md)

                // Streak Milestones Toggle
                HStack(spacing: MBSpacing.md) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(MBColors.gold)
                        .frame(width: 32, height: 32)
                        .background(MBColors.gold.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                    VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                        Text("Streak Milestones")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textPrimary)

                        Text("Celebrate 7, 14, 30 day streaks")
                            .font(MBTypography.caption())
                            .foregroundStyle(MBColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $notificationService.preferences.streakMilestonesEnabled)
                        .labelsHidden()
                        .tint(MBColors.primary)
                        .onChange(of: notificationService.preferences.streakMilestonesEnabled) { _, _ in
                            HapticManager.shared.toggleChanged()
                        }
                }
                .padding(MBSpacing.md)

                MBDivider()
                    .padding(.horizontal, MBSpacing.md)

                // Weekly Digest Toggle
                HStack(spacing: MBSpacing.md) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18))
                        .foregroundStyle(MBColors.info)
                        .frame(width: 32, height: 32)
                        .background(MBColors.info.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                    VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                        Text("Weekly Digest")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textPrimary)

                        Text("Sunday summary of your dreams")
                            .font(MBTypography.caption())
                            .foregroundStyle(MBColors.textTertiary)
                    }

                    Spacer()

                    Toggle("", isOn: $notificationService.preferences.weeklyDigestEnabled)
                        .labelsHidden()
                        .tint(MBColors.primary)
                        .onChange(of: notificationService.preferences.weeklyDigestEnabled) { _, _ in
                            HapticManager.shared.toggleChanged()
                        }
                }
                .padding(MBSpacing.md)

                // Show permission warning if not authorized
                if !notificationService.isAuthorized {
                    MBDivider()
                        .padding(.horizontal, MBSpacing.md)

                    Button {
                        Task {
                            _ = await notificationService.requestAuthorization()
                        }
                    } label: {
                        HStack(spacing: MBSpacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(MBColors.warning)
                            Text("Notifications disabled. Tap to enable.")
                                .font(MBTypography.caption())
                                .foregroundStyle(MBColors.warning)
                            Spacer()
                        }
                        .padding(MBSpacing.md)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - App Section

    private var appSection: some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            Text("App")
                .font(MBTypography.caption(.semibold))
                .foregroundStyle(MBColors.textTertiary)
                .padding(.leading, MBSpacing.xs)

            VStack(spacing: 0) {
                Link(destination: URL(string: "https://aid4nscud.github.io/moonbeat-ai/privacy.html")!) {
                    HStack(spacing: MBSpacing.md) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(MBColors.info)
                            .frame(width: 32, height: 32)
                            .background(MBColors.info.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                        Text("Privacy Policy")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
                            .foregroundStyle(MBColors.textMuted)
                    }
                    .padding(MBSpacing.md)
                }

                MBDivider()
                    .padding(.horizontal, MBSpacing.md)

                Link(destination: URL(string: "https://aid4nscud.github.io/moonbeat-ai/terms.html")!) {
                    HStack(spacing: MBSpacing.md) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(MBColors.info)
                            .frame(width: 32, height: 32)
                            .background(MBColors.info.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                        Text("Terms of Service")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
                            .foregroundStyle(MBColors.textMuted)
                    }
                    .padding(MBSpacing.md)
                }

                MBDivider()
                    .padding(.horizontal, MBSpacing.md)

                Button {
                    Task {
                        do {
                            try await purchaseService.restorePurchases()
                        } catch {
                            self.error = error
                            self.showError = true
                        }
                    }
                } label: {
                    HStack(spacing: MBSpacing.md) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18))
                            .foregroundStyle(MBColors.primary)
                            .frame(width: 32, height: 32)
                            .background(MBColors.primary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                        Text("Restore Purchases")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textPrimary)

                        Spacer()
                    }
                    .padding(MBSpacing.md)
                }
                .buttonStyle(.plain)
            }
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            Text("About")
                .font(MBTypography.caption(.semibold))
                .foregroundStyle(MBColors.textTertiary)
                .padding(.leading, MBSpacing.xs)

            VStack(spacing: 0) {
                HStack {
                    Text("Version")
                        .font(MBTypography.body())
                        .foregroundStyle(MBColors.textPrimary)

                    Spacer()

                    Text(appVersion)
                        .font(MBTypography.body())
                        .foregroundStyle(MBColors.textSecondary)
                }
                .padding(MBSpacing.md)

                MBDivider()
                    .padding(.horizontal, MBSpacing.md)

                HStack {
                    Text("Build")
                        .font(MBTypography.body())
                        .foregroundStyle(MBColors.textPrimary)

                    Spacer()

                    Text(buildNumber)
                        .font(MBTypography.body())
                        .foregroundStyle(MBColors.textSecondary)
                }
                .padding(MBSpacing.md)
            }
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.border, lineWidth: 1)
            )
        }
    }

    // MARK: - Sign Out Section

    private var signOutSection: some View {
        Button {
            HapticManager.shared.warning()
            showSignOutConfirmation = true
        } label: {
            HStack {
                Spacer()
                Text("Sign Out")
                    .font(MBTypography.label())
                    .foregroundStyle(MBColors.error)
                Spacer()
            }
            .padding(MBSpacing.md)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.error.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Delete Account Section

    private var deleteAccountSection: some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            Text("Danger Zone")
                .font(MBTypography.caption(.semibold))
                .foregroundStyle(MBColors.error.opacity(0.8))
                .padding(.leading, MBSpacing.xs)

            Button {
                HapticManager.shared.warning()
                showDeleteAccountConfirmation = true
            } label: {
                HStack(spacing: MBSpacing.md) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(MBColors.error)
                        .frame(width: 32, height: 32)
                        .background(MBColors.error.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                    VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                        Text("Delete Account")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.error)

                        Text("Permanently delete your account and all data")
                            .font(MBTypography.caption())
                            .foregroundStyle(MBColors.textTertiary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MBColors.error.opacity(0.5))
                }
                .padding(MBSpacing.md)
            }
            .buttonStyle(.plain)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.error.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Customer Center Handler

    private func handleCustomerCenterAction(_ action: CustomerCenterAction) {
        switch action {
        case .restoreStarted:
            print("Customer Center: Restore started")
        case .restoreCompleted(let customerInfo):
            print("Customer Center: Restore completed - \(customerInfo.entitlements)")
        case .restoreFailed(let error):
            print("Customer Center: Restore failed - \(error)")
            self.error = error
            self.showError = true
        case .showingManageSubscriptions:
            print("Customer Center: Showing manage subscriptions")
        case .refundRequestStarted(let productId):
            print("Customer Center: Refund request started for \(productId)")
        case .refundRequestCompleted(let status):
            print("Customer Center: Refund request completed with status \(status)")
        case .feedbackSurveyCompleted(let surveyOptionID):
            print("Customer Center: Feedback survey completed with option \(surveyOptionID)")
        @unknown default:
            print("Customer Center: Unknown action")
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private func signOut() {
        Task {
            do {
                try await authService.signOut()
                purchaseService.cleanup()
            } catch {
                self.error = error
                self.showError = true
            }
        }
    }

    private func deleteAccount() {
        Task {
            do {
                try await authService.deleteAccount()
            } catch {
                self.error = error
                self.showError = true
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService.shared)
        .environmentObject(PurchaseService.shared)
}
