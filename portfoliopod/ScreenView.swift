//
//  ScreenView.swift
//  portfoliopod
//
//  Main screen content view
//

import AVFoundation
import Combine
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
      } else if let payload = node.payloadID, ["library", "music-playlists", "music-songs"].contains(payload) {
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
              .offset(y: -physics.scrollOffset)  // Drive scroll with wheel (clockwise = up/forward)
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
  @ObservedObject private var audioPlayer = AudioPlayerManager.shared

  var body: some View {
    VStack(spacing: 30) {
      // Album Art (Classic iPod style)
      ZStack(alignment: .bottom) {
        if let art = audioPlayer.nowPlayingArtwork {
          Image(uiImage: art)
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .frame(width: 140, height: 140)
            .clipped()
            .overlay(
              Rectangle()
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
        } else {
          // Loading artwork from URL
          if let artworkURL = audioPlayer.nowPlayingArtworkURL {
            AsyncImage(url: artworkURL) { phase in
              switch phase {
              case .success(let image):
                image
                  .resizable()
                  .aspectRatio(1, contentMode: .fill)
              case .failure, .empty:
                placeholderArtwork
              @unknown default:
                placeholderArtwork
              }
            }
            .frame(width: 140, height: 140)
            .clipped()
            .overlay(
              Rectangle()
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
          } else {
            placeholderArtwork
          }
        }

        // Visualizer only when playing
        if audioPlayer.isPlaying {
          BarVisualizer()
            .frame(width: 120, height: 40)
            .padding(.bottom, 10)
        }
      }
      .padding(.top, 40)

      // Song info
      VStack(spacing: 6) {
        Text(audioPlayer.nowPlayingTitle.isEmpty ? "Not Playing" : audioPlayer.nowPlayingTitle)
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(.black)
          .lineLimit(2)
          .multilineTextAlignment(.center)
          .truncationMode(.tail)
          .padding(.horizontal, 20)

        Text(audioPlayer.nowPlayingArtist)
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(.gray)
          .lineLimit(1)
          .truncationMode(.tail)
      }

      // Progress Bar (Classic iPod style)
      VStack(spacing: 8) {
        GeometryReader { geo in
          ZStack(alignment: .leading) {
            // Background
            Rectangle()
              .fill(Color.black.opacity(0.1))
              .frame(height: 4)

            // Progress
            Rectangle()
              .fill(Color.black)
              .frame(width: geo.size.width * audioPlayer.progress, height: 4)
          }
        }
        .frame(height: 4)
        .padding(.horizontal, 20)

        // Time stamps
        HStack {
          Text(audioPlayer.currentTimeFormatted)
          Spacer()
          Text(audioPlayer.durationFormatted)
        }
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(.gray)
        .padding(.horizontal, 20)
      }
      .padding(.top, 10)

      Spacer()
    }
    .background(Color.white)
  }

  private var placeholderArtwork: some View {
    Rectangle()
      .fill(Color(white: 0.95))
      .frame(width: 140, height: 140)
      .overlay(
        Image(systemName: "music.note")
          .font(.system(size: 40))
          .foregroundColor(.gray)
      )
      .overlay(
        Rectangle()
          .stroke(Color.black.opacity(0.2), lineWidth: 1)
      )
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
    let payload = navigationStack.last?.payloadID ?? ""

    VStack(spacing: 0) {
      // iTunes API is always authorized (no permissions needed)
      if payload == "library" {
        rootMenu
      } else if payload == "music-playlists" {
        playlistsList
      } else if payload == "music-songs" {
        songsList
      } else {
        // Fallback or unexpected state
        Text("[ MUSIC_ERROR ]")
          .font(.system(size: 14, design: .monospaced))
      }
    }
    .onAppear {
      musicManager.checkPermissions()
    }
  }

  private var rootMenu: some View {
    VStack(spacing: 0) {
      rootRow(index: 0, title: "Playlists")
      rootRow(index: 1, title: "Songs")
    }
  }

  private func rootRow(index: Int, title: String) -> some View {
    HStack {
      Text(index == selectedIndex ? "[ \(title) ]" : "  \(title)")
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

  private var playlistsList: some View {
    VStack(spacing: 0) {
      let playlists = musicManager.playlists

      if playlists.isEmpty {
        Text("[ NO PLAYLISTS FOUND ]")
          .font(.system(size: 14, design: .monospaced))
          .foregroundColor(.gray)
          .padding(.top, 40)
      } else {
        ScrollViewReader { proxy in
          ScrollView {
            VStack(spacing: 0) {
              ForEach(0..<playlists.count, id: \.self) { index in
                let playlist = playlists[index]
                let name = playlist.name
                HStack {
                  Text(index == selectedIndex ? "[ \(name) ]" : "  \(name)")
                    .font(
                      .system(
                        size: 15, weight: index == selectedIndex ? .bold : .medium,
                        design: .monospaced)
                    )
                    .foregroundColor(index == selectedIndex ? .white : .black)
                  Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                  index == selectedIndex ? SettingsStore.shared.theme.accentColor : Color.clear
                )
                .id(index)
              }
            }
          }
          .scrollDisabled(true)
          .onChange(of: selectedIndex) { oldIndex, newIndex in
            if newIndex < playlists.count {
              withAnimation(.easeInOut(duration: 0.12)) {
                proxy.scrollTo(newIndex, anchor: .center)
              }
            }
          }
        }
      }
    }
    .onAppear {
      print("DEBUG: playlistsList appeared. Playlists count: \(musicManager.playlists.count)")
    }
  }

  private var songsList: some View {
    VStack(spacing: 0) {
      let songs = musicManager.allSongs

      if musicManager.isLoading {
        Text("[ LOADING... ]")
          .font(.system(size: 14, design: .monospaced))
          .foregroundColor(.gray)
          .padding(.top, 40)
      } else if songs.isEmpty {
        Text("[ NO SONGS FOUND ]")
          .font(.system(size: 14, design: .monospaced))
          .foregroundColor(.gray)
          .padding(.top, 40)
      } else {
        ScrollViewReader { proxy in
          ScrollView {
            VStack(spacing: 0) {
              ForEach(0..<songs.count, id: \.self) { index in
                let item = songs[index]
                let title = item.title
                HStack {
                  Text(index == selectedIndex ? "[ \(title) ]" : "  \(title)")
                    .font(
                      .system(
                        size: 15, weight: index == selectedIndex ? .bold : .medium,
                        design: .monospaced)
                    )
                    .foregroundColor(index == selectedIndex ? .white : .black)
                  Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                  index == selectedIndex ? SettingsStore.shared.theme.accentColor : Color.clear
                )
                .id(index)
              }
            }
          }
          .scrollDisabled(true)
          .onChange(of: selectedIndex) { oldIndex, newIndex in
            if newIndex < songs.count {
              withAnimation(.easeInOut(duration: 0.12)) {
                proxy.scrollTo(newIndex, anchor: .center)
              }
            }
          }
        }
      }
    }
    .onAppear {
      print("DEBUG: songsList appeared. Songs count: \(musicManager.allSongs.count)")
    }
  }
}
