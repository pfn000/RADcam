import React, { useEffect, useState } from 'react';
import { Pressable, StyleSheet, Text, View } from 'react-native';
import { useRadcam } from '../hooks/useRadcam';
import { RadcamPreviewView } from '../native/RadcamMulticamModule';

export function CameraScreen() {
  const { capabilities, isRunning, isRecording, lastRecordingPath, start, stop, startRecording, stopRecording } = useRadcam();
  const [fps, setFps] = useState(0);
  const [activeCameras, setActiveCameras] = useState(0);

  useEffect(() => {
    start().catch(console.warn);
    return () => {
      stop().catch(console.warn);
    };
  }, [start, stop]);

  return (
    <View style={styles.root}>
      <RadcamPreviewView
        style={styles.preview}
        onFrameMetrics={(event) => {
          setFps(event.nativeEvent.fps);
          setActiveCameras(event.nativeEvent.activeCameras);
        }}
      />
      <View style={styles.overlay}>
        <Text style={styles.heading}>RADcam MultiCam</Text>
        <Text style={styles.meta}>Mode: {capabilities?.selectedMode ?? 'detecting...'}</Text>
        <Text style={styles.meta}>Active cameras: {activeCameras}</Text>
        <Text style={styles.meta}>Preview FPS: {fps.toFixed(1)}</Text>
        <Text style={styles.meta}>Session: {isRunning ? 'running' : 'stopped'}</Text>
        <Text style={styles.meta} numberOfLines={1}>Last file: {lastRecordingPath ?? 'none'}</Text>

        <Pressable
          style={[styles.button, isRecording && styles.buttonStop]}
          onPress={() => {
            if (isRecording) {
              stopRecording().catch(console.warn);
            } else {
              startRecording({ codec: 'hevc' }).catch(console.warn);
            }
          }}>
          <Text style={styles.buttonLabel}>{isRecording ? 'Stop Recording' : 'Start Recording'}</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  preview: { flex: 1 },
  overlay: {
    position: 'absolute',
    left: 16,
    right: 16,
    bottom: 20,
    padding: 14,
    borderRadius: 12,
    backgroundColor: 'rgba(7, 11, 24, 0.76)'
  },
  heading: { color: '#fff', fontSize: 18, fontWeight: '700', marginBottom: 8 },
  meta: { color: '#d9e3ff', fontSize: 13, marginBottom: 4 },
  button: {
    marginTop: 12,
    backgroundColor: '#3867ff',
    borderRadius: 10,
    alignItems: 'center',
    paddingVertical: 12
  },
  buttonStop: { backgroundColor: '#d54444' },
  buttonLabel: { color: '#fff', fontWeight: '600' }
});
