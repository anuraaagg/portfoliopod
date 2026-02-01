//
//  ScreenView.swift
//  portfoliopod
//
//  Main screen content view
//

import Combine
import MediaPlayer
import SwiftUI

struct ScreenView: View {
  @ObservedObject var contentStore: ContentStore
  @Binding var navigationStack: [MenuNode]
  @Binding var selectedIndex: Int
  @ObservedObject var physics: ClickWheelPhysics

  var body: some View {
    ZStack {
      Color.white
        .ignoresSafeArea()

      VStack(spacing: 0) {
        StatusBarView(title: navigationStack.isEmpty ? "iPod" : navigationStack.last?.title ?? "")

        let items =
          navigationStack.isEmpty
          ? (contentStore.rootMenu.children ?? []) : (navigationStack.last?.children ?? [])

        // Show menu list if we have items to display
        if !items.isEmpty {
          // Split-Screen for Menus
          HStack(spacing: 0) {
            MenuListView(
              items: items,
              contentStore: contentStore,
              navigationStack: $navigationStack,
              selectedIndex: $selectedIndex
            )
            .frame(maxWidth: .infinity)

            // Right Side: Dynamic Preview (only for menu categories)
            if items.contains(where: { $0.children != nil }) {
              Rectangle()
                .fill(Color(white: 0.98))
                .frame(width: 120)
                .overlay(
                  VStack(spacing: 12) {
                    if selectedIndex < items.count {
                      let item = items[selectedIndex]

                      ZStack {
                        if let imageName = item.imageName {
                          Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .padding(8)
                        } else {
                          let icon = getCategoryIcon(for: item.title)
                          Image(systemName: icon)
                            .font(.system(size: 32))
                            .foregroundColor(SettingsStore.shared.theme.accentColor)
                        }
                      }
                      .frame(width: 100, height: 100)
                      .background(Color.white)
                      .overlay(
                        Rectangle()
                          .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                      )

                      Text(item.title.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)

                      if let count = item.children?.count {
                        Text("\(count) ITEMS")
                          .font(.system(size: 8, weight: .semibold, design: .monospaced))
                          .foregroundColor(.gray)
                      }
                    }
                  }
                )
                .overlay(
                  Rectangle()
                    .fill(Color.black.opacity(0.1))
                    .frame(width: 1),
                  alignment: .leading
                )
            }
          }
        } else if let lastNode = navigationStack.last {
          // Content view for leaf nodes
          NavigationContentView(
            node: lastNode,
            contentStore: contentStore,
            navigationStack: $navigationStack,
            selectedIndex: $selectedIndex,
            physics: physics
          )
        }
      }
    }
  }

  private func getCategoryIcon(for title: String) -> String {
    switch title.lowercased() {
    case "music": return "music.note"
    case "work": return "briefcase.fill"
    case "experiments": return "flask.fill"
    case "contact": return "envelope.fill"
    case "about": return "person.fill"
    case "writing": return "pencil.tip"
    default: return "folder.fill"
    }
  }
}

struct VideoContentView: View {
  let videoName: String

  var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()

      VStack {
        Spacer()

        // Placeholder for video (Brutalist style)
        ZStack {
          Rectangle()
            .stroke(SettingsStore.shared.theme.accentColor, lineWidth: 2)

          VStack(spacing: 12) {
            Image(systemName: "video.fill")
              .font(.system(size: 40))
              .foregroundColor(SettingsStore.shared.theme.accentColor)

            Text("[ INITIALIZING VIDEO ... ]")
              .font(.system(size: 12, weight: .bold, design: .monospaced))
              .foregroundColor(SettingsStore.shared.theme.accentColor)

            Text("SOURCE: \(videoName.uppercased()).MP4")
              .font(.system(size: 10, weight: .medium, design: .monospaced))
              .foregroundColor(.white)
          }
        }
        .frame(width: 280, height: 160)

        Spacer()

        // Classic Video Controls
        HStack {
          Image(systemName: "backward.fill")
          Spacer()
          ZStack(alignment: .leading) {
            Rectangle().fill(Color.white.opacity(0.1)).frame(height: 2)
            Rectangle().fill(SettingsStore.shared.theme.accentColor).frame(width: 120, height: 2)
          }
          .frame(width: 180)
          Spacer()
          Image(systemName: "forward.fill")
        }
        .foregroundColor(.white)
        .padding(.horizontal, 30)
        .padding(.bottom, 20)
      }
    }
  }
}

