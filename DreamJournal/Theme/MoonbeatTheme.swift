import SwiftUI

// MARK: - Moonbeat Design System
// A celestial, dreamy design language for the dream journal app

// MARK: - Color Palette

enum MBColors {
    // Primary Palette - Deep celestial purples
    static let primary = Color(hex: "7C3AED")           // Vibrant purple
    static let primaryLight = Color(hex: "A78BFA")      // Soft lavender
    static let primaryDark = Color(hex: "5B21B6")       // Deep purple

    // Secondary Palette - Cosmic indigos
    static let secondary = Color(hex: "4F46E5")         // Rich indigo
    static let secondaryLight = Color(hex: "818CF8")    // Soft indigo
    static let secondaryDark = Color(hex: "3730A3")     // Deep indigo

    // Accent Colors
    static let accent = Color(hex: "F472B6")            // Dreamy pink
    static let accentAlt = Color(hex: "22D3EE")         // Celestial cyan
    static let gold = Color(hex: "FBBF24")              // Premium gold

    // Semantic Colors
    static let success = Color(hex: "34D399")           // Emerald green
    static let warning = Color(hex: "FBBF24")           // Amber
    static let error = Color(hex: "F87171")             // Soft red
    static let info = Color(hex: "60A5FA")              // Sky blue

    // Neutral Palette - Night sky tones
    static let background = Color(hex: "0F0A1A")        // Deep night
    static let backgroundElevated = Color(hex: "1A1228") // Slightly lifted
    static let backgroundCard = Color(hex: "231836")    // Card surface
    static let backgroundGlow = Color(hex: "2D1F4A")    // Glowing surface

    // Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.7)
    static let textTertiary = Color.white.opacity(0.5)
    static let textMuted = Color.white.opacity(0.3)

    // Border Colors
    static let border = Color.white.opacity(0.1)
    static let borderFocused = Color(hex: "7C3AED").opacity(0.5)

    // Tag/Badge Colors
    static let tagTheme = Color(hex: "7C3AED").opacity(0.15)
    static let tagEmotion = Color(hex: "4F46E5").opacity(0.15)
    static let tagPro = Color(hex: "FBBF24").opacity(0.15)
}

// MARK: - Gradients

