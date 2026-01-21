//
//  MotionManager.swift
//  portfoliopod
//
//  Handles gyroscope and accelerometer data for real-time physics and lighting
//

import Combine
import CoreMotion
import Foundation

class MotionManager: ObservableObject {
  private let motionManager = CMMotionManager()

  @Published var tilt: Double = 0.0
  @Published var shakeDetected: Bool = false

  private var lastShakeTime: Date = .distantPast

  init() {
    // Start motion updates at 60Hz
    if motionManager.isDeviceMotionAvailable {
      motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
      motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (motion, error) in
        guard let self = self, let motion = motion else { return }

        // Tilt (bound to horizontal roll)
        // Normalize and smooth for shader lightAngle
        let roll = motion.attitude.roll
        self.tilt = roll

        // Shake detection (Simple acceleration threshold)
        let accel = motion.userAcceleration
        let totalAccel = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)

        if totalAccel > 2.5 && Date().timeIntervalSince(self.lastShakeTime) > 1.0 {
          self.shakeDetected = true
          self.lastShakeTime = Date()
          // Reset shuffle flag quickly
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shakeDetected = false
          }
        }
      }
    }
  }

  func stopUpdates() {
    motionManager.stopDeviceMotionUpdates()
  }
}
