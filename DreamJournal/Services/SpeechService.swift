import Foundation
import Speech
import AVFoundation

// MARK: - Speech Service Errors

enum SpeechServiceError: LocalizedError {
    case notAuthorized
    case recognitionFailed(Error)
    case recordingFailed(Error)
    case noAudioInput

    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition is not authorized. Please enable it in Settings."
        case .recognitionFailed(let error):
            return "Speech recognition failed: \(error.localizedDescription)"
        case .recordingFailed(let error):
            return "Recording failed: \(error.localizedDescription)"
        case .noAudioInput:
            return "No audio input available."
        }
    }
}

// MARK: - Speech Service

@MainActor
final class SpeechService: ObservableObject {
    static let shared = SpeechService()

    @Published private(set) var isRecording = false
    @Published private(set) var isTranscribing = false
    @Published private(set) var transcript = ""
    @Published private(set) var audioLevel: Float = 0

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    var isAuthorized: Bool {
        SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    // MARK: - Recording

    func startRecording() async throws {
        guard isAuthorized else {
            throw SpeechServiceError.notAuthorized
        }

        // Reset state
        transcript = ""
        stopRecording()

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Set up audio file for saving
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        recordingURL = documentsPath.appendingPathComponent("\(UUID().uuidString).m4a")

        // Configure recorder settings
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()

        // Set up speech recognition
        audioEngine = AVAudioEngine()

        guard let audioEngine = audioEngine else {
            throw SpeechServiceError.noAudioInput
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true
        recognitionRequest?.addsPunctuation = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Calculate audio level
            let level = self?.calculateAudioLevel(from: buffer) ?? 0
            Task { @MainActor in
                self?.audioLevel = level
            }
        }

        // Ensure tap cleanup if engine start fails
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            // Clean up the tap we just installed to prevent memory leak
            inputNode.removeTap(onBus: 0)
            self.audioEngine = nil
            recognitionRequest = nil
            audioRecorder?.stop()
            audioRecorder = nil
            throw SpeechServiceError.recordingFailed(error)
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest!) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcript = result.bestTranscription.formattedString
                }

                if error != nil || result?.isFinal == true {
                    self?.isTranscribing = false
                }
            }
        }

        isRecording = true
        isTranscribing = true
    }

    /// The URL of the last recorded audio file (kept until cleanup is called)
    private(set) var lastRecordingURL: URL?

    func stopRecording() -> (transcript: String, audioURL: URL?)? {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)

        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioRecorder?.stop()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        isRecording = false
        isTranscribing = false
        audioLevel = 0

        // Return transcript and audio URL (file kept for upload retry)
        let finalTranscript = transcript

        // Keep the recording URL for potential retries
        lastRecordingURL = recordingURL
        recordingURL = nil

        return (finalTranscript, lastRecordingURL)
    }

    /// Clean up the recorded audio file after successful upload
    func cleanupRecording() {
        if let url = lastRecordingURL {
            try? FileManager.default.removeItem(at: url)
            lastRecordingURL = nil
        }
    }

    /// Clean up recording on failure (with optional error logging)
    func cleanupRecordingOnFailure() {
        // Keep the file for a potential manual retry, but clear our reference
        // The file will be cleaned up by the system eventually
        lastRecordingURL = nil
    }

    func cancelRecording() {
        _ = stopRecording()
        transcript = ""
    }

    // MARK: - Audio Level Calculation

    private func calculateAudioLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0 }

        let frameLength = Int(buffer.frameLength)
        var sum: Float = 0

        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }

        let average = sum / Float(frameLength)
        let db = 20 * log10(average)

        // Normalize to 0-1 range
        let normalized = (db + 80) / 80
        return max(0, min(1, normalized))
    }
}
