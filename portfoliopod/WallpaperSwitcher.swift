//
//  WallpaperSwitcher.swift
//  portfoliopod
//
//  iOS-Style Lock Screen Switcher
//

import PhotosUI
import SwiftUI

struct WallpaperSwitcher: View {
  @ObservedObject var settings = SettingsStore.shared
  @Binding var isPresented: Bool
  @State private var showPhotoPicker = false
  @State private var selectedItem: PhotosPickerItem? = nil
  @State private var pendingImage: UIImage? = nil  // Validated image ready for preview
  @State private var showError = false
  @State private var errorMessage = ""

  var body: some View {
    ZStack {
      // 1. Main Switcher UI
      switcherContent
        .opacity(pendingImage == nil ? 1 : 0)

      // 2. Preview Overlay (Apple-style alignment step)
      if let image = pendingImage {
        WallpaperPreviewView(
          image: image,
          onCancel: {
            withAnimation {
              pendingImage = nil
              selectedItem = nil
            }
          },
          onSet: {
            // Commit the wallpaper
            let success = settings.addUserWallpaper(image: image)
            withAnimation {
              pendingImage = nil
              selectedItem = nil
            }
            if !success {
              errorMessage = "Failed to save wallpaper. Please try again."
              showError = true
            }
          }
        )
        .transition(.opacity)
        .zIndex(10)
      }
    }
    .onChange(of: selectedItem) {
      guard let item = selectedItem else { return }
      Task {
        do {
          if let data = try await item.loadTransferable(type: Data.self),
            let uiImage = UIImage(data: data)
          {
            await MainActor.run {
              withAnimation {
                pendingImage = uiImage
              }
            }
          } else {
            await MainActor.run {
              errorMessage = "Failed to load image. Please try again."
              showError = true
            }
          }
        } catch {
          await MainActor.run {
            errorMessage = "Error loading image: \(error.localizedDescription)"
            showError = true
          }
        }
      }
    }
    .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
    .alert("Error", isPresented: $showError) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage)
    }
  }

  var switcherContent: some View {
    ZStack {
      // Blur Background
      Rectangle()
        .fill(.ultraThinMaterial)
        .ignoresSafeArea()
        .onTapGesture {
          withAnimation {
            isPresented = false
          }
        }

      VStack(spacing: 0) {

        // Carousel
        TabView(selection: $settings.selectedWallpaperID) {
          ForEach(settings.availableWallpapers) { wallpaper in
            WallpaperCard(
              wallpaper: wallpaper,
              isSelected: settings.selectedWallpaperID == wallpaper.id
            )
            .tag(wallpaper.id)
            .onTapGesture {
              withAnimation {
                settings.selectedWallpaperID = wallpaper.id
              }
            }
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .frame(width: UIScreen.main.bounds.width, height: 580)
        .padding(.top, 60)

        Spacer()

        // Action Buttons
        HStack(spacing: 20) {
          Button(action: {
            withAnimation {
              isPresented = false
            }
          }) {
            Text("Done")
              .font(.system(size: 15, weight: .semibold))
              .foregroundColor(.black)
              .padding(.horizontal, 30)
              .padding(.vertical, 12)
              .background(Color.white.opacity(0.9))
              .clipShape(Capsule())
              .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
          }

          Button(action: {
            showPhotoPicker = true
          }) {
            HStack(spacing: 8) {
              Image(systemName: "photo")
                .font(.system(size: 16, weight: .semibold))
              Text("Add Photo")
                .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.blue)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
          }
        }
        .padding(.bottom, 60)
      }
    }
  }
}

// MARK: - Subviews

struct WallpaperPreviewView: View {
  let image: UIImage
  let onCancel: () -> Void
  let onSet: () -> Void

  var body: some View {
    ZStack {
      // Background
      Color.black
        .ignoresSafeArea()

      // Fullscreen Preview
      Image(uiImage: image)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()

      // Control buttons
      VStack {
        HStack {
          Button(action: onCancel) {
            Text("Cancel")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(.white)
              .padding(.horizontal, 20)
              .padding(.vertical, 12)
              .background(.ultraThinMaterial)
              .cornerRadius(20)
          }

          Spacer()

          Button(action: onSet) {
            Text("Set Wallpaper")
              .font(.system(size: 16, weight: .bold))
              .foregroundColor(.white)
              .padding(.horizontal, 20)
              .padding(.vertical, 12)
              .background(Color.blue)
              .cornerRadius(20)
          }
        }
        .padding(.top, 60)
        .padding(.horizontal, 20)

        Spacer()
      }
    }
  }
}

struct WallpaperCard: View {
  let wallpaper: SettingsStore.Wallpaper
  let isSelected: Bool
  @State private var showDeleteConfirmation = false
  @ObservedObject var settings = SettingsStore.shared

  var body: some View {
    ZStack {
      // Background blur effect
      RoundedRectangle(cornerRadius: 24)
        .fill(.ultraThinMaterial)
        .opacity(0.3)

      // Thumbnail with fixed aspect ratio container
      ZStack {
        if wallpaper.type == .gradient {
          LinearGradient(
            colors: wallpaper.swiftUIColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        } else if wallpaper.type == .image {
          WallpaperThumbnail(
            imageName: wallpaper.imageName,
            thumbnailName: wallpaper.thumbnailName
          )
        }
      }
      .frame(width: 280, height: 500)
      .clipShape(RoundedRectangle(cornerRadius: 24))

      // Checkmark Overlay
      if isSelected {
        VStack {
          Spacer()
          ZStack {
            Circle()
              .fill(Color.blue)
              .frame(width: 50, height: 50)

            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 32))
              .foregroundColor(.white)
          }
          .shadow(radius: 4)
          .padding(.bottom, 30)
        }
        .frame(width: 280, height: 500)
      }

      // Delete button for user-added wallpapers
      if wallpaper.isUserAdded {
        VStack {
          HStack {
            Spacer()
            Button(action: {
              showDeleteConfirmation = true
            }) {
              ZStack {
                Circle()
                  .fill(Color.white.opacity(0.9))
                  .frame(width: 36, height: 36)

                Image(systemName: "trash.circle.fill")
                  .font(.system(size: 28))
                  .foregroundColor(.red)
              }
              .shadow(radius: 4)
            }
            .padding(15)
          }
          Spacer()
        }
        .frame(width: 280, height: 500)
      }
    }
    .frame(width: 300, height: 520)
    .clipShape(RoundedRectangle(cornerRadius: 24))
    .overlay(
      RoundedRectangle(cornerRadius: 24)
        .stroke(Color.white.opacity(isSelected ? 0.5 : 0.2), lineWidth: isSelected ? 2 : 1)
    )
    .scaleEffect(isSelected ? 1.0 : 0.88)
    .opacity(isSelected ? 1.0 : 0.75)
    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isSelected)
    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
    .alert("Delete Wallpaper?", isPresented: $showDeleteConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        settings.deleteWallpaper(id: wallpaper.id)
      }
    } message: {
      Text("This wallpaper will be permanently deleted.")
    }
  }
}

struct WallpaperThumbnail: View {
  let imageName: String?
  let thumbnailName: String?

  var body: some View {
    ZStack {
      Color.black.opacity(0.1)

      Group {
        // Prefer thumbnail for better performance, fall back to full image
        if let thumbName = thumbnailName, let uiImage = loadUserImage(named: thumbName) {
          Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
        } else if let imgName = imageName, let uiImage = loadUserImage(named: imgName) {
          Image(uiImage: uiImage)
            .resizable()
            .scaledToFit()
        } else if let imgName = imageName {
          // Fall back to asset catalog
          Image(imgName)
            .resizable()
            .scaledToFit()
        }
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