enum MBGradients {
    // Primary Brand Gradient
    static let primary = LinearGradient(
        colors: [MBColors.primary, MBColors.secondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Dreamy aurora gradient
    static let aurora = LinearGradient(
        colors: [
            Color(hex: "7C3AED"),
            Color(hex: "4F46E5"),
            Color(hex: "2DD4BF")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Sunset dream gradient
    static let sunset = LinearGradient(
        colors: [
            Color(hex: "F472B6"),
            Color(hex: "7C3AED"),
            Color(hex: "4F46E5")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Night sky gradient (for backgrounds)
    static let nightSky = LinearGradient(
        colors: [
            Color(hex: "1A0F2E"),
            Color(hex: "0F0A1A"),
            Color(hex: "0A0510")
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Cosmic gradient
    static let cosmic = LinearGradient(
        colors: [
            Color(hex: "4F46E5"),
            Color(hex: "7C3AED"),
            Color(hex: "F472B6")
        ],
        startPoint: .leading,
        endPoint: .trailing
    )

    // Glow effect gradient
    static let glow = RadialGradient(
        colors: [
            Color(hex: "7C3AED").opacity(0.3),
            Color(hex: "7C3AED").opacity(0.1),
            Color.clear
        ],
        center: .center,
        startRadius: 0,
        endRadius: 200
    )

    // Card overlay gradient
    static let cardOverlay = LinearGradient(
        colors: [
            Color.white.opacity(0.05),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    // Premium gold gradient
    static let gold = LinearGradient(
        colors: [
            Color(hex: "FBBF24"),
            Color(hex: "F59E0B"),
            Color(hex: "D97706")
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // Text gradient for special headings
    static let textShimmer = LinearGradient(
        colors: [
            Color.white,
            Color(hex: "A78BFA"),
            Color.white
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Glass Morphism Presets

enum MBGlass {
    /// Standard glass effect for cards
    static let card = GlassConfig(
        material: .ultraThinMaterial,
        opacity: 0.5,
        borderOpacity: 0.15,
        blur: 20
    )

    /// Lighter glass for secondary elements
    static let light = GlassConfig(
        material: .thinMaterial,
        opacity: 0.3,
        borderOpacity: 0.1,
        blur: 15
    )

    /// Heavy glass for prominent elements
    static let heavy = GlassConfig(
        material: .regularMaterial,
        opacity: 0.6,
        borderOpacity: 0.2,
        blur: 25
    )

    /// Premium glass with gradient border
    static let premium = GlassConfig(
        material: .ultraThinMaterial,
        opacity: 0.4,
        borderOpacity: 0.25,
        blur: 20,
        hasGradientBorder: true
    )

    /// Frosted glass for overlays
    static let frosted = GlassConfig(
        material: .thickMaterial,
        opacity: 0.7,
        borderOpacity: 0.1,
        blur: 30
    )
}

struct GlassConfig {
    let material: Material
    let opacity: Double
    let borderOpacity: Double
    let blur: CGFloat
    var hasGradientBorder: Bool = false
}

// MARK: - Typography

enum MBTypography {
    // Display - Hero text
    static func display(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 48, weight: weight, design: .rounded)
    }

    // Large Title - Very large headings
    static func largeTitle(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 34, weight: weight, design: .rounded)
    }

    // Title - Large headings
    static func titleLarge(_ weight: Font.Weight = .bold) -> Font {
        .system(size: 34, weight: weight, design: .rounded)
    }

    static func titleMedium(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 28, weight: weight, design: .rounded)
    }

    static func titleSmall(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 22, weight: weight, design: .rounded)
    }

    // Convenience alias for title (maps to titleMedium)
    static func title(_ weight: Font.Weight = .semibold) -> Font {
        titleMedium(weight)
    }

    // Headline - Section headings
    static func headline(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 17, weight: weight, design: .rounded)
    }

    // Body - Primary content
    static func bodyLarge(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 17, weight: weight, design: .rounded)
    }

    static func body(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 15, weight: weight, design: .rounded)
    }

    static func bodyBold() -> Font {
        .system(size: 15, weight: .bold, design: .rounded)
    }

    static func bodySmall(_ weight: Font.Weight = .regular) -> Font {
        .system(size: 13, weight: weight, design: .rounded)
    }

    // Caption - Supporting text
    static func caption(_ weight: Font.Weight = .medium) -> Font {
        .system(size: 12, weight: weight, design: .rounded)
    }

    static func captionSmall(_ weight: Font.Weight = .medium) -> Font {
        .system(size: 11, weight: weight, design: .rounded)
    }

    // Overline - Small uppercase labels
    static func overline(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 10, weight: weight, design: .rounded)
    }

    // Label - Buttons, tags
    static func label(_ weight: Font.Weight = .semibold) -> Font {
        .system(size: 14, weight: weight, design: .rounded)
    }
}

// MARK: - Spacing

enum MBSpacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
}

// MARK: - Corner Radius

enum MBRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let full: CGFloat = 9999
}

// MARK: - Shadows

enum MBShadow {
    // Elevation levels
    static let xs = (color: Color.black.opacity(0.08), radius: 2.0, x: 0.0, y: 1.0)
    static let sm = (color: Color.black.opacity(0.1), radius: 4.0, x: 0.0, y: 2.0)
    static let md = (color: Color.black.opacity(0.15), radius: 8.0, x: 0.0, y: 4.0)
    static let lg = (color: Color.black.opacity(0.2), radius: 16.0, x: 0.0, y: 8.0)
    static let xl = (color: Color.black.opacity(0.25), radius: 24.0, x: 0.0, y: 12.0)

    // Glow shadows for emphasis
    static let primaryGlow = (color: MBColors.primary.opacity(0.4), radius: 20.0, x: 0.0, y: 0.0)
    static let accentGlow = (color: MBColors.accent.opacity(0.4), radius: 20.0, x: 0.0, y: 0.0)
    static let successGlow = (color: MBColors.success.opacity(0.4), radius: 16.0, x: 0.0, y: 0.0)
    static let errorGlow = (color: MBColors.error.opacity(0.4), radius: 16.0, x: 0.0, y: 0.0)

    // Soft inner shadows (for pressed states)
    static let inner = (color: Color.black.opacity(0.15), radius: 4.0, x: 0.0, y: 2.0)
}

// MARK: - Animation

enum MBAnimation {
    // Basic timings
    static let quick = Animation.easeOut(duration: 0.15)
    static let standard = Animation.easeInOut(duration: 0.25)
    static let smooth = Animation.easeInOut(duration: 0.35)
    static let slow = Animation.easeInOut(duration: 0.5)

    // Spring animations with consistent feel
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
    static let springSnappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
    static let springSubtle = Animation.spring(response: 0.35, dampingFraction: 0.9)

    // Ease animations
    static let easeIn = Animation.easeIn(duration: 0.25)
    static let easeOut = Animation.easeOut(duration: 0.3)
    static let easeInOut = Animation.easeInOut(duration: 0.35)

    // Specific use cases
    static let cardTap = Animation.spring(response: 0.2, dampingFraction: 0.6)
    static let modalPresent = Animation.spring(response: 0.45, dampingFraction: 0.85)
    static let tabSwitch = Animation.easeInOut(duration: 0.25)
    static let stagger: (Int) -> Animation = { index in
        Animation.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05)
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

extension View {
    // Card style modifier
    func mbCard(padding: CGFloat = MBSpacing.md) -> some View {
        self
            .padding(padding)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.border, lineWidth: 1)
            )
    }

    // Elevated card with glow
    func mbCardGlow(padding: CGFloat = MBSpacing.md) -> some View {
        self
            .padding(padding)
            .background(
                ZStack {
                    MBColors.backgroundCard
                    MBGradients.cardOverlay
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.border, lineWidth: 1)
            )
            .shadow(
                color: MBShadow.md.color,
                radius: MBShadow.md.radius,
                x: MBShadow.md.x,
                y: MBShadow.md.y
            )
    }

    // Glass morphism effect
    func mbGlass() -> some View {
        self
            .background(.ultraThinMaterial.opacity(0.5))
            .background(MBColors.backgroundCard.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }

    // Primary button style
    func mbButtonPrimary() -> some View {
        self
            .font(MBTypography.label())
            .foregroundStyle(.white)
            .padding(.horizontal, MBSpacing.lg)
            .padding(.vertical, MBSpacing.sm)
            .background(MBGradients.primary)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
            .shadow(
                color: MBShadow.primaryGlow.color,
                radius: MBShadow.primaryGlow.radius / 2,
                x: 0,
                y: 4
            )
    }

    // Secondary button style
    func mbButtonSecondary() -> some View {
        self
            .font(MBTypography.label())
            .foregroundStyle(MBColors.textPrimary)
            .padding(.horizontal, MBSpacing.lg)
            .padding(.vertical, MBSpacing.sm)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.md)
                    .stroke(MBColors.border, lineWidth: 1)
            )
    }

    // Ghost button style
    func mbButtonGhost() -> some View {
        self
            .font(MBTypography.label())
            .foregroundStyle(MBColors.primary)
            .padding(.horizontal, MBSpacing.lg)
            .padding(.vertical, MBSpacing.sm)
    }

    // Tag/Badge style
    func mbTag(color: Color = MBColors.primary) -> some View {
        self
            .font(MBTypography.caption())
            .foregroundStyle(color)
            .padding(.horizontal, MBSpacing.xs)
            .padding(.vertical, MBSpacing.xxs)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }

    // Pro badge style
    func mbProBadge() -> some View {
        self
            .font(MBTypography.captionSmall(.bold))
            .foregroundStyle(MBColors.gold)
            .padding(.horizontal, MBSpacing.xs)
            .padding(.vertical, MBSpacing.xxxs)
            .background(MBGradients.gold.opacity(0.2))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(MBColors.gold.opacity(0.3), lineWidth: 1)
            )
    }

    // Text field style
    func mbTextField() -> some View {
        self
            .font(MBTypography.body())
            .foregroundStyle(MBColors.textPrimary)
            .padding(MBSpacing.md)
            .background(MBColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.md)
                    .stroke(MBColors.border, lineWidth: 1)
            )
    }

    // Shimmer loading effect
    func mbShimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }

