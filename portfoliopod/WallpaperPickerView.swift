//
//  WallpaperPickerView.swift
//  portfoliopod
//
//  Horizontal picker for selecting wallpapers
//

import SwiftUI

struct WallpaperPickerView: View {
  @ObservedObject var settings = SettingsStore.shared
  @Binding var isPresented: Bool

  var body: some View {
    VStack(spacing: 20) {
      Text("CHOOSE WALLPAPER")
        .font(.system(size: 14, weight: .bold, design: .monospaced))
        .foregroundColor(.white)
        .padding(.top, 20)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 15) {
          ForEach(settings.availableWallpapers) { wallpaper in
            WallpaperOptionCard(
              wallpaper: wallpaper,
              isSelected: settings.selectedWallpaperID == wallpaper.id
            ) {
              withAnimation {
                settings.selectedWallpaperID = wallpaper.id
              }
            }
          }
        }
        .padding(.horizontal, 20)
      }
      .frame(height: 120)

      Button(action: {
        withAnimation {
          isPresented = false
        }
      }) {
        Text("DONE")
          .font(.system(size: 14, weight: .bold, design: .monospaced))
          .foregroundColor(.black)
          .padding(.horizontal, 30)
          .padding(.vertical, 10)
          .background(Color.white)
          .cornerRadius(20)
      }
      .padding(.bottom, 20)
    }
    .background(Color.black.opacity(0.85))
    .cornerRadius(20)
    .padding(20)
  }
}

struct WallpaperOptionCard: View {
  let wallpaper: SettingsStore.Wallpaper
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        ZStack {
          if wallpaper.type == .gradient {
            LinearGradient(
              colors: wallpaper.swiftUIColors,
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          } else if wallpaper.type == .image, let imageName = wallpaper.imageName {
            Image(imageName)
              .resizable()
              .aspectRatio(contentMode: .fill)
          }
        }
        .frame(width: 80, height: 80)
        .cornerRadius(12)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(isSelected ? Color.green : Color.clear, lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

        Text(wallpaper.name.uppercased())
          .font(.system(size: 10, weight: .semibold, design: .monospaced))
          .foregroundColor(isSelected ? .green : .white)
          .lineLimit(1)
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}
