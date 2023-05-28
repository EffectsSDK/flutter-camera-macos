import 'package:camera_macos/camera_macos_arguments.dart';
import 'package:camera_macos/effects_sdk_camera_macos_controller.dart';
import 'package:camera_macos/effects_sdk_camera_macos_method_channel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'effects_sdk_camera_macos_platform_interface.dart';

class CameraMacOSView extends StatefulWidget {
  /// Handles how the widget should fit the screen.
  final BoxFit fit;

  /// DeviceId of the video streaming device
  final String? deviceId;

  /// Audio DeviceId of the audio streaming device
  final String? audioDeviceId;

  /// Enable audio while recording video. Defaults to 'true'. You can always override this setting when calling the 'startRecording' method.
  final bool enableAudio;

  /// Choose between audio or video mode
  final CameraMacOSMode cameraMode;

  /// Callback that gets called while the "initialize" method hasn't returned a value yet.
  final Widget Function(Object?)? onCameraLoading;

  /// Callback that gets called when the "initialize" method has returned a value.
  final Function(CameraEffectsSDKMacOSController) onCameraInizialized;

  /// Callback that gets called when the "destroy" method has returned.
  final Widget Function()? onCameraDestroyed;

  /// [EXPERIMENTAL][NOT WORKING] It won't work until Flutter will officially support macOS Platform Views.
  final bool usePlatformView;

  const CameraMacOSView({
    Key? key,
    this.deviceId,
    this.audioDeviceId,
    this.enableAudio = true,
    this.fit = BoxFit.contain,
    required this.cameraMode,
    required this.onCameraInizialized,
    this.onCameraLoading,
    this.onCameraDestroyed,
    this.usePlatformView = false,
  }) : super(key: key);

  @override
  CameraMacOSViewState createState() => CameraMacOSViewState();
}

class CameraMacOSViewState extends State<CameraMacOSView> {
  late CameraMacOSArguments arguments;
  late Future<CameraMacOSArguments?> initializeCameraFuture;

  @override
  void initState() {
    super.initState();
    initializeCameraFuture = CameraEffectsSDKPlatform.instance
        .initialize(
      deviceId: widget.deviceId,
      audioDeviceId: widget.audioDeviceId,
      cameraMacOSMode: widget.cameraMode,
      enableAudio: widget.enableAudio,
    )
        .then((value) {
      if (value != null) {
        this.arguments = value;
        widget.onCameraInizialized(
          CameraEffectsSDKMacOSController(value),
        );
      }
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializeCameraFuture,
      builder: (BuildContext context, AsyncSnapshot<CameraMacOSArguments?> snapshot) {
        if (snapshot.hasError) {
          if (widget.onCameraLoading != null) {
            return widget.onCameraLoading!(snapshot.error);
          } else {
            return const ColoredBox(color: Colors.black);
          }
        }
        if (!snapshot.hasData) {
          if (widget.onCameraLoading != null) {
            return widget.onCameraLoading!(null);
          } else {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
        }

        if (snapshot.data != null && snapshot.data!.textureId == null) {
          return Container();
        }

        if (CameraEffectsSDKPlatform.instance is MethodChannelEffectsSDKCamera &&
            (CameraEffectsSDKPlatform.instance as MethodChannelEffectsSDKCamera).isDestroyed) {
          if (widget.onCameraDestroyed != null) {
            return widget.onCameraDestroyed!();
          } else {
            return Container();
          }
        }

        final Map<String, dynamic> creationParams = <String, dynamic>{
          "width": snapshot.data!.size.width,
          "height": snapshot.data!.size.height,
        };

        return ClipRect(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: FittedBox(
              fit: widget.fit,
              child: SizedBox(
                width: snapshot.data!.size.width,
                height: snapshot.data!.size.height,
                child: widget.usePlatformView
                    ? UiKitView(
                        viewType: "camera_macos_view",
                        onPlatformViewCreated: (id) {
                          print(id);
                        },
                        creationParams: creationParams,
                        creationParamsCodec: const StandardMessageCodec(),
                      )
                    : Texture(textureId: snapshot.data!.textureId!),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(CameraMacOSView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // if camera mode has changed mode, reinitialize the camera
    if (oldWidget.deviceId != widget.deviceId ||
        oldWidget.audioDeviceId != widget.audioDeviceId ||
        oldWidget.cameraMode != widget.cameraMode ||
        oldWidget.enableAudio != widget.enableAudio ||
        oldWidget.usePlatformView != widget.usePlatformView ||
        oldWidget.key != widget.key) {
      initializeCameraFuture = CameraEffectsSDKPlatform.instance
          .initialize(
        deviceId: widget.deviceId,
        audioDeviceId: widget.audioDeviceId,
        cameraMacOSMode: widget.cameraMode,
        enableAudio: widget.enableAudio,
      )
          .then((value) {
        if (value != null) {
          this.arguments = value;
          widget.onCameraInizialized(
            CameraEffectsSDKMacOSController(value),
          );
        }
        return value;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}

enum CameraMacOSMode {
  photo,
  video,
}