    // Apply standard shadow
    func mbShadow(_ style: (color: Color, radius: Double, x: Double, y: Double) = MBShadow.md) -> some View {
        self.shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }

    // MARK: - Glass Morphism Modifiers

    /// Apply glass effect from preset
    func mbGlass(_ config: GlassConfig, radius: CGFloat = MBRadius.lg) -> some View {
        self
            .background(config.material.opacity(config.opacity))
            .background(MBColors.backgroundCard.opacity(config.opacity * 0.6))
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(
                        config.hasGradientBorder ?
                            AnyShapeStyle(LinearGradient(
                                colors: [MBColors.primary.opacity(config.borderOpacity), MBColors.secondary.opacity(config.borderOpacity * 0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )) :
                            AnyShapeStyle(Color.white.opacity(config.borderOpacity)),
                        lineWidth: 1
                    )
            )
    }

    /// Elevated card with configurable shadow level
    func mbCardElevated(
        padding: CGFloat = MBSpacing.md,
        elevation: (color: Color, radius: Double, x: Double, y: Double) = MBShadow.md
    ) -> some View {
        self
            .padding(padding)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.border, lineWidth: 1)
            )
            .shadow(color: elevation.color, radius: elevation.radius, x: elevation.x, y: elevation.y)
    }

    /// Card with animated glow border (for focus states)
    func mbCardFocused(isFocused: Bool, padding: CGFloat = MBSpacing.md) -> some View {
        self
            .padding(padding)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(
                        isFocused ? MBColors.primary.opacity(0.6) : MBColors.border,
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .shadow(
                color: isFocused ? MBColors.primary.opacity(0.3) : .clear,
                radius: isFocused ? 8 : 0,
                y: 0
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }

    /// Pressed state modifier for interactive elements
    func mbPressed(_ isPressed: Bool) -> some View {
        self
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.1), value: isPressed)
    }
}

// MARK: - Shimmer Effect

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.1),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 2)
                        .offset(x: -geo.size.width + (phase * geo.size.width * 2))
                    }
                    .mask(content)
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Button State Enum

enum MBButtonState {
    case idle
    case loading
    case success
    case error
}

// MARK: - Custom Button Styles

struct MBPrimaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var state: MBButtonState = .idle
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        MBPrimaryButtonContent(
            configuration: configuration,
            isLoading: isLoading,
            state: state,
            isDisabled: isDisabled
        )
    }
}

private struct MBPrimaryButtonContent: View {
    let configuration: ButtonStyleConfiguration
    let isLoading: Bool
    let state: MBButtonState
    let isDisabled: Bool

    @State private var pulseScale: CGFloat = 1.0
    @State private var showCheckmark = false
    @State private var rotationAngle: Double = 0

    private var effectiveState: MBButtonState {
        if isLoading { return .loading }
        return state
    }

