import AVFoundation
import Metal

final class MultiCamManager: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  static let shared = MultiCamManager()

  private let queue = DispatchQueue(label: "radcam.multicam.queue")
  private let session = AVCaptureMultiCamSession()
  private let capabilities = CameraCapabilities.detect()
  private var outputs: [AVCaptureVideoDataOutput] = []
  private var currentBuffers: [String: CVPixelBuffer] = [:]
  private let encoder = VideoEncoder()
  private var renderer: RadSplatRenderer?
  private var outputTexture: MTLTexture?

  var onFrame: ((MTLTexture, CMTime, Int) -> Void)?

  func configure(device: MTLDevice) throws {
    renderer = try RadSplatRenderer(device: device)
    try queue.sync {
      guard !session.isRunning else { return }
      session.beginConfiguration()
      defer { session.commitConfiguration() }

      let selectedDevices = selectDevices()

      for device in selectedDevices {
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { continue }
        session.addInputWithNoConnections(input)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)

        guard session.canAddOutput(output) else { continue }
        session.addOutputWithNoConnections(output)

        if let port = input.ports.first(where: { $0.mediaType == .video }) {
          let connection = AVCaptureConnection(inputPorts: [port], output: output)
          if session.canAddConnection(connection) {
            session.addConnection(connection)
          }
        }

        outputs.append(output)
      }
    }
  }

  private func selectDevices() -> [AVCaptureDevice] {
    switch capabilities.mode {
    case "multi": return Array(capabilities.rearDevices.prefix(3))
    case "dual": return Array(capabilities.rearDevices.prefix(2))
    default: return Array(capabilities.rearDevices.prefix(1))
    }
  }

  func capabilityReport() -> [String: Any] {
    [
      "supportsMultiCam": capabilities.supportsMultiCam,
      "availableRearCameraIDs": capabilities.rearDevices.map { $0.uniqueID },
      "selectedMode": capabilities.mode
    ]
  }

  func startSession() { queue.async { self.session.startRunning() } }
  func stopSession() { queue.async { self.session.stopRunning() } }

  func startRecording(codec: String) throws -> String {
    let url = try encoder.start(codec: codec, width: 1280, height: 720)
    return url.path
  }

  func stopRecording() async -> String? {
    return await encoder.stop()?.path
  }

  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard
      let renderer,
      let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    else { return }

    let time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
    guard time.isValid else { return }

    currentBuffers[String(describing: ObjectIdentifier(output))] = pixelBuffer

    let textures = currentBuffers.values.compactMap { renderer.makeTexture(from: $0) }
    guard let first = textures.first else { return }

    if outputTexture == nil || outputTexture?.width != first.width || outputTexture?.height != first.height {
      let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: first.width, height: first.height, mipmapped: false)
      descriptor.usage = [.shaderRead, .shaderWrite]
      outputTexture = first.device.makeTexture(descriptor: descriptor)
    }

    guard let outputTexture else { return }
    renderer.render(inputs: textures, output: outputTexture)

    onFrame?(outputTexture, time, textures.count)
    encoder.append(pixelBuffer: pixelBuffer, at: time)
  }
}
