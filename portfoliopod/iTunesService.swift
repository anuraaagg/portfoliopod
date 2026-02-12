//
//  iTunesService.swift
//  portfoliopod
//
//  Service for iTunes Search API
//

import Foundation

class iTunesService {

    static let shared = iTunesService()

    private let baseURL = "https://itunes.apple.com/search"

    private init() {}

    // MARK: - Search Songs

    func searchSongs(query: String, limit: Int = 50) async throws -> [iTunesTrack] {
        guard !query.isEmpty else { return [] }

        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "term", value: query),
            URLQueryItem(name: "media", value: "music"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else {
            print("iTunesService: Invalid URL")
            return []
        }

        print("iTunesService: Searching for '\(query)'...")

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            print("iTunesService: Bad response")
            return []
        }

        let searchResponse = try JSONDecoder().decode(iTunesSearchResponse.self, from: data)

        print("iTunesService: Found \(searchResponse.results.count) tracks")

        return searchResponse.results
    }

    // MARK: - Get Top Songs by Artist

    func getTopSongs(artist: String, limit: Int = 25) async throws -> [iTunesTrack] {
        return try await searchSongs(query: artist, limit: limit)
    }

    // MARK: - Popular Searches (Curated)

    func getPopularSongs() async throws -> [iTunesTrack] {
        // Mix of popular artists for demo purposes
        let artists = ["Arijit Singh", "The Weeknd", "Taylor Swift", "Drake", "Ed Sheeran"]
        let randomArtist = artists.randomElement() ?? "Arijit Singh"
        return try await searchSongs(query: randomArtist, limit: 25)
    }

    // MARK: - Curated Playlists

    func getCuratedPlaylist(name: String, searchTerms: [String]) async throws -> [iTunesTrack] {
        var allTracks: [iTunesTrack] = []

        for term in searchTerms.prefix(3) {  // Limit to 3 searches to avoid rate limiting
            let tracks = try await searchSongs(query: term, limit: 10)
            allTracks.append(contentsOf: tracks)
        }

        return allTracks
    }
}