    var body: some View {
        HStack(spacing: MBSpacing.xs) {
            switch effectiveState {
            case .loading:
                // Pulsing loading indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 18, height: 18)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(rotationAngle))
                }
                .scaleEffect(pulseScale)
                .onAppear {
                    withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        pulseScale = 1.15
                    }
                }

            case .success:
                // Animated checkmark
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .opacity(showCheckmark ? 1 : 0)
                    .onAppear {
                        withAnimation(MBAnimation.springBouncy) {
                            showCheckmark = true
                        }
                    }
                    .onDisappear {
                        showCheckmark = false
                    }

            case .error:
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)

            case .idle:
                EmptyView()
            }

            if effectiveState != .success {
                configuration.label
                    .opacity(effectiveState == .loading ? 0.7 : 1)
            }
        }
        .font(MBTypography.label())
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, MBSpacing.md)
        .background(
            Group {
                if isDisabled {
                    MBGradients.primary.opacity(0.4)
                } else if configuration.isPressed {
                    MBGradients.primary.opacity(0.8)
                } else if effectiveState == .success {
                    LinearGradient(
                        colors: [MBColors.success, MBColors.success.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else if effectiveState == .error {
                    LinearGradient(
                        colors: [MBColors.error, MBColors.error.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    MBGradients.primary
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
        .shadow(
            color: shadowColor,
            radius: configuration.isPressed ? MBShadow.primaryGlow.radius / 4 : MBShadow.primaryGlow.radius / 2,
            x: 0,
            y: configuration.isPressed ? 2 : 4
        )
        .scaleEffect(configuration.isPressed ? 0.98 : 1)
        .opacity(isDisabled ? 0.6 : 1)
        .animation(MBAnimation.spring, value: effectiveState)
        .animation(MBAnimation.quick, value: configuration.isPressed)
    }

    private var shadowColor: Color {
        switch effectiveState {
        case .success:
            return MBColors.success.opacity(0.4)
        case .error:
            return MBColors.error.opacity(0.4)
        default:
            return MBShadow.primaryGlow.color
        }
    }
}

struct MBSecondaryButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var state: MBButtonState = .idle
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        MBSecondaryButtonContent(
            configuration: configuration,
            isLoading: isLoading,
            state: state,
            isDisabled: isDisabled
        )
    }
}

private struct MBSecondaryButtonContent: View {
    let configuration: ButtonStyleConfiguration
    let isLoading: Bool
    let state: MBButtonState
    let isDisabled: Bool

    @State private var rotationAngle: Double = 0
    @State private var showCheckmark = false

    private var effectiveState: MBButtonState {
        if isLoading { return .loading }
        return state
    }

    var body: some View {
        HStack(spacing: MBSpacing.xs) {
            switch effectiveState {
            case .loading:
                // Loading spinner
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(MBColors.textSecondary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }

            case .success:
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MBColors.success)
                    .scaleEffect(showCheckmark ? 1 : 0)
                    .onAppear {
                        withAnimation(MBAnimation.springBouncy) {
                            showCheckmark = true
                        }
                    }
                    .onDisappear {
                        showCheckmark = false
                    }

            case .error:
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(MBColors.error)

            case .idle:
                EmptyView()
            }

            if effectiveState != .success {
                configuration.label
                    .opacity(effectiveState == .loading ? 0.6 : 1)
            }
        }
        .font(MBTypography.label())
        .foregroundStyle(isDisabled ? MBColors.textTertiary : MBColors.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, MBSpacing.md)
        .background(
            Group {
                if effectiveState == .success {
                    MBColors.success.opacity(0.1)
                } else if effectiveState == .error {
                    MBColors.error.opacity(0.1)
                } else if configuration.isPressed {
                    MBColors.backgroundGlow
                } else {
                    MBColors.backgroundCard
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.md)
                .stroke(borderColor, lineWidth: 1)
        )
        .scaleEffect(configuration.isPressed ? 0.98 : 1)
        .opacity(isDisabled ? 0.5 : 1)
        .animation(MBAnimation.spring, value: effectiveState)
        .animation(MBAnimation.quick, value: configuration.isPressed)
    }

    private var borderColor: Color {
        switch effectiveState {
        case .success:
            return MBColors.success.opacity(0.3)
        case .error:
            return MBColors.error.opacity(0.3)
        default:
            return MBColors.border
        }
    }
}

struct MBGhostButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var color: Color = MBColors.primary

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: MBSpacing.xxs) {
            if isLoading {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: 14, height: 14)
                    .rotationEffect(.degrees(configuration.isPressed ? 0 : 360))
                    .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: isLoading)
            }
            configuration.label
                .opacity(isLoading ? 0.6 : 1)
        }
        .font(MBTypography.label())
        .foregroundStyle(configuration.isPressed ? color.opacity(0.7) : color)
        .padding(.vertical, MBSpacing.sm)
        .scaleEffect(configuration.isPressed ? 0.98 : 1)
        .animation(MBAnimation.quick, value: configuration.isPressed)
    }
}

// MARK: - Destructive Button Style

