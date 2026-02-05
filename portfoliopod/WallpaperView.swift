//
//  WallpaperView.swift
//  portfoliopod
//
//  Renders the dynamic background
//

import SwiftUI

struct WallpaperView: View {
  let wallpaper: SettingsStore.Wallpaper
  @State private var animateGradient: Bool = false

  var body: some View {
    ZStack {
      if wallpaper.type == .gradient {
        // Animated Gradient
        LinearGradient(
          colors: wallpaper.swiftUIColors,
          startPoint: animateGradient ? .topLeading : .bottomLeading,
          endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .onAppear {
          withAnimation(.linear(duration: 10.0).repeatForever(autoreverses: true)) {
            animateGradient.toggle()
          }
        }
        .ignoresSafeArea()
      } else if wallpaper.type == .image, let imageName = wallpaper.imageName {
        // Image Wallpaper - full screen fill
        Group {
          if let uiImage = loadUserImage(named: imageName) {
            Image(uiImage: uiImage)
              .resizable()
          } else {
            Image(imageName)
              .resizable()
          }
        }
        .aspectRatio(contentMode: .fill)
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .ignoresSafeArea()
      }
    }
  }

  private func loadUserImage(named filename: String) -> UIImage? {
    if let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
      .first
    {
      let fileURL = documentsDir.appendingPathComponent(filename)
      if FileManager.default.fileExists(atPath: fileURL.path) {
        return UIImage(contentsOfFile: fileURL.path)
      }
    }
    return nil
  }
}
