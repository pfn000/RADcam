import ExpoModulesCore
import MetalKit

final class RadcamPreviewView: ExpoView, MTKViewDelegate {
  let onFrameMetrics = EventDispatcher()

  private var mtkView: MTKView
  private var texture: MTLTexture?
  private var start = CACurrentMediaTime()
  private var frameCount: Double = 0
  private var activeCameras = 0

  required init(appContext: AppContext? = nil) {
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("Metal unavailable")
    }

    mtkView = MTKView(frame: .zero, device: device)
    mtkView.framebufferOnly = false
    mtkView.colorPixelFormat = .bgra8Unorm
    super.init(appContext: appContext)

    addSubview(mtkView)
    mtkView.delegate = self

    try? MultiCamManager.shared.configure(device: device)
    MultiCamManager.shared.onFrame = { [weak self] texture, _, active in
      self?.texture = texture
      self?.activeCameras = active
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    mtkView.frame = bounds
  }

  func draw(in view: MTKView) {
    guard let texture, let drawable = view.currentDrawable else { return }
    frameCount += 1

    let elapsed = CACurrentMediaTime() - start
    if elapsed >= 1 {
      onFrameMetrics([
        "fps": frameCount / elapsed,
        "activeCameras": activeCameras
      ])
      start = CACurrentMediaTime()
      frameCount = 0
    }

    guard let commandQueue = view.device?.makeCommandQueue(),
          let commandBuffer = commandQueue.makeCommandBuffer(),
          let blit = commandBuffer.makeBlitCommandEncoder() else {
      return
    }

    blit.copy(from: texture,
              sourceSlice: 0,
              sourceLevel: 0,
              sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
              sourceSize: MTLSize(width: texture.width, height: texture.height, depth: 1),
              to: drawable.texture,
              destinationSlice: 0,
              destinationLevel: 0,
              destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
    blit.endEncoding()

    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
}