struct MBDestructiveButtonStyle: ButtonStyle {
    var isLoading: Bool = false
    var isOutlined: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: MBSpacing.xs) {
            if isLoading {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(isOutlined ? MBColors.error : .white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(configuration.isPressed ? 0 : 360))
                    .animation(.linear(duration: 0.8).repeatForever(autoreverses: false), value: isLoading)
            }
            configuration.label
                .opacity(isLoading ? 0.6 : 1)
        }
        .font(MBTypography.label())
        .foregroundStyle(isOutlined ? MBColors.error : .white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, MBSpacing.md)
        .background(
            Group {
                if isOutlined {
                    Color.clear
                } else if configuration.isPressed {
                    MBColors.error.opacity(0.8)
                } else {
                    MBColors.error
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.md)
                .stroke(isOutlined ? MBColors.error : .clear, lineWidth: 1)
        )
        .shadow(
            color: isOutlined ? .clear : MBColors.error.opacity(0.3),
            radius: configuration.isPressed ? 4 : 8,
            y: configuration.isPressed ? 2 : 4
        )
        .scaleEffect(configuration.isPressed ? 0.98 : 1)
        .animation(MBAnimation.quick, value: configuration.isPressed)
    }
}

// MARK: - Call-to-Action Button Style (with animated glow)

struct MBCTAButtonStyle: ButtonStyle {
    var isLoading: Bool = false

    @State private var glowOpacity: Double = 0.4
    @State private var rotationAngle: Double = 0

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: MBSpacing.xs) {
            if isLoading {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 18, height: 18)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 18, height: 18)
                        .rotationEffect(.degrees(rotationAngle))
                }
                .onAppear {
                    withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                }
            }
            configuration.label
                .opacity(isLoading ? 0.7 : 1)
        }
        .font(MBTypography.label(.bold))
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, MBSpacing.md)
        .background(
            ZStack {
                // Animated glow behind
                RoundedRectangle(cornerRadius: MBRadius.md)
                    .fill(MBGradients.cosmic)
                    .blur(radius: 8)
                    .opacity(glowOpacity)
                    .scaleEffect(1.05)

                // Main gradient
                MBGradients.cosmic
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.md)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.4), .white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: MBColors.primary.opacity(0.5), radius: 12, y: 6)
        .scaleEffect(configuration.isPressed ? 0.97 : 1)
        .animation(MBAnimation.quick, value: configuration.isPressed)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                glowOpacity = 0.7
            }
        }
    }
}

// MARK: - Icon Button Style

struct MBIconButtonStyle: ButtonStyle {
    var size: CGFloat = 44
    var background: Color = MBColors.backgroundCard
    var isLoading: Bool = false

    @State private var rotationAngle: Double = 0

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if isLoading {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(MBColors.textSecondary, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: size * 0.4, height: size * 0.4)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
            } else {
                configuration.label
            }
        }
        .frame(width: size, height: size)
        .background(
            Circle()
                .fill(configuration.isPressed ? MBColors.backgroundGlow : background)
                .shadow(
                    color: configuration.isPressed ? .clear : MBShadow.sm.color,
                    radius: configuration.isPressed ? 0 : MBShadow.sm.radius,
                    y: configuration.isPressed ? 0 : MBShadow.sm.y
                )
        )
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(
                    configuration.isPressed ? MBColors.primary.opacity(0.3) : MBColors.border,
                    lineWidth: 1
                )
        )
        .scaleEffect(configuration.isPressed ? 0.92 : 1)
        .animation(MBAnimation.cardTap, value: configuration.isPressed)
    }
}

// MARK: - Compact Pill Button Style

struct MBPillButtonStyle: ButtonStyle {
    var color: Color = MBColors.primary
    var isLoading: Bool = false

    @State private var rotationAngle: Double = 0

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: MBSpacing.xxs) {
            if isLoading {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .frame(width: 12, height: 12)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }
            }
            configuration.label
                .opacity(isLoading ? 0.7 : 1)
        }
        .font(MBTypography.caption(.semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, MBSpacing.sm)
        .padding(.vertical, MBSpacing.xs)
        .background(
            Capsule()
                .fill(configuration.isPressed ? color.opacity(0.8) : color)
        )
        .scaleEffect(configuration.isPressed ? 0.96 : 1)
        .animation(MBAnimation.quick, value: configuration.isPressed)
    }
}

// MARK: - Button Style Extensions

extension ButtonStyle where Self == MBPrimaryButtonStyle {
    static var mbPrimary: MBPrimaryButtonStyle { MBPrimaryButtonStyle() }

    static func mbPrimary(isLoading: Bool) -> MBPrimaryButtonStyle {
        MBPrimaryButtonStyle(isLoading: isLoading)
    }

    static func mbPrimary(state: MBButtonState) -> MBPrimaryButtonStyle {
        MBPrimaryButtonStyle(state: state)
    }

    static func mbPrimary(isLoading: Bool = false, state: MBButtonState = .idle, isDisabled: Bool = false) -> MBPrimaryButtonStyle {
        MBPrimaryButtonStyle(isLoading: isLoading, state: state, isDisabled: isDisabled)
    }
}

extension ButtonStyle where Self == MBSecondaryButtonStyle {
    static var mbSecondary: MBSecondaryButtonStyle { MBSecondaryButtonStyle() }

