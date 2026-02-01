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
  @Published var scrollOffset: CGFloat = 0  // Added for content scrolling

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

  // Authentic Click Wheel Sensitivity: Updated for better stability
  let degreesPerStep: Double = 30.0

  // Performance Optimization: Pre-initialize haptic generator
  private let tickGenerator = UIImpactFeedbackGenerator(style: .light)
  private let centerGenerator = UIImpactFeedbackGenerator(style: .medium)

  var tickAngle: Double {
    return (2.0 * .pi) / Double(max(numberOfItems, 1))
  }

  private var displayLink: CADisplayLink?
  private var lastUpdateTime: CFTimeInterval = 0

  init(numberOfItems: Int) {
    print("ClickWheelPhysics: Initializing with \(numberOfItems) items...")
    self.numberOfItems = numberOfItems
    tickGenerator.prepare()
    centerGenerator.prepare()
    startAnimationLoop()
  }

  private func updateTickAngle() {
    // Reset selection when items change
    selectionIndex = 0
    currentAngle = 0
    angularMomentum = 0
    rotationBuffer = 0
    scrollOffset = 0
  }

  func reset(to index: Int = 0) {
    selectionIndex = index
    currentAngle = 0
    angularMomentum = 0
    rotationBuffer = 0
    scrollOffset = 0
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
    lastUpdateTime = currentTime

    guard !isDragging else { return }

    // Apply momentum with friction
    if abs(angularMomentum) > 0.0001 {
      angularMomentum *= friction

      // Update buffer from momentum
      // Update buffer from momentum
      let deltaDegrees = (angularMomentum * 180.0 / .pi)
      rotationBuffer += deltaDegrees

      // Update scroll offset for continuous scrolling
      scrollOffset -= CGFloat(deltaDegrees * 1.5)  // Reduced sensitivity
      processBuffer()

      currentAngle += angularMomentum
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
    scrollOffset -= CGFloat(deltaDegrees * 1.5)  // Reduced sensitivity

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
    // iPod Acceleration Logic: If spinning fast, multiplier increases
    let absVelocity = abs(angularVelocity)
    let accelerationMultiplier = absVelocity > 5.0 ? (1.0 + (absVelocity - 5.0) * 0.2) : 1.0
    let effectiveThreshold = degreesPerStep / accelerationMultiplier

    if abs(rotationBuffer) >= effectiveThreshold {
      let steps = Int(rotationBuffer / effectiveThreshold)

      // Update index with bounds checking
      let proposedIndex = selectionIndex + steps
      let clampedIndex = max(0, min(proposedIndex, numberOfItems - 1))

      if clampedIndex != selectionIndex {
        selectionIndex = clampedIndex
        triggerTickSensory()
      } else {
        // AUTHENTIC BEHAVIOR: If we hit the end of the list,
        // drain the buffer so it doesn't "wind up" against the wall.
        rotationBuffer = 0
      }

      rotationBuffer -= Double(steps) * effectiveThreshold
    }
  }

  var hapticsEnabled: Bool = true

  private func triggerTickSensory() {
    guard hapticsEnabled else { return }

    // Optimized: Use intensity from SettingsStore
    tickGenerator.impactOccurred(intensity: CGFloat(SettingsStore.shared.hapticIntensity))

    // Audio feedback
    SoundManager.shared.playClick()
  }

  public let centerPressSubject = PassthroughSubject<Void, Never>()

  func centerButtonPress() {
    centerGenerator.impactOccurred(intensity: CGFloat(SettingsStore.shared.hapticIntensity))
    centerPressSubject.send()
  }
}
