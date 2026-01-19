//
//  AccessibilitySupport.swift
//  portfoliopod
//
//  Accessibility and reduced motion support
//

import SwiftUI
import Combine

class AccessibilitySettings: ObservableObject {
    @Published var reducedMotion: Bool = false
    @Published var disableHaptics: Bool = false
    
    init() {
        // Check system accessibility settings
        reducedMotion = UIAccessibility.isReduceMotionEnabled
        disableHaptics = UIAccessibility.isAssistiveTouchRunning
        
        // Listen for changes
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reducedMotion = UIAccessibility.isReduceMotionEnabled
        }
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