struct MenuListView: View {
  let items: [MenuNode]
  @ObservedObject var contentStore: ContentStore
  @Binding var navigationStack: [MenuNode]
  @Binding var selectedIndex: Int

  var body: some View {
    VStack(spacing: 0) {
      ScrollViewReader { proxy in
        ScrollView {
          VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
              MenuItemView(
                item: item,
                isSelected: index == selectedIndex
              )
              .id(index)
            }
          }
        }
        .scrollDisabled(true)  // Authentic feeling (controlled by ClickWheel only)
        .onChange(of: selectedIndex) { oldIndex, newIndex in
          if newIndex < items.count {
            withAnimation(.easeInOut(duration: 0.12)) {
              proxy.scrollTo(newIndex, anchor: .center)
            }
          }
        }
      }
    }
    .background(Color.white)
    .overlay(
      Rectangle()
        .fill(Color.gray.opacity(0.2))
        .frame(width: 1)
        .padding(.vertical, 0),
      alignment: .trailing
    )
  }
}

struct MenuItemView: View {
  let item: MenuNode
  let isSelected: Bool

  var body: some View {
    HStack {
      if let iconPath = item.iconPath,
        let uiImage = UIImage(contentsOfFile: iconPath)
      {
        Image(uiImage: uiImage)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 44, height: 44)  // Icon size "same as others" (standard thumbnail feel)
          .padding(.trailing, 8)
      }

      Text(isSelected ? "[ \(item.title) ]" : "  \(item.title)")
        .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .monospaced))
        .foregroundColor(isSelected ? .white : .black)

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(
      isSelected ? SettingsStore.shared.theme.accentColor : Color.clear  // Dynamic accent selection
    )
  }
}

struct StatusBarView: View {
  let title: String
  @State private var currentTime = Date()
  let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

  var body: some View {
    HStack {
      Text(timeString(from: currentTime))
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(.black)

      Spacer()

      Text(title.uppercased())
        .font(.system(size: 12, weight: .bold, design: .monospaced))
        .foregroundColor(.black)

      Spacer()

      // Battery icon
      HStack(spacing: 4) {
        Image(systemName: "battery.100")
          .font(.system(size: 12))
          .foregroundColor(SettingsStore.shared.theme.accentColor)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(Color(white: 0.95))
    .overlay(
      Rectangle()
        .fill(Color.black.opacity(0.1))
        .frame(height: 1),
      alignment: .bottom
    )
    .onReceive(timer) { input in
      currentTime = input
    }
  }

  private func timeString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date)
  }
}

struct NavigationContentView: View {
  let node: MenuNode
  @ObservedObject var contentStore: ContentStore
  @Binding var navigationStack: [MenuNode]
  @Binding var selectedIndex: Int
  @ObservedObject var physics: ClickWheelPhysics

  var body: some View {
    VStack(spacing: 0) {
      if node.id.contains("nowplaying") {
        ClassicNowPlayingView()
      } else if node.payloadID == "library" {
        MusicLibraryView(navigationStack: $navigationStack, selectedIndex: $selectedIndex)
      } else if node.contentType == .menu, let children = node.children {
        MenuListView(
          items: children,
          contentStore: contentStore,
          navigationStack: $navigationStack,
          selectedIndex: $selectedIndex
        )
      } else {
        ScrollViewReader { proxy in
          ScrollView {
            contentView
              .id("top")
              .padding(20)
              .offset(y: -physics.scrollOffset)  // Drive scroll with wheel
          }
          .scrollDisabled(true)  // Authentic iPod experience
        }
      }

      Spacer()
    }
  }

