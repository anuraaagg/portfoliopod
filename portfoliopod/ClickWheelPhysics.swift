//
//  ClickWheelPhysics.swift
//  portfoliopod
//
//  Physics-driven click wheel interaction system
//

import Combine
import SwiftUI
import UIKit

class ClickWheelPhysics: ObservableObject {
  // Physics state
  @Published var currentAngle: Double = 0
  @Published var previousAngle: Double = 0
  @Published var deltaAngle: Double = 0
  @Published var angularVelocity: Double = 0
  @Published var angularMomentum: Double = 0
  @Published var selectionIndex: Int = 0

  // Configuration
  let inertia: Double = 0.85
  let friction: Double = 0.92

  // Interaction state
  @Published var isDragging: Bool = false
  @Published var lastDragAngle: Double = 0
  @Published var rotationBuffer: Double = 0  // Accumulated relative rotation

  @Published var numberOfItems: Int {
    didSet {
      updateTickAngle()
    }
  }

  // Configuration for "stepped" feel
  let degreesPerStep: Double = 60.0  // Significantly slower (more degrees needed per item change)

  var tickAngle: Double {
    return (2.0 * .pi) / Double(max(numberOfItems, 1))
  }

  private var displayLink: CADisplayLink?
  private var lastUpdateTime: CFTimeInterval = 0

  init(numberOfItems: Int) {
    print("ClickWheelPhysics: Initializing with \(numberOfItems) items...")
    self.numberOfItems = numberOfItems
    startAnimationLoop()
  }

  private func updateTickAngle() {
    // Reset selection when items change
    selectionIndex = 0
    currentAngle = 0
    angularMomentum = 0
    rotationBuffer = 0
  }

  deinit {
    stopAnimationLoop()
  }

  func startAnimationLoop() {
    print("ClickWheelPhysics: Starting animation loop...")
    displayLink = CADisplayLink(target: self, selector: #selector(update))
    displayLink?.preferredFramesPerSecond = 60
    displayLink?.add(to: .main, forMode: .common)
  }

  func stopAnimationLoop() {
    displayLink?.invalidate()
    displayLink = nil
  }

  @objc private func update() {
    let currentTime = CACurrentMediaTime()
    let deltaTime = lastUpdateTime > 0 ? currentTime - lastUpdateTime : 0.016
    lastUpdateTime = currentTime

    guard !isDragging else { return }

    // Apply momentum with friction
    if abs(angularMomentum) > 0.0001 {
      angularMomentum *= friction

      // Update buffer from momentum
      let deltaDegrees = (angularMomentum * 180.0 / .pi)
      rotationBuffer += deltaDegrees
      processBuffer()

      currentAngle += angularMomentum
    } else {
      // Momentum Snapping Logic
      // If we are stopped but not perfectly on a tick, gently snap
      // This is simulated by processBuffer checking the threshold
    }
  }

  func normalizeAngle(_ angle: Double) -> Double {
    var normalized = angle
    let fullCircle = 2.0 * .pi
    normalized = normalized.truncatingRemainder(dividingBy: fullCircle)
    if normalized < 0 { normalized += fullCircle }
    return normalized
  }

  func startDrag(at point: CGPoint, center: CGPoint) {
    isDragging = true
    angularMomentum = 0
    // Keep rotationBuffer to avoid "jump" if dragging fast
    lastDragAngle = angleFromPoint(point, center: center)
    previousAngle = lastDragAngle
  }

  func updateDrag(at point: CGPoint, center: CGPoint) {
    guard isDragging else { return }

    let newAngle = angleFromPoint(point, center: center)
    var deltaAngle = newAngle - lastDragAngle

    // Handle wrap-around
    if deltaAngle > .pi {
      deltaAngle -= 2.0 * .pi
    } else if deltaAngle < -.pi {
      deltaAngle += 2.0 * .pi
    }

    currentAngle += deltaAngle
    lastDragAngle = newAngle

    // Update relative buffer (in degrees)
    let deltaDegrees = (deltaAngle * 180.0 / .pi)
    rotationBuffer += deltaDegrees

    processBuffer()

    // Calculate velocity for momentum (with smoothing)
    let instantaneousVelocity = deltaAngle / 0.016
    angularVelocity = (angularVelocity * 0.7) + (instantaneousVelocity * 0.3)
    angularMomentum = angularVelocity * (1.0 - inertia)
  }

  func endDrag() {
    isDragging = false
  }

  func angleFromPoint(_ point: CGPoint, center: CGPoint) -> Double {
    let dx = point.x - center.x
    let dy = point.y - center.y
    return atan2(dy, dx)
  }

  private func processBuffer() {
    // If buffer exceeds threshold, move selection and subtract from buffer
    let threshold = degreesPerStep

    if abs(rotationBuffer) >= threshold {
      let steps = Int(rotationBuffer / threshold)

      // Update index with bounds checking
      let proposedIndex = selectionIndex + steps
      let clampedIndex = max(0, min(proposedIndex, numberOfItems - 1))

      if clampedIndex != selectionIndex {
        selectionIndex = clampedIndex
        triggerTickSensory()
      }

      rotationBuffer -= Double(steps) * threshold
    }
  }

  var hapticsEnabled: Bool = true

  private func triggerTickSensory() {
    guard hapticsEnabled else { return }

    // Taptic feedback for the "tick"
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.prepare()
    generator.impactOccurred(intensity: 0.65)

    // Optional: Log tick for debugging sensory sync
    // print("ClickWheelPhysics: Tick @ Index \(selectionIndex)")
  }

  func centerButtonPress() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
  }
}
