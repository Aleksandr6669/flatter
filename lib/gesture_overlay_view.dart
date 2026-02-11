import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'vision_detector_views/detector_view.dart';
import 'vision_detector_views/pose_painter.dart';

class GestureOverlayView extends StatefulWidget {
  const GestureOverlayView({
    super.key,
    required this.webViewController,
    required this.child,
  });

  final WebViewController webViewController;
  final Widget child;

  @override
  State<GestureOverlayView> createState() => _GestureOverlayViewState();
}

class _GestureOverlayViewState extends State<GestureOverlayView> {
  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions());
  bool _canProcess = true;
  bool _isBusy = false;
  CustomPaint? _customPaint;
  var _cameraLensDirection = CameraLensDirection.front;

  // Virtual cursor
  Offset _cursorPosition = const Offset(0, 0);

  @override
  void dispose() {
    _canProcess = false;
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Opacity(
          opacity: 0.3, // Make camera view semi-transparent
          child: DetectorView(
            title: 'Pose Detector',
            customPaint: _customPaint,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) => _cameraLensDirection = value,
          ),
        ),
        Positioned(
          top: _cursorPosition.dy,
          left: _cursorPosition.dx,
          child: const Icon(Icons.mouse, color: Colors.red, size: 24),
        ),
      ],
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;

    final poses = await _poseDetector.processImage(inputImage);

    if (!mounted) {
        _isBusy = false;
        return;
    }

    if (inputImage.metadata?.size != null &&
        inputImage.metadata?.rotation != null) {
      final painter = PosePainter(
        poses,
        inputImage.metadata!.size,
        inputImage.metadata!.rotation,
        _cameraLensDirection,
      );
      _customPaint = CustomPaint(painter: painter);

      // Gesture control logic
      if (poses.isNotEmpty) {
        final pose = poses.first;
        final leftIndex = pose.landmarks[PoseLandmarkType.leftIndex];
        final leftThumb = pose.landmarks[PoseLandmarkType.leftThumb];

        if (leftIndex != null) {
          // Get the screen size
          final screenSize = MediaQuery.of(context).size;

          // Invert X coordinate for front camera
          final x = screenSize.width - (leftIndex.x / inputImage.metadata!.size.width) * screenSize.width;
          final y = (leftIndex.y / inputImage.metadata!.size.height) * screenSize.height;

          _cursorPosition = Offset(x, y);

          if (leftThumb != null) {
            final distance = (leftIndex.x - leftThumb.x).abs() + (leftIndex.y - leftThumb.y).abs();
            if (distance < 50) { // Click threshold
              widget.webViewController.runJavaScript('document.elementFromPoint(${_cursorPosition.dx}, ${_cursorPosition.dy}).click();');
            }
          }
        }
      }
    } else {
      _customPaint = null;
    }
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }
}
