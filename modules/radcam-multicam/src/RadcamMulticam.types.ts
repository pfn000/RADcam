export type CameraMode = 'single' | 'dual' | 'multi';

export type CapabilityReport = {
  supportsMultiCam: boolean;
  availableRearCameraIDs: string[];
  selectedMode: CameraMode;
};
