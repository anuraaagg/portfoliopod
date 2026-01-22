//
//  PodBreaker.swift
//  portfoliopod
//
//  Classic mechanical brick breaker game controlled by the click wheel
//

import Combine
import SwiftUI

struct PodBreakerView: View {
  @ObservedObject var physics: ClickWheelPhysics

  enum GameState {
    case menu
    case playing
    case gameOver
    case victory
  }

  @State private var gameState: GameState = .menu
  @State private var ballPosition = CGPoint(x: 160, y: 160)
  @State private var ballVelocity = CGPoint(x: 0, y: 0)
  @State private var paddleX: CGFloat = 160
  @State private var bricks: [Brick] = []
  @State private var score = 0
  @State private var lives = 3

  // Game Constants
  let paddleWidth: CGFloat = 60
  let paddleHeight: CGFloat = 8
  let ballRadius: CGFloat = 5
  let brickRows = 5
  let brickCols = 8

  // Timer for game loop
  let timer = Timer.publish(every: 1 / 60, on: .main, in: .common).autoconnect()

  struct Brick: Identifiable {
    let id = UUID()
    var rect: CGRect
    var color: Color
    var isDestroyed = false
    var pointValue: Int
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        Color.black.ignoresSafeArea()

        // --- Game World ---

        // Bricks
        ForEach(bricks) { brick in
          if !brick.isDestroyed {
            RoundedRectangle(cornerRadius: 2)
              .fill(brick.color)
              .frame(width: brick.rect.width - 2, height: brick.rect.height - 2)  // Gap between bricks
              .position(x: brick.rect.midX, y: brick.rect.midY)
              .shadow(color: brick.color.opacity(0.5), radius: 2, x: 0, y: 0)
          }
        }

        // Ball
        Circle()
          .fill(Color.white)
          .frame(width: ballRadius * 2, height: ballRadius * 2)
          .position(ballPosition)
          .shadow(color: .white.opacity(0.8), radius: 4)

        // Paddle
        RoundedRectangle(cornerRadius: 3)
          .fill(Color.white)
          .frame(width: paddleWidth, height: paddleHeight)
          .position(x: paddleX, y: geo.size.height - 30)
          .shadow(color: .blue.opacity(0.5), radius: 5)

        // --- HUD ---
        VStack {
          HStack {
            Text("SCORE: \(score)")
              .font(.system(size: 12, weight: .bold, design: .monospaced))
              .foregroundColor(.white)
            Spacer()
            HStack(spacing: 4) {
              ForEach(0..<max(0, lives), id: \.self) { _ in
                Image(systemName: "heart.fill")
                  .font(.system(size: 10))
                  .foregroundColor(.red)
              }
            }
          }
          .padding(.horizontal, 12)
          .padding(.top, 8)
          Spacer()
        }

