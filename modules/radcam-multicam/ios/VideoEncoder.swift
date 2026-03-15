import AVFoundation

final class VideoEncoder {
  private var writer: AVAssetWriter?
  private var input: AVAssetWriterInput?
  private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
  private var recordingURL: URL?
  private var startTime: CMTime?

  func start(codec: String, width: Int, height: Int) throws -> URL {
    let fileName = "radcam-\(UUID().uuidString).mov"
    let output = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    let writer = try AVAssetWriter(outputURL: output, fileType: .mov)

    let codecType: AVVideoCodecType = codec == "h264" ? .h264 : .hevc
    let settings: [String: Any] = [
      AVVideoCodecKey: codecType,
      AVVideoWidthKey: width,
      AVVideoHeightKey: height
    ]

    let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    input.expectsMediaDataInRealTime = true

    let attrs: [String: Any] = [
      kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA),
      kCVPixelBufferWidthKey as String: width,
      kCVPixelBufferHeightKey as String: height,
      kCVPixelBufferMetalCompatibilityKey as String: true
    ]

    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: attrs)

    guard writer.canAdd(input) else { throw NSError(domain: "radcam", code: -20) }
    writer.add(input)

    self.writer = writer
    self.input = input
    self.adaptor = adaptor
    self.recordingURL = output
    self.startTime = nil

    writer.startWriting()
    return output
  }

  func append(pixelBuffer: CVPixelBuffer, at time: CMTime) {
    guard let writer, let input, let adaptor else { return }
    if startTime == nil {
      startTime = time
      writer.startSession(atSourceTime: time)
    }
    guard input.isReadyForMoreMediaData else { return }
    adaptor.append(pixelBuffer, withPresentationTime: time)
  }

  func stop() async -> URL? {
    guard let writer, let input else { return nil }
    input.markAsFinished()
    await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
      writer.finishWriting {
        continuation.resume()
      }
    }
    let url = recordingURL
    self.writer = nil
    self.input = nil
    self.adaptor = nil
    self.recordingURL = nil
    return url
  }
}
