import SwiftUI

// MARK: - Moonbeat Reusable Components

// MARK: - Navigation Header

struct MBNavigationHeader<TrailingContent: View>: View {
    let title: String
    var subtitle: String? = nil
    var showBackButton: Bool = false
    var onBack: (() -> Void)? = nil
    @ViewBuilder var trailing: () -> TrailingContent

    init(
        title: String,
        subtitle: String? = nil,
        showBackButton: Bool = false,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> TrailingContent = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.onBack = onBack
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: MBSpacing.md) {
            if showBackButton {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(MBColors.textPrimary)
                }
                .buttonStyle(.mbIcon(size: 40, background: .clear))
            }

            VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                Text(title)
                    .font(MBTypography.titleSmall())
                    .foregroundStyle(MBColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(MBTypography.bodySmall())
                        .foregroundStyle(MBColors.textSecondary)
                }
            }

            Spacer()

            trailing()
        }
        .padding(.horizontal, MBSpacing.md)
        .padding(.vertical, MBSpacing.sm)
    }
}

// MARK: - Section Header

struct MBSectionHeader: View {
    let title: String
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(MBTypography.headline())
                .foregroundStyle(MBColors.textPrimary)

            Spacer()

            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(MBTypography.label())
                        .foregroundStyle(MBColors.primary)
                }
            }
        }
    }
}

// MARK: - Dream Card

struct MBDreamCard: View {
    let title: String
    let date: String
    let time: String
    var themes: [String] = []
    var emotions: [String] = []
    var hasVideo: Bool = false
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: MBSpacing.sm) {
                // Header row
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: MBSpacing.xxs) {
                        Text(title)
                            .font(MBTypography.headline())
                            .foregroundStyle(MBColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)

                        Text("\(date) • \(time)")
                            .font(MBTypography.caption())
                            .foregroundStyle(MBColors.textTertiary)
                    }

                    Spacer()

                    if hasVideo {
                        Image(systemName: "video.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(MBColors.accent)
                            .padding(MBSpacing.xs)
                            .background(MBColors.accent.opacity(0.15))
                            .clipShape(Circle())
                    }
                }

                // Tags
                if !themes.isEmpty || !emotions.isEmpty {
                    MBFlowLayout(spacing: MBSpacing.xxs) {
                        ForEach(themes, id: \.self) { theme in
                            Text(theme)
                                .mbTag(color: MBColors.primary)
                        }
                        ForEach(emotions, id: \.self) { emotion in
                            Text(emotion)
                                .mbTag(color: MBColors.secondary)
                        }
                    }
                }
            }
            .padding(MBSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Empty State

struct MBEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: MBSpacing.lg) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(MBColors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)

                Image(systemName: icon)
                    .font(.system(size: 48))
                    .foregroundStyle(MBGradients.primary)
                    .symbolEffect(.pulse.byLayer)
            }

            VStack(spacing: MBSpacing.xs) {
                Text(title)
                    .font(MBTypography.titleSmall())
                    .foregroundStyle(MBColors.textPrimary)

                Text(message)
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    HStack(spacing: MBSpacing.xs) {
                        Image(systemName: "plus")
                        Text(actionTitle)
                    }
                }
                .buttonStyle(.mbPrimary)
                .padding(.horizontal, MBSpacing.xxl)
            }
        }
        .padding(MBSpacing.xl)
    }
}

// MARK: - Loading State

struct MBLoadingView: View {
    var message: String = "Loading..."

    var body: some View {
        VStack(spacing: MBSpacing.md) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: MBColors.primary))
                .scaleEffect(1.2)

            Text(message)
                .font(MBTypography.body())
                .foregroundStyle(MBColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MBColors.background)
    }
}

// MARK: - Error State

struct MBErrorView: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: MBSpacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(MBColors.error)

            Text(message)
                .font(MBTypography.body())
                .foregroundStyle(MBColors.textSecondary)
                .multilineTextAlignment(.center)

            if let retryAction {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.mbSecondary)
                    .padding(.horizontal, MBSpacing.xl)
            }
        }
        .padding(MBSpacing.xl)
    }
}

// MARK: - Credits Badge with Urgency States

struct MBCreditsBadge: View {
    let credits: Int
    var isPro: Bool = false