  @ViewBuilder
  private var contentView: some View {
    switch node.contentType {
    case .text:
      if let payloadID = node.payloadID,
        let content = contentStore.getTextContent(id: payloadID)
      {
        TextContentView(content: content)
      }
    case .project:
      if let payloadID = node.payloadID,
        let content = contentStore.getProjectContent(id: payloadID)
      {
        ProjectContentView(content: content)
      }
    case .video:
      // New Video support
      VideoContentView(videoName: node.payloadID ?? "demo")
    case .experiment:
      if let payloadID = node.payloadID {
        if payloadID == "podbreaker" {
          PodBreakerView(physics: physics)
        } else if payloadID == "coverflow" {
          CoverFlowView(items: contentStore.rootMenu.children ?? [], selectedIndex: $selectedIndex)
        } else if let content = contentStore.getExperimentContent(id: payloadID) {
          ExperimentContentView(content: content)
        }
      }
    case .writing:
      if let payloadID = node.payloadID,
        let content = contentStore.getWritingContent(id: payloadID)
      {
        WritingContentView(content: content)
      }
    case .utility:
      if let payloadID = node.payloadID {
        switch payloadID {
        case "clock":
          ExtrasView(type: .clock)
        case "browser":
          ExtrasView(type: .browser)
        case "notes":
          ExtrasView(type: .notes)
        case "search":
          SearchView(
            contentStore: contentStore, navigationStack: $navigationStack, physics: physics)
        case "haptics":
          SettingsView(type: .haptics)
        case "clicker":
          SettingsView(type: .clicker)
        case "legal":
          SettingsView(type: .legal)
        default:
          Text("Utility [\(payloadID.uppercased())] not implemented")
            .font(.system(size: 14, design: .monospaced))
        }
      }
    default:
      Text("Content not available")
        .foregroundColor(.gray)
        .font(.system(size: 14, weight: .medium))
    }
  }
}

struct TextContentView: View {
  let content: TextContent

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      if let title = content.title {
        Text("> \(title.uppercased())")
          .font(.system(size: 18, weight: .bold, design: .monospaced))
          .foregroundColor(SettingsStore.shared.theme.accentColor)
      }

      if !content.body.isEmpty {
        Text(content.body)
          .font(.system(size: 14, weight: .medium, design: .monospaced))
          .foregroundColor(.black)
          .lineSpacing(6)
      }

