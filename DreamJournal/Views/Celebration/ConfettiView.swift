import SwiftUI

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let position: CGPoint
    let velocity: CGVector
    let rotation: Double
    let rotationSpeed: Double
    let scale: Double
    let shape: ConfettiShape
}

enum ConfettiShape: CaseIterable {
    case circle, square, star, moon
}

// MARK: - Confetti View

struct ConfettiView: View {
    @Binding var isActive: Bool
    let milestone: StreakMilestone?

    @State private var particles: [ConfettiParticle] = []
    @State private var timer: Timer?

    private let colors: [Color] = [
        MBColors.primary,
        MBColors.secondary,
        MBColors.accent,
        MBColors.gold,
        .purple,
        .pink,
        .orange
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    confettiPiece(for: particle)
                        .position(particle.position)
                        .rotationEffect(.degrees(particle.rotation))
                        .scaleEffect(particle.scale)
                }

                // Milestone message
                if let milestone = milestone, isActive {
                    VStack(spacing: MBSpacing.md) {
                        Text(milestone.emoji)
                            .font(.system(size: 80))

                        Text("\(milestone.rawValue)-Day Streak!")
                            .font(MBTypography.titleLarge())
                            .foregroundStyle(MBColors.textPrimary)

                        Text(milestone.celebration)
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, MBSpacing.xl)
                    }
                    .padding(MBSpacing.xl)
                    .background(
                        RoundedRectangle(cornerRadius: MBRadius.xl)
                            .fill(MBColors.backgroundCard)
                            .shadow(color: MBColors.primary.opacity(0.3), radius: 20)
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .onAppear {
                if isActive {
                    startConfetti(in: geometry.size)
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    startConfetti(in: geometry.size)
                } else {
                    stopConfetti()
                }
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    isActive = false
                }
            }
            .onDisappear {
                // IMPORTANT: Clean up timer to prevent memory leak
                timer?.invalidate()
                timer = nil
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(isActive)
    }

    @ViewBuilder
    private func confettiPiece(for particle: ConfettiParticle) -> some View {
        switch particle.shape {
        case .circle:
            Circle()
                .fill(particle.color)
                .frame(width: 10, height: 10)
        case .square:
            Rectangle()
                .fill(particle.color)
                .frame(width: 10, height: 10)
        case .star:
            Image(systemName: "star.fill")
                .foregroundStyle(particle.color)
                .font(.system(size: 12))
        case .moon:
            Image(systemName: "moon.fill")
                .foregroundStyle(particle.color)
                .font(.system(size: 12))
        }
    }

    private func startConfetti(in size: CGSize) {
        particles = []

        // Create initial burst
        for _ in 0..<80 {
            let particle = createParticle(in: size)
            particles.append(particle)
        }

        // Animate particles
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateParticles(in: size)
        }

        // Stop after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeOut(duration: 0.5)) {
                isActive = false
            }
        }
    }

    private func stopConfetti() {
        timer?.invalidate()
        timer = nil
        particles = []
    }

    private func createParticle(in size: CGSize) -> ConfettiParticle {
        let startX = size.width / 2 + CGFloat.random(in: -50...50)
        let startY = size.height / 2

        return ConfettiParticle(
            color: colors.randomElement() ?? MBColors.primary,
            position: CGPoint(x: startX, y: startY),
            velocity: CGVector(
                dx: CGFloat.random(in: -8...8),
                dy: CGFloat.random(in: -15 ... -5)
            ),
            rotation: Double.random(in: 0...360),
            rotationSpeed: Double.random(in: -10...10),
            scale: Double.random(in: 0.5...1.5),
            shape: ConfettiShape.allCases.randomElement() ?? .circle
        )
    }

    private func updateParticles(in size: CGSize) {
        particles = particles.compactMap { particle in
            var newParticle = particle
            let newX = particle.position.x + particle.velocity.dx
            let newY = particle.position.y + particle.velocity.dy + 2 // gravity

            // Remove if off screen
            if newY > size.height + 50 {
                return nil
            }

            return ConfettiParticle(
                color: particle.color,
                position: CGPoint(x: newX, y: newY),
                velocity: CGVector(
                    dx: particle.velocity.dx * 0.99,
                    dy: particle.velocity.dy + 0.3
                ),
                rotation: particle.rotation + particle.rotationSpeed,
                rotationSpeed: particle.rotationSpeed,
                scale: particle.scale,
                shape: particle.shape
            )
        }
    }
}

// MARK: - Streak Celebration Modifier

struct StreakCelebrationModifier: ViewModifier {
    @Binding var showCelebration: Bool
    let milestone: StreakMilestone?

    func body(content: Content) -> some View {
        content
            .overlay {
                if showCelebration {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    ConfettiView(isActive: $showCelebration, milestone: milestone)
                }
            }
            .animation(.spring(), value: showCelebration)
    }
}

extension View {
    func streakCelebration(isActive: Binding<Bool>, milestone: StreakMilestone?) -> some View {
        modifier(StreakCelebrationModifier(showCelebration: isActive, milestone: milestone))
    }

    func videoCelebration(isActive: Binding<Bool>) -> some View {
        modifier(VideoCelebrationModifier(showCelebration: isActive))
    }
}

// MARK: - Video Celebration View

struct VideoCelebrationView: View {
    @Binding var isActive: Bool

    @State private var particles: [ConfettiParticle] = []
    @State private var timer: Timer?
    @State private var showContent = false

