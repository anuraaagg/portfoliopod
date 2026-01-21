//
//  BootLoaderView.swift
//  portfoliopod
//
//  Classic Apple boot animation
//

import SwiftUI

struct BootLoaderView: View {
  @Binding var isBooting: Bool
  @State private var rotation: Double = 0
  @State private var opacity: Double = 1.0
  @State private var showSpinner: Bool = false

  var body: some View {
    ZStack {
      // Black background
      Color.black
        .ignoresSafeArea()

      VStack(spacing: 30) {
        // Apple logo (using SF Symbol apple.logo)
        Image(systemName: "apple.logo")
          .font(.system(size: 80))
          .foregroundColor(.white)

        // Spinning loader (appears after a delay)
        if showSpinner {
          SpinningLoader()
            .frame(width: 40, height: 40)
            .transition(.opacity)
        }
      }
    }
    .opacity(opacity)
    .onAppear {
      // Show spinner after 0.5s
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        withAnimation(.easeIn(duration: 0.3)) {
          showSpinner = true
        }
      }

      // Fade out after 2s
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        withAnimation(.easeOut(duration: 0.5)) {
          opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          isBooting = false
        }
      }
    }
  }
}

struct SpinningLoader: View {
  @State private var isAnimating = false

  var body: some View {
    GeometryReader { geo in
      let size = min(geo.size.width, geo.size.height)

      ForEach(0..<12) { index in
        RoundedRectangle(cornerRadius: 2)
          .fill(Color.white)
          .frame(width: size * 0.12, height: size * 0.28)
          .offset(y: -size * 0.35)
          .rotationEffect(.degrees(Double(index) * 30))
          .opacity(opacityFor(index: index))
      }
      .frame(width: size, height: size)
      .rotationEffect(.degrees(isAnimating ? 360 : 0))
      .animation(
        Animation.linear(duration: 1.0).repeatForever(autoreverses: false),
        value: isAnimating
      )
      .onAppear {
        isAnimating = true
      }
    }
  }

  private func opacityFor(index: Int) -> Double {
    let baseOpacity = 0.2
    let maxOpacity = 1.0
    let step = (maxOpacity - baseOpacity) / 12.0
    return baseOpacity + step * Double(11 - index)
  }
}
