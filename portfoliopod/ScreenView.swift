//
//  ScreenView.swift
//  portfoliopod
//
//  Main screen content view
//

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
                  VStack(spacing: 8) {
                    if selectedIndex < items.count {
                      let item = items[selectedIndex]

                      if let imageName = item.imageName {
                        Image(imageName)
                          .resizable()
                          .scaledToFit()
                          .frame(maxWidth: 100, maxHeight: 100)
                          .padding(8)
                      } else {
                        let icon = getCategoryIcon(for: item.title)
                        Image(systemName: icon)
                          .font(.system(size: 40))
                          .foregroundColor(Color(red: 0, green: 0.35, blue: 0.85).opacity(0.7))
                      }

                      Text(item.title)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)

                      if let count = item.children?.count {
                        Text("\(count) items")
                          .font(.system(size: 10, weight: .semibold))
                          .foregroundColor(.gray)
                      }
                    }
                  }
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

        // Placeholder for video
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.3), lineWidth: 1)

          VStack(spacing: 12) {
            Image(systemName: "video.fill")
              .font(.system(size: 40))
              .foregroundColor(.white)

            Text("Playing: \(videoName).mp4")
              .font(.system(size: 14, weight: .bold))
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
            Rectangle().fill(Color.white.opacity(0.3)).frame(height: 4)
            Rectangle().fill(Color.white).frame(width: 120, height: 4)
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
      Text(item.title)
        .font(.system(size: 17, weight: isSelected ? .bold : .semibold))  // Bold, crisp typography
        .foregroundColor(isSelected ? .white : .black)

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(
      isSelected ? Color(red: 0, green: 0.35, blue: 0.85) : Color.clear  // Classic blue selection
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

      Text(title)
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(.black)

      Spacer()

      // Battery icon (Actual system battery)
      HStack(spacing: 4) {
        Image(systemName: "battery.100")
          .font(.system(size: 14))
          .foregroundColor(.black)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(
      LinearGradient(
        colors: [Color(white: 0.92), Color(white: 0.8)],
        startPoint: .top,
        endPoint: .bottom
      )
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
      } else if node.contentType == .menu, let children = node.children {
        MenuListView(
          items: children,
          contentStore: contentStore,
          navigationStack: $navigationStack,
          selectedIndex: $selectedIndex
        )
      } else {
        ScrollView {
          contentView
            .padding(20)
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
          PodBreakerView(wheelAngle: $physics.currentAngle)
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
    VStack(alignment: .leading, spacing: 16) {
      if let title = content.title {
        Text(title)
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(.black)
      }

      if !content.body.isEmpty {
        Text(content.body)
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(Color(white: 0.2))
          .lineSpacing(4)
      }

      if let bullets = content.bullets {
        VStack(alignment: .leading, spacing: 10) {
          ForEach(bullets, id: \.self) { bullet in
            HStack(alignment: .top, spacing: 10) {
              Text("•")
                .foregroundColor(.black)
                .font(.system(size: 14, weight: .bold))
              Text(bullet)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(white: 0.2))
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
    VStack(alignment: .leading, spacing: 16) {
      Text(content.title)
        .font(.system(size: 22, weight: .bold))
        .foregroundColor(.black)

      VStack(alignment: .leading, spacing: 8) {
        Text("OVERVIEW")
          .font(.system(size: 11, weight: .bold))
          .foregroundColor(.gray)

        Text(content.overview)
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(Color(white: 0.2))
          .lineSpacing(4)
      }

      VStack(alignment: .leading, spacing: 8) {
        Text("OUTCOME")
          .font(.system(size: 11, weight: .bold))
          .foregroundColor(.gray)
          .padding(.top, 8)

        VStack(alignment: .leading, spacing: 8) {
          ForEach(content.outcome, id: \.self) { outcome in
            HStack(alignment: .top, spacing: 8) {
              Text("•")
                .foregroundColor(.black)
              Text(outcome)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(white: 0.3))
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
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 4) {
        Text(content.title)
          .font(.system(size: 22, weight: .bold))
          .foregroundColor(.black)

        if let readingTime = content.estimatedReadingTime {
          Text("\(readingTime) MIN READ")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.gray)
        }
      }

      // Progress bar
      Rectangle()
        .fill(Color(white: 0.9))
        .frame(height: 2)
        .overlay(
          GeometryReader { g in
            Rectangle()
              .fill(Color.black)
              .frame(width: g.size.width * 0.3)  // Example progress
          }
        )

      Text(content.body)
        .font(.system(size: 15, weight: .medium))
        .foregroundColor(Color(white: 0.15))
        .lineSpacing(6)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct ClassicNowPlayingView: View {
  var body: some View {
    VStack(spacing: 20) {
      // Album Art (Large, 6th Gen style)
      ZStack(alignment: .bottom) {
        // Reflection
        RoundedRectangle(cornerRadius: 8)
          .fill(
            LinearGradient(
              colors: [Color.blue.opacity(0.1), .clear],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(width: 140, height: 40)
          .offset(y: 100)
          .blur(radius: 4)

        RoundedRectangle(cornerRadius: 8)
          .fill(Color.blue)
          .frame(width: 140, height: 140)
          .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
          .overlay(
            Image(systemName: "music.note")
              .font(.system(size: 40))
              .foregroundColor(.white.opacity(0.5))
          )
      }
      .padding(.top, 20)

      VStack(spacing: 4) {
        Text("Track Name")
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(.black)

        Text("Artist Name")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.gray)

        Text("Album Name")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.gray)
      }

      // Progress Bar
      VStack(spacing: 6) {
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 2)
            .fill(Color(white: 0.9))
            .frame(height: 4)

          RoundedRectangle(cornerRadius: 2)
            .fill(Color.blue)
            .frame(width: 80, height: 4)
        }
        .padding(.horizontal, 30)

        HStack {
          Text("1:23")
          Spacer()
          Text("-2:45")
        }
        .font(.system(size: 10, weight: .bold))
        .foregroundColor(.gray)
        .padding(.horizontal, 30)
      }

      Spacer()
    }
    .background(Color.white)
  }
}
