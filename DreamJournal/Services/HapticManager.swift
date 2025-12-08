import UIKit

// MARK: - Haptic Feedback Manager
// Centralized haptic feedback for premium tactile experience

@MainActor
final class HapticManager {
    static let shared = HapticManager()

    // Pre-instantiated generators for performance
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    private init() {
        // Prepare generators for faster response
        prepareAll()
    }

    // MARK: - Preparation

    func prepareAll() {
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
        softImpact.prepare()
        rigidImpact.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }

    // MARK: - Basic Impacts

    /// Light tap - for subtle interactions like button hover
    func lightTap() {
        lightImpact.impactOccurred()
    }

    /// Medium tap - for standard button presses
    func mediumTap() {
        mediumImpact.impactOccurred()
    }

    /// Heavy tap - for significant actions
    func heavyTap() {
        heavyImpact.impactOccurred()
    }

    /// Soft tap - for gentle feedback
    func softTap() {
        softImpact.impactOccurred()
    }

    /// Rigid tap - for definitive actions
    func rigidTap() {
        rigidImpact.impactOccurred()
    }

    /// Generic impact with style - for flexible use
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        switch style {
        case .light:
            lightTap()
        case .medium:
            mediumTap()
        case .heavy:
            heavyTap()
        case .soft:
            softTap()
        case .rigid:
            rigidTap()
        @unknown default:
            mediumTap()
        }
    }

    // MARK: - Selection

    /// Selection changed - for picker/segmented control changes
    func selection() {
        selectionFeedback.selectionChanged()
    }

    // MARK: - Notifications

    /// Success - for completed actions
    func success() {
        notificationFeedback.notificationOccurred(.success)
    }

    /// Warning - for cautionary feedback
    func warning() {
        notificationFeedback.notificationOccurred(.warning)
    }

    /// Error - for failed actions
    func error() {
        notificationFeedback.notificationOccurred(.error)
    }

    /// Generic notification with type - for flexible use
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationFeedback.notificationOccurred(type)
    }

    // MARK: - Contextual Haptics

    /// Recording started - distinctive pattern
    func recordingStart() {
        mediumImpact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.softImpact.impactOccurred()
        }
    }

    /// Recording stopped - reverse pattern
    func recordingStop() {
        softImpact.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.mediumImpact.impactOccurred()
        }
    }

    /// Recording pulse - synced with audio level
    /// Call this at a rate appropriate for audio visualization (e.g., 10Hz)
    func recordingPulse(intensity: Float) {
        guard intensity > 0.3 else { return }
        softImpact.impactOccurred(intensity: CGFloat(intensity * 0.5))
    }

    /// Dream saved successfully
    func dreamSaved() {
        success()
    }

    /// Video generation started
    func videoGenerationStarted() {
        mediumTap()
    }

    /// Video generation completed
    func videoGenerationCompleted() {
        // Celebratory pattern
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.lightImpact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.lightImpact.impactOccurred()
        }
    }

    /// Video generation failed
    func videoGenerationFailed() {
        error()
    }

    /// Tab changed
    func tabChanged() {
        selection()
    }

    /// Card pressed (for dream cards)
    func cardPressed() {
        lightTap()
    }

    /// Swipe action triggered
    func swipeAction() {
        mediumTap()
    }

    /// Delete action
    func deleteAction() {
        warning()
    }

    /// Paywall presented
    func paywallPresented() {
        mediumTap()
    }

    /// Purchase completed
    func purchaseCompleted() {
        // Extra celebratory pattern for purchases
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.success()
        }
    }

    /// Streak milestone reached
    func streakMilestone() {
        // Distinctive celebration
        heavyTap()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.mediumImpact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.lightImpact.impactOccurred()
        }
    }

    /// Achievement unlocked
    func achievementUnlocked() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.rigidImpact.impactOccurred()
        }
    }

    /// Credit warning (low credits)
    func creditWarning() {
        warning()
    }

    /// Pull to refresh triggered
    func pullToRefresh() {
        softTap()
    }

    // MARK: - Additional Contextual Haptics

    /// Button press - standard button feedback
    func buttonPress() {
        mediumTap()
    }

    /// Toggle switched
    func toggleChanged() {
        selection()
    }

    /// Slider value changed
    func sliderChanged() {
        selection()
    }

    /// Navigation happened (push/pop)
    func navigation() {
        softTap()
    }

    /// Modal presented
    func modalPresented() {
        softTap()
    }

    /// Modal dismissed
    func modalDismissed() {
        lightTap()
    }

    /// List item selected
    func itemSelected() {
        lightTap()
    }

    /// Expand/collapse action
    func expandCollapse() {
        softTap()
    }

    /// Share action triggered
    func shareAction() {
        mediumTap()
    }

    /// Copy to clipboard
    func copied() {
        lightTap()
    }

    /// Refresh completed
    func refreshCompleted() {
        success()
    }

    /// Action sheet presented
    func actionSheet() {
        softTap()
    }

    /// Alert presented
    func alert() {
        warning()
    }

    /// Search activated
    func searchActivated() {
        lightTap()
    }

    /// Scroll to top
    func scrollToTop() {
        softTap()
    }

    /// Filter/sort changed
    func filterChanged() {
        selection()
    }

    /// AI interpretation generated
    func interpretationGenerated() {
        success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.lightImpact.impactOccurred()
        }
    }

    /// Long press recognized
    func longPress() {
        rigidTap()
    }

    /// Zoom changed
    func zoomChanged() {
        lightTap()
    }
}