        // --- States Overlays ---
        if gameState == .menu {
          VStack(spacing: 16) {
            Text("POD BREAKER")
              .font(.system(size: 28, weight: .heavy, design: .rounded))
              .foregroundColor(.white)
              .shadow(color: .blue, radius: 10)

            Text("Press Center to Start")
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(.gray)
              .blinking(duration: 1.0)
          }
          .background(Color.black.opacity(0.7).cornerRadius(12))
        } else if gameState == .gameOver {
          VStack(spacing: 12) {
            Text("GAME OVER")
              .font(.system(size: 24, weight: .bold))
              .foregroundColor(.red)

            Text("Final Score: \(score)")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(.white)

            Text("Press Center to Retry")
              .font(.system(size: 12))
              .foregroundColor(.gray)
          }
          .padding(20)
          .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
        } else if gameState == .victory {
          VStack(spacing: 12) {
            Text("YOU WON!")
              .font(.system(size: 24, weight: .bold))
              .foregroundColor(.green)

            Text("Score: \(score)")
              .font(.system(size: 16, weight: .medium))
              .foregroundColor(.white)

            Text("Press Center to Play Again")
              .font(.system(size: 12))
              .foregroundColor(.gray)
          }
          .padding(20)
          .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.1)))
        }

      }
      .onAppear {
        resetGame(fullReset: true)
      }
      .onReceive(timer) { _ in
        updateGame(size: geo.size)
      }
      .onReceive(physics.$currentAngle) { angle in
        // Map wheel rotation to paddle movement directly
        // Use normalized angle (0 to 2pi) mapped to screen width
        let normalized = angle.truncatingRemainder(dividingBy: 2 * .pi)
        let positiveAngle = normalized < 0 ? normalized + 2 * .pi : normalized

        let targetX = CGFloat((positiveAngle / (2 * .pi)) * Double(geo.size.width))

        // Smooth interpolation for paddle
        withAnimation(.linear(duration: 0.05)) {
          paddleX = targetX
        }
      }
      .onReceive(physics.centerPressSubject) {
        handleCenterPress(size: geo.size)
      }
    }
  }

  private func handleCenterPress(size: CGSize) {
    if gameState == .menu || gameState == .gameOver || gameState == .victory {
      resetGame(fullReset: true)
      gameState = .playing
      launchBall()
    } else if gameState == .playing {
      if ballVelocity == .zero {
        launchBall()
      }
    }
  }

  private func resetGame(fullReset: Bool) {
    if fullReset {
      score = 0
      lives = 3

      // Initialize Bricks
      var newBricks: [Brick] = []
      let colors: [Color] = [.red, .orange, .yellow, .green, .blue]

      let brickW: CGFloat = 34
      let brickH: CGFloat = 12
      let startY: CGFloat = 40

      for row in 0..<brickRows {
        for col in 0..<brickCols {
          let x = CGFloat(col) * (brickW + 4) + 24
          let y = startY + CGFloat(row) * (brickH + 4)
          newBricks.append(
            Brick(
              rect: CGRect(x: x, y: y, width: brickW, height: brickH),
              color: colors[row % colors.count],
              pointValue: (brickRows - row) * 10
            ))
        }
      }
      bricks = newBricks
    }

    // Reset Ball Logic
    ballPosition = CGPoint(x: paddleX, y: 200)
    ballVelocity = .zero
  }

  private func launchBall() {
    // Randomize start direction slightly
    let randomX = Double.random(in: -2...2)
    ballVelocity = CGPoint(x: randomX, y: -3.5)
  }

  private func updateGame(size: CGSize) {
    if gameState != .playing { return }

    // Check if ball is waiting to launch (lives lost but game continues)
    if ballVelocity == .zero {
      ballPosition = CGPoint(x: paddleX, y: size.height - 40)
      return
    }

    // Move Ball
    ballPosition.x += ballVelocity.x
    ballPosition.y += ballVelocity.y

    // Wall Collisions
    if ballPosition.x <= ballRadius || ballPosition.x >= size.width - ballRadius {
      ballVelocity.x *= -1
    }
    if ballPosition.y <= ballRadius {
      ballVelocity.y *= -1
    }

    // Paddle Collision
    let paddleRect = CGRect(
      x: paddleX - paddleWidth / 2, y: size.height - 30 - paddleHeight / 2, width: paddleWidth,
      height: paddleHeight)
    let ballRect = CGRect(
      x: ballPosition.x - ballRadius, y: ballPosition.y - ballRadius, width: ballRadius * 2,
      height: ballRadius * 2)

    if paddleRect.intersects(ballRect) && ballVelocity.y > 0 {
      ballVelocity.y *= -1

      // Add "English" (spin) based on where it hit the paddle
      let hitOffset = (ballPosition.x - paddleX) / (paddleWidth / 2)
      ballVelocity.x += hitOffset * 2.0

      // Cap speed
      // ballVelocity.x = min(max(ballVelocity.x, -5), 5)
    }

    // Brick Collision
    for i in 0..<bricks.count {
      if !bricks[i].isDestroyed {
        if bricks[i].rect.intersects(ballRect) {
          bricks[i].isDestroyed = true
          ballVelocity.y *= -1
          score += bricks[i].pointValue

          // Slight speed increase
          ballVelocity.x *= 1.02
          ballVelocity.y *= 1.02

          let generator = UIImpactFeedbackGenerator(style: .light)
          generator.impactOccurred()

          // Check Victory
          if bricks.allSatisfy({ $0.isDestroyed }) {
            gameState = .victory
          }
          break  // Only hit one brick per frame
        }
      }
    }

    // Death Logic
    if ballPosition.y > size.height {
      lives -= 1
      if lives > 0 {
        // Serve again
        ballVelocity = .zero
      } else {
        gameState = .gameOver
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
      }
    }
  }
}

// Helper for blinking text
struct BlinkingViewModifier: ViewModifier {
  let duration: Double
  @State private var blinking: Bool = false

  func body(content: Content) -> some View {
    content
      .opacity(blinking ? 0 : 1)
      .onAppear {
        withAnimation(.easeOut(duration: duration).repeatForever()) {
          blinking = true
        }
      }
  }
}

extension View {
  func blinking(duration: Double = 1.0) -> some View {
    modifier(BlinkingViewModifier(duration: duration))
  }
}
