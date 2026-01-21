//
//  MetalRenderer.swift
//  portfoliopod
//
//  Metal renderer for device shell
//

import Metal
import MetalKit
import SwiftUI
import UIKit

class MetalRenderer: NSObject, MTKViewDelegate {
  var device: MTLDevice?
  var commandQueue: MTLCommandQueue?
  var renderPipelineState: MTLRenderPipelineState?
  var vertexBuffer: MTLBuffer?

  // Shader parameters
  var resolution: SIMD2<Float> = SIMD2<Float>(0, 0)
  var time: Float = 0
  var lightAngle: Float = 0
  var roughness: Float = 0.6
  var grainScale: Float = 0.003
  var vignetteAmount: Float = 0.15

  override init() {
    super.init()
    setupMetal()
  }

  func setupMetal() {
    print("MetalRenderer: Starting setup...")
    device = MTLCreateSystemDefaultDevice()
    guard let device = device else {
      print("MetalRenderer Error: Metal is not supported on this device/simulator")
      return
    }

    commandQueue = device.makeCommandQueue()
    print("MetalRenderer: Command queue created.")

    // Load shader library
    guard let library = device.makeDefaultLibrary() else {
      print(
        "MetalRenderer Error: Could not make default library. Check Shaders.metal target membership."
      )
      return
    }

    guard let vertexFunction = library.makeFunction(name: "vertex_main"),
      let fragmentFunction = library.makeFunction(name: "fragment_main")
    else {
      print("MetalRenderer Error: Could not find shader functions.")
      return
    }

    // Create vertex descriptor
    let vertexDescriptor = MTLVertexDescriptor()

    // Position attribute
    vertexDescriptor.attributes[0].format = .float2
    vertexDescriptor.attributes[0].offset = 0
    vertexDescriptor.attributes[0].bufferIndex = 0

    // TexCoord attribute
    vertexDescriptor.attributes[1].format = .float2
    vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 2
    vertexDescriptor.attributes[1].bufferIndex = 0

    // Layout
    vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 4

    // Create render pipeline
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
    pipelineDescriptor.vertexDescriptor = vertexDescriptor

    do {
      renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
      print("MetalRenderer: Pipeline state created.")
    } catch {
      print("MetalRenderer Error: Failed to create render pipeline: \(error)")
    }

    // Create fullscreen quad vertices
    let vertices: [Float] = [
      -1.0, -1.0, 0.0, 1.0,
      1.0, -1.0, 1.0, 1.0,
      -1.0, 1.0, 0.0, 0.0,
      1.0, 1.0, 1.0, 0.0,
    ]

    vertexBuffer = device.makeBuffer(
      bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: [])
    print("MetalRenderer: Vertex buffer created.")
  }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    resolution = SIMD2<Float>(Float(size.width), Float(size.height))
  }

  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable,
      let commandQueue = commandQueue,
      let renderPipelineState = renderPipelineState,
      let vertexBuffer = vertexBuffer,
      let commandBuffer = commandQueue.makeCommandBuffer(),
      let renderPassDescriptor = view.currentRenderPassDescriptor
    else {
      return
    }

    time += 0.016  // ~60fps

    // lightAngle is now driven externally via MotionManager

    guard
      let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    else {
      return
    }

    renderEncoder.setRenderPipelineState(renderPipelineState)

    // Set vertex buffer
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)

    // Set fragment parameters
    var res = resolution
    var t = time
    var la = lightAngle
    var r = roughness
    var gs = grainScale
    var va = vignetteAmount

    renderEncoder.setFragmentBytes(&res, length: MemoryLayout<SIMD2<Float>>.size, index: 0)
    renderEncoder.setFragmentBytes(&t, length: MemoryLayout<Float>.size, index: 1)
    renderEncoder.setFragmentBytes(&la, length: MemoryLayout<Float>.size, index: 2)
    renderEncoder.setFragmentBytes(&r, length: MemoryLayout<Float>.size, index: 3)
    renderEncoder.setFragmentBytes(&gs, length: MemoryLayout<Float>.size, index: 4)
    renderEncoder.setFragmentBytes(&va, length: MemoryLayout<Float>.size, index: 5)

    renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
    renderEncoder.endEncoding()

    commandBuffer.present(drawable)
    commandBuffer.commit()
  }
}

struct MetalView: UIViewRepresentable {
  var lightAngle: Float

  func makeUIView(context: Context) -> MTKView {
    let mtkView = MTKView()
    mtkView.device = MTLCreateSystemDefaultDevice()
    mtkView.delegate = context.coordinator
    mtkView.preferredFramesPerSecond = 60
    mtkView.enableSetNeedsDisplay = false
    mtkView.isPaused = false
    mtkView.framebufferOnly = false
    return mtkView
  }

  func updateUIView(_ uiView: MTKView, context: Context) {
    context.coordinator.lightAngle = lightAngle
  }

  func makeCoordinator() -> MetalRenderer {
    MetalRenderer()
  }
}
