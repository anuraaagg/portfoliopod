import Foundation

// MARK: - Models (Copied from App)

struct iTunesSearchResponse: Codable {
  let resultCount: Int
  let results: [iTunesTrack]
}

struct iTunesTrack: Codable, Identifiable {
  let trackId: Int
  let trackName: String
  let artistName: String
  let collectionName: String?
  let artworkUrl100: String?
  let artworkUrl60: String?
  let previewUrl: String?
  let trackTimeMillis: Int?
  let releaseDate: String?
  let primaryGenreName: String?
  let collectionId: Int?

  var id: Int { trackId }
}

// MARK: - Debug Script

func runDebug() async {
  let queries = [
    "Arijit Singh", "Taylor Swift", "The Weeknd", "A.R. Rahman", "Shreya Ghoshal", "Ed Sheeran",
  ]

  for query in queries {
    print("\n--- Testing query: \(query) ---")
    let urlString =
      "https://itunes.apple.com/search?term=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)&media=music&entity=song&limit=50"

    guard let url = URL(string: urlString) else {
      print("Invalid URL")
      continue
    }

    do {
      let (data, response) = try await URLSession.shared.data(from: url)

      if let httpResponse = response as? HTTPURLResponse {
        print("Status Code: \(httpResponse.statusCode)")
      }

      do {
        let decoder = JSONDecoder()
        let result = try decoder.decode(iTunesSearchResponse.self, from: data)
        print("Successfully decoded \(result.results.count) tracks")

        // Print specific track details for inspection (first 3)
        for track in result.results.prefix(3) {
          print("  - \(track.trackName) by \(track.artistName) (ID: \(track.trackId))")
        }

      } catch let decodingError as DecodingError {
        print("Decoding Failed:")
        switch decodingError {
        case .keyNotFound(let key, let context):
          print("  Missing Key: \(key.stringValue)")
          print("  Context: \(context.debugDescription)")
          print("  Path: \(context.codingPath)")
        case .valueNotFound(let type, let context):
          print("  Value Not Found: \(type)")
          print("  Context: \(context.debugDescription)")
          print("  Path: \(context.codingPath)")
        case .typeMismatch(let type, let context):
          print("  Type Mismatch: Expected \(type)")
          print("  Context: \(context.debugDescription)")
          print("  Path: \(context.codingPath)")
        case .dataCorrupted(let context):
          print("  Data Corrupted: \(context.debugDescription)")
          print("  Path: \(context.codingPath)")
        @unknown default:
          print("  Unknown Decoding Error")
        }

        // Print raw JSON snippet around failure if possible (hard to pinpoint exact location without stream parser)
        if let jsonString = String(data: data, encoding: .utf8) {
          // print("  Raw JSON (truncated): \(jsonString.prefix(500))")
        }

      } catch {
        print("General Error: \(error)")
      }

    } catch {
      print("Network Error: \(error)")
    }
  }
}

// Run the async function
let semaphore = DispatchSemaphore(value: 0)
Task {
  await runDebug()
  semaphore.signal()
}
semaphore.wait()
