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
  @StateObject private var motionManager = MotionManager()
  @StateObject private var physics = ClickWheelPhysics(numberOfItems: 0)
  @StateObject private var stickerStore = StickerStore()  // Sticker Manager
  @State private var navigationStack: [MenuNode] = []
  @State private var selectedIndex: Int = 0
  @State private var isBooting: Bool = true  // Boot animation state
  @State private var isPoweredOn: Bool = true  // Power state

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // System background (Premium Studio Look)
        RadialGradient(
          stops: [
            .init(color: Color(white: 0.98), location: 0),
            .init(color: Color(white: 0.82), location: 1),
          ],
          center: .center,
          startRadius: 0,
          endRadius: 1000
        )
        .ignoresSafeArea()

        // Metallic reflection overlay (Real-time gyro driven)
        MetalView(lightAngle: Float(motionManager.tilt))
          .opacity(0.15)
          .ignoresSafeArea()

        RealisticIPodShell(
          contentStore: contentStore,
          navigationStack: $navigationStack,
          selectedIndex: $selectedIndex,
          currentMenuItems: currentMenuItems,
          physics: physics,
          onCenterPress: handleCenterPress,
          onMenuPress: handleMenuPress,
          isBooting: $isBooting,
          isPoweredOn: $isPoweredOn,
          stickerStore: stickerStore,
          motionManager: motionManager
        )
        .frame(width: min(geometry.size.width * 0.9, 360))
        .aspectRatio(0.597, contentMode: .fit)  // Authentic 6th Gen Ratio
        .padding(.top, 60)  // Extra clearance for the top edge
        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
      }
      .onAppear {
        // Sync physics with initial items
        physics.numberOfItems = currentMenuItems.count
      }
      .onChange(of: currentMenuItems.count) { oldCount, newCount in
        physics.numberOfItems = newCount
      }
      .onChange(of: physics.selectionIndex) { oldIndex, newIndex in
        selectedIndex = newIndex
      }
      .onReceive(motionManager.$shakeDetected) { shaken in
        if shaken {
          shuffleContent()
        }
      }
    }
    .preferredColorScheme(.light)
    .environmentObject(accessibilitySettings)
  }

  private var currentMenuItems: [MenuNode] {
    let items =
      navigationStack.isEmpty
      ? (contentStore.rootMenu.children ?? []) : (navigationStack.last?.children ?? [])
    return items
  }

  private func shuffleContent() {
    // Shake to shuffle logic
    let items = contentStore.rootMenu.children ?? []
    if let randomItem = items.randomElement() {
      withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
        navigationStack = [randomItem]
        selectedIndex = 0
      }
      // Simple haptic for shake
      let generator = UIImpactFeedbackGenerator(style: .heavy)
      generator.impactOccurred()
    }
  }

  private func handleCenterPress() {
    guard !currentMenuItems.isEmpty else { return }
    guard selectedIndex < currentMenuItems.count else { return }

    // Special handling for Music Library Leaf Selection
    if navigationStack.last?.payloadID == "library" {
      let playlists = MusicLibraryManager.shared.playlists
      if selectedIndex < playlists.count {
        MusicLibraryManager.shared.playPlaylist(playlists[selectedIndex])
        // Optionally navigate to "Now Playing"
        let nowPlayingNode = MenuNode(
          id: "nowplaying", title: "Now Playing", contentType: .media, payloadID: "nowplaying")
        withAnimation(.easeOut(duration: 0.2)) {
          navigationStack.append(nowPlayingNode)
          selectedIndex = 0
          physics.reset(to: 0)
        }
      }
      return
    }

    // Navigate into any item (menu with children OR leaf content)
    withAnimation(.easeOut(duration: 0.2)) {
      navigationStack.append(selectedItem)
      selectedIndex = 0
      physics.reset(to: 0)  // Force physics synchronization
    }
  }

  private func handleMenuPress() {
    if !navigationStack.isEmpty {
      withAnimation(.easeOut(duration: 0.2)) {
        navigationStack.removeLast()
        selectedIndex = 0
        physics.reset(to: 0)  // Force physics synchronization
      }
    }
  }
}

struct RealisticIPodShell: View {
  let contentStore: ContentStore
  @Binding var navigationStack: [MenuNode]
  @Binding var selectedIndex: Int
  let currentMenuItems: [MenuNode]
  @ObservedObject var physics: ClickWheelPhysics  // Accept physics object
  let onCenterPress: () -> Void
  let onMenuPress: () -> Void
  @Binding var isBooting: Bool
  @Binding var isPoweredOn: Bool
  @ObservedObject var stickerStore: StickerStore
  @ObservedObject var motionManager: MotionManager  // Accept motion manager

