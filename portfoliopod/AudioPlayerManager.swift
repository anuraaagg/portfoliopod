//
//  AudioPlayerManager.swift
//  portfoliopod
//
//  AVPlayer-based audio playback for iTunes previews
//

import AVFoundation
import Combine
import SwiftUI

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()

    // Player state
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 30  // iTunes previews are ~30s
    @Published var nowPlayingTitle: String = ""
    @Published var nowPlayingArtist: String = ""
    @Published var nowPlayingArtwork: UIImage? = nil
    @Published var nowPlayingArtworkURL: URL? = nil

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        setupAudioSession()
    }

    deinit {
        removeTimeObserver()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("AudioPlayer: Audio session configured")
        } catch {
            print("AudioPlayer: Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Playback Control

    func play(song: MusicLibraryManager.SimpleSong) {
        guard let previewURL = song.previewURL else {
            print("AudioPlayer: No preview URL for \(song.title)")
            return
        }

        print("AudioPlayer: Playing \(song.title) by \(song.artist)")

        // Update metadata
        nowPlayingTitle = song.title
        nowPlayingArtist = song.artist
        nowPlayingArtworkURL = song.artworkURL

        // Load artwork
        if let artworkURL = song.artworkURL {
            loadArtwork(from: artworkURL)
        } else {
            nowPlayingArtwork = nil
        }

        // Create player
        let playerItem = AVPlayerItem(url: previewURL)
        player = AVPlayer(playerItem: playerItem)

        // Setup time observer
        setupTimeObserver()

        // Play
        player?.play()
        isPlaying = true

        // Observe end of track
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.handlePlaybackEnd()
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
        print("AudioPlayer: Paused")
    }

    func resume() {
        player?.play()
        isPlaying = true
        print("AudioPlayer: Resumed")
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    func stop() {
        player?.pause()
        player = nil
        removeTimeObserver()
        isPlaying = false
        currentTime = 0
        print("AudioPlayer: Stopped")
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }

    // MARK: - Time Observation

    private func setupTimeObserver() {
        removeTimeObserver()

        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds

            // Update duration if available
            if let duration = self.player?.currentItem?.duration.seconds,
               duration.isFinite {
                self.duration = duration
            }
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    private func handlePlaybackEnd() {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.currentTime = 0
            print("AudioPlayer: Playback ended")
        }
    }

    // MARK: - Artwork Loading

    private func loadArtwork(from url: URL) {
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.nowPlayingArtwork = image
                    }
                }
            } catch {
                print("AudioPlayer: Failed to load artwork: \(error)")
                await MainActor.run {
                    self.nowPlayingArtwork = nil
                }
            }
        }
    }

    // MARK: - Helper Computed Properties

    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var currentTimeFormatted: String {
        formatTime(currentTime)
    }

    var durationFormatted: String {
        formatTime(duration)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
