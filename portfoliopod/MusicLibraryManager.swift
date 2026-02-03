//
//  MusicLibraryManager.swift
//  portfoliopod
//
//  Phase 5: Apple Music / iTunes Integration
//

import Combine
import Foundation
import MediaPlayer
import UIKit

class MusicLibraryManager: ObservableObject {
  static let shared = MusicLibraryManager()

  @Published var playlists: [MPMediaPlaylist] = []
  @Published var allSongs: [MPMediaItem] = []
  @Published var permissionStatus: MPMediaLibraryAuthorizationStatus = .notDetermined

  // Now Playing metadata
  @Published var nowPlayingTitle: String = ""
  @Published var nowPlayingArtist: String = ""
  @Published var nowPlayingArtwork: UIImage? = nil

  private let player = MPMusicPlayerController.systemMusicPlayer

  private init() {
    checkPermissions()
    setupNowPlayingObservers()
  }

  func checkPermissions() {
    permissionStatus = MPMediaLibrary.authorizationStatus()
    if permissionStatus == .notDetermined {
      MPMediaLibrary.requestAuthorization { [weak self] status in
        DispatchQueue.main.async {
          self?.permissionStatus = status
          if status == .authorized {
            self?.refreshLibrary()
          }
        }
      }
    } else if permissionStatus == .authorized {
      refreshLibrary()
    }
  }

  func refreshLibrary() {
    fetchPlaylists()
    fetchAllSongs()
  }

  func fetchPlaylists() {
    DispatchQueue.global(qos: .userInitiated).async {
      let query = MPMediaQuery.playlists()
      let collections = (query.collections as? [MPMediaPlaylist]) ?? []
      DispatchQueue.main.async {
        self.playlists = collections
      }
    }
  }

  func fetchAllSongs() {
    DispatchQueue.global(qos: .userInitiated).async {
      let query = MPMediaQuery.songs()
      let items = query.items ?? []
      DispatchQueue.main.async {
        self.allSongs = items
      }
    }
  }

  func playPlaylist(_ playlist: MPMediaPlaylist) {
    let collection = MPMediaItemCollection(items: playlist.items)
    player.setQueue(with: collection)
    player.play()
  }

  func playSong(_ item: MPMediaItem) {
    let collection = MPMediaItemCollection(items: [item])
    player.setQueue(with: collection)
    player.play()
  }

  private func setupNowPlayingObservers() {
    NotificationCenter.default.addObserver(
      self, selector: #selector(handleNowPlayingChanged),
      name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player)
    NotificationCenter.default.addObserver(
      self, selector: #selector(handlePlaybackStateChanged),
      name: .MPMusicPlayerControllerPlaybackStateDidChange, object: player)
    player.beginGeneratingPlaybackNotifications()
    updateNowPlayingMetadata()
  }

  @objc private func handleNowPlayingChanged() {
    updateNowPlayingMetadata()
  }

  @objc private func handlePlaybackStateChanged() {
    updateNowPlayingMetadata()
  }

  private func updateNowPlayingMetadata() {
    let item = player.nowPlayingItem
    let title = item?.title ?? ""
    let artist = item?.artist ?? ""
    var art: UIImage? = nil
    if let artwork = item?.artwork {
      let size = CGSize(width: 300, height: 300)
      art = artwork.image(at: size)
    }
    DispatchQueue.main.async {
      self.nowPlayingTitle = title
      self.nowPlayingArtist = artist
      self.nowPlayingArtwork = art
    }
  }
}
