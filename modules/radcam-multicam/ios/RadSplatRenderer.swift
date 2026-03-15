import Metal
import CoreVideo

final class RadSplatRenderer {
  private let device: MTLDevice
  private let commandQueue: MTLCommandQueue
  private let radialPipeline: MTLComputePipelineState
  private let compositePipeline: MTLComputePipelineState
  private var textureCache: CVMetalTextureCache?

  init(device: MTLDevice) throws {
    self.device = device
    guard let queue = device.makeCommandQueue() else {
      throw NSError(domain: "radcam", code: -100, userInfo: [NSLocalizedDescriptionKey: "No command queue"])
    }
    commandQueue = queue

    let bundle = Bundle(for: RadcamMulticamModule.self)
    let library = try device.makeDefaultLibrary(bundle: bundle)
    radialPipeline = try device.makeComputePipelineState(function: library.makeFunction(name: "radialSplatKernel")!)
    compositePipeline = try device.makeComputePipelineState(function: library.makeFunction(name: "compositeKernel")!)

    CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
  }

  func makeTexture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
    guard let textureCache else { return nil }
    let width = CVPixelBufferGetWidth(pixelBuffer)
    let height = CVPixelBufferGetHeight(pixelBuffer)

    var cvTexture: CVMetalTexture?
    let status = CVMetalTextureCacheCreateTextureFromImage(
      nil,
      textureCache,
      pixelBuffer,
      nil,
      .bgra8Unorm,
      width,
      height,
      0,
      &cvTexture
    )

    guard status == kCVReturnSuccess, let cvTexture else { return nil }
    return CVMetalTextureGetTexture(cvTexture)
  }

  func render(inputs: [MTLTexture], output: MTLTexture) {
    guard let cmd = commandQueue.makeCommandBuffer() else { return }

    for input in inputs {
      if let enc = cmd.makeComputeCommandEncoder() {
        enc.setComputePipelineState(radialPipeline)
        enc.setTexture(input, index: 0)
        enc.setTexture(output, index: 1)

        let threads = MTLSize(width: 8, height: 8, depth: 1)
        let groups = MTLSize(width: (output.width + 7) / 8, height: (output.height + 7) / 8, depth: 1)
        enc.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
        enc.endEncoding()
      }
    }

    if let enc = cmd.makeComputeCommandEncoder() {
      enc.setComputePipelineState(compositePipeline)
      enc.setTexture(output, index: 0)
      enc.setTexture(output, index: 1)
      let threads = MTLSize(width: 8, height: 8, depth: 1)
      let groups = MTLSize(width: (output.width + 7) / 8, height: (output.height + 7) / 8, depth: 1)
      enc.dispatchThreadgroups(groups, threadsPerThreadgroup: threads)
      enc.endEncoding()
    }

    cmd.commit()
  }
}