    private var urgencyColor: Color {
        if isPro { return MBColors.gold }
        switch credits {
        case 3...: return MBColors.textPrimary
        case 2: return MBColors.warning
        case 1: return MBColors.warning
        default: return MBColors.error
        }
    }

    private var shouldPulse: Bool {
        credits == 1 && !isPro
    }

    var body: some View {
        HStack(spacing: MBSpacing.xxs) {
            if isPro {
                Image(systemName: "infinity")
                    .font(.system(size: 12, weight: .bold))
                Text("PRO")
                    .font(MBTypography.captionSmall(.bold))
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 12))
                    .symbolEffect(.pulse, options: .repeating, isActive: shouldPulse)
                Text("\(credits)")
                    .font(MBTypography.caption(.bold))
            }
        }
        .foregroundStyle(urgencyColor)
        .padding(.horizontal, MBSpacing.sm)
        .padding(.vertical, MBSpacing.xxs)
        .background(
            Group {
                if isPro {
                    MBColors.gold.opacity(0.15)
                } else if credits <= 1 {
                    urgencyColor.opacity(0.15)
                } else {
                    MBColors.backgroundCard
                }
            }
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(isPro ? MBColors.gold.opacity(0.3) : urgencyColor.opacity(credits <= 2 ? 0.5 : 0.1), lineWidth: 1)
        )
    }
}

// MARK: - Feature Row

struct MBFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    var iconColor: Color = MBColors.primary

    var body: some View {
        HStack(alignment: .top, spacing: MBSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

            VStack(alignment: .leading, spacing: MBSpacing.xxs) {
                Text(title)
                    .font(MBTypography.headline())
                    .foregroundStyle(MBColors.textPrimary)

                Text(description)
                    .font(MBTypography.bodySmall())
                    .foregroundStyle(MBColors.textSecondary)
            }

            Spacer()
        }
    }
}

// MARK: - Settings Row

struct MBSettingsRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var iconColor: Color = MBColors.primary
    var showChevron: Bool = true
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: MBSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

                VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                    Text(title)
                        .font(MBTypography.body())
                        .foregroundStyle(MBColors.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(MBTypography.caption())
                            .foregroundStyle(MBColors.textTertiary)
                    }
                }

                Spacer()

                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MBColors.textMuted)
                }
            }
            .padding(MBSpacing.md)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Toggle Row

struct MBToggleRow: View {
    let icon: String
    let title: String
    var subtitle: String? = nil
    var iconColor: Color = MBColors.primary
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: MBSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 32, height: 32)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: MBRadius.sm))

            VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                Text(title)
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textPrimary)

                if let subtitle {
                    Text(subtitle)
                        .font(MBTypography.caption())
                        .foregroundStyle(MBColors.textTertiary)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(MBColors.primary)
                .labelsHidden()
        }
        .padding(MBSpacing.md)
        .background(MBColors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
    }
}

// MARK: - Flow Layout

struct MBFlowLayout: Layout {
    var spacing: CGFloat = MBSpacing.xs

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Animated Background

struct MBAnimatedBackground: View {
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            MBColors.background
                .ignoresSafeArea()

            // Animated gradient orbs
            GeometryReader { geo in
                Circle()
                    .fill(MBColors.primary.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(
                        x: animateGradient ? geo.size.width * 0.2 : geo.size.width * 0.6,
                        y: animateGradient ? geo.size.height * 0.1 : geo.size.height * 0.3
                    )

                Circle()
                    .fill(MBColors.secondary.opacity(0.1))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(
                        x: animateGradient ? geo.size.width * 0.7 : geo.size.width * 0.3,
                        y: animateGradient ? geo.size.height * 0.6 : geo.size.height * 0.4
                    )

                Circle()
                    .fill(MBColors.accent.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .blur(radius: 50)
                    .offset(
                        x: animateGradient ? geo.size.width * 0.1 : geo.size.width * 0.5,
                        y: animateGradient ? geo.size.height * 0.8 : geo.size.height * 0.7
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
}

// MARK: - Pulsing Recording Indicator

struct MBRecordingIndicator: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Outer pulse
            Circle()
                .fill(MBColors.error.opacity(0.3))
                .frame(width: 100, height: 100)
                .scaleEffect(isPulsing ? 1.3 : 1)
                .opacity(isPulsing ? 0 : 0.5)

            // Middle pulse
            Circle()
                .fill(MBColors.error.opacity(0.5))
                .frame(width: 80, height: 80)
                .scaleEffect(isPulsing ? 1.2 : 1)
                .opacity(isPulsing ? 0.3 : 0.7)

            // Core
            Circle()
                .fill(MBColors.error)
                .frame(width: 60, height: 60)

            Image(systemName: "mic.fill")
                .font(.system(size: 24))
                .foregroundStyle(.white)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Audio Level Visualizer

struct MBAudioVisualizer: View {
    let levels: [CGFloat]
    var barCount: Int = 40

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                let level = index < levels.count ? levels[index] : 0

                RoundedRectangle(cornerRadius: 2)
                    .fill(barColor(for: level))
                    .frame(width: 4, height: max(4, level * 60))
                    .animation(.easeOut(duration: 0.1), value: level)
            }
        }
    }

    private func barColor(for level: CGFloat) -> Color {
        switch level {
        case 0..<0.4:
            return MBColors.primary
        case 0.4..<0.7:
            return MBColors.primaryLight
        case 0.7..<0.85:
            return MBColors.warning
        default:
            return MBColors.error
        }
    }
}

// MARK: - Video Generation Status

struct MBVideoStatusBadge: View {
    enum Status {
        case pending
        case processing
        case completed
        case failed

