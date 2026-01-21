//
//  AccessibilitySupport.swift
//  portfoliopod
//
//  Accessibility and reduced motion support
//

import Combine
import SwiftUI

class AccessibilitySettings: ObservableObject {
  @Published var reducedMotion: Bool = false
  @Published var disableHaptics: Bool = false

  init() {
    print("AccessibilitySettings: Initializing...")
    // Check system accessibility settings
    reducedMotion = UIAccessibility.isReduceMotionEnabled
    disableHaptics = UIAccessibility.isAssistiveTouchRunning

    // Listen for changes
    NotificationCenter.default.addObserver(
      forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      guard let self = self else { return }
      self.reducedMotion = UIAccessibility.isReduceMotionEnabled
      print("AccessibilitySettings: Reduced motion changed to \(self.reducedMotion)")
    }
    print("AccessibilitySettings: Initialized.")
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }
}

extension View {
  func withAccessibilitySupport(_ settings: AccessibilitySettings) -> some View {
    self
      .animation(settings.reducedMotion ? nil : .default, value: UUID())
  }
}