    static func mbSecondary(isLoading: Bool) -> MBSecondaryButtonStyle {
        MBSecondaryButtonStyle(isLoading: isLoading)
    }

    static func mbSecondary(state: MBButtonState) -> MBSecondaryButtonStyle {
        MBSecondaryButtonStyle(state: state)
    }

    static func mbSecondary(isLoading: Bool = false, state: MBButtonState = .idle, isDisabled: Bool = false) -> MBSecondaryButtonStyle {
        MBSecondaryButtonStyle(isLoading: isLoading, state: state, isDisabled: isDisabled)
    }
}

extension ButtonStyle where Self == MBGhostButtonStyle {
    static var mbGhost: MBGhostButtonStyle { MBGhostButtonStyle() }

    static func mbGhost(isLoading: Bool) -> MBGhostButtonStyle {
        MBGhostButtonStyle(isLoading: isLoading)
    }

    static func mbGhost(color: Color) -> MBGhostButtonStyle {
        MBGhostButtonStyle(color: color)
    }

    static func mbGhost(isLoading: Bool = false, color: Color = MBColors.primary) -> MBGhostButtonStyle {
        MBGhostButtonStyle(isLoading: isLoading, color: color)
    }
}

extension ButtonStyle where Self == MBDestructiveButtonStyle {
    static var mbDestructive: MBDestructiveButtonStyle { MBDestructiveButtonStyle() }

    static func mbDestructive(isLoading: Bool) -> MBDestructiveButtonStyle {
        MBDestructiveButtonStyle(isLoading: isLoading)
    }

    static var mbDestructiveOutlined: MBDestructiveButtonStyle {
        MBDestructiveButtonStyle(isOutlined: true)
    }

    static func mbDestructive(isLoading: Bool = false, isOutlined: Bool = false) -> MBDestructiveButtonStyle {
        MBDestructiveButtonStyle(isLoading: isLoading, isOutlined: isOutlined)
    }
}

extension ButtonStyle where Self == MBCTAButtonStyle {
    static var mbCTA: MBCTAButtonStyle { MBCTAButtonStyle() }

    static func mbCTA(isLoading: Bool) -> MBCTAButtonStyle {
        MBCTAButtonStyle(isLoading: isLoading)
    }
}

extension ButtonStyle where Self == MBIconButtonStyle {
    static var mbIcon: MBIconButtonStyle { MBIconButtonStyle() }

    static func mbIcon(size: CGFloat = 44, background: Color = MBColors.backgroundCard, isLoading: Bool = false) -> MBIconButtonStyle {
        MBIconButtonStyle(size: size, background: background, isLoading: isLoading)
    }
}

extension ButtonStyle where Self == MBPillButtonStyle {
    static var mbPill: MBPillButtonStyle { MBPillButtonStyle() }

    static func mbPill(color: Color) -> MBPillButtonStyle {
        MBPillButtonStyle(color: color)
    }

    static func mbPill(isLoading: Bool) -> MBPillButtonStyle {
        MBPillButtonStyle(isLoading: isLoading)
    }

    static func mbPill(color: Color = MBColors.primary, isLoading: Bool = false) -> MBPillButtonStyle {
        MBPillButtonStyle(color: color, isLoading: isLoading)
    }
}

// MARK: - Emotion Helpers

enum MBEmotions {
    /// Map emotion names to colors
    static func color(for emotion: String) -> Color {
        switch emotion.lowercased() {
        case "joy", "happiness", "happy":
            return Color(hex: "FFD700") // Warm gold
        case "peace", "calm", "serene":
            return MBColors.info // Sky blue
        case "love", "affection":
            return Color(hex: "FF69B4") // Hot pink
        case "wonder", "awe", "amazement":
            return MBColors.primaryLight // Soft lavender
        case "fear", "scared", "frightened":
            return MBColors.secondary // Rich indigo
        case "anxiety", "nervous", "worried":
            return Color(hex: "FF8C42") // Anxious orange
        case "sadness", "sad", "grief":
            return Color(hex: "6B7FD7") // Melancholy blue
        case "anger", "angry", "frustrated":
            return MBColors.error // Soft red
        case "confusion", "confused":
            return MBColors.warning // Amber
        default:
            return MBColors.primary
        }
    }

    /// Map emotion names to SF Symbol icons (preferred for clean UI)
    static func icon(for emotion: String) -> String {
        switch emotion.lowercased() {
        case "joy", "happiness", "happy":
            return "sun.max.fill"
        case "peace", "calm", "serene":
            return "leaf.fill"
        case "love", "affection":
            return "heart.fill"
        case "wonder", "awe", "amazement":
            return "sparkles"
        case "fear", "scared", "frightened":
            return "bolt.fill"
        case "anxiety", "nervous", "worried":
            return "exclamationmark.triangle.fill"
        case "sadness", "sad", "grief":
            return "cloud.rain.fill"
        case "anger", "angry", "frustrated":
            return "flame.fill"
        case "confusion", "confused":
            return "questionmark.circle.fill"
        default:
            return "circle.fill"
        }
    }

