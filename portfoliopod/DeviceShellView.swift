//
//  DeviceShellView.swift
//  portfoliopod
//
//  Main device shell container
//

import SwiftUI

struct DeviceShellView: View {
  @StateObject private var contentStore = ContentStore()
  @StateObject private var accessibilitySettings = AccessibilitySettings()
  @State private var navigationStack: [MenuNode] = []
  @State private var selectedIndex: Int = 0

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // System background
        Color.black
          .ignoresSafeArea()

        // Metal device shell
        MetalView()
          .ignoresSafeArea()

        // Screen area (inset ~6-8%)
        let screenInset: CGFloat = geometry.size.width * 0.07
        let screenWidth = geometry.size.width - (screenInset * 2)
        let screenHeight = screenWidth * 1.5  // iPod Classic aspect ratio
        let screenY = (geometry.size.height - screenHeight) / 2

        VStack(spacing: 0) {
          Spacer()
            .frame(height: screenY)

          // Screen content
          ScreenView(
            contentStore: contentStore,
            navigationStack: $navigationStack,
            selectedIndex: $selectedIndex
          )
          .frame(width: screenWidth, height: screenHeight)
          .background(Color.white)  // Classic white screen background
          .cornerRadius(8)
          .overlay(
            // Screen glass effects
            ScreenGlassOverlay()
          )
          .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)

          Spacer()
            .frame(height: geometry.size.height - screenY - screenHeight)
        }

        // Click wheel (positioned below screen)
        let wheelSize = min(geometry.size.width * 0.7, 280)
        let wheelY = screenY + screenHeight + 40

        ClickWheelView(
          numberOfItems: max(currentMenuItems.count, 1),
          onSelectionChange: { index in
            if index < currentMenuItems.count {
              selectedIndex = index
            }
          },
          onCenterPress: {
            handleCenterPress()
          },
          onMenuPress: {
            handleMenuPress()
          }
        )
        .frame(width: wheelSize, height: wheelSize)
        .position(x: geometry.size.width / 2, y: wheelY)
        .onChange(of: currentMenuItems.count) { newCount in
          // Reset selection when menu changes
          selectedIndex = 0
        }
      }
    }
    .preferredColorScheme(.dark)
    .environmentObject(accessibilitySettings)
  }

  private var currentMenuItems: [MenuNode] {
    if navigationStack.isEmpty {
      return contentStore.rootMenu.children ?? []
    } else {
      return navigationStack.last?.children ?? []
    }
  }

  private func handleCenterPress() {
    guard !currentMenuItems.isEmpty else { return }
    guard selectedIndex < currentMenuItems.count else { return }

    let selectedItem = currentMenuItems[selectedIndex]

    if selectedItem.contentType == .menu && selectedItem.children != nil {
      withAnimation(.easeOut(duration: 0.2)) {
        navigationStack.append(selectedItem)
        selectedIndex = 0
      }
    }
    // Content items are displayed automatically via NavigationContentView
  }

  private func handleMenuPress() {
    // Menu button = back button
    if !navigationStack.isEmpty {
      withAnimation(.easeOut(duration: 0.2)) {
        navigationStack.removeLast()
        selectedIndex = 0
      }
    }
  }
}

struct ScreenGlassOverlay: View {
  var body: some View {
    ZStack {
      // Inner shadow
      RoundedRectangle(cornerRadius: 12)
        .strokeBorder(
          LinearGradient(
            colors: [
              Color.white.opacity(0.1),
              Color.clear,
            ],
            startPoint: .top,
            endPoint: .bottom
          ),
          lineWidth: 1
        )

      // Subtle top-edge highlight
      VStack {
        LinearGradient(
          colors: [
            Color.white.opacity(0.15),
            Color.clear,
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 2)
        .blur(radius: 1)

        Spacer()
      }

      // Noise overlay (1-2% opacity)
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.clear)
        .overlay(
          Image(systemName: "circle.grid.3x3")
            .resizable()
            .scaledToFill()
            .foregroundStyle(Color.white.opacity(0.02))
            .opacity(1)
            .clipped()
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }
}
