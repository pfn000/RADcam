import AVFoundation

struct CameraCapabilities {
  let supportsMultiCam: Bool
  let rearDevices: [AVCaptureDevice]
  let mode: String

  static func detect() -> CameraCapabilities {
    let discovery = AVCaptureDevice.DiscoverySession(
      deviceTypes: [.builtInWideAngleCamera, .builtInUltraWideCamera, .builtInTelephotoCamera],
      mediaType: .video,
      position: .back
    )

    let rear = discovery.devices
    let supports = AVCaptureMultiCamSession.isMultiCamSupported

    let mode: String
    if supports && rear.count >= 3 {
      mode = "multi"
    } else if rear.count >= 2 {
      mode = "dual"
    } else {
      mode = "single"
    }

    return CameraCapabilities(supportsMultiCam: supports, rearDevices: rear, mode: mode)
  }
}