        var icon: String {
            switch self {
            case .pending: return "clock.fill"
            case .processing: return "gearshape.2.fill"
            case .completed: return "checkmark.circle.fill"
            case .failed: return "xmark.circle.fill"
            }
        }

        var label: String {
            switch self {
            case .pending: return "Pending"
            case .processing: return "Processing"
            case .completed: return "Ready"
            case .failed: return "Failed"
            }
        }

        var color: Color {
            switch self {
            case .pending: return MBColors.warning
            case .processing: return MBColors.info
            case .completed: return MBColors.success
            case .failed: return MBColors.error
            }
        }
    }

    let status: Status

    var body: some View {
        HStack(spacing: MBSpacing.xxs) {
            if status == .processing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: status.color))
                    .scaleEffect(0.7)
            } else {
                Image(systemName: status.icon)
                    .font(.system(size: 12))
            }

            Text(status.label)
                .font(MBTypography.caption())
        }
        .foregroundStyle(status.color)
        .padding(.horizontal, MBSpacing.xs)
        .padding(.vertical, MBSpacing.xxs)
        .background(status.color.opacity(0.15))
        .clipShape(Capsule())
    }
}

// MARK: - Hero Moon Icon

struct MBMoonIcon: View {
    var size: CGFloat = 120

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(MBColors.primary.opacity(0.2))
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: 30)
                .scaleEffect(isAnimating ? 1.1 : 1)

            // Moon circle
            Circle()
                .fill(MBGradients.primary)
                .frame(width: size, height: size)
                .shadow(color: MBColors.primary.opacity(0.5), radius: 20, x: 0, y: 0)

            // Moon icon
            Image(systemName: "moon.stars.fill")
                .font(.system(size: size * 0.45))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Divider

struct MBDivider: View {
    var body: some View {
        Rectangle()
            .fill(MBColors.border)
            .frame(height: 1)
    }
}

// MARK: - Skeleton Loading Components

struct MBSkeletonRectangle: View {
    var width: CGFloat? = nil
    var height: CGFloat = 16

    var body: some View {
        RoundedRectangle(cornerRadius: MBRadius.xs)
            .fill(MBColors.backgroundGlow)
            .frame(width: width, height: height)
            .mbShimmer()
    }
}

struct MBSkeletonCircle: View {
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(MBColors.backgroundGlow)
            .frame(width: size, height: size)
            .mbShimmer()
    }
}

struct MBSkeletonCapsule: View {
    var width: CGFloat = 60
    var height: CGFloat = 20

    var body: some View {
        Capsule()
            .fill(MBColors.backgroundGlow)
            .frame(width: width, height: height)
            .mbShimmer()
    }
}

