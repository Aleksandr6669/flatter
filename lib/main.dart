
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
      theme: ThemeData(
        brightness: Brightness.dark,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  bool _isCameraInitialized = false;
  List<Pose> _poses = [];
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    // Use the front camera for a selfie view
    final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first);

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.base,
        mode: PoseDetectionMode.stream,
      ),
    );

    _cameraController!.startImageStream((image) {
      _processImage(image);
    });

    if (mounted) {
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_poseDetector == null || !mounted) return;

    final inputImage = InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        // Use the camera's sensor orientation
        rotation: _cameraController!.description.sensorOrientation == 90
            ? InputImageRotation.rotation90deg
            : InputImageRotation.rotation270deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );

    final poses = await _poseDetector!.processImage(inputImage);

    if (mounted) {
      setState(() {
        _poses = poses;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized && _cameraController != null
          ? CustomPaint(
              size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
              painter: PosePainter(
                poses: _poses,
                imageSize: _imageSize ?? Size.zero,
                cameraLensDirection: _cameraController!.description.lensDirection,
              ),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final CameraLensDirection cameraLensDirection;

  PosePainter({required this.poses, required this.imageSize, required this.cameraLensDirection});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.cyanAccent;

    final circlePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.lightBlueAccent;

    for (final pose in poses) {
      // Draw circles for landmarks
      pose.landmarks.forEach((_, landmark) {
        final point = _transformPoint(landmark.x, landmark.y, size);
        canvas.drawCircle(point, 6.0, circlePaint);
      });

      // Define connections
      final connections = {
        PoseLandmarkType.leftWrist: PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftElbow: PoseLandmarkType.leftShoulder,
        PoseLandmarkType.leftShoulder: PoseLandmarkType.rightShoulder,
        PoseLandmarkType.rightShoulder: PoseLandmarkType.rightElbow,
        PoseLandmarkType.rightElbow: PoseLandmarkType.rightWrist,

        PoseLandmarkType.leftShoulder: PoseLandmarkType.leftHip,
        PoseLandmarkType.leftHip: PoseLandmarkType.rightHip,
        PoseLandmarkType.rightHip: PoseLandmarkType.rightShoulder,
        
        // You can add more connections for legs, etc.
      };

      // Draw lines for connections
      connections.forEach((start, end) {
        final p1 = pose.landmarks[start];
        final p2 = pose.landmarks[end];
        if (p1 != null && p2 != null) {
          canvas.drawLine(
            _transformPoint(p1.x, p1.y, size),
            _transformPoint(p2.x, p2.y, size),
            paint,
          );
        }
      });
    }
  }
  
  Offset _transformPoint(double x, double y, Size size) {
      // This transformation now assumes the canvas covers the whole screen.
      // We scale the points from the image size to the screen (canvas) size.
      final double scaleX = size.width / imageSize.height;
      final double scaleY = size.height / imageSize.width;

      // For the front camera, the image is mirrored, so we need to flip the X-axis.
      double flippedX = imageSize.height - x;

      return Offset(flippedX * scaleX, y * scaleY);
  }


  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses || oldDelegate.imageSize != imageSize;
  }
}
