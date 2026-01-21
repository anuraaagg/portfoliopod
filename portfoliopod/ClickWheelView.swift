//
//  ClickWheelView.swift
//  portfoliopod
//
//  Interactive click wheel component
//

import SwiftUI

struct ClickWheelView: View {
  @ObservedObject var physics: ClickWheelPhysics  // Accept injected physics
  let onCenterPress: () -> Void
  let onMenuPress: () -> Void

  @State private var isDragging: Bool = false

  var body: some View {
    GeometryReader { geometry in
      let radius = min(geometry.size.width, geometry.size.height) / 2
      let innerRadius = radius * 0.42

      ZStack {
        // Outer wheel body (Black Click Wheel)
        Circle()
          .fill(
            LinearGradient(
              colors: [Color(white: 0.18), Color(white: 0.12)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )

        // Label Areas (Cardinal icons - white on black)
        Group {
          Image(systemName: "square.grid.2x2.fill")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color.white.opacity(0.7))
            .offset(y: -radius * 0.72)

          Image(systemName: "playpause.fill")
            .font(.system(size: 14))
            .foregroundColor(Color.white.opacity(0.7))
            .offset(y: radius * 0.72)

          Image(systemName: "forward.end.fill")
            .font(.system(size: 14))
            .foregroundColor(Color.white.opacity(0.7))
            .offset(x: radius * 0.72)

          Image(systemName: "backward.end.fill")
            .font(.system(size: 14))
            .foregroundColor(Color.white.opacity(0.7))
            .offset(x: -radius * 0.72)
        }
        .allowsHitTesting(false)

        // Center button (Dark gray matching wheel)
        Circle()
          .fill(
            LinearGradient(
              colors: [Color(white: 0.25), Color(white: 0.18)],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          .frame(width: innerRadius * 2, height: innerRadius * 2)
          .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)

        // Unified Gesture Layer
        GeometryReader { gestureGeo in
          Color.clear
            .contentShape(Circle())
            .gesture(
              DragGesture(minimumDistance: 0)
                .onChanged { value in
                  let dx = value.location.x - (gestureGeo.size.width / 2)
                  let dy = value.location.y - (gestureGeo.size.height / 2)
                  let dist = sqrt(dx * dx + dy * dy)

                  if dist > innerRadius && dist < radius {
                    if !isDragging {
                      isDragging = true
                      physics.startDrag(
                        at: value.location,
                        center: CGPoint(x: gestureGeo.size.width / 2, y: gestureGeo.size.height / 2)
                      )
                    } else {
                      physics.updateDrag(
                        at: value.location,
                        center: CGPoint(x: gestureGeo.size.width / 2, y: gestureGeo.size.height / 2)
                      )
                    }
                  }
                }
                .onEnded { value in
                  let dx = value.location.x - (gestureGeo.size.width / 2)
                  let dy = value.location.y - (gestureGeo.size.height / 2)
                  let dist = sqrt(dx * dx + dy * dy)
                  let moveDist = sqrt(
                    value.translation.width * value.translation.width + value.translation.height
                      * value.translation.height)

                  // TAP DETECTION
                  if moveDist < 15 && dist < innerRadius {
                    print("ClickWheelView: [CENTER TAP DETECTED]")
                    physics.centerButtonPress()
                    onCenterPress()
                  } else if moveDist < 15 && dist > innerRadius && dist < radius {
                    let angle = atan2(dy, dx) + .pi / 2
                    let normalizedAngle = angle < 0 ? angle + 2 * .pi : angle

                    if normalizedAngle > 5.5 || normalizedAngle < 0.7 {
                      onMenuPress()
                    }
                  }

                  isDragging = false
                  physics.endDrag()
                }
            )
        }
      }
      .frame(width: radius * 2, height: radius * 2)
      .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
    }
  }
}
