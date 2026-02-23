//
//  StickerLayer.swift
//  portfoliopod
//
//  Manages the sticker overlay system
//

import Combine
import SwiftUI
import UIKit

struct Sticker: Identifiable, Codable {
  var id = UUID()
  var imageName: String
  var positionX: CGFloat  // Relative 0-1
  var positionY: CGFloat  // Relative 0-1
  var scale: CGFloat
  var rotationDegrees: Double
}

class StickerStore: ObservableObject {
  @Published var stickers: [Sticker] = []

  init() {
    // Randomized placements for "Old Retro Tech" vibe
    // Using asset names for device compatibility
    stickers = [
      Sticker(
        imageName: "sticker_graffiti",
        positionX: 0.2, positionY: 0.85, scale: 0.45, rotationDegrees: -15
      ),
      Sticker(
        imageName: "sticker_circle_crew",
        positionX: 0.85, positionY: 0.75, scale: 0.35, rotationDegrees: 12
      ),
      Sticker(
        imageName: "sticker_character_1",
        positionX: 0.1, positionY: 0.15, scale: 0.5, rotationDegrees: -5
      ),
      Sticker(
        imageName: "sticker_luffy",
        positionX: 0.9, positionY: 0.2, scale: 0.4, rotationDegrees: 20
      ),
      Sticker(
        imageName: "sticker_helmet_swords",
        positionX: 0.5, positionY: 0.92, scale: 0.4, rotationDegrees: -5
      ),
    ]
  }

  func addSticker(_ sticker: Sticker) {
    stickers.append(sticker)
  }

  func updateStickerPosition(id: UUID, x: CGFloat, y: CGFloat) {
    if let index = stickers.firstIndex(where: { $0.id == id }) {
      stickers[index].positionX = x
      stickers[index].positionY = y
    }
  }

  func removeSticker(id: UUID) {
    withAnimation(.easeOut(duration: 0.3)) {
      stickers.removeAll { $0.id == id }
    }
  }

  func clearStickers() {
    stickers.removeAll()
  }
}

struct StickerLayerView: View {
  @ObservedObject var store: StickerStore

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        ForEach(store.stickers) { sticker in
          // Load from assets (named) or bundle
          let uiImage: UIImage? = UIImage(named: sticker.imageName)

          if let uiImage = uiImage {
            Image(uiImage: uiImage)
              .resizable()
              .scaledToFit()
              .frame(width: geometry.size.width * sticker.scale)
              .rotationEffect(.degrees(sticker.rotationDegrees))
              .position(
                x: geometry.size.width * sticker.positionX,
                y: geometry.size.height * sticker.positionY
              )
              // Retro tech style: Subtle multiply-ish blend and realistic shadow
              .shadow(color: .black.opacity(0.4), radius: 3, x: 2, y: 2)
              // Interactivity
              .gesture(
                DragGesture(coordinateSpace: .named("stickerLayer"))
                  .onChanged { value in
                    // Calculate relative position (0-1)
                    let newX = min(max(value.location.x / geometry.size.width, 0), 1)
                    let newY = min(max(value.location.y / geometry.size.height, 0), 1)
                    store.updateStickerPosition(id: sticker.id, x: newX, y: newY)
                  }
              )
              .onLongPressGesture(minimumDuration: 0.5) {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                store.removeSticker(id: sticker.id)
              }
              .overlay(
                // Noise / Worn texture overlay
                ZStack {
                  Color.black.opacity(0.05)
                  ForEach(0..<5) { _ in
                    Rectangle()
                      .fill(Color.white.opacity(0.05))
                      .frame(width: 1, height: 1)
                      .offset(x: CGFloat.random(in: -20...20), y: CGFloat.random(in: -20...20))
                  }
                }
                .blendMode(.overlay)
                .allowsHitTesting(false)
              )
          } else {
            // Fallback for testing/debugging
            Image(systemName: "questionmark.square.dashed")
              .font(.system(size: 30))
              .foregroundColor(.gray)
              .position(
                x: geometry.size.width * sticker.positionX,
                y: geometry.size.height * sticker.positionY
              )
          }
        }
      }
      .coordinateSpace(name: "stickerLayer")
    }
  }
}
