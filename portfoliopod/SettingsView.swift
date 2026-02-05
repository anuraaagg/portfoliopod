import Combine
import SwiftUI

class SettingsStore: ObservableObject {
  @Published var hapticIntensity: Double {
    didSet { UserDefaults.standard.set(hapticIntensity, forKey: "hapticIntensity") }
  }
  @Published var clickVolume: Double {
    didSet { UserDefaults.standard.set(clickVolume, forKey: "clickVolume") }
  }
  @Published var themeIndex: Int {
    didSet { UserDefaults.standard.set(themeIndex, forKey: "themeIndex") }
  }

  @Published var selectedWallpaperID: String {
    didSet { UserDefaults.standard.set(selectedWallpaperID, forKey: "selectedWallpaperID") }
  }

  @Published var refreshFlag: Bool = false

  init() {
    self.hapticIntensity =
      UserDefaults.standard.double(forKey: "hapticIntensity") == 0
      ? 0.5 : UserDefaults.standard.double(forKey: "hapticIntensity")
    self.clickVolume =
      UserDefaults.standard.double(forKey: "clickVolume") == 0
      ? 0.8 : UserDefaults.standard.double(forKey: "clickVolume")
    self.themeIndex = UserDefaults.standard.integer(forKey: "themeIndex")
    self.selectedWallpaperID =
      UserDefaults.standard.string(forKey: "selectedWallpaperID") ?? "global-art"

    // Load wallpapers from UserDefaults or use defaults
    if let data = UserDefaults.standard.data(forKey: "availableWallpapers"),
      let decoded = try? JSONDecoder().decode([Wallpaper].self, from: data)
    {
      self.availableWallpapers = decoded
    } else {
      self.availableWallpapers = Self.defaultWallpapers()
      saveWallpapers()
    }
  }

  // Save wallpapers to UserDefaults
  private func saveWallpapers() {
    if let encoded = try? JSONEncoder().encode(availableWallpapers) {
      UserDefaults.standard.set(encoded, forKey: "availableWallpapers")
    }
  }

  // Default wallpapers
  private static func defaultWallpapers() -> [Wallpaper] {
    return [
      Wallpaper(
        id: "global-art", name: "Global", type: .image,
        colors: [], imageName: "startup_wallpaper", thumbnailName: nil, isUserAdded: false),
      Wallpaper(
        id: "silver-gradient", name: "Silver Studio", type: .gradient,
        colors: [
          CodableColor(color: Color(white: 0.98)),
          CodableColor(color: Color(white: 0.82)),
        ], imageName: nil, thumbnailName: nil, isUserAdded: false),
      Wallpaper(
        id: "midnight-blue", name: "Midnight", type: .gradient,
        colors: [
          CodableColor(color: Color(red: 0.05, green: 0.05, blue: 0.15)),
          CodableColor(color: Color(red: 0.1, green: 0.1, blue: 0.3)),
        ],
        imageName: nil, thumbnailName: nil, isUserAdded: false),
      Wallpaper(
        id: "sunset-vibes", name: "Sunset", type: .gradient,
        colors: [
          CodableColor(color: Color.orange.opacity(0.8)),
          CodableColor(color: Color.purple.opacity(0.8)),
        ], imageName: nil, thumbnailName: nil, isUserAdded: false),
      Wallpaper(
        id: "deep-forest", name: "Forest", type: .gradient,
        colors: [
          CodableColor(color: Color(red: 0.1, green: 0.3, blue: 0.15)),
          CodableColor(color: Color(red: 0.05, green: 0.2, blue: 0.1)),
        ],
        imageName: nil, thumbnailName: nil, isUserAdded: false),
      Wallpaper(
        id: "minimal-dark", name: "Dark Mode", type: .gradient,
        colors: [
          CodableColor(color: Color(white: 0.15)),
          CodableColor(color: Color(white: 0.05)),
        ], imageName: nil, thumbnailName: nil, isUserAdded: false),
    ]
  }

  enum Theme: Int {
    case industrial = 0
    case classic = 1

    var accentColor: Color {
      switch self {
      case .industrial: return .red
      case .classic: return Color(red: 0.2, green: 0.6, blue: 0.9)  // Authentic iPod Blue
      }
    }
  }

  var theme: Theme {
    Theme(rawValue: themeIndex) ?? .industrial
  }

  // MARK: - Wallpaper Data
  struct Wallpaper: Identifiable, Codable {
    let id: String
    let name: String
    let type: WallpaperType
    let colors: [CodableColor]
    let imageName: String?
    let thumbnailName: String?
    let isUserAdded: Bool

    // Convenience computed property for SwiftUI Colors
    var swiftUIColors: [Color] {
      colors.map { $0.color }
    }
  }

  enum WallpaperType: Codable {
    case gradient
    case image
  }

  // Helper struct to make Color Codable
  struct CodableColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    var color: Color {
      Color(red: red, green: green, blue: blue, opacity: opacity)
    }

