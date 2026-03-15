import React from 'react';
import { SafeAreaView, StatusBar, StyleSheet } from 'react-native';
import { CameraScreen } from './src/components/CameraScreen';

export default function App() {
  return (
    <SafeAreaView style={styles.root}>
      <StatusBar barStyle="light-content" />
      <CameraScreen />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#02040c'
  }
});
