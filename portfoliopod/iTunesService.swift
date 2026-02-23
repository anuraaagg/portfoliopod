//
//  iTunesService.swift
//  portfoliopod
//
//  Service for iTunes Search API
//

import Foundation
import os

class iTunesService {

  static let shared = iTunesService()
  private let logger = Logger(subsystem: "com.anuragsingh.portfoliopod", category: "iTunesService")

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
      URLQueryItem(name: "limit", value: String(limit)),
    ]

    guard let url = components.url else {
      logger.error("Invalid URL")
      return []
    }

    logger.info("Searching for '\(query)'...")
    logger.debug("URL = \(url.absoluteString)")

    do {
      let (data, response) = try await URLSession.shared.data(from: url)

      guard let httpResponse = response as? HTTPURLResponse else {
        logger.error("Invalid response type")
        return []
      }

      logger.debug("HTTP Status = \(httpResponse.statusCode)")

      guard httpResponse.statusCode == 200 else {
        logger.error("Bad status code: \(httpResponse.statusCode)")
        if let responseString = String(data: data, encoding: .utf8) {
          logger.debug("Response body: \(responseString.prefix(500))")
        }
        return []
      }

      let searchResponse = try JSONDecoder().decode(iTunesSearchResponse.self, from: data)

      logger.info("Found \(searchResponse.results.count) tracks")
      if let firstTrack = searchResponse.results.first {
        logger.debug("Sample track: \(firstTrack.trackName) by \(firstTrack.artistName)")
        logger.debug("Preview URL: \(firstTrack.previewUrl ?? "nil")")
      }

      return searchResponse.results
    } catch let decodingError as DecodingError {
      logger.error("Decoding error: \(decodingError.localizedDescription)")
      switch decodingError {
      case .keyNotFound(let key, let context):
        logger.error("  Missing key: \(key.stringValue)")
        logger.error("  Context: \(context.debugDescription)")
      case .typeMismatch(let type, let context):
        logger.error("  Type mismatch: expected \(type)")
        logger.error("  Context: \(context.debugDescription)")
      case .valueNotFound(let type, let context):
        logger.error("  Value not found: \(type)")
        logger.error("  Context: \(context.debugDescription)")
      case .dataCorrupted(let context):
        logger.error("  Data corrupted: \(context.debugDescription)")
      @unknown default:
        logger.error("  Unknown decoding error")
      }
      return []
    } catch {
      logger.error("Error: \(error.localizedDescription)")
      return []
    }
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
