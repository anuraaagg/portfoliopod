//
//  MusicLibraryManager.swift
//  portfoliopod
//
//  Music library using iTunes Search API (free, no auth required)
//

import Combine
import Foundation
import UIKit
import os

class MusicLibraryManager: ObservableObject {
  static let shared = MusicLibraryManager()
  private let logger = Logger(
    subsystem: "com.anuragsingh.portfoliopod", category: "MusicLibraryManager")

  // Auth status (simplified for iTunes - no auth needed)
  enum AuthStatus {
    case authorized
    case notDetermined
    case denied
  }

  // Simplified data models for UI compatibility
  struct SimplePlaylist: Identifiable {
    let id: String
    let name: String
    let artworkURL: URL?
    let songs: [SimpleSong]
  }

  struct SimpleSong: Identifiable, Equatable {
    let id: String
    let title: String
    let artist: String
    let album: String
    let artworkURL: URL?
    let previewURL: URL?
    let durationSeconds: Int

    static func == (lhs: SimpleSong, rhs: SimpleSong) -> Bool {
      lhs.id == rhs.id
    }
  }

  @Published var playlists: [SimplePlaylist] = []
  @Published var allSongs: [SimpleSong] = []
  @Published var permissionStatus: AuthStatus = .authorized  // Always authorized for iTunes API
  @Published var isLoading: Bool = false
  @Published var isInSearchMode: Bool = false
  @Published private(set) var curatedSongs: [SimpleSong] = []

  // Reference to audio player
  private lazy var audioPlayer: AudioPlayerManager = AudioPlayerManager.shared
  private lazy var itunesService: iTunesService = iTunesService.shared

  private init() {
    logger.info("Initialized with iTunes Search API")
    loadCuratedContent()
  }

  // MARK: - Load Curated Content

  func loadCuratedContent() {
    logger.info("Loading curated content...")
    isLoading = true

    Task {
      do {
        // Load curated playlists
        async let popularSongs = loadPopularSongs()
        async let indianHits = loadIndianHits()
        async let westernHits = loadWesternHits()

        let (popular, indian, western) = try await (popularSongs, indianHits, westernHits)

        await MainActor.run {
          self.playlists = [popular, indian, western]
          let combined = Array((popular.songs + indian.songs + western.songs).prefix(100))
          self.curatedSongs = combined
          if !self.isInSearchMode {
            self.allSongs = combined
          }
          self.isLoading = false
          logger.info("Loaded \(self.playlists.count) playlists, \(self.allSongs.count) songs")
        }
      } catch {
        logger.error("Error loading content: \(error.localizedDescription)")
        await MainActor.run {
          self.isLoading = false
        }
      }
    }
  }

  private func loadPopularSongs() async throws -> SimplePlaylist {
    let tracks = try await itunesService.getPopularSongs()
    return SimplePlaylist(
      id: "popular",
      name: "Popular Songs",
      artworkURL: URL(string: tracks.first?.artworkUrl300 ?? ""),
      songs: tracks.asSimpleSongs
    )
  }

  private func loadIndianHits() async throws -> SimplePlaylist {
    let searchTerms = ["Arijit Singh", "A.R. Rahman", "Shreya Ghoshal"]
    let tracks = try await itunesService.getCuratedPlaylist(
      name: "Indian Hits",
      searchTerms: searchTerms
    )
    return SimplePlaylist(
      id: "indian",
      name: "Indian Hits",
      artworkURL: URL(string: tracks.first?.artworkUrl300 ?? ""),
      songs: tracks.asSimpleSongs
    )
  }

  private func loadWesternHits() async throws -> SimplePlaylist {
    let searchTerms = ["The Weeknd", "Taylor Swift", "Ed Sheeran"]
    let tracks = try await itunesService.getCuratedPlaylist(
      name: "Western Hits",
      searchTerms: searchTerms
    )
    return SimplePlaylist(
      id: "western",
      name: "Western Hits",
      artworkURL: URL(string: tracks.first?.artworkUrl300 ?? ""),
      songs: tracks.asSimpleSongs
    )
  }

  // MARK: - Search

  func search(query: String) {
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      // Exit search mode and restore curated content
      isInSearchMode = false
      allSongs = curatedSongs
      return
    }
    isInSearchMode = true
    isLoading = true

    Task {
      do {
        let tracks = try await itunesService.searchSongs(query: trimmed, limit: 50)

        await MainActor.run {
          self.allSongs = tracks.asSimpleSongs
          self.isInSearchMode = true
          self.isLoading = false
          logger.info("Search returned \(self.allSongs.count) results")
        }
      } catch {
        logger.error("Search error: \(error.localizedDescription)")
        await MainActor.run {
          self.isLoading = false
        }
      }
    }
  }

  // MARK: - Playback

  func openPlaylist(_ playlist: SimplePlaylist) {
    logger.info("Opening playlist: \(playlist.name)")
    allSongs = playlist.songs
  }

  func playPlaylist(_ playlist: SimplePlaylist) {
    guard let firstSong = playlist.songs.first else {
      logger.warning("Playlist is empty")
      return
    }
    playSong(firstSong)
  }

  func playSong(_ song: SimpleSong) {
    logger.info("Playing '\(song.title)' by \(song.artist)")
    audioPlayer.play(song: song)
  }

  func togglePlayPause() {
    audioPlayer.togglePlayPause()
  }

  func pausePlayback() {
    audioPlayer.pause()
  }

  func stopPlayback() {
    audioPlayer.stop()
  }

  // MARK: - Legacy Compatibility

  func checkPermissions() {
    // No permissions needed for iTunes API
    logger.info("No permissions required for iTunes API")
    permissionStatus = .authorized
  }

  func refreshLibrary() {
    loadCuratedContent()
  }

  // Compatibility computed property for old UI code
  var permissionStatusCompat: Int {
    switch permissionStatus {
    case .authorized: return 3
    case .denied: return 2
    case .notDetermined: return 0
    }
  }
}
