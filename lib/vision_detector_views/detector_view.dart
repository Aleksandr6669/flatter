import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

class DetectorView extends StatefulWidget {
  const DetectorView({
    super.key,
    required this.title,
    required this.onImage,
    this.customPaint,
    this.text,
    this.initialCameraLensDirection = CameraLensDirection.back,
    this.onCameraLensDirectionChanged,
  });

  final String title;
  final CustomPaint? customPaint;
  final String? text;
  final Function(InputImage inputImage) onImage;
  final CameraLensDirection initialCameraLensDirection;
  final Function(CameraLensDirection)? onCameraLensDirectionChanged;

  @override
  State<DetectorView> createState() => _DetectorViewState();
}

class _DetectorViewState extends State<DetectorView> {
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;
  bool _changingCameraLens = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  void _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == widget.initialCameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_cameras.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: _switchLiveCamera,
                child: Icon(
                  Platform.isIOS
                      ? Icons.flip_camera_ios_outlined
                      : Icons.flip_camera_android_outlined,
                ),
              ),
            ),
        ],
      ),
      body: _liveFeedBody(),
    );
  }

  Widget _liveFeedBody() {
    if (_cameras.isEmpty) {
      return Container();
    }
    if (_controller == null) {
      return Container();
    }
    if (_controller?.value.isInitialized == false) {
      return Container();
    }
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Center(
            child: _changingCameraLens
                ? const Center(
                    child: Text('Changing camera lens'),
                  )
                : CameraPreview(
                    _controller!,
                    child: widget.customPaint,
                  ),
          ),
          if (widget.text != null)
            Positioned(
              bottom: 100,
              left: 50,
              right: 50,
              child: Text(
                widget.text!,
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Future _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      // Set to ResolutionPreset.high. Do NOT set it to ResolutionPreset.max because for some phones does not work.
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage);
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;

    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }

  void _processCameraImage(CameraImage image) {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      return;
    }
    widget.onImage(inputImage);
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) {
      return null;
    }

    // get image rotation
    // it is used in android to convert the InputImage from Dart to Java:
    final camera = _cameras[_cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) {
        return null;
      }
      if (camera.lensDirection == CameraLensDirection.front) {
        // front-facing camera requires a mirror property to be applied.
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        // back-facing camera requires a mirror property to be applied.
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) {
      return null;
    }

    // get image format
    final format = InputImageFormatValue.fromRawValue(image.format.raw);

    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    // since format is constraint to nv21 or bgra8888, both only have one plane
    if (image.planes.length != 1) {
      return null;
    }
    final plane = image.planes.first;

    // compose InputImage using bytes
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}