    init(color: Color) {
      // Extract color components using UIColor
      let uiColor = UIColor(color)
      var r: CGFloat = 0
      var g: CGFloat = 0
      var b: CGFloat = 0
      var a: CGFloat = 0
      uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
      self.red = Double(r)
      self.green = Double(g)
      self.blue = Double(b)
      self.opacity = Double(a)
    }
  }

  @Published var availableWallpapers: [Wallpaper] = []

  func addUserWallpaper(image: UIImage) -> Bool {
    // 1. Generate unique file name
    let filename = UUID().uuidString + ".jpg"
    let thumbFilename = UUID().uuidString + "_thumb.jpg"

    // 2. Create thumbnail (300x650 for preview)
    let thumbnailSize = CGSize(width: 300, height: 650)
    let thumbnail = createThumbnail(image: image, size: thumbnailSize)

    // 3. Save both images to documents directory
    guard let data = image.jpegData(compressionQuality: 0.8),
      let thumbData = thumbnail.jpegData(compressionQuality: 0.7),
      let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        .first
    else {
      print("Error: Failed to prepare image data")
      return false
    }

    let fileURL = documentsDir.appendingPathComponent(filename)
    let thumbURL = documentsDir.appendingPathComponent(thumbFilename)

    do {
      try data.write(to: fileURL)
      try thumbData.write(to: thumbURL)
    } catch {
      print("Error: Failed to save image - \(error.localizedDescription)")
      return false
    }

    // 4. Create new Wallpaper model
    let newWallpaper = Wallpaper(
      id: filename,  // ID is filename for user photos
      name: "Custom Photo",
      type: .image,
      colors: [],
      imageName: filename,  // Store filename here
      thumbnailName: thumbFilename,  // Store thumbnail filename
      isUserAdded: true
    )

    // 5. Append to available wallpapers and persist
    DispatchQueue.main.async {
      self.availableWallpapers.insert(newWallpaper, at: 0)  // Add to front
      self.selectedWallpaperID = newWallpaper.id
      self.saveWallpapers()
    }

    return true
  }

  private func createThumbnail(image: UIImage, size: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: size))
    }
  }

  func deleteWallpaper(id: String) {
    guard let wallpaper = availableWallpapers.first(where: { $0.id == id }),
      wallpaper.isUserAdded
    else {
      return  // Can't delete non-user wallpapers
    }

    // Delete image files
    if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      .first
    {
      if let imageName = wallpaper.imageName {
        let fileURL = documentsDir.appendingPathComponent(imageName)
        try? FileManager.default.removeItem(at: fileURL)
      }
      if let thumbName = wallpaper.thumbnailName {
        let thumbURL = documentsDir.appendingPathComponent(thumbName)
        try? FileManager.default.removeItem(at: thumbURL)
      }
    }

    // Remove from array
    availableWallpapers.removeAll { $0.id == id }

    // If this was the selected wallpaper, select the first one
    if selectedWallpaperID == id {
      selectedWallpaperID = availableWallpapers.first?.id ?? "global-art"
    }

    saveWallpapers()
  }

  var currentWallpaper: Wallpaper {
    availableWallpapers.first(where: { $0.id == selectedWallpaperID }) ?? availableWallpapers[0]
  }

  static let shared = SettingsStore()
}

struct SettingsView: View {
  let type: SettingType
  @ObservedObject var settings = SettingsStore.shared

  enum SettingType {
    case haptics
    case clicker
    case legal
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 30) {
      Text("[ SETTINGS :: \(title.uppercased()) ]")
        .font(.system(size: 14, weight: .bold, design: .monospaced))
        .foregroundColor(.red)

      switch type {
      case .haptics:
        VStack(alignment: .leading, spacing: 10) {
          Text("INTENSITY: \(Int(settings.hapticIntensity * 100))%")
            .font(.system(size: 12, design: .monospaced))

          Slider(value: $settings.hapticIntensity, in: 0...1)
            .accentColor(.red)
            .allowsHitTesting(false)  // Disable touch per user request
        }

      case .clicker:
        VStack(alignment: .leading, spacing: 10) {
          Text("VOLUME: \(Int(settings.clickVolume * 100))%")
            .font(.system(size: 12, design: .monospaced))

          Slider(value: $settings.clickVolume, in: 0...1)
            .accentColor(.red)
            .allowsHitTesting(false)  // Disable touch per user request
        }

      case .legal:
        VStack(alignment: .leading, spacing: 30) {
          // Theme Picker
          VStack(alignment: .leading, spacing: 10) {
            Text("AESTHETIC:")
              .font(.system(size: 10, design: .monospaced))

            Picker("Theme", selection: $settings.themeIndex) {
              Text("INDUSTRIAL").tag(0)
              Text("CLASSIC").tag(1)
            }
            .pickerStyle(.segmented)
            .scaleEffect(0.9)
            .frame(width: 200)
          }

          Divider()

          ScrollView {
            VStack(alignment: .leading, spacing: 15) {
              Text("LEGAL NOTICE")
                .font(.system(size: 12, weight: .bold, design: .monospaced))

              Text(
                "This software is a creative experiment and is not affiliated with Apple Inc. All iPod trademarks and designs are the property of their respective owners.\n\nBuilt for exploration and portfolio demonstration."
              )
              .font(.system(size: 11, design: .monospaced))
              .foregroundColor(.gray)

              Text("VERSION 1.0.4\nBUILD: BRUTALIST_01")
                .font(.system(size: 10, design: .monospaced))
            }
          }
        }
      }

      Spacer()
    }
    .padding(20)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .background(Color.white)
  }

  private var title: String {
    switch type {
    case .haptics: return "Haptics"
    case .clicker: return "Clicker"
    case .legal: return "About"
    }
  }
}
