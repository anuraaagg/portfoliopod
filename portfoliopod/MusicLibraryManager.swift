//
//  MusicLibraryManager.swift
//  portfoliopod
//
//  Music library using iTunes Search API (free, no auth required)
//

import Combine
import Foundation
import UIKit

class MusicLibraryManager: ObservableObject {
  static let shared = MusicLibraryManager()

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

  // Reference to audio player
  private let audioPlayer = AudioPlayerManager.shared
  private let iTunesService = iTunesService.shared

  // Auth status (simplified for iTunes - no auth needed)
  enum AuthStatus {
    case authorized
    case notDetermined
    case denied
  }

  private init() {
    print("MusicLibraryManager: Initialized with iTunes Search API")
    loadCuratedContent()
  }

  // MARK: - Load Curated Content

  func loadCuratedContent() {
    print("MusicLibraryManager: Loading curated content...")
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
          self.allSongs = Array((popular.songs + indian.songs + western.songs).prefix(100))
          self.isLoading = false
          print("MusicLibraryManager: Loaded \(self.playlists.count) playlists, \(self.allSongs.count) songs")
        }
      } catch {
        print("MusicLibraryManager: Error loading content: \(error)")
        await MainActor.run {
          self.isLoading = false
        }
      }
    }
  }

  private func loadPopularSongs() async throws -> SimplePlaylist {
    let tracks = try await iTunesService.getPopularSongs()
    return SimplePlaylist(
      id: "popular",
      name: "Popular Songs",
      artworkURL: URL(string: tracks.first?.artworkUrl300 ?? ""),
      songs: tracks.asSimpleSongs
    )
  }

  private func loadIndianHits() async throws -> SimplePlaylist {
    let searchTerms = ["Arijit Singh", "A.R. Rahman", "Shreya Ghoshal"]
    let tracks = try await iTunesService.getCuratedPlaylist(
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
    let tracks = try await iTunesService.getCuratedPlaylist(
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
    guard !query.isEmpty else { return }

    isLoading = true

    Task {
      do {
        let tracks = try await iTunesService.searchSongs(query: query, limit: 50)

        await MainActor.run {
          self.allSongs = tracks.asSimpleSongs
          self.isLoading = false
          print("MusicLibraryManager: Search returned \(self.allSongs.count) results")
        }
      } catch {
        print("MusicLibraryManager: Search error: \(error)")
        await MainActor.run {
          self.isLoading = false
        }
      }
    }
  }

  // MARK: - Playback

  func playPlaylist(_ playlist: SimplePlaylist) {
    guard let firstSong = playlist.songs.first else {
      print("MusicLibraryManager: Playlist is empty")
      return
    }
    playSong(firstSong)
  }

  func playSong(_ song: SimpleSong) {
    print("MusicLibraryManager: Playing '\(song.title)' by \(song.artist)")
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
    print("MusicLibraryManager: No permissions required for iTunes API")
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
