//
//  ClickWheelView.swift
//  portfoliopod
//
//  Interactive click wheel component
//

import SwiftUI

struct ClickWheelView: View {
  let numberOfItems: Int
  let onSelectionChange: (Int) -> Void
  let onCenterPress: () -> Void
  let onMenuPress: () -> Void

  @StateObject private var physics: ClickWheelPhysics
  @State private var dragLocation: CGPoint = .zero
  @State private var isDragging: Bool = false

  init(
    numberOfItems: Int, onSelectionChange: @escaping (Int) -> Void,
    onCenterPress: @escaping () -> Void, onMenuPress: @escaping () -> Void
  ) {
    self.numberOfItems = numberOfItems
    self.onSelectionChange = onSelectionChange
    self.onCenterPress = onCenterPress
    self.onMenuPress = onMenuPress
    _physics = StateObject(wrappedValue: ClickWheelPhysics(numberOfItems: numberOfItems))
  }

  var body: some View {
    GeometryReader { geometry in
      let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
      let radius = min(geometry.size.width, geometry.size.height) / 2

      ZStack {
        // Outer wheel body (concave ring effect)
        Circle()
          .fill(
            RadialGradient(
              colors: [
                Color(white: 0.15),
                Color(white: 0.12),
                Color(white: 0.15),
              ],
              center: .center,
              startRadius: radius * 0.4,
              endRadius: radius
            )
          )
          .overlay(
            Circle()
              .strokeBorder(
                LinearGradient(
                  colors: [Color.white.opacity(0.1), Color.clear, Color.black.opacity(0.2)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                ),
                lineWidth: 1
              )
          )
          .frame(width: radius * 2, height: radius * 2)

        // Concave depth illusion
        Circle()
          .stroke(
            LinearGradient(
              colors: [Color.black.opacity(0.4), Color.white.opacity(0.1)],
              startPoint: .top,
              endPoint: .bottom
            ),
            lineWidth: 4
          )
          .padding(2)
          .blur(radius: 2)
          .opacity(0.5)

        // Label Areas (Modern restraint: No icons, just clean interaction surface)

        // Center button (raised 1-2px effect)
        Button(action: {
          physics.centerButtonPress()
          onCenterPress()
        }) {
          ZStack {
            Circle()
              .fill(
                LinearGradient(
                  colors: [
                    Color(white: 0.2),
                    Color(white: 0.18),
                  ],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: radius * 0.45, height: radius * 0.45)
              .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

            // Subtle rim highlight for the "raised" look
            Circle()
              .strokeBorder(
                LinearGradient(
                  colors: [.white.opacity(0.15), .clear],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                ),
                lineWidth: 1
              )
              .frame(width: radius * 0.45, height: radius * 0.45)
          }
        }
        .buttonStyle(PlainButtonStyle())
      }
      .contentShape(Circle())
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            let distanceFromCenter = sqrt(
              pow(value.location.x - center.x, 2) + pow(value.location.y - center.y, 2))
            let centerButtonRadius = radius * 0.225

            // Only handle wheel drag if outside center button
            if distanceFromCenter > centerButtonRadius {
              if !isDragging {
                isDragging = true
                physics.startDrag(at: value.location, center: center)
              } else {
                physics.updateDrag(at: value.location, center: center)
              }
              dragLocation = value.location
            }
          }
          .onEnded { _ in
            isDragging = false
            physics.endDrag()
          }
      )
      .simultaneousGesture(
        TapGesture()
          .onEnded { _ in
            // Menu button tap (top area of the ring)
            let tapLocation = dragLocation
            let dx = tapLocation.x - center.x
            let dy = tapLocation.y - center.y
            let angle = atan2(dy, dx)  // -pi to pi

            let distanceFromCenter = sqrt(dx * dx + dy * dy)
            let innerRadius = radius * 0.225

            // If tap is in the top quadrant and on the ring
            if distanceFromCenter > innerRadius && distanceFromCenter < radius {
              // Normalized angle for "up": around -pi/2
              if angle > -2.3 && angle < -0.8 {
                onMenuPress()
              }
            }
          }
      )
      .onChange(of: physics.selectionIndex) { newIndex in
        onSelectionChange(newIndex)
      }
      .onChange(of: numberOfItems) { newCount in
        // Reset physics when number of items changes
        if physics.numberOfItems != newCount {
          physics.numberOfItems = newCount
        }
      }
    }
  }
}
