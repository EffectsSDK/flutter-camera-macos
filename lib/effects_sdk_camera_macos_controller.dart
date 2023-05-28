import 'dart:typed_data';

import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/effects_sdk_camera_macos_method_channel.dart';
import 'package:camera_macos/effects_sdk_camera_macos_platform_interface.dart';
import 'package:camera_macos/exceptions.dart';

class CameraEffectsSDKMacOSController {
  late CameraMacOSArguments args;

  CameraEffectsSDKMacOSController(this.args);

  CameraEffectsSDKPlatform get _platformInstance => CameraEffectsSDKPlatform.instance;

  /// Call this method to take a picture.
  Future<CameraMacOSFile?> takePicture() {
    return _platformInstance.takePicture();
  }

  /// Call this method to start a video recording.
  Future<bool?> recordVideo({
    /// Expressed in seconds
    double? maxVideoDuration,

    /// A URL location to save the video. Default is Library/Cache directory of the application.
    String? url,

    /// Enable audio (this flag overrides the initialization setting)
    bool? enableAudio,

    /// Called only when the video has reached the max duration pointed by maxVideoDuration
    Function(CameraMacOSFile?, CameraMacOSException?)? onVideoRecordingFinished,
  }) {
    return _platformInstance.startVideoRecording(
      maxVideoDuration: maxVideoDuration,
      enableAudio: enableAudio,
      url: url,
      onVideoRecordingFinished: onVideoRecordingFinished,
    );
  }

  /// Call this method to stop video recording and collect the video data.
  Future<CameraMacOSFile?> stopRecording() {
    return _platformInstance.stopVideoRecording();
  }

  /// Destroy the camera instance
  Future<bool?> destroy() {
    return _platformInstance.destroy();
  }

  /// Getter that checks if a video is currently recording
  bool get isRecording => (_platformInstance as MethodChannelEffectsSDKCamera).isRecording;

  /// Getter that checks if a camera instance has been destroyed or not initiliazed yet.
  bool get isDestroyed => (_platformInstance as MethodChannelEffectsSDKCamera).isDestroyed;

  Future<void> setBlur(double blurPower) {
    return _platformInstance.setBlur(blurPower);
  }

  Future<void> clearBlur() {
    return _platformInstance.clearBlur();
  }

  Future<void> setBeautificationLevel(double level) {
    return _platformInstance.setBeautificationLevel(level);
  }

  Future<void> clearBeautification() {
    return _platformInstance.clearBeautification();
  }

  Future<void> setBackgroundImage(String url) {
    return _platformInstance.setBackgroundImage(url);
  }

  Future<void> setBackgroundColor(int color) {
    return _platformInstance.setBackgroundColor(color);
  }

  Future<void> clearBackground() {
    return _platformInstance.clearBackground();
  }

  Future<Int8List> getFrameDataBuffer() {
    return _platformInstance.getFrameDataBuffer();
  }
}