/// Skeleton loading state for dream cards
struct MBDreamCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: MBSpacing.xs) {
                    MBSkeletonRectangle(width: 180, height: 18)
                    MBSkeletonRectangle(width: 100, height: 12)
                }
                Spacer()
                MBSkeletonCircle(size: 32)
            }

            // Transcript preview
            VStack(alignment: .leading, spacing: MBSpacing.xxs) {
                MBSkeletonRectangle(height: 14)
                MBSkeletonRectangle(width: 240, height: 14)
            }

            // Tags
            HStack(spacing: MBSpacing.xxs) {
                MBSkeletonCapsule(width: 60, height: 22)
                MBSkeletonCapsule(width: 48, height: 22)
                MBSkeletonCapsule(width: 54, height: 22)
            }
        }
        .padding(MBSpacing.md)
        .background(MBColors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.lg)
                .stroke(MBColors.border, lineWidth: 1)
        )
        .padding(.horizontal, MBSpacing.md)
    }
}

/// Skeleton loading state for a list of dream cards
struct MBDreamListSkeleton: View {
    var count: Int = 3

    var body: some View {
        ScrollView {
            LazyVStack(spacing: MBSpacing.lg) {
                // Section header skeleton
                HStack {
                    MBSkeletonRectangle(width: 80, height: 20)
                    Spacer()
                    MBSkeletonRectangle(width: 60, height: 14)
                }
                .padding(.horizontal, MBSpacing.md)

                // Dream cards
                ForEach(0..<count, id: \.self) { _ in
                    MBDreamCardSkeleton()
                }
            }
            .padding(.vertical, MBSpacing.md)
        }
    }
}

// MARK: - Enhanced Date Section Header

struct MBDateSectionHeader: View {
    let date: Date
    let dreamCount: Int

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                let formatted = MBDateFormatter.sectionHeader(for: date)

                Text(formatted.primary)
                    .font(MBTypography.titleMedium())
                    .foregroundStyle(MBColors.textPrimary)

                if let secondary = formatted.secondary {
                    Text(secondary)
                        .font(MBTypography.caption())
                        .foregroundStyle(MBColors.textTertiary)
                }
            }

            Spacer()

            // Dream count badge
            HStack(spacing: MBSpacing.xxs) {
                Image(systemName: MBMoonPhase.icon(for: date))
                    .font(.system(size: 12))
                Text("\(dreamCount)")
                    .font(MBTypography.caption(.bold))
            }
            .foregroundStyle(MBColors.textSecondary)
            .padding(.horizontal, MBSpacing.sm)
            .padding(.vertical, MBSpacing.xxs)
            .background(MBColors.backgroundCard)
            .clipShape(Capsule())
        }
        .padding(.horizontal, MBSpacing.md)
        .padding(.top, MBSpacing.lg)
        .padding(.bottom, MBSpacing.xs)
    }
}

// MARK: - Search Bar

