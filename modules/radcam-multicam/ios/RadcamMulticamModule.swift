import ExpoModulesCore

public final class RadcamMulticamModule: Module {
  public func definition() -> ModuleDefinition {
    Name("RadcamMulticam")

    View(RadcamPreviewView.self) {
      Events("onFrameMetrics")
    }

    AsyncFunction("getCapabilitiesAsync") { () -> [String: Any] in
      MultiCamManager.shared.capabilityReport()
    }

    AsyncFunction("startSessionAsync") {
      MultiCamManager.shared.startSession()
    }

    AsyncFunction("stopSessionAsync") {
      MultiCamManager.shared.stopSession()
    }

    AsyncFunction("startRecordingAsync") { (options: [String: Any]) -> [String: String] in
      let codec = options["codec"] as? String ?? "hevc"
      let filePath = try MultiCamManager.shared.startRecording(codec: codec)
      return ["filePath": filePath]
    }

    AsyncFunction("stopRecordingAsync") { () async -> [String: String?] in
      let filePath = await MultiCamManager.shared.stopRecording()
      return ["filePath": filePath]
    }
  }
}
