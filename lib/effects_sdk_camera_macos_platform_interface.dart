import 'dart:typed_data';

import 'package:camera_macos/effects_sdk_camera_macos_view.dart';
import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/camera_macos_device.dart';
import 'package:camera_macos/camera_macos_file.dart';
import 'package:camera_macos/exceptions.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'effects_sdk_camera_macos_method_channel.dart';

typedef CameraMacOS = CameraEffectsSDKPlatform;

abstract class CameraEffectsSDKPlatform extends PlatformInterface {
  /// Constructs a CameraEffectsSDKPlatform.
  CameraEffectsSDKPlatform() : super(token: _token);

  static final Object _token = Object();

  static CameraEffectsSDKPlatform _instance = MethodChannelEffectsSDKCamera();

  /// The default instance of [CameraEffectsSDKPlatform] to use.
  ///
  /// Defaults to [MethodChannelEffectsSDKCamera].
  static CameraEffectsSDKPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CameraEffectsSDKPlatform] when
  /// they register themselves.
  static set instance(CameraEffectsSDKPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<CameraMacOSArguments?> initialize({
    String? deviceId,
    String? audioDeviceId,
    bool enableAudio = true,
    required CameraMacOSMode cameraMacOSMode,
  }) {
    throw UnimplementedError("");
  }

  Future<List<CameraMacOSDevice>> listDevices({CameraMacOSDeviceType? deviceType}) {
    throw UnimplementedError("");
  }

  Future<CameraMacOSFile?> takePicture() {
    throw UnimplementedError("");
  }

  Future<bool> startVideoRecording({
    double? maxVideoDuration,
    String? url,
    bool? enableAudio,
    Function(CameraMacOSFile?, CameraMacOSException?)? onVideoRecordingFinished,
  }) {
    throw UnimplementedError("");
  }

  Future<CameraMacOSFile?> stopVideoRecording() {
    throw UnimplementedError("");
  }

  Future<bool?> destroy() {
    throw UnimplementedError("");
  }

  // Enable background blur with [blurPower] from 0 to 1.
  Future<void> setBlur(double blurPower) {
    throw UnimplementedError('setBlur() is not implemented.');
  }

  /// Disable background blur.
  Future<void> clearBlur() {
    throw UnimplementedError('clearBlur() is not implemented.');
  }

  /// Enable beautification. [level] could be from 0 to 1. Higher number -> more visible effect ofbeautification.
  Future<void> setBeautificationLevel(double level) {
    throw UnimplementedError('setBeautificationLevel() is not implemented.');
  }

  /// Disable beautification.
  Future<void> clearBeautification() {
    throw UnimplementedError('clearBeautification() is not implemented.');
  }

  /// Set image for background.
  Future<void> setBackgroundImage(String url) {
    throw UnimplementedError('setBackgroundImage() is not implemented.');
  }

  /// Set BGRA [color] for background.
  Future<void> setBackgroundColor(int color) {
    throw UnimplementedError('setBackgroundColor() is not implemented.');
  }

  /// Disable background.
  Future<void> clearBackground() {
    throw UnimplementedError('clearBackground() is not implemented.');
  }

  /// Returns a [Int8List] that is updated on every new frame processed in camera preview
  Future<Int8List> getFrameDataBuffer() async {
    throw UnimplementedError('getFrameDataBuffer() is not implemented.');
  }
}
