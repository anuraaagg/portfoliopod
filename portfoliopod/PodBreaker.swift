//
//  PodBreaker.swift
//  portfoliopod
//
//  Simple brick breaker game controlled by the click wheel
//

import Combine
import SwiftUI

struct PodBreakerView: View {
  @Binding var wheelAngle: Double  // Normalized angle from ClickWheel

  @State private var ballPosition = CGPoint(x: 160, y: 120)
  @State private var ballVelocity = CGPoint(x: 2.5, y: -2.5)
  @State private var paddleX: CGFloat = 160
  @State private var bricks: [Brick] = []
  @State private var gameOver = false

  let timer = Timer.publish(every: 1 / 60, on: .main, in: .common).autoconnect()

  struct Brick: Identifiable {
    let id = UUID()
    var rect: CGRect
    var isDestroyed = false
  }

  init(wheelAngle: Binding<Double>) {
    _wheelAngle = wheelAngle

    var initialBricks: [Brick] = []
    for row in 0..<4 {
      for col in 0..<8 {
        initialBricks.append(
          Brick(
            rect: CGRect(
              x: CGFloat(col * 38 + 10), y: CGFloat(row * 15 + 30), width: 34, height: 10)))
      }
    }
    _bricks = State(initialValue: initialBricks)
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        Color.black.ignoresSafeArea()

        // Bricks
        ForEach(bricks) { brick in
          if !brick.isDestroyed {
            RoundedRectangle(cornerRadius: 2)
              .fill(Color.blue)
              .frame(width: brick.rect.width, height: brick.rect.height)
              .position(x: brick.rect.midX, y: brick.rect.midY)
          }
        }

        // Ball
        Circle()
          .fill(Color.white)
          .frame(width: 8, height: 8)
          .position(ballPosition)

        // Paddle
        RoundedRectangle(cornerRadius: 2)
          .fill(Color.white)
          .frame(width: 50, height: 6)
          .position(x: paddleX, y: geo.size.height - 20)

        if gameOver {
          Text("GAME OVER")
            .foregroundColor(.white)
            .font(.system(size: 24, weight: .bold))
        }
      }
      .onReceive(timer) { _ in
        updateGame(size: geo.size)
      }
      .onChange(of: wheelAngle) { oldAngle, newAngle in
        // Map wheel rotation to paddle movement
        // wheelAngle usually goes 0 to 2pi
        let normalized = newAngle.truncatingRemainder(dividingBy: 2 * .pi)
        let targetX = CGFloat((normalized / (2 * .pi)) * Double(geo.size.width))
        withAnimation(.interactiveSpring()) {
          paddleX = targetX
        }
      }
    }
  }

  private func updateGame(size: CGSize) {
    if gameOver { return }

    // Update position
    ballPosition.x += ballVelocity.x
    ballPosition.y += ballVelocity.y

    // Wall collisions
    if ballPosition.x < 4 || ballPosition.x > size.width - 4 {
      ballVelocity.x *= -1
    }
    if ballPosition.y < 4 {
      ballVelocity.y *= -1
    }

    // Paddle collision
    let paddleRect = CGRect(x: paddleX - 25, y: size.height - 23, width: 50, height: 6)
    if paddleRect.contains(ballPosition) {
      ballVelocity.y *= -1
      ballPosition.y = size.height - 24  // Prevent sticking
    }

    // Brick collision
    for i in 0..<bricks.count {
      if !bricks[i].isDestroyed && bricks[i].rect.contains(ballPosition) {
        bricks[i].isDestroyed = true
        ballVelocity.y *= -1
        break
      }
    }

    // Fall off bottom
    if ballPosition.y > size.height {
      gameOver = true
    }
  }
}