  var body: some View {
    GeometryReader { geo in
      let width = geo.size.width

      ZStack(alignment: .top) {

        // Main Body (Silver/Dark Slate)
        RoundedRectangle(cornerRadius: width * 0.16)  // Modern softer corners
          .fill(
            LinearGradient(
              stops: [
                .init(color: Color(red: 0.32, green: 0.36, blue: 0.42), location: 0),
                .init(color: Color(red: 0.38, green: 0.42, blue: 0.48), location: 0.15),
                .init(color: Color(red: 0.42, green: 0.46, blue: 0.52), location: 0.5),
                .init(color: Color(red: 0.38, green: 0.42, blue: 0.48), location: 0.85),
                .init(color: Color(red: 0.32, green: 0.36, blue: 0.42), location: 1.0),
              ],
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .shadow(color: .black.opacity(0.35), radius: 25, x: 0, y: 15)
          .overlay(
            VStack {
              LinearGradient(
                colors: [Color.black.opacity(0.15), .clear], startPoint: .top, endPoint: .bottom
              )
              .frame(height: 25)
              Spacer()
              LinearGradient(
                colors: [.clear, Color.black.opacity(0.15)], startPoint: .top, endPoint: .bottom
              )
              .frame(height: 25)
            }
            .clipShape(RoundedRectangle(cornerRadius: width * 0.16))
          )
          .overlay(
            // Polished Chrome Frame (The physical rim)
            RoundedRectangle(cornerRadius: width * 0.16)
              .strokeBorder(
                LinearGradient(
                  colors: [Color(white: 0.95), Color(white: 0.6), Color(white: 0.95)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                ),
                lineWidth: 2.5
              )
          )
          .overlay(
            // Sticker Layer
            StickerLayerView(store: stickerStore)
              .clipShape(RoundedRectangle(cornerRadius: width * 0.16))
          )

        // Internal Content Area
        VStack(spacing: 0) {
          // Forehead: Matches Side Bezel (6% of width)
          Color.clear.frame(height: width * 0.06)

          // Main Control Cluster (Screen + Wheel)
          VStack(spacing: 0) {
            // Screen Cluster
            ZStack {
              // Outer Bezel
              RoundedRectangle(cornerRadius: width * 0.075)  // More rounded screen corners
                .fill(Color(white: 0.04))
                .frame(width: width * 0.88, height: width * 0.70)
                .overlay(
                  RoundedRectangle(cornerRadius: width * 0.075)
                    .strokeBorder(Color(white: 0.12), lineWidth: 1.5)
                )

              // Viewport
              ScreenView(
                contentStore: contentStore,
                navigationStack: $navigationStack,
                selectedIndex: $selectedIndex,
                physics: physics
              )
              .frame(width: width * 0.84, height: width * 0.66)
              .cornerRadius(width * 0.065)
              .offset(
                x: CGFloat(motionManager.tilt) * 3.0,
                y: CGFloat(motionManager.tilt) * 2.0
              )
              .overlay(
                Group {
                  if isBooting && isPoweredOn {
                    BootLoaderView(isBooting: $isBooting)
                  }
                  if !isPoweredOn {
                    Color.black
                  }

                  // Inner Shadow (Air Gap Depth)
                  RoundedRectangle(cornerRadius: width * 0.045)
                    .stroke(
                      LinearGradient(
                        colors: [.black.opacity(0.8), .black.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                      lineWidth: 3.5
                    )
                    .blur(radius: 2)
                }
              )
              .clipShape(RoundedRectangle(cornerRadius: width * 0.065))
            }

            // Gap: 4% of width (Slimmer spacing)
            Color.clear.frame(height: width * 0.04)

            // Click Wheel
            ClickWheelView(
              physics: physics,
              onCenterPress: onCenterPress,
              onMenuPress: onMenuPress
            )
            .frame(width: width * 0.65, height: width * 0.65)
          }

          // Chin: 4% of width (Slimmer spacing)
          Color.clear.frame(height: width * 0.04)
        }
      }
    }
  }
}

struct ScreenGlassOverlay: View {
  var body: some View {
    ZStack {
      // Modern Glass highlight
      RoundedRectangle(cornerRadius: 2)
        .fill(
          LinearGradient(
            colors: [
              Color.white.opacity(0.2),
              Color.white.opacity(0.0),
              Color.white.opacity(0.1),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .opacity(0.4)
        .blendMode(.screen)

      // Subtle top-edge highlight
      VStack {
        LinearGradient(
          colors: [
            Color.white.opacity(0.1),
            Color.clear,
          ],
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 1)

        Spacer()
      }
    }
  }
}
