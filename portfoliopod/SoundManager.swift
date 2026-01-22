//
//  SoundManager.swift
//  portfoliopod
//
//  Manages realistic click wheel audio feedback using AVAudioEngine
//

import AVFoundation
import Combine
import Foundation

class SoundManager: ObservableObject {
  static let shared = SoundManager()

  private var engine: AVAudioEngine
  private var playerNode: AVAudioPlayerNode
  private var clickBuffer: AVAudioPCMBuffer?

  @Published var isMuted: Bool = false

  init() {
    engine = AVAudioEngine()
    playerNode = AVAudioPlayerNode()

    setupEngine()
    generateClickBuffer()
  }

  private func setupEngine() {
    engine.attach(playerNode)
    engine.connect(playerNode, to: engine.mainMixerNode, format: nil)

    do {
      try engine.start()
    } catch {
      print("SoundManager: Failed to start engine: \(error)")
    }
  }

  private func generateClickBuffer() {
    // Synthesize a short, crisp mechanic click (Piezo style)
    let format = engine.mainMixerNode.outputFormat(forBus: 0)
    let sampleRate = Float(format.sampleRate)
    let duration = 0.004  // 4ms extremely short mechanic click
    let frameCount = AVAudioFrameCount(sampleRate * Float(duration))

    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
      return
    }
    buffer.frameLength = frameCount

    let channels = Int(format.channelCount)

    // Generate a burst of filtered noise/square wave
    if let floatChannelData = buffer.floatChannelData {
      for frame in 0..<Int(frameCount) {
        let time = Float(frame) / sampleRate
        // Envelope: Fast attack, fast decay
        let envelope = 1.0 - (time / Float(duration))

        // Oscillation: High pitch square-ish wave
        let frequency: Float = 2200.0
        let waveform = sign(sin(2.0 * .pi * frequency * time))

        let sample = waveform * envelope * 0.3  // Volume 0.3

        for channel in 0..<channels {
          floatChannelData[channel][frame] = sample
        }
      }
    }

    self.clickBuffer = buffer
  }

  func playClick() {
    guard !isMuted, let buffer = clickBuffer else { return }

    if !engine.isRunning {
      try? engine.start()
    }

    // Stop ensures we can re-trigger immediately without overlapping weirdness
    if playerNode.isPlaying {
      playerNode.stop()
    }

    playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    playerNode.play()
  }
}
