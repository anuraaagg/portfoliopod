//
//  MusicLibraryManager.swift
//  portfoliopod
//
//  Phase 5: Apple Music / iTunes Integration
//

import Combine
import Foundation
import MediaPlayer

class MusicLibraryManager: ObservableObject {
  static let shared = MusicLibraryManager()

  @Published var playlists: [MPMediaItemCollection] = []
  @Published var permissionStatus: MPMediaLibraryAuthorizationStatus = .notDetermined

  private init() {
    checkPermissions()
  }

  func checkPermissions() {
    permissionStatus = MPMediaLibrary.authorizationStatus()
    if permissionStatus == .notDetermined {
      MPMediaLibrary.requestAuthorization { [weak self] status in
        DispatchQueue.main.async {
          self?.permissionStatus = status
          if status == .authorized {
            self?.fetchPlaylists()
          }
        }
      }
    } else if permissionStatus == .authorized {
      fetchPlaylists()
    }
  }

  func fetchPlaylists() {
    let query = MPMediaQuery.playlists()
    if let collections = query.collections {
      self.playlists = collections
    }
  }

  func playPlaylist(_ playlist: MPMediaItemCollection) {
    let musicPlayer = MPMusicPlayerController.systemMusicPlayer
    musicPlayer.setQueue(with: playlist)
    musicPlayer.play()
  }
}
