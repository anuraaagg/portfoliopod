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
  @Published var numberOfItems: Int {
    didSet {
      updateTickAngle()
    }
  }

  var tickAngle: Double {
    return (2.0 * .pi) / Double(max(numberOfItems, 1))
  }

  private var displayLink: CADisplayLink?
  private var lastUpdateTime: CFTimeInterval = 0

  init(numberOfItems: Int) {
    self.numberOfItems = numberOfItems
    startAnimationLoop()
  }

  private func updateTickAngle() {
    // Reset selection when items change
    selectionIndex = 0
    currentAngle = 0
    angularMomentum = 0
  }

  deinit {
    stopAnimationLoop()
  }

  func startAnimationLoop() {
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

    // Apply momentum
    if abs(angularMomentum) > 0.0001 {
      angularMomentum *= friction

      // Edge resistance (soft resistance, never hard stops)
      // But for a continuous wheel, we only apply this if we want to simulate bounds.
      // In the iPod, it's a continuous circle, but the list has bounds.
      // We'll handle list bounds resistance here.

      currentAngle += angularMomentum

      // Update selection based on angle
      updateSelectionFromAngle()

      // Snap to nearest item when momentum is low
      if abs(angularMomentum) < 0.005 {
        snapToNearestItem()
      }
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

    // Calculate velocity for momentum
    angularVelocity = deltaAngle / 0.016
    angularMomentum = (angularMomentum * 0.5) + (angularVelocity * (1.0 - inertia))

    updateSelectionFromAngle()
  }

  func endDrag() {
    isDragging = false
    // Momentum will continue via update loop
  }

  func angleFromPoint(_ point: CGPoint, center: CGPoint) -> Double {
    let dx = point.x - center.x
    let dy = point.y - center.y
    return atan2(dy, dx)
  }

  func updateSelectionFromAngle() {
    let normalized = normalizeAngle(currentAngle)
    let targetIndex = Int((normalized / tickAngle).rounded()) % numberOfItems
    let newIndex = targetIndex < 0 ? targetIndex + numberOfItems : targetIndex

    if newIndex != selectionIndex {
      selectionIndex = newIndex
      // Trigger haptic feedback
      triggerHaptic(.light)
    }
  }

  func snapToNearestItem() {
    let normalized = normalizeAngle(currentAngle)
    let targetAngle = Double(selectionIndex) * tickAngle

    var diff = targetAngle - normalized
    if diff > .pi { diff -= 2.0 * .pi }
    if diff < -.pi { diff += 2.0 * .pi }

    // Cubic-out snapping animation (120-180ms)
    withAnimation(.timingCurve(0.215, 0.61, 0.355, 1, duration: 0.15)) {
      currentAngle += diff
    }

    angularMomentum = 0
  }

  var hapticsEnabled: Bool = true

  func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
    guard hapticsEnabled else { return }
    let generator = UIImpactFeedbackGenerator(style: style)
    generator.impactOccurred()
  }

  func centerButtonPress() {
    triggerHaptic(.medium)
  }
}