    /// Map emotion names to emoji (deprecated - use icon(for:) instead)
    @available(*, deprecated, message: "Use icon(for:) for consistent SF Symbol styling")
    static func emoji(for emotion: String) -> String {
        switch emotion.lowercased() {
        case "joy", "happiness", "happy":
            return "😊"
        case "peace", "calm", "serene":
            return "😌"
        case "love", "affection":
            return "❤️"
        case "wonder", "awe", "amazement":
            return "🌟"
        case "fear", "scared", "frightened":
            return "😨"
        case "anxiety", "nervous", "worried":
            return "😰"
        case "sadness", "sad", "grief":
            return "😢"
        case "anger", "angry", "frustrated":
            return "😠"
        case "confusion", "confused":
            return "😵‍💫"
        default:
            return "💭"
        }
    }

    /// Categorize emotion as positive, negative, or neutral
    static func sentiment(for emotion: String) -> Sentiment {
        switch emotion.lowercased() {
        case "joy", "happiness", "happy", "peace", "calm", "serene", "love", "affection", "wonder", "awe", "amazement":
            return .positive
        case "fear", "scared", "frightened", "anxiety", "nervous", "worried", "sadness", "sad", "grief", "anger", "angry", "frustrated":
            return .negative
        default:
            return .neutral
        }
    }

    enum Sentiment {
        case positive
        case neutral
        case negative

        var color: Color {
            switch self {
            case .positive: return MBColors.success
            case .neutral: return MBColors.info
            case .negative: return MBColors.secondary
            }
        }

        var icon: String {
            switch self {
            case .positive: return "sun.max.fill"
            case .neutral: return "cloud.fill"
            case .negative: return "cloud.rain.fill"
            }
        }
    }
}

// MARK: - Theme Helpers

enum MBThemes {
    /// Map theme names to SF Symbols
    static func icon(for theme: String) -> String {
        switch theme.lowercased() {
        case "flying":
            return "bird"
        case "falling":
            return "arrow.down.circle"
        case "chase", "chasing", "being chased":
            return "figure.run"
        case "water", "ocean", "swimming":
            return "drop.fill"
        case "death", "dying":
            return "moon.zzz"
        case "lost", "maze":
            return "map"
        case "teeth":
            return "mouth"
        case "naked", "nudity":
            return "figure.stand"
        case "late", "running late":
            return "clock.badge.exclamationmark"
        case "test", "exam":
            return "doc.text"
        case "animals", "animal":
            return "pawprint.fill"
        case "flying vehicle", "airplane", "vehicle":
            return "airplane"
        case "relationship", "romance":
            return "heart.fill"
        case "family":
            return "person.3.fill"
        case "house", "home":
            return "house.fill"
        case "adventure", "journey":
            return "figure.hiking"
        case "nature", "forest":
            return "leaf.fill"
        case "supernatural", "magic":
            return "sparkles"
        case "work", "office":
            return "briefcase.fill"
        case "school", "college":
            return "graduationcap.fill"
        default:
            return "star.fill"
        }
    }

    /// Map theme names to colors
    static func color(for theme: String) -> Color {
        switch theme.lowercased() {
        case "flying":
            return MBColors.accentAlt // Celestial cyan
        case "water", "ocean", "swimming":
            return MBColors.info // Sky blue
        case "death", "dying":
            return MBColors.secondary // Deep indigo
        case "relationship", "romance", "love":
            return MBColors.accent // Dreamy pink
        case "fear", "chase", "chasing":
            return MBColors.error // Soft red
        case "nature", "forest", "animals":
            return MBColors.success // Emerald green
        case "supernatural", "magic":
            return MBColors.primaryLight // Soft lavender
        default:
            return MBColors.primary
        }
    }
}

// MARK: - Moon Phase Helpers

enum MBMoonPhase {
    /// Get moon phase icon based on day of month (simplified)
    static func icon(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let phase = day % 8
        switch phase {
        case 0: return "moon.fill"
        case 1: return "moon.righthalf.filled"
        case 2: return "circle"
        case 3: return "moon.lefthalf.filled"
        case 4: return "moon.fill"
        case 5: return "moon.righthalf.filled"
        case 6: return "circle"
        case 7: return "moon.lefthalf.filled"
        default: return "moon.fill"
        }
    }

    /// Get moon phase name based on day of month
    static func name(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        let phase = day % 8
        switch phase {
        case 0, 4: return "Full Moon"
        case 1, 5: return "Waning Gibbous"
        case 2, 6: return "New Moon"
        case 3, 7: return "Waxing Crescent"
        default: return "Moon"
        }
    }
}

// MARK: - Date Formatting Helpers

