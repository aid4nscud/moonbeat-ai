import SwiftUI
import AppTrackingTransparency

// MARK: - Onboarding Page

struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    @State private var notificationsGranted = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "mic.fill",
            title: "Capture Your Dreams",
            description: "Record your dreams the moment you wake up using your voice. Our AI transcribes and saves them instantly.",
            color: MBColors.primary
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "Discover Patterns",
            description: "AI analyzes your dreams to reveal recurring themes, emotions, and hidden meanings in your subconscious.",
            color: MBColors.secondary
        ),
        OnboardingPage(
            icon: "film.stack",
            title: "Visualize Dreams",
            description: "Transform your dreams into stunning AI-generated videos. Bring your nighttime adventures to life.",
            color: MBColors.accent
        ),
        OnboardingPage(
            icon: "bell.fill",
            title: "Never Forget",
            description: "Get gentle morning reminders to capture your dreams before they fade. Build a streak and unlock insights.",
            color: MBColors.gold
        )
    ]

    var body: some View {
        ZStack {
            MBColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button("Skip") {
                            withAnimation {
                                currentPage = pages.count - 1
                            }
                        }
                        .font(MBTypography.label())
                        .foregroundStyle(MBColors.textTertiary)
                        .padding()
                    }
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: MBSpacing.xs) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? MBColors.primary : MBColors.textMuted)
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.vertical, MBSpacing.lg)

                // Action button
                VStack(spacing: MBSpacing.md) {
                    if currentPage == pages.count - 1 {
                        // Notification permission page
                        Button {
                            Task {
                                notificationsGranted = await NotificationService.shared.requestAuthorization()
                                completeOnboarding()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "bell.badge.fill")
                                Text("Enable Notifications")
                            }
                            .font(MBTypography.label())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MBSpacing.md)
                            .background(MBGradients.primary)
                            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
                        }

                        Button("Maybe Later") {
                            completeOnboarding()
                        }
                        .font(MBTypography.caption())
                        .foregroundStyle(MBColors.textTertiary)
                    } else {
                        Button {
                            withAnimation {
                                currentPage += 1
                            }
                        } label: {
                            HStack {
                                Text("Continue")
                                Image(systemName: "arrow.right")
                            }
                            .font(MBTypography.label())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, MBSpacing.md)
                            .background(MBGradients.primary)
                            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
                        }
                    }
                }
                .padding(.horizontal, MBSpacing.xl)
                .padding(.bottom, MBSpacing.xxl)
            }
        }
    }

    private func completeOnboarding() {
        // Schedule notifications if granted
        if notificationsGranted {
            NotificationService.shared.scheduleMorningReminder()
        }

        // Track onboarding completion
        Task {
            await MetaAnalyticsService.shared.trackOnboardingComplete()
            await MetaAnalyticsService.shared.updateConversionValue(for: .onboardingComplete)

            // Request ATT permission after a brief delay
            // This gives the best opt-in rates according to Meta guidelines
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
            _ = await MetaAnalyticsService.shared.requestTrackingAuthorization()
        }

        withAnimation {
            hasCompletedOnboarding = true
        }
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: MBSpacing.xl) {
            Spacer()

            // Animated icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(page.color.opacity(0.2))
                    .frame(width: 180, height: 180)
                    .blur(radius: 30)

                Circle()
                    .fill(page.color.opacity(0.3))
                    .frame(width: 140, height: 140)

                Image(systemName: page.icon)
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, MBSpacing.xl)

            // Title
            Text(page.title)
                .font(MBTypography.titleLarge())
                .foregroundStyle(MBColors.textPrimary)
                .multilineTextAlignment(.center)

            // Description
            Text(page.description)
                .font(MBTypography.body())
                .foregroundStyle(MBColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, MBSpacing.xl)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
}
