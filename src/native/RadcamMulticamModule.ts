import { requireNativeModule, requireNativeViewManager } from 'expo-modules-core';
import { ComponentType } from 'react';
import { ViewProps } from 'react-native';

export type CameraMode = 'single' | 'dual' | 'multi';

export type RecordingOptions = {
  codec: 'h264' | 'hevc';
  fileName?: string;
};

export type CapabilityReport = {
  supportsMultiCam: boolean;
  availableRearCameraIDs: string[];
  selectedMode: CameraMode;
};

type RadcamNativeModule = {
  getCapabilitiesAsync(): Promise<CapabilityReport>;
  startSessionAsync(): Promise<void>;
  stopSessionAsync(): Promise<void>;
  startRecordingAsync(options: RecordingOptions): Promise<{ filePath: string }>;
  stopRecordingAsync(): Promise<{ filePath: string | null }>;
};

export type RadcamPreviewViewProps = ViewProps & {
  onFrameMetrics?: (event: { nativeEvent: { fps: number; activeCameras: number } }) => void;
};

export const RadcamMulticamModule = requireNativeModule<RadcamNativeModule>('RadcamMulticam');
export const RadcamPreviewView = requireNativeViewManager('RadcamPreviewView') as ComponentType<RadcamPreviewViewProps>;
