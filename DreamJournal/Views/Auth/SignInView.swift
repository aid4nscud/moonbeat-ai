import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isLoading = false
    @State private var error: Error?
    @State private var showError = false
    @State private var animateGlow = false
    @State private var showHero = false
    @State private var showFeatures = false
    @State private var showButtons = false

    var body: some View {
        ZStack {
            // Deep gradient background
            LinearGradient(
                colors: [
                    Color(hex: "0D0B14"),
                    Color(hex: "1A1525"),
                    Color(hex: "0D0B14")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Floating particles
            ParticleView(particleCount: 40)
                .ignoresSafeArea()

            // Glowing orbs for depth
            GlowingOrb(color: MBColors.primary, size: 300, delay: 0)
                .offset(x: -100, y: -200)
            GlowingOrb(color: MBColors.secondary, size: 250, delay: 1.5)
                .offset(x: 150, y: 100)
            GlowingOrb(color: MBColors.accent, size: 200, delay: 0.8)
                .offset(x: -80, y: 300)

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                // Hero section with entrance animation
                VStack(spacing: 20) {
                    // App icon with glow
                    ZStack {
                        // Glow effect
                        Circle()
                            .fill(MBColors.primary.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .blur(radius: 30)
                            .scaleEffect(animateGlow ? 1.1 : 0.9)

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [MBColors.primary, MBColors.secondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 88, height: 88)
                            .shadow(color: MBColors.primary.opacity(0.5), radius: 20, x: 0, y: 8)

                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundStyle(.white)
                            .symbolEffect(.pulse, isActive: animateGlow)
                    }
                    .scaleEffect(showHero ? 1 : 0.5)
                    .opacity(showHero ? 1 : 0)

                    VStack(spacing: 12) {
                        Text("Moonbeat AI")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, Color.white.opacity(0.85)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("Unlock the meaning behind\nyour dreams")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                    }
                    .opacity(showHero ? 1 : 0)
                    .offset(y: showHero ? 0 : 20)
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showHero)

                Spacer()
                    .frame(height: 40)

                // Value propositions with staggered animation
                VStack(spacing: 16) {
                    FeatureRow(icon: "mic.fill", text: "Record dreams with your voice")
                        .opacity(showFeatures ? 1 : 0)
                        .offset(x: showFeatures ? 0 : -30)
                    FeatureRow(icon: "sparkles", text: "AI reveals hidden patterns & meanings")
                        .opacity(showFeatures ? 1 : 0)
                        .offset(x: showFeatures ? 0 : -30)
                        .animation(.easeOut(duration: 0.5).delay(0.1), value: showFeatures)
                    FeatureRow(icon: "film.fill", text: "Generate stunning dream videos")
                        .opacity(showFeatures ? 1 : 0)
                        .offset(x: showFeatures ? 0 : -30)
                        .animation(.easeOut(duration: 0.5).delay(0.2), value: showFeatures)
                }
                .padding(.horizontal, 32)
                .animation(.easeOut(duration: 0.5), value: showFeatures)

                Spacer()

                // Bottom section with entrance animation
                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        request.requestedScopes = [.email, .fullName]
                    } onCompletion: { result in
                        handleSignIn(result: result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.white.opacity(0.2), radius: 10, x: 0, y: 4)

                    #if DEBUG && targetEnvironment(simulator)
                    Button {
                        Task {
                            isLoading = true
                            defer { isLoading = false }
                            do {
                                try await authService.devSignIn()
                            } catch {
                                self.error = error
                                self.showError = true
                            }
                        }
                    } label: {
                        Text("Continue with Test Account")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.1))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                    #endif

                    Text("Free to start · 3 dream videos included")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(MBColors.primary)
                        .padding(.top, 4)

                    HStack(spacing: 4) {
                        Text("By continuing, you agree to our")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.35))
                        Link("Terms", destination: URL(string: "https://aid4nscud.github.io/moonbeat-ai/terms.html")!)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                        Text("&")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.35))
                        Link("Privacy", destination: URL(string: "https://aid4nscud.github.io/moonbeat-ai/privacy.html")!)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 30)
                .animation(.easeOut(duration: 0.6).delay(0.3), value: showButtons)
            }

            // Loading overlay
            if isLoading {
                Color.black.opacity(0.7)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    )
            }
        }
        .onAppear {
            // Hero entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                showHero = true
            }
            // Start glow animation
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                animateGlow = true
            }
            // Staggered entrance animations
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showFeatures = true
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
                showButtons = true
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
    }

    private func handleSignIn(result: Result<ASAuthorization, Error>) {
        Task {
            isLoading = true
            defer { isLoading = false }

            switch result {
            case .success(let authorization):
                do {
                    try await authService.signInWithApple(authorization: authorization)
                } catch {
                    self.error = error
                    self.showError = true
                }
            case .failure(let error):
                // Don't show error for user cancellation
                if (error as? ASAuthorizationError)?.code != .canceled {
                    self.error = error
                    self.showError = true
                }
            }
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(MBColors.primary)
                .frame(width: 20)

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.85))

            Spacer()
        }
    }
}

// MARK: - Particle System

private struct ParticleView: View {
    let particleCount: Int

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<particleCount, id: \.self) { _ in
                ParticleCell(bounds: geo.size)
            }
        }
    }
}

private struct ParticleCell: View {
    let bounds: CGSize

    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 1

    private let size: CGFloat = .random(in: 2...5)
    private let duration: Double = .random(in: 8...15)

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .blur(radius: size > 3 ? 1 : 0)
            .opacity(opacity)
            .scaleEffect(scale)
            .position(position)
            .onAppear {
                position = CGPoint(
                    x: .random(in: 0...bounds.width),
                    y: .random(in: 0...bounds.height)
                )

                withAnimation(.easeIn(duration: 2).delay(.random(in: 0...3))) {
                    opacity = .random(in: 0.2...0.6)
                }

                withAnimation(
                    .easeInOut(duration: duration)
                    .repeatForever(autoreverses: true)
                ) {
                    position = CGPoint(
                        x: position.x + .random(in: -50...50),
                        y: position.y - .random(in: 30...100)
                    )
                    scale = .random(in: 0.5...1.5)
                }
            }
    }
}

// MARK: - Glowing Orb

private struct GlowingOrb: View {
    let color: Color
    let size: CGFloat
    let delay: Double

    @State private var animate = false

    var body: some View {
        Circle()
            .fill(color.opacity(0.15))
            .frame(width: size, height: size)
            .blur(radius: size / 3)
            .scaleEffect(animate ? 1.2 : 0.8)
            .opacity(animate ? 0.8 : 0.4)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 4)
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    animate = true
                }
            }
    }
}

#Preview {
    SignInView()
        .environmentObject(AuthService.shared)
}
