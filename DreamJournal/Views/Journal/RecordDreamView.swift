import SwiftUI

struct RecordDreamView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var tabController: TabController
    @StateObject private var speechService = SpeechService.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isAuthorized = false
    @State private var showPermissionAlert = false
    @State private var isSaving = false
    @State private var showSaveConfirmation = false
    @State private var error: Error?
    @State private var showError = false
    @State private var animatePulse = false

    // Input mode toggle
    @State private var useTextInput = false
    @State private var manualTranscript = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // Animated background
                MBAnimatedBackground()

                VStack(spacing: MBSpacing.lg) {
                    // Input mode toggle
                    inputModeToggle
                        .padding(.top, MBSpacing.md)

                    if useTextInput {
                        // Text input mode
                        textInputSection
                    } else {
                        Spacer()

                        // Recording indicator
                        recordingIndicator

                        // Transcript area
                        transcriptSection
                    }

                    // Controls
                    controlsSection

                    // Less bottom padding when recording to maximize button visibility
                    Spacer()
                        .frame(height: speechService.isRecording ? MBSpacing.xs : MBSpacing.md)
                }
                .padding(.horizontal, MBSpacing.lg)

                // Saving overlay
                if isSaving {
                    savingOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Record Dream")
                        .font(MBTypography.headline())
                        .foregroundStyle(MBColors.textPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if speechService.isRecording {
                        Button {
                            speechService.cancelRecording()
                        } label: {
                            Text("Cancel")
                                .font(MBTypography.label())
                                .foregroundStyle(MBColors.error)
                        }
                    }
                }
            }
            .toolbarBackground(MBColors.background.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            isAuthorized = await speechService.requestAuthorization()
        }
        .alert("Microphone Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable microphone and speech recognition access in Settings to record your dreams.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
        .alert("Dream Saved!", isPresented: $showSaveConfirmation) {
            Button("View Dreams") {
                tabController.switchToDreams()
            }
        } message: {
            Text("Your dream has been recorded and analyzed.")
        }
    }

    // MARK: - Views

    private var inputModeToggle: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(MBAnimation.spring) {
                    useTextInput = false
                    isTextFieldFocused = false
                }
                HapticManager.shared.impact(style: .light)
            } label: {
                HStack(spacing: MBSpacing.xxs) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 14))
                        .symbolEffect(.bounce, value: !useTextInput)
                    Text("Voice")
                        .font(MBTypography.label())
                }
                .foregroundStyle(useTextInput ? MBColors.textSecondary : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MBSpacing.sm)
                .background(
                    Group {
                        if !useTextInput {
                            LinearGradient(
                                colors: [MBColors.primary, MBColors.primary.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.clear
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
            }

            Button {
                withAnimation(MBAnimation.spring) {
                    useTextInput = true
                    if speechService.isRecording {
                        speechService.cancelRecording()
                    }
                }
                HapticManager.shared.impact(style: .light)
            } label: {
                HStack(spacing: MBSpacing.xxs) {
                    Image(systemName: "keyboard")
                        .font(.system(size: 14))
                        .symbolEffect(.bounce, value: useTextInput)
                    Text("Type")
                        .font(MBTypography.label())
                }
                .foregroundStyle(useTextInput ? .white : MBColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, MBSpacing.sm)
                .background(
                    Group {
                        if useTextInput {
                            LinearGradient(
                                colors: [MBColors.primary, MBColors.primary.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            Color.clear
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: MBRadius.md))
            }
        }
        .padding(4)
        .background(MBColors.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: MBRadius.lg)
                .stroke(MBColors.border, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 8, y: 2)
    }

    private var textInputSection: some View {
        VStack(alignment: .leading, spacing: MBSpacing.md) {
            VStack(alignment: .leading, spacing: MBSpacing.sm) {
                Text("Describe Your Dream")
                    .font(MBTypography.headline())
                    .foregroundStyle(MBColors.textPrimary)

                Text("Write down everything you remember...")
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textSecondary)
            }

            TextEditor(text: $manualTranscript)
                .font(MBTypography.body())
                .foregroundStyle(MBColors.textPrimary)
                .scrollContentBackground(.hidden)
                .focused($isTextFieldFocused)
                .frame(minHeight: 200, maxHeight: 300)
                .padding(MBSpacing.md)
                .background(
                    ZStack {
                        MBColors.backgroundCard
                        // Subtle glow on focus
                        if isTextFieldFocused {
                            RoundedRectangle(cornerRadius: MBRadius.lg)
                                .fill(MBColors.primary.opacity(0.03))
                        }
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: MBRadius.lg)
                        .stroke(
                            isTextFieldFocused
                                ? LinearGradient(
                                    colors: [MBColors.primary.opacity(0.8), MBColors.secondary.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  )
                                : LinearGradient(
                                    colors: [MBColors.border, MBColors.border],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                  ),
                            lineWidth: isTextFieldFocused ? 1.5 : 1
                        )
                )
                .overlay(alignment: .topLeading) {
                    if manualTranscript.isEmpty {
                        Text("I was walking through a forest when suddenly...")
                            .font(MBTypography.body())
                            .foregroundStyle(MBColors.textMuted)
                            .padding(MBSpacing.md)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
                .scaleEffect(isTextFieldFocused ? 1.005 : 1.0)
                .shadow(color: isTextFieldFocused ? MBColors.primary.opacity(0.12) : .clear, radius: 12, y: 4)
                .animation(MBAnimation.spring, value: isTextFieldFocused)
                .onChange(of: isTextFieldFocused) { _, newValue in
                    if newValue {
                        HapticManager.shared.impact(style: .light)
                    }
                }

            HStack {
                Text("\(manualTranscript.count) characters")
                    .font(MBTypography.caption())
                    .foregroundStyle(MBColors.textMuted)

                Spacer()

                if !manualTranscript.isEmpty {
                    Button {
                        manualTranscript = ""
                    } label: {
                        Text("Clear")
                            .font(MBTypography.caption())
                            .foregroundStyle(MBColors.error)
                    }
                }
            }
        }
    }

    private var recordingIndicator: some View {
        VStack(spacing: MBSpacing.lg) {
            recordingCircle
                .onAppear {
                    if speechService.isRecording {
                        animatePulse = true
                    }
                }
                .onChange(of: speechService.isRecording) { _, isRecording in
                    animatePulse = isRecording
                }

            statusText

            if speechService.isRecording {
                AudioLevelView(level: speechService.audioLevel)
                    .frame(height: 50)
                    .padding(.horizontal, MBSpacing.lg)
            }
        }
    }

    private var recordingCircle: some View {
        ZStack {
            if speechService.isRecording {
                pulseRings
            }
            mainCircle
            micIcon
        }
    }

    private var pulseRings: some View {
        ForEach(0..<3, id: \.self) { i in
            Circle()
                .stroke(MBColors.error.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                .frame(width: 120 + CGFloat(i) * 30, height: 120 + CGFloat(i) * 30)
                .scaleEffect(animatePulse ? 1.2 : 1)
                .opacity(animatePulse ? 0 : 0.5)
                .animation(
                    .easeOut(duration: 1.5)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.3),
                    value: animatePulse
                )
        }
    }

    @ViewBuilder
    private var mainCircle: some View {
        if speechService.isRecording {
            Circle()
                .fill(MBColors.error)
                .frame(width: 100, height: 100)
                .shadow(color: MBColors.error.opacity(0.5), radius: 20, x: 0, y: 0)
        } else {
            Circle()
                .fill(MBGradients.primary)
                .frame(width: 100, height: 100)
                .shadow(color: MBColors.primary.opacity(0.5), radius: 20, x: 0, y: 0)
        }
    }

    private var micIcon: some View {
        Image(systemName: speechService.isRecording ? "waveform" : "mic.fill")
            .font(.system(size: 40))
            .foregroundStyle(.white)
            .symbolEffect(.variableColor.iterative, isActive: speechService.isRecording)
    }

    private var statusText: some View {
        VStack(spacing: MBSpacing.xxs) {
            Text(speechService.isRecording ? "Listening..." : "Ready to Record")
                .font(MBTypography.titleSmall())
                .foregroundStyle(MBColors.textPrimary)

            Text(speechService.isRecording ? "Speak naturally about your dream" : "Tap the button below to start")
                .font(MBTypography.body())
                .foregroundStyle(MBColors.textSecondary)
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: MBSpacing.sm) {
            HStack {
                Text("Transcript")
                    .font(MBTypography.headline())
                    .foregroundStyle(MBColors.textPrimary)

                Spacer()

                if speechService.isTranscribing {
                    HStack(spacing: MBSpacing.xxs) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: MBColors.primary))
                            .scaleEffect(0.7)
                        Text("Processing...")
                            .font(MBTypography.caption())
                            .foregroundStyle(MBColors.textTertiary)
                    }
                }
            }

            ScrollView {
                Text(speechService.transcript.isEmpty
                     ? "Your dream will appear here as you speak..."
                     : speechService.transcript)
                    .font(MBTypography.body())
                    .foregroundStyle(speechService.transcript.isEmpty
                                    ? MBColors.textMuted
                                    : MBColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: speechService.isRecording ? 120 : 180)
            .animation(MBAnimation.spring, value: speechService.isRecording)
            .padding(MBSpacing.md)
            .background(MBColors.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: MBRadius.lg)
                    .stroke(MBColors.border, lineWidth: 1)
            )
        }
    }

    private var controlsSection: some View {
        VStack(spacing: MBSpacing.md) {
            if useTextInput {
                // Text input mode - Save button
                Button {
                    saveTextDream()
                } label: {
                    HStack(spacing: MBSpacing.xs) {
                        if !isSaving {
                            Image(systemName: "square.and.arrow.down.fill")
                        }
                        Text(isSaving ? "Saving..." : "Save Dream")
                    }
                }
                .buttonStyle(.mbCTA(isLoading: isSaving))
                .disabled(manualTranscript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
            } else {
                // Voice input mode
                if speechService.isRecording {
                    // Large, prominent stop button when recording
                    Button {
                        stopAndSave()
                    } label: {
                        HStack(spacing: MBSpacing.sm) {
                            if !isSaving {
                                ZStack {
                                    // Pulsing background circle
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 32, height: 32)
                                        .scaleEffect(animatePulse ? 1.3 : 1.0)
                                        .opacity(animatePulse ? 0 : 0.5)

                                    // Stop icon
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            Text(isSaving ? "Saving..." : "Stop & Save Dream")
                                .font(MBTypography.headline())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, MBSpacing.lg)
                    .background(
                        ZStack {
                            // Animated glow behind
                            RoundedRectangle(cornerRadius: MBRadius.lg)
                                .fill(MBColors.error)
                                .blur(radius: 12)
                                .opacity(0.5)
                                .scaleEffect(1.05)

                            // Main background
                            RoundedRectangle(cornerRadius: MBRadius.lg)
                                .fill(MBColors.error)
                        }
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: MBRadius.lg))
                    .shadow(color: MBColors.error.opacity(0.5), radius: 16, y: 8)
                    .scaleEffect(isSaving ? 0.98 : 1.0)
                    .animation(MBAnimation.spring, value: isSaving)
                    .disabled(isSaving)
                    .padding(.horizontal, MBSpacing.xs)
                } else {
                    Button {
                        startRecording()
                    } label: {
                        HStack(spacing: MBSpacing.xs) {
                            Image(systemName: "mic.fill")
                                .symbolEffect(.variableColor.iterative)
                            Text("Start Recording")
                        }
                    }
                    .buttonStyle(.mbCTA)
                    .disabled(!isAuthorized)
                }

                if !isAuthorized && !useTextInput {
                    Button {
                        showPermissionAlert = true
                    } label: {
                        HStack(spacing: MBSpacing.xxs) {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Enable Permissions")
                        }
                        .font(MBTypography.bodySmall())
                        .foregroundStyle(MBColors.warning)
                    }
                }
            }
        }
    }

    private var savingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: MBSpacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: MBColors.primary))
                    .scaleEffect(1.5)

                Text("Saving your dream...")
                    .font(MBTypography.body())
                    .foregroundStyle(MBColors.textSecondary)
            }
            .padding(MBSpacing.xl)
            .mbGlass()
        }
    }

    // MARK: - Actions

    private func startRecording() {
        Task {
            do {
                try await speechService.startRecording()
            } catch {
                self.error = error
                self.showError = true
            }
        }
    }

    private func saveTextDream() {
        let transcript = manualTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else { return }

        Task {
            await saveDream(transcript: transcript, audioURL: nil)
            // Clear the text field BEFORE clearing focus to avoid UI glitches
            if showSaveConfirmation {
                manualTranscript = ""
                isTextFieldFocused = false
            }
        }
    }

    private func stopAndSave() {
        guard let result = speechService.stopRecording(),
              !result.transcript.isEmpty else {
            error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No transcript recorded"])
            showError = true
            speechService.cleanupRecording() // Clean up any partial recording
            return
        }

        Task {
            await saveDream(transcript: result.transcript, audioURL: result.audioURL)
        }
    }

    private func saveDream(transcript: String, audioURL: URL?) async {
        guard let userId = authService.currentUser?.id else { return }

        isSaving = true
        defer { isSaving = false }

        // Analyze the dream
        let analysis = DreamAnalysisService.shared.analyzeDream(transcript)

        // Generate title from first sentence or 50 chars
        let title = generateTitle(from: transcript)

        do {
            _ = try await DreamService.shared.createDream(
                userId: userId,
                title: title,
                transcript: transcript,
                themes: analysis.themes,
                emotions: analysis.emotions,
                audioURL: audioURL
            )

            // Clean up temp audio file AFTER successful upload
            speechService.cleanupRecording()

            showSaveConfirmation = true
        } catch {
            // Don't clean up on failure - keep file for potential retry
            speechService.cleanupRecordingOnFailure()
            self.error = error
            self.showError = true
        }
    }

    private func generateTitle(from transcript: String) -> String {
        // Try to get first sentence
        let sentences = transcript.components(separatedBy: CharacterSet(charactersIn: ".!?"))
        if let firstSentence = sentences.first, !firstSentence.isEmpty {
            let trimmed = firstSentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.count <= 50 {
                return trimmed
            }
            return String(trimmed.prefix(47)) + "..."
        }

        // Fallback to first 50 characters
        if transcript.count <= 50 {
            return transcript
        }
        return String(transcript.prefix(47)) + "..."
    }
}

// MARK: - Audio Level View

struct AudioLevelView: View {
    let level: Float

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(0..<30, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(width: max(4, (geometry.size.width - 90) / 30))
                        .scaleEffect(y: barScale(for: index), anchor: .bottom)
                        .animation(.easeOut(duration: 0.1), value: level)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func barScale(for index: Int) -> CGFloat {
        let threshold = Float(index) / 30.0
        if level > threshold {
            return CGFloat(0.2 + (level - threshold) * 0.8)
        }
        return 0.2
    }

    private func barColor(for index: Int) -> Color {
        let threshold = Float(index) / 30.0
        if level > threshold {
            if index < 20 {
                return MBColors.primary
            } else if index < 25 {
                return MBColors.warning
            } else {
                return MBColors.error
            }
        }
        return MBColors.textMuted.opacity(0.3)
    }
}

#Preview {
    RecordDreamView()
        .environmentObject(AuthService.shared)
        .environmentObject(TabController.shared)
}