      if let bullets = content.bullets {
        VStack(alignment: .leading, spacing: 12) {
          ForEach(bullets, id: \.self) { bullet in
            HStack(alignment: .top, spacing: 8) {
              Text("::")
                .foregroundColor(.red)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
              Text(bullet)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.black)
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct ProjectContentView: View {
  let content: ProjectContent

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      Text("[ \(content.title.uppercased()) ]")
        .font(.system(size: 18, weight: .bold, design: .monospaced))
        .foregroundColor(.red)

      VStack(alignment: .leading, spacing: 10) {
        Text("// OVERVIEW")
          .font(.system(size: 10, weight: .bold, design: .monospaced))
          .foregroundColor(.gray)

        Text(content.overview)
          .font(.system(size: 14, weight: .medium, design: .monospaced))
          .foregroundColor(.black)
          .lineSpacing(6)
      }

      VStack(alignment: .leading, spacing: 10) {
        Text("// OUTCOME")
          .font(.system(size: 10, weight: .bold, design: .monospaced))
          .foregroundColor(.gray)

        VStack(alignment: .leading, spacing: 8) {
          ForEach(content.outcome, id: \.self) { outcome in
            HStack(alignment: .top, spacing: 8) {
              Text("+")
                .foregroundColor(.red)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
              Text(outcome)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.black)
            }
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct ExperimentContentView: View {
  let content: ExperimentContent

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(content.title)
        .font(.system(size: 20, weight: .bold))
        .foregroundColor(.black)

      Text(content.description)
        .font(.system(size: 15, weight: .medium))
        .foregroundColor(Color(white: 0.2))
        .lineSpacing(4)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct WritingContentView: View {
  let content: WritingContent

  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      VStack(alignment: .leading, spacing: 10) {
        Text("> \(content.title.uppercased())")
          .font(.system(size: 18, weight: .bold, design: .monospaced))
          .foregroundColor(.red)

        if let readingTime = content.estimatedReadingTime {
          Text("[ \(readingTime) MIN READ ]")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.gray)
        }
      }

      // Progress bar (Brutalist style)
      Rectangle()
        .fill(Color.black.opacity(0.05))
        .frame(height: 4)
        .overlay(
          GeometryReader { g in
            Rectangle()
              .fill(Color.red)
              .frame(width: g.size.width * 0.3)  // Example progress
          }
        )

      Text(content.body)
        .font(.system(size: 14, weight: .medium, design: .monospaced))
        .foregroundColor(.black)
        .lineSpacing(8)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct ClassicNowPlayingView: View {
  var body: some View {
    VStack(spacing: 30) {
      // Album Art (Brutalist frame)
      ZStack(alignment: .bottom) {
        Rectangle()
          .fill(Color.black)
          .frame(width: 140, height: 140)
          .overlay(
            Rectangle()
              .stroke(SettingsStore.shared.theme.accentColor, lineWidth: 2)
          )
          .overlay(
            BarVisualizer()
              .frame(width: 120, height: 40)
              .padding(.bottom, 10),
            alignment: .bottom
          )
          .overlay(
            Image(systemName: "waveform.path")
              .font(.system(size: 40))
              .foregroundColor(SettingsStore.shared.theme.accentColor)
          )
      }
      .padding(.top, 40)

      VStack(spacing: 12) {
        Text("[ NOW_PLAYING ]")
          .font(.system(size: 10, weight: .bold, design: .monospaced))
          .foregroundColor(.gray)

        VStack(spacing: 6) {
          Text("LOOPS: SESSION_01")
            .font(.system(size: 16, weight: .bold, design: .monospaced))
            .foregroundColor(.black)

          Text("ANURAG")
            .font(.system(size: 14, weight: .semibold, design: .monospaced))
            .foregroundColor(SettingsStore.shared.theme.accentColor)
        }
      }

      // Progress Bar (Terminal style)
      VStack(spacing: 12) {
        ZStack(alignment: .leading) {
          Rectangle()
            .fill(Color.black.opacity(0.1))
            .frame(height: 4)

          Rectangle()
            .fill(SettingsStore.shared.theme.accentColor)
            .frame(width: 80, height: 4)
        }
        .frame(width: 200)

        HStack {
          Text("01:23")
          Spacer()
          Text("-02:45")
        }
        .font(.system(size: 10, weight: .bold, design: .monospaced))
        .foregroundColor(.gray)
        .frame(width: 200)
      }

      Spacer()
    }
    .background(Color.white)
  }
}

struct BarVisualizer: View {
  @State private var barHeights: [CGFloat] = Array(repeating: 5, count: 12)
  let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

  var body: some View {
    HStack(alignment: .bottom, spacing: 3) {
      ForEach(0..<barHeights.count, id: \.self) { index in
        Rectangle()
          .fill(SettingsStore.shared.theme.accentColor.opacity(0.8))
          .frame(width: 4, height: barHeights[index])
          .animation(.spring(response: 0.2, dampingFraction: 0.5), value: barHeights[index])
      }
    }
    .onReceive(timer) { _ in
      for i in 0..<barHeights.count {
        barHeights[i] = CGFloat.random(in: 4...30)
      }
    }
  }
}

struct MusicLibraryView: View {
  @ObservedObject var musicManager = MusicLibraryManager.shared
  @Binding var navigationStack: [MenuNode]
  @Binding var selectedIndex: Int

  var body: some View {
    VStack(spacing: 0) {
      if musicManager.permissionStatus == .authorized {
        VStack(spacing: 0) {
          let playlists = musicManager.playlists
          if playlists.isEmpty {
            Text("[ NO PLAYLISTS FOUND ]")
              .font(.system(size: 14, design: .monospaced))
              .foregroundColor(.gray)
              .padding(.top, 40)
          } else {
            ForEach(0..<playlists.count, id: \.self) { index in
              playlistRow(index: index, playlist: playlists[index])
            }
          }
        }
      } else {
        VStack(spacing: 12) {
          Image(systemName: "lock.fill")
            .font(.system(size: 30))
          Text("[ ACCESS_DENIED ]")
            .font(.system(size: 14, weight: .bold, design: .monospaced))
          Text("ENABLE MUSIC PERMISSIONS IN SETTINGS")
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.gray)
        }
        .padding(.top, 60)
      }
    }
    .onAppear {
      musicManager.checkPermissions()
    }
  }

  private func playlistRow(index: Int, playlist: MPMediaItemCollection) -> some View {
    let name = playlist.value(forProperty: MPMediaPlaylistPropertyName) as? String ?? "Unknown"
    return HStack {
      Text(
        index == selectedIndex
          ? "[ \(name) ]"
          : "  \(name)"
      )
      .font(
        .system(size: 15, weight: index == selectedIndex ? .bold : .medium, design: .monospaced)
      )
      .foregroundColor(index == selectedIndex ? .white : .black)
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(index == selectedIndex ? SettingsStore.shared.theme.accentColor : Color.clear)
  }
}