struct MBSearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search dreams..."
    var onSubmit: () -> Void = {}

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: MBSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(isFocused ? MBColors.primary : MBColors.textTertiary)

            TextField(placeholder, text: $text)
                .font(MBTypography.body())
                .foregroundStyle(MBColors.textPrimary)
                .focused($isFocused)
                .onSubmit(onSubmit)

            if !text.isEmpty {
                Button {
                    text = ""
                    HapticManager.shared.lightTap()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(MBColors.textMuted)
                }
                .transition(MBTransition.scaleWithFade)
            }
        }
        .padding(.horizontal, MBSpacing.md)
        .padding(.vertical, MBSpacing.sm)
        .background(
            ZStack {
                MBColors.backgroundCard
                // Subtle glow on focus
                if isFocused {
                    RoundedRectangle(cornerRadius: MBRadius.lg)
                        .fill(MBColors.primary.opacity(0.03))
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.lg)
                .stroke(
                    isFocused
                        ? LinearGradient(colors: [MBColors.primary.opacity(0.6), MBColors.secondary.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [MBColors.border, MBColors.border], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
        // Subtle scale on focus
        .scaleEffect(isFocused ? 1.01 : 1.0)
        // Glow shadow on focus
        .shadow(color: isFocused ? MBColors.primary.opacity(0.15) : .clear, radius: 8, y: 2)
        .animation(MBAnimation.spring, value: isFocused)
        .onChange(of: isFocused) { _, newValue in
            if newValue {
                HapticManager.shared.impact(style: .light)
            }
        }
    }
}

// MARK: - Filter Chip

struct MBFilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = MBColors.primary
    var onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap()
            HapticManager.shared.selection()
        }) {
            Text(label)
                .font(MBTypography.caption(.medium))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, MBSpacing.sm)
                .padding(.vertical, MBSpacing.xs)
                .background(isSelected ? color : color.opacity(0.15))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Filter Bar

struct MBFilterBar: View {
    let themes: [String]
    let emotions: [String]
    @Binding var selectedThemes: Set<String>
    @Binding var selectedEmotions: Set<String>

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            // Toggle button
            Button {
                withAnimation(MBAnimation.smooth) {
                    isExpanded.toggle()
                }
                HapticManager.shared.lightTap()
            } label: {
                HStack(spacing: MBSpacing.xs) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 16))

                    Text("Filters")
                        .font(MBTypography.label())

                    if !selectedThemes.isEmpty || !selectedEmotions.isEmpty {
                        Text("\(selectedThemes.count + selectedEmotions.count)")
                            .font(MBTypography.captionSmall(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, MBSpacing.xs)
                            .padding(.vertical, MBSpacing.xxxs)
                            .background(MBColors.primary)
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(MBColors.textSecondary)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: MBSpacing.md) {
                    // Themes
                    if !themes.isEmpty {
                        VStack(alignment: .leading, spacing: MBSpacing.xs) {
                            Text("Themes")
                                .font(MBTypography.caption())
                                .foregroundStyle(MBColors.textTertiary)

                            MBFlowLayout(spacing: MBSpacing.xs) {
                                ForEach(themes, id: \.self) { theme in
                                    MBFilterChip(
                                        label: theme,
                                        isSelected: selectedThemes.contains(theme),
                                        color: MBThemes.color(for: theme)
                                    ) {
                                        if selectedThemes.contains(theme) {
                                            selectedThemes.remove(theme)
                                        } else {
                                            selectedThemes.insert(theme)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Emotions
                    if !emotions.isEmpty {
                        VStack(alignment: .leading, spacing: MBSpacing.xs) {
                            Text("Emotions")
                                .font(MBTypography.caption())
                                .foregroundStyle(MBColors.textTertiary)

                            MBFlowLayout(spacing: MBSpacing.xs) {
                                ForEach(emotions, id: \.self) { emotion in
                                    MBFilterChip(
                                        label: emotion,
                                        isSelected: selectedEmotions.contains(emotion),
                                        color: MBEmotions.color(for: emotion)
                                    ) {
                                        if selectedEmotions.contains(emotion) {
                                            selectedEmotions.remove(emotion)
                                        } else {
                                            selectedEmotions.insert(emotion)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Clear all button
                    if !selectedThemes.isEmpty || !selectedEmotions.isEmpty {
                        Button {
                            selectedThemes.removeAll()
                            selectedEmotions.removeAll()
                            HapticManager.shared.lightTap()
                        } label: {
                            Text("Clear All")
                                .font(MBTypography.caption())
                                .foregroundStyle(MBColors.error)
                        }
                    }
                }
                .padding(.top, MBSpacing.xs)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(MBSpacing.md)
        .background(MBColors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
    }
}


// MARK: - Sentiment Indicator

struct MBSentimentIndicator: View {
    let emotions: [String]

    private var dominantSentiment: MBEmotions.Sentiment {
        guard let first = emotions.first else { return .neutral }
        return MBEmotions.sentiment(for: first)
    }

    var body: some View {
        HStack(spacing: MBSpacing.xs) {
            Image(systemName: dominantSentiment.icon)
                .font(.system(size: 12))

            // Emotion distribution bar
            HStack(spacing: 2) {
                ForEach(emotions.prefix(4), id: \.self) { emotion in
                    Capsule()
                        .fill(MBEmotions.color(for: emotion))
                        .frame(width: 16, height: 6)
                }
            }
        }
        .foregroundStyle(dominantSentiment.color)
        .padding(.horizontal, MBSpacing.sm)
        .padding(.vertical, MBSpacing.xs)
        .background(dominantSentiment.color.opacity(0.1))
        .clipShape(Capsule())
    }
}

// MARK: - Video Indicator Badge

struct MBVideoIndicator: View {
    var isAnimated: Bool = false

    var body: some View {
        Image(systemName: "video.fill")
            .font(.system(size: 12))
            .foregroundStyle(MBColors.accentAlt)
            .padding(MBSpacing.xs)
            .background(MBColors.accentAlt.opacity(0.15))
            .clipShape(Circle())
            .symbolEffect(.pulse, options: .repeating, isActive: isAnimated)
    }
}
