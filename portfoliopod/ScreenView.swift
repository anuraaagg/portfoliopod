//
//  ScreenView.swift
//  portfoliopod
//
//  Main screen content view
//

import SwiftUI

struct ScreenView: View {
  @ObservedObject var contentStore: ContentStore
  @Binding var navigationStack: [MenuNode]
  @Binding var selectedIndex: Int

  var body: some View {
    ZStack {
      Color.black
        .ignoresSafeArea()

      if navigationStack.isEmpty {
        MenuListView(
          items: contentStore.rootMenu.children ?? [],
          contentStore: contentStore,
          navigationStack: $navigationStack,
          selectedIndex: $selectedIndex
        )
      } else if let lastNode = navigationStack.last {
        NavigationContentView(
          node: lastNode,
          contentStore: contentStore,
          navigationStack: $navigationStack,
          selectedIndex: $selectedIndex
        )
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
      // Status bar
      StatusBarView(title: navigationStack.isEmpty ? "iPod" : navigationStack.last?.title ?? "")

      // List items (max 6 visible)
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
        .onChange(of: selectedIndex) { newIndex in
          if newIndex < items.count {
            withAnimation(.easeInOut(duration: 0.12)) {
              proxy.scrollTo(newIndex, anchor: .center)
            }
          }
        }
        .onAppear {
          if selectedIndex < items.count {
            proxy.scrollTo(selectedIndex, anchor: .center)
          }
        }
      }

      Spacer()
    }
    .background(Color.white)
  }
}

struct MenuItemView: View {
  let item: MenuNode
  let isSelected: Bool

  var body: some View {
    HStack {
      Text(item.title)
        .font(.system(size: 16, weight: isSelected ? .semibold : .medium))
        .foregroundColor(isSelected ? .black : Color(white: 0.85))

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(
      isSelected ? Color(white: 0.95) : Color.clear
    )
  }
}

struct StatusBarView: View {
  let title: String

  var body: some View {
    HStack {
      Text(title)
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(.black)

      Spacer()

      // Battery icon
      Image(systemName: "battery.100")
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.black)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(
      LinearGradient(
        colors: [Color(white: 0.9), Color(white: 0.75)],
        startPoint: .top,
        endPoint: .bottom
      )
    )
  }
}

struct NavigationContentView: View {
  let node: MenuNode
  @ObservedObject var contentStore: ContentStore
  @Binding var navigationStack: [MenuNode]
  @Binding var selectedIndex: Int

  var body: some View {
    VStack(spacing: 0) {
      StatusBarView(title: node.title)

      if node.contentType == .menu, let children = node.children {
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
    case .experiment:
      if let payloadID = node.payloadID,
        let content = contentStore.getExperimentContent(id: payloadID)
      {
        ExperimentContentView(content: content)
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
