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

        // The Physical iPod Model (Centered Classic 6th Gen)
        RealisticIPodShell(
          contentStore: contentStore,
          navigationStack: $navigationStack,
          selectedIndex: $selectedIndex,
          currentMenuItems: currentMenuItems,
          physics: physics,  // Pass physics object
          onCenterPress: handleCenterPress,
          onMenuPress: handleMenuPress,
          isBooting: $isBooting,
          isPoweredOn: $isPoweredOn,
          stickerStore: stickerStore,
          motionManager: motionManager  // Pass motion manager
        )
        .frame(width: min(geometry.size.width * 0.9, 360))
        .aspectRatio(0.597, contentMode: .fit)  // Real iPod Classic Ratio (61.8mm / 103.5mm)
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

    let selectedItem = currentMenuItems[selectedIndex]

    // Navigate into any item (menu with children OR leaf content)
    withAnimation(.easeOut(duration: 0.2)) {
      navigationStack.append(selectedItem)
      selectedIndex = 0
    }
  }

  private func handleMenuPress() {
    if !navigationStack.isEmpty {
      withAnimation(.easeOut(duration: 0.2)) {
        navigationStack.removeLast()
        selectedIndex = 0
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

      ZStack {
        // Power Button "Outside" (Top Edge)
        // Simulated as sitting on the top casing
        RoundedRectangle(cornerRadius: 2)
          .fill(
            LinearGradient(
              colors: [Color(white: 0.25), Color(white: 0.15)],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .frame(width: width * 0.10, height: width * 0.03)  // ~6mm wide, 2mm tall
          .offset(x: width * 0.25, y: -geo.size.height / 2 - (width * 0.015))  // Top-Right, protruding
          .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            withAnimation(.easeInOut(duration: 0.3)) {
              isPoweredOn.toggle()
            }
            if isPoweredOn { isBooting = true }
          }
          .zIndex(0)  // Behind the main face plate effectively, or just sitting up top

        // Main Body (Dark Slate Blue - Modern iPod)
        RoundedRectangle(cornerRadius: 28)  // Softer, more modern corners
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
          .shadow(color: .black.opacity(0.45), radius: 35, x: 0, y: 20)
          .shadow(color: .black.opacity(0.45), radius: 35, x: 0, y: 20)
          // Removed matte finish noise overlay to fix circular artifacts
          .overlay(
            // Top/Bottom subtle gradient
            VStack {
              LinearGradient(
                colors: [Color.black.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom
              )
              .frame(height: 25)
              Spacer()
              LinearGradient(
                colors: [.clear, Color.black.opacity(0.2)], startPoint: .top, endPoint: .bottom
              )
              .frame(height: 25)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28))
          )
          .overlay(
            // Sticker Layer (On top of shell, below content)
            StickerLayerView(store: stickerStore)
              .clipShape(RoundedRectangle(cornerRadius: 28))
          )

        // Internal Content Area
        VStack(spacing: 0) {
          // Top Padding (Forehead): ~7mm real world relative
          Color.clear.frame(height: width * 0.11)

          // Main Control Cluster
          VStack(spacing: 0) {
            // Screen Cluster
            ZStack {
              // Bezel (Real width ~84% of device)
              RoundedRectangle(cornerRadius: 15)  // Slightly tighter corners for realism
                .fill(Color(white: 0.06))
                .frame(width: width * 0.84, height: width * 0.65)  // ~4:3 aspectish + bezel
                .overlay(
                  RoundedRectangle(cornerRadius: 15)
                    .strokeBorder(Color(white: 0.15), lineWidth: 1.5)
                )

              // Viewport (2.5" diag -> 0.82 width ratio, actual display)
              ScreenView(
                contentStore: contentStore,
                navigationStack: $navigationStack,
                selectedIndex: $selectedIndex,
                physics: physics
              )
              .frame(width: width * 0.79, height: width * 0.60)  // LCD Area
              .cornerRadius(12)
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

                  // Inner Shadow
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(
                      LinearGradient(
                        colors: [.black.opacity(0.6), .black.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                      ),
                      lineWidth: 3
                    )
                    .blur(radius: 1.5)
                }
              )
              .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Fixed tight gap (Real world is ~8-10mm, user wants tight 5%)
            Color.clear.frame(height: width * 0.08)

            // Click Wheel (Real: 38.1mm / 61.8mm = 61.6%)
            ClickWheelView(
              physics: physics,
              onCenterPress: onCenterPress,
              onMenuPress: onMenuPress
            )
            .frame(width: width * 0.616, height: width * 0.616)
          }

          Spacer(minLength: width * 0.05)  // Natural Chin
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
