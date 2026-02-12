//
//  iTunesModels.swift
//  portfoliopod
//
//  iTunes Search API models
//

import Foundation

// MARK: - iTunes Search Response

struct iTunesSearchResponse: Codable {
    let resultCount: Int
    let results: [iTunesTrack]
}

// MARK: - iTunes Track

struct iTunesTrack: Codable, Identifiable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let collectionName: String?
    let artworkUrl100: String
    let artworkUrl60: String?
    let previewUrl: String
    let trackTimeMillis: Int?
    let releaseDate: String?
    let primaryGenreName: String?
    let collectionId: Int?

    var id: Int { trackId }

    // Computed properties for easier use
    var artworkUrl300: String {
        artworkUrl100.replacingOccurrences(of: "100x100", with: "300x300")
    }

    var durationSeconds: Int {
        guard let millis = trackTimeMillis else { return 30 }
        return millis / 1000
    }
}

// MARK: - Simplified models for UI compatibility

extension iTunesTrack {
    var asSimpleSong: MusicLibraryManager.SimpleSong {
        MusicLibraryManager.SimpleSong(
            id: String(trackId),
            title: trackName,
            artist: artistName,
            album: collectionName ?? "",
            artworkURL: URL(string: artworkUrl300),
            previewURL: URL(string: previewUrl),
            durationSeconds: durationSeconds
        )
    }
}

extension Array where Element == iTunesTrack {
    var asSimpleSongs: [MusicLibraryManager.SimpleSong] {
        self.map { $0.asSimpleSong }
    }
}
