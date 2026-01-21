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
    // Default stickers (Placeholders until user provides PNGs)
    // We can add some sample stickers if assets are available, otherwise empty.
    // stickers = [
    //   Sticker(imageName: "sticker_apple", positionX: 0.5, positionY: 0.8, scale: 0.1, rotationDegrees: 0)
    // ]
  }

  func addSticker(_ sticker: Sticker) {
    stickers.append(sticker)
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
          // Try to load user provided image, fallback to system image for testing if missing
          if UIImage(named: sticker.imageName) != nil {
            Image(sticker.imageName)
              .resizable()
              .scaledToFit()
              .frame(width: geometry.size.width * sticker.scale)
              .rotationEffect(.degrees(sticker.rotationDegrees))
              .position(
                x: geometry.size.width * sticker.positionX,
                y: geometry.size.height * sticker.positionY
              )
              .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)  // Realistic thickness shadow
          } else {
            // Fallback for testing/debugging
            Image(systemName: "star.fill")  // Placeholder
              .font(.system(size: 50))
              .foregroundColor(.yellow)
              .frame(width: geometry.size.width * sticker.scale)
              .rotationEffect(.degrees(sticker.rotationDegrees))
              .position(
                x: geometry.size.width * sticker.positionX,
                y: geometry.size.height * sticker.positionY
              )
              .opacity(0.8)
          }
        }
      }
    }
  }
}
