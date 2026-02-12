//
//  MusicLibraryManager.swift
//  portfoliopod
//
//  Apple Music Integration using MusicKit (supports streaming)
//

import Combine
import Foundation
import MusicKit
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

  struct SimpleSong: Identifiable {
    let id: String
    let title: String
    let artist: String
    let artworkURL: URL?
    let musicKitSong: Song?  // Keep reference for playback
  }

  @Published var playlists: [SimplePlaylist] = []
  @Published var allSongs: [SimpleSong] = []
  @Published var permissionStatus: MusicAuthorization.Status = .notDetermined

  // Now Playing metadata
  @Published var nowPlayingTitle: String = ""
  @Published var nowPlayingArtist: String = ""
  @Published var nowPlayingArtwork: UIImage? = nil

  // MusicKit player
  private let musicPlayer = ApplicationMusicPlayer.shared
  private var cancellables = Set<AnyCancellable>()

  private init() {
    checkPermissions()
    setupNowPlayingObservers()
  }

  func checkPermissions() {
    permissionStatus = MusicAuthorization.currentStatus
    print("MusicLibraryManager: MusicKit permission status = \(permissionStatus)")

    Task {
      let status = await MusicAuthorization.request()
      await MainActor.run {
        self.permissionStatus = status
        print("MusicLibraryManager: MusicKit authorization result = \(status)")

        if status == .authorized {
          print("MusicLibraryManager: Apple Music authorized, loading library...")
          self.refreshLibrary()
        } else {
          print("MusicLibraryManager: Apple Music not authorized - status: \(status)")
          print("  User needs to:")
          print("  1. Have an active Apple Music subscription")
          print("  2. Be signed in to Apple ID")
          print("  3. Grant permission when prompted")
        }
      }
    }
  }

  func refreshLibrary() {
    fetchPlaylists()
    fetchAllSongs()
  }

  func fetchPlaylists() {
    print("MusicLibraryManager: Fetching Apple Music playlists...")
    Task {
      do {
        var request = MusicLibraryRequest<Playlist>()
        request.limit = 50
        let response = try await request.response()

        let simplePlaylists = await withTaskGroup(of: SimplePlaylist?.self) { group in
          for playlist in response.items {
            group.addTask {
              await self.convertPlaylist(playlist)
            }
          }

          var results: [SimplePlaylist] = []
          for await result in group {
            if let playlist = result {
              results.append(playlist)
            }
          }
          return results
        }

        await MainActor.run {
          self.playlists = simplePlaylists
          print("MusicLibraryManager: Loaded \(self.playlists.count) playlists")
        }
      } catch {
        print("MusicLibraryManager: Error fetching playlists: \(error)")
      }
    }
  }

  func fetchAllSongs() {
    print("MusicLibraryManager: Fetching Apple Music library songs...")
    Task {
      do {
        var request = MusicLibraryRequest<Song>()
        request.limit = 100  // Adjust as needed
        let response = try await request.response()

        let simpleSongs = response.items.map { song in
          SimpleSong(
            id: song.id.rawValue,
            title: song.title,
            artist: song.artistName,
            artworkURL: song.artwork?.url(width: 300, height: 300),
            musicKitSong: song
          )
        }

        await MainActor.run {
          self.allSongs = simpleSongs
          print("MusicLibraryManager: Loaded \(self.allSongs.count) songs")
          if self.allSongs.isEmpty {
            print("MusicLibraryManager: No songs in library. This could mean:")
            print("  - No songs added to Apple Music library")
            print("  - Not subscribed to Apple Music")
            print("  - Library sync disabled in Settings > Music")
          }
        }
      } catch {
        print("MusicLibraryManager: Error fetching songs: \(error)")
        print("  Error details: \(error.localizedDescription)")
      }
    }
  }

  private func convertPlaylist(_ playlist: Playlist) async -> SimplePlaylist? {
    do {
      // Fetch detailed playlist with tracks
      let detailedRequest = MusicCatalogResourceRequest<Playlist>(
        matching: \.id, equalTo: playlist.id)
      let detailedResponse = try await detailedRequest.response()

      guard let detailedPlaylist = detailedResponse.items.first,
        let tracks = detailedPlaylist.tracks
      else {
        return SimplePlaylist(
          id: playlist.id.rawValue,
          name: playlist.name,
          artworkURL: playlist.artwork?.url(width: 300, height: 300),
          songs: []
        )
      }

      let songs = tracks.prefix(50).compactMap { track -> SimpleSong? in
        // Extract Song from Track enum
        guard case .song(let song) = track else { return nil }

        return SimpleSong(
          id: track.id.rawValue,
          title: track.title,
          artist: track.artistName,
          artworkURL: track.artwork?.url(width: 300, height: 300),
          musicKitSong: song
        )
      }

      return SimplePlaylist(
        id: playlist.id.rawValue,
        name: playlist.name,
        artworkURL: playlist.artwork?.url(width: 300, height: 300),
        songs: songs
      )
    } catch {
      print("MusicLibraryManager: Error loading playlist \(playlist.name): \(error)")
      return SimplePlaylist(
        id: playlist.id.rawValue,
        name: playlist.name,
        artworkURL: playlist.artwork?.url(width: 300, height: 300),
        songs: []
      )
    }
  }

  func playPlaylist(_ playlist: SimplePlaylist) {
    print("MusicLibraryManager: Playing playlist: \(playlist.name)")
    Task {
      do {
        let songs = playlist.songs.compactMap { $0.musicKitSong }
        if !songs.isEmpty {
          musicPlayer.queue = ApplicationMusicPlayer.Queue(for: songs)
          try await musicPlayer.play()
          print("MusicLibraryManager: Playback started")
        }
      } catch {
        print("MusicLibraryManager: Playback error: \(error)")
      }
    }
  }

  func playSong(_ song: SimpleSong) {
    print("MusicLibraryManager: Playing song: \(song.title)")
    Task {
      do {
        if let mkSong = song.musicKitSong {
          musicPlayer.queue = ApplicationMusicPlayer.Queue(for: [mkSong])
          try await musicPlayer.play()
          print("MusicLibraryManager: Playback started")
        }
      } catch {
        print("MusicLibraryManager: Playback error: \(error)")
      }
    }
  }

  private func setupNowPlayingObservers() {
    // Observe playback state changes
    musicPlayer.state.objectWillChange
      .sink { [weak self] _ in
        self?.updateNowPlayingMetadata()
      }
      .store(in: &cancellables)

    // Initial update
    updateNowPlayingMetadata()
  }

  private func updateNowPlayingMetadata() {
    Task {
      guard let currentEntry = musicPlayer.queue.currentEntry else {
        await MainActor.run {
          self.nowPlayingTitle = ""
          self.nowPlayingArtist = ""
          self.nowPlayingArtwork = nil
        }
        return
      }

      let title = currentEntry.title
      let artist = currentEntry.subtitle ?? ""
      var artwork: UIImage? = nil

      if let artworkURL = currentEntry.artwork?.url(width: 300, height: 300) {
        // Load artwork asynchronously
        do {
          let (data, _) = try await URLSession.shared.data(from: artworkURL)
          artwork = UIImage(data: data)
        } catch {
          print("MusicLibraryManager: Failed to load artwork: \(error)")
        }
      }

      await MainActor.run {
        self.nowPlayingTitle = title
        self.nowPlayingArtist = artist
        self.nowPlayingArtwork = artwork
      }
    }
  }

  // Compatibility computed properties for existing UI code
  var permissionStatusCompat: Int {
    switch permissionStatus {
    case .authorized: return 3  // MPMediaLibraryAuthorizationStatus.authorized
    case .denied: return 2
    case .restricted: return 1
    case .notDetermined: return 0
    @unknown default: return 0
    }
  }
}