enum MBDateFormatter {
    // MARK: - Cached Formatters (expensive to create, so reuse)

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE" // "Tuesday"
        return formatter
    }()

    private static let weekdayMonthDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d" // "Tuesday, Dec 5"
        return formatter
    }()

    private static let fullDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy" // "Tuesday, Dec 5, 2024"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    private static let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter
    }()

    private static let abbreviatedRelativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    // MARK: - Public Methods

    /// Format date for section headers with smart relative formatting
    static func sectionHeader(for date: Date) -> (primary: String, secondary: String?) {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return ("Today", nil)
        } else if calendar.isDateInYesterday(date) {
            return ("Yesterday", nil)
        } else if isDateInThisWeek(date) {
            return (weekdayFormatter.string(from: date), nil)
        } else if isDateInThisYear(date) {
            return (weekdayMonthDayFormatter.string(from: date), nil)
        } else {
            return (fullDateFormatter.string(from: date), nil)
        }
    }

    /// Check if date is within this week
    private static func isDateInThisWeek(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return false }
        return date > weekAgo
    }

    /// Check if date is within this year
    private static func isDateInThisYear(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.year, from: date) == calendar.component(.year, from: Date())
    }

    /// Format time for dream cards
    static func timeString(for date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// Format relative time (e.g., "2 hours ago")
    static func relativeTime(for date: Date) -> String {
        relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// Format abbreviated relative time (e.g., "2h ago")
    static func abbreviatedRelativeTime(for date: Date) -> String {
        abbreviatedRelativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// Format relative date string for sharing (e.g., "December 6, 2024")
    static func relativeDateString(for date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            return longDateFormatter.string(from: date)
        }
    }
}

// MARK: - Enhanced Glass Morphism

extension View {
    /// Premium glass morphism with subtle border gradient
    func mbGlassPremium() -> some View {
        self
            .background(.ultraThinMaterial.opacity(0.5))
            .background(MBColors.backgroundCard.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
    }

    /// Sentiment indicator bar (left edge of card)
    func mbSentimentBar(emotions: [String]) -> some View {
        HStack(spacing: 0) {
            // Sentiment bar
            let dominantEmotion = emotions.first ?? ""
            let sentiment = MBEmotions.sentiment(for: dominantEmotion)

            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [sentiment.color, sentiment.color.opacity(0.3)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4)

            self
        }
    }

    /// Shimmer effect for loading skeletons (alias for mbShimmer)
    func shimmer() -> some View {
        self.mbShimmer(isActive: true)
    }
}

// MARK: - Transition Presets

enum MBTransition {
    /// Slide up from bottom with fade
    static let slideUp = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom).combined(with: .opacity),
        removal: .move(edge: .bottom).combined(with: .opacity)
    )

    /// Slide from leading edge
    static let slideFromLeading = AnyTransition.asymmetric(
        insertion: .move(edge: .leading).combined(with: .opacity),
        removal: .move(edge: .trailing).combined(with: .opacity)
    )

    /// Scale with fade (for modals/cards)
    static let scaleWithFade = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.95).combined(with: .opacity),
        removal: .scale(scale: 0.95).combined(with: .opacity)
    )

    /// Pop in from center
    static let popIn = AnyTransition.asymmetric(
        insertion: .scale(scale: 0.8).combined(with: .opacity),
        removal: .scale(scale: 0.9).combined(with: .opacity)
    )

    /// Smooth fade only
    static let fade = AnyTransition.opacity

    /// Blur transition
    static let blur = AnyTransition.modifier(
        active: BlurModifier(isActive: true),
        identity: BlurModifier(isActive: false)
    )

    /// Slide with blur
    static let slideWithBlur = AnyTransition.asymmetric(
        insertion: .move(edge: .bottom)
            .combined(with: .opacity)
            .combined(with: .modifier(
                active: BlurModifier(isActive: true),
                identity: BlurModifier(isActive: false)
            )),
        removal: .move(edge: .bottom)
            .combined(with: .opacity)
    )
}

// MARK: - Blur Modifier for Transitions

private struct BlurModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .blur(radius: isActive ? 10 : 0)
    }
}

// MARK: - View Transition Extensions

extension View {
    /// Apply staggered entrance animation
    func mbStaggeredEntrance(index: Int, appeared: Bool) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .animation(MBAnimation.stagger(index), value: appeared)
    }

    /// Apply smooth scale animation on appear
    func mbScaleOnAppear(delay: Double = 0) -> some View {
        modifier(ScaleOnAppearModifier(delay: delay))
    }

    /// Apply slide transition with consistent styling
    func mbSlideTransition(edge: Edge = .bottom) -> some View {
        self.transition(
            .asymmetric(
                insertion: .move(edge: edge).combined(with: .opacity),
                removal: .move(edge: edge).combined(with: .opacity)
            )
        )
    }

    /// Hero-like scale animation from card to detail
    func mbHeroTransition(id: String, namespace: Namespace.ID) -> some View {
        self.matchedGeometryEffect(id: id, in: namespace)
    }
}

// MARK: - Scale On Appear Modifier

private struct ScaleOnAppearModifier: ViewModifier {
    let delay: Double
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.9)
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(MBAnimation.springBouncy.delay(delay)) {
                    appeared = true
                }
            }
    }
}

// MARK: - Interactive Tap Modifier

extension View {
    /// Add interactive tap effect with scale and haptic
    func mbInteractiveTap(action: @escaping () -> Void) -> some View {
        modifier(InteractiveTapModifier(action: action))
    }
}

private struct InteractiveTapModifier: ViewModifier {
    let action: () -> Void
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .opacity(isPressed ? 0.9 : 1.0)
            .animation(MBAnimation.cardTap, value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            HapticManager.shared.impact(style: .light)
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        action()
                    }
            )
    }
}
