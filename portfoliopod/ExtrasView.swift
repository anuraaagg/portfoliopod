import Combine
import SwiftUI
import WebKit

struct ClockView: View {
  @State private var currentTime = Date()
  let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

  var body: some View {
    VStack(spacing: 20) {
      Text("[ SYSTEM TIME ]")
        .font(.system(size: 14, weight: .bold, design: .monospaced))
        .foregroundColor(.red)

      Text(timeFormatter.string(from: currentTime))
        .font(.system(size: 48, weight: .black, design: .monospaced))
        .foregroundColor(.black)
        .padding()
        .background(
          Rectangle()
            .stroke(Color.black, lineWidth: 2)
        )

      Text(dateFormatter.string(from: currentTime).uppercased())
        .font(.system(size: 14, weight: .medium, design: .monospaced))
        .foregroundColor(.gray)
    }
    .onReceive(timer) { input in
      currentTime = input
    }
  }

  private var timeFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter
  }

  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .full
    return formatter
  }
}

struct PodBrowserView: View {
  let url: URL

  var body: some View {
    VStack(spacing: 0) {
      // "Browser" Bar
      HStack {
        Text("SAFARI.EXE")
          .font(.system(size: 10, weight: .bold, design: .monospaced))
          .foregroundColor(.white)
        Spacer()
        Text(url.host?.uppercased() ?? "BROWSER")
          .font(.system(size: 8, weight: .medium, design: .monospaced))
          .foregroundColor(.white.opacity(0.7))
      }
      .padding(.horizontal, 10)
      .padding(.vertical, 4)
      .background(Color.black)

      SwiftUIWebView(url: url)
    }
    .border(Color.black, width: 2)
  }
}

struct SwiftUIWebView: UIViewRepresentable {
  let url: URL

  func makeUIView(context: Context) -> WKWebView {
    let webView = WKWebView()
    webView.load(URLRequest(url: url))
    return webView
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct ExtrasView: View {
  let type: ExtraType

  enum ExtraType {
    case clock
    case browser
    case notes
  }

  var body: some View {
    VStack {
      switch type {
      case .clock:
        ClockView()
      case .browser:
        PodBrowserView(url: URL(string: "https://anuraaaggxdesign.framer.website/")!)
      case .notes:
        VStack(alignment: .leading, spacing: 10) {
          Text("[ NOTES.TXT ]")
            .font(.system(size: 14, weight: .bold, design: .monospaced))
            .foregroundColor(.red)

          ScrollView {
            Text(
              "Welcome to the PortfolioPod.\n\nThis is a brutalist exploration of interactions, combining retro hardware aesthetics with modern web portfolios.\n\nBuilt by Anuraag."
            )
            .font(.system(size: 13, design: .monospaced))
            .lineSpacing(6)
          }
        }
        .padding(20)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.white)
  }
}
