import SwiftUI
import AVKit
import Photos

struct VideoPlayerView: View {
    let url: URL

    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var isSaving = false
    @State private var showSaveSuccess = false
    @State private var error: Error?
    @State private var showError = false
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let player = player {
                // Use native VideoPlayer with built-in controls
                VideoPlayer(player: player)
                    .ignoresSafeArea()
            }

            // Loading overlay
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text("Loading video...")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.7))
            }

            // Top bar overlay
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 60)

                    Spacer()

                    HStack(spacing: 16) {
                        Button {
                            saveToPhotos()
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.5), radius: 4)
                            }
                        }
                        .disabled(isSaving)

                        Button {
                            shareVideo()
                        } label: {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.5), radius: 4)
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                }

                Spacer()
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .alert("Saved!", isPresented: $showSaveSuccess) {
            Button("OK") { }
        } message: {
            Text("Your dream video has been saved to your photo library.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(error?.localizedDescription ?? "An error occurred")
        }
    }

    // MARK: - Player Setup

    private func setupPlayer() {
        print("VideoPlayerView: Setting up player with URL: \(url)")

        let playerItem = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: playerItem)
        self.player = player

        // Wait for video to be ready
        Task { @MainActor in
            var attempts = 0
            while attempts < 50 { // 5 second timeout
                let status = playerItem.status
                print("VideoPlayerView: Status check \(attempts): \(status.rawValue)")

                if status == .readyToPlay {
                    print("VideoPlayerView: Ready, starting playback")
                    player.play()
                    isLoading = false
                    return
                } else if status == .failed {
                    print("VideoPlayerView: Failed: \(playerItem.error?.localizedDescription ?? "unknown")")
                    self.error = playerItem.error
                    self.showError = true
                    isLoading = false
                    return
                }

                try? await Task.sleep(nanoseconds: 100_000_000)
                attempts += 1
            }

            print("VideoPlayerView: Timeout, playing anyway")
            player.play()
            isLoading = false
        }

        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
    }

    // MARK: - Save to Photos

    private func saveToPhotos() {
        Task {
            isSaving = true
            defer { isSaving = false }

            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized else {
                error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Photo library access denied"])
                showError = true
                return
            }

            do {
                let localURL = try await VideoService.shared.downloadVideo(from: url)
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: localURL)
                }
                try? FileManager.default.removeItem(at: localURL)
                showSaveSuccess = true
            } catch {
                self.error = error
                self.showError = true
            }
        }
    }

    // MARK: - Share

    private func shareVideo() {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

#Preview {
    VideoPlayerView(url: URL(string: "https://example.com/video.mp4")!)
}
