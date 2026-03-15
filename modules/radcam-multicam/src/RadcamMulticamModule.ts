import { requireNativeModule } from 'expo-modules-core';
import { CapabilityReport } from './RadcamMulticam.types';

type RadcamModule = {
  getCapabilitiesAsync(): Promise<CapabilityReport>;
};

export default requireNativeModule<RadcamModule>('RadcamMulticam');
