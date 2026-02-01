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

  @Published var refreshFlag: Bool = false

  init() {
    self.hapticIntensity =
      UserDefaults.standard.double(forKey: "hapticIntensity") == 0
      ? 0.5 : UserDefaults.standard.double(forKey: "hapticIntensity")
    self.clickVolume =
      UserDefaults.standard.double(forKey: "clickVolume") == 0
      ? 0.8 : UserDefaults.standard.double(forKey: "clickVolume")
    self.themeIndex = UserDefaults.standard.integer(forKey: "themeIndex")
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
        }

      case .clicker:
        VStack(alignment: .leading, spacing: 10) {
          Text("VOLUME: \(Int(settings.clickVolume * 100))%")
            .font(.system(size: 12, design: .monospaced))

          Slider(value: $settings.clickVolume, in: 0...1)
            .accentColor(.red)
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