    private let colors: [Color] = [
        MBColors.accent,
        MBColors.accentAlt,
        MBColors.primary,
        MBColors.secondary,
        .pink,
        .cyan,
        .purple
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Confetti particles
                ForEach(particles) { particle in
                    confettiPiece(for: particle)
                        .position(particle.position)
                        .rotationEffect(.degrees(particle.rotation))
                        .scaleEffect(particle.scale)
                }

                // Celebration message
                if showContent {
                    VStack(spacing: MBSpacing.lg) {
                        // Animated icon
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [MBColors.accent.opacity(0.3), .clear],
                                        center: .center,
                                        startRadius: 20,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 140, height: 140)

                            Image(systemName: "sparkles.tv.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [MBColors.accent, MBColors.accentAlt],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .symbolEffect(.bounce, options: .repeating)
                        }

                        VStack(spacing: MBSpacing.sm) {
                            Text("Video Ready!")
                                .font(MBTypography.titleLarge())
                                .foregroundStyle(MBColors.textPrimary)

                            Text("Your dream has been transformed into a magical video")
                                .font(MBTypography.body())
                                .foregroundStyle(MBColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, MBSpacing.xl)
                        }

                        // Watch button
                        Button {
                            withAnimation(MBAnimation.spring) {
                                isActive = false
                            }
                        } label: {
                            HStack(spacing: MBSpacing.sm) {
                                Image(systemName: "play.fill")
                                Text("Watch Now")
                            }
                            .font(MBTypography.bodyBold())
                            .foregroundStyle(.white)
                            .padding(.horizontal, MBSpacing.xl)
                            .padding(.vertical, MBSpacing.md)
                            .background(
                                LinearGradient(
                                    colors: [MBColors.accent, MBColors.primary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: MBColors.accent.opacity(0.4), radius: 10, y: 4)
                        }
                    }
                    .padding(MBSpacing.xxl)
                    .background(
                        RoundedRectangle(cornerRadius: MBRadius.xl)
                            .fill(MBColors.backgroundCard)
                            .overlay(
                                RoundedRectangle(cornerRadius: MBRadius.xl)
                                    .stroke(
                                        LinearGradient(
                                            colors: [MBColors.accent.opacity(0.5), MBColors.primary.opacity(0.2)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: MBColors.accent.opacity(0.3), radius: 30)
                    )
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .onAppear {
                if isActive {
                    startCelebration(in: geometry.size)
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    startCelebration(in: geometry.size)
                } else {
                    stopCelebration()
                }
            }
            .onTapGesture {
                withAnimation(MBAnimation.spring) {
                    isActive = false
                }
            }
            .onDisappear {
                // IMPORTANT: Clean up timer to prevent memory leak
                timer?.invalidate()
                timer = nil
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(isActive)
    }

    @ViewBuilder
    private func confettiPiece(for particle: ConfettiParticle) -> some View {
        switch particle.shape {
        case .circle:
            Circle()
                .fill(particle.color)
                .frame(width: 8, height: 8)
        case .square:
            Rectangle()
                .fill(particle.color)
                .frame(width: 8, height: 8)
        case .star:
            Image(systemName: "star.fill")
                .foregroundStyle(particle.color)
                .font(.system(size: 10))
        case .moon:
            Image(systemName: "sparkle")
                .foregroundStyle(particle.color)
                .font(.system(size: 10))
        }
    }

    private func startCelebration(in size: CGSize) {
        particles = []
        showContent = false

        // Create initial burst
        for _ in 0..<60 {
            let particle = createParticle(in: size)
            particles.append(particle)
        }

        // Animate particles
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateParticles(in: size)
        }

        // Show content with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(MBAnimation.springBouncy) {
                showContent = true
            }
            HapticManager.shared.success()
        }
    }

    private func stopCelebration() {
        timer?.invalidate()
        timer = nil
        particles = []
        showContent = false
    }

    private func createParticle(in size: CGSize) -> ConfettiParticle {
        let startX = size.width / 2 + CGFloat.random(in: -100...100)
        let startY = size.height / 2 - 100

        return ConfettiParticle(
            color: colors.randomElement() ?? MBColors.accent,
            position: CGPoint(x: startX, y: startY),
            velocity: CGVector(
                dx: CGFloat.random(in: -6...6),
                dy: CGFloat.random(in: -12 ... -4)
            ),
            rotation: Double.random(in: 0...360),
            rotationSpeed: Double.random(in: -8...8),
            scale: Double.random(in: 0.5...1.2),
            shape: ConfettiShape.allCases.randomElement() ?? .star
        )
    }

    private func updateParticles(in size: CGSize) {
        particles = particles.compactMap { particle in
            let newX = particle.position.x + particle.velocity.dx
            let newY = particle.position.y + particle.velocity.dy + 1.5 // gravity

            // Remove if off screen
            if newY > size.height + 50 {
                return nil
            }

            return ConfettiParticle(
                color: particle.color,
                position: CGPoint(x: newX, y: newY),
                velocity: CGVector(
                    dx: particle.velocity.dx * 0.99,
                    dy: particle.velocity.dy + 0.25
                ),
                rotation: particle.rotation + particle.rotationSpeed,
                rotationSpeed: particle.rotationSpeed,
                scale: particle.scale,
                shape: particle.shape
            )
        }
    }
}

// MARK: - Video Celebration Modifier

struct VideoCelebrationModifier: ViewModifier {
    @Binding var showCelebration: Bool

    func body(content: Content) -> some View {
        content
            .overlay {
                if showCelebration {
                    Color.black.opacity(0.6)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    VideoCelebrationView(isActive: $showCelebration)
                }
            }
            .animation(MBAnimation.spring, value: showCelebration)
    }
}
