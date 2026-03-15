import { useCallback, useEffect, useState } from 'react';
import { CapabilityReport, RadcamMulticamModule, RecordingOptions } from '../native/RadcamMulticamModule';

export function useRadcam() {
  const [capabilities, setCapabilities] = useState<CapabilityReport | null>(null);
  const [isRunning, setRunning] = useState(false);
  const [isRecording, setRecording] = useState(false);
  const [lastRecordingPath, setLastRecordingPath] = useState<string | null>(null);

  useEffect(() => {
    RadcamMulticamModule.getCapabilitiesAsync().then(setCapabilities).catch(console.warn);
  }, []);

  const start = useCallback(async () => {
    await RadcamMulticamModule.startSessionAsync();
    setRunning(true);
  }, []);

  const stop = useCallback(async () => {
    await RadcamMulticamModule.stopSessionAsync();
    setRunning(false);
  }, []);

  const startRecording = useCallback(async (options: RecordingOptions) => {
    const result = await RadcamMulticamModule.startRecordingAsync(options);
    setLastRecordingPath(result.filePath);
    setRecording(true);
  }, []);

  const stopRecording = useCallback(async () => {
    const result = await RadcamMulticamModule.stopRecordingAsync();
    setLastRecordingPath(result.filePath);
    setRecording(false);
  }, []);

  return {
    capabilities,
    isRunning,
    isRecording,
    lastRecordingPath,
    start,
    stop,
    startRecording,
    stopRecording
  };
}
