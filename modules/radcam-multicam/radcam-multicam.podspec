require 'json'
package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name         = 'radcam-multicam'
  s.version      = package['version']
  s.summary      = 'Open-source AVFoundation + Metal multicam capture pipeline for Expo.'
  s.description  = 'Captures rear cameras, processes frames with Metal radial splat compute shaders, and exposes preview/recording controls to React Native.'
  s.license      = 'MIT'
  s.author       = 'RADcam OSS'
  s.homepage     = 'https://github.com/example/radcam'
  s.platforms    = { :ios => '16.0' }
  s.source       = { :git => 'https://github.com/example/radcam.git' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  s.source_files = 'ios/**/*.{h,m,mm,swift,metal}'
  s.resource_bundles = {
    'RadcamShaders' => ['ios/**/*.metal']
  }
  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '5.9',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++20'
  }
end
