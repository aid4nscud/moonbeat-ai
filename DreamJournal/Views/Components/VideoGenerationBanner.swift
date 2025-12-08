import SwiftUI

/// A floating banner that shows video generation progress
struct VideoGenerationBanner: View {
    @ObservedObject var videoService = VideoService.shared

    var body: some View {
        if !videoService.activeGenerations.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(videoService.activeGenerations.values)) { generation in
                    GenerationRow(generation: generation)
                }
            }
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
            .padding(.horizontal, MBSpacing.md)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: videoService.activeGenerations.count)
        }
    }
}

private struct GenerationRow: View {
    let generation: VideoGenerationInfo

    var body: some View {
        HStack(spacing: MBSpacing.md) {
            // Status icon
            statusIcon

            // Text
            VStack(alignment: .leading, spacing: MBSpacing.xxxs) {
                Text(statusTitle)
                    .font(MBTypography.label())
                    .foregroundStyle(MBColors.textPrimary)

                if let title = generation.dreamTitle {
                    Text(title)
                        .font(MBTypography.caption())
                        .foregroundStyle(MBColors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Progress or checkmark
            if generation.status == .completed {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(MBColors.success)
            } else if generation.status == .failed {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(MBColors.error)
            } else {
                Text("\(Int(generation.progress * 100))%")
                    .font(MBTypography.caption(.semibold))
                    .foregroundStyle(MBColors.primary)
                    .monospacedDigit()
            }
        }
        .padding(MBSpacing.md)
        .background(
            // Progress bar background
            GeometryReader { geo in
                if generation.status != .completed && generation.status != .failed {
                    Rectangle()
                        .fill(MBColors.primary.opacity(0.1))
                        .frame(width: geo.size.width * generation.progress)
                        .animation(.linear(duration: 0.3), value: generation.progress)
                }
            }
        )
    }

    @ViewBuilder
    private var statusIcon: some View {
        ZStack {
            Circle()
                .fill(statusColor.opacity(0.15))
                .frame(width: 36, height: 36)

            if generation.status == .completed {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MBColors.success)
            } else if generation.status == .failed {
                Image(systemName: "exclamationmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MBColors.error)
            } else {
                // Animated sparkle for generating
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(MBColors.primary)
                    .symbolEffect(.pulse, options: .repeating)
            }
        }
    }

    private var statusTitle: String {
        switch generation.status {
        case .pending:
            return "Queued..."
        case .processing:
            return "Creating your dream video..."
        case .completed:
            return "Video ready!"
        case .failed:
            return "Generation failed"
        }
    }

    private var statusColor: Color {
        switch generation.status {
        case .pending, .processing:
            return MBColors.primary
        case .completed:
            return MBColors.success
        case .failed:
            return MBColors.error
        }
    }
}

// MARK: - Compact Banner (for tab bar area)

struct CompactVideoGenerationBanner: View {
    @ObservedObject var videoService = VideoService.shared

    var body: some View {
        if let generation = videoService.activeGenerations.values.first {
            HStack(spacing: MBSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MBColors.primary)
                    .symbolEffect(.pulse, options: .repeating)

                Text(videoService.generatingCount == 1 ? "Generating video..." : "Generating \(videoService.generatingCount) videos...")
                    .font(MBTypography.caption(.medium))
                    .foregroundStyle(MBColors.textSecondary)

                Spacer()

                Text("\(Int(generation.progress * 100))%")
                    .font(MBTypography.caption(.semibold))
                    .foregroundStyle(MBColors.primary)
                    .monospacedDigit()
            }
            .padding(.horizontal, MBSpacing.md)
            .padding(.vertical, MBSpacing.sm)
            .background(MBColors.primary.opacity(0.1))
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

#Preview("Banner") {
    VStack {
        VideoGenerationBanner()
        Spacer()
    }
    .background(MBColors.background)
}
