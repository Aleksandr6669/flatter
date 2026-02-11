
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras: cameras));
}

// Main App Widget
class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const MyApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air OS Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0F1A),
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      home: HomeScreen(cameras: cameras),
    );
  }
}

// Home Screen Widget
class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const HomeScreen({super.key, required this.cameras});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _cameraController;
  PoseDetector? _poseDetector;
  List<Pose> _poses = [];
  Size? _imageSize;
  Offset? _cursorPosition;
  bool _isPinching = false;
  bool _isHandVisible = false; // Diagnostic flag

  final GlobalKey _vikaButtonKey = GlobalKey();
  final GlobalKey _leraButtonKey = GlobalKey();
  final GlobalKey _aboutButtonKey = GlobalKey();

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
    final camera = widget.cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => widget.cameras.first);

    _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();

    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(model: PoseDetectionModel.base, mode: PoseDetectionMode.stream),
    );

    _cameraController!.startImageStream(_processImage);

    if (mounted) setState(() {});
  }

  void _processImage(CameraImage image) async {
    if (!mounted || _poseDetector == null) return;

    final inputImage = InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _cameraController!.description.sensorOrientation == 90
            ? InputImageRotation.rotation90deg
            : InputImageRotation.rotation270deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );

    final poses = await _poseDetector!.processImage(inputImage);
    final Size screenSize = MediaQuery.of(context).size;

    Offset? newCursorPosition;
    bool newIsPinching = false;
    bool handVisible = false;

    if (poses.isNotEmpty) {
      final pose = poses.first;
      final leftIndex = pose.landmarks[PoseLandmarkType.leftIndex];
      final leftThumb = pose.landmarks[PoseLandmarkType.leftThumb];

      if (leftIndex != null && leftThumb != null) {
        handVisible = true;
        newCursorPosition = _transformPoint(leftIndex.x, leftIndex.y, screenSize,
            Size(image.width.toDouble(), image.height.toDouble()));

        final distance = sqrt(pow(leftIndex.x - leftThumb.x, 2) + pow(leftIndex.y - leftThumb.y, 2));
        newIsPinching = distance < 50;

        if (newIsPinching && !_isPinching) {
          _handleGesture(newCursorPosition);
        }
      }
    }

    setState(() {
      _poses = poses;
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      _cursorPosition = newCursorPosition;
      _isPinching = newIsPinching;
      _isHandVisible = handVisible;
    });
  }

  void _handleGesture(Offset cursorPosition) {
    _checkButtonPress(_vikaButtonKey, "VIKA OPEN");
    _checkButtonPress(_leraButtonKey, "LERA OPEN");
    _checkButtonPress(_aboutButtonKey, "ABOUT READ MORE");
  }

  void _checkButtonPress(GlobalKey key, String buttonName) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && _cursorPosition != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final buttonRect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);

      if (buttonRect.contains(_cursorPosition!)) {
        print("--- GESTURE DETECTED: Pressed '$buttonName' button ---");
      }
    }
  }

  Offset _transformPoint(double x, double y, Size screenSize, Size imageSize) {
    if (imageSize.width == 0 || imageSize.height == 0) return Offset.zero;
    final double scaleX = screenSize.width / imageSize.height;
    final double scaleY = screenSize.height / imageSize.width;
    double flippedX = imageSize.height - x;
    return Offset(flippedX * scaleX, y * scaleY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_cameraController?.value.isInitialized ?? false)
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: PosePainter(
                poses: _poses,
                imageSize: _imageSize ?? Size.zero,
                cursorPosition: _cursorPosition,
                isPinching: _isPinching,
                transformPoint: _transformPoint,
              ),
            ),

          Positioned(
            top: 100, left: 50,
            child: InfoCard(
              system: 'SYSTEM / VIKA', title: 'VIKA', description: 'Your guide and support.',
              buttonText: 'OPEN', buttonKey: _vikaButtonKey,
            ),
          ),
          Positioned(
            top: 350, left: 300,
            child: InfoCard(
              system: 'SYSTEM / LERA', title: 'LERA', titleColor: const Color(0xFFF472B6),
              description: 'Creativity and drive.', buttonText: 'OPEN', buttonKey: _leraButtonKey,
            ),
          ),
          Positioned(
            top: 150, right: 50,
            child: InfoCard(
              system: 'ABOUT', title: 'ABOUT AIR OS', 
              description: 'This is a demo of a futuristic OS\\ncontrolled by hand gestures.',
              buttonText: 'READ MORE', buttonKey: _aboutButtonKey,
            ),
          ),

          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Controls Active'),
              ),
            ),
          ),

          // --- DIAGNOSTIC WIDGET ---
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Poses found: ${_poses.length}', style: const TextStyle(color: Colors.white)),
                  Text('Hand visible: $_isHandVisible', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
          
          if (!(_cameraController?.value.isInitialized ?? false))
             const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String system, title, description, buttonText;
  final Color titleColor;
  final GlobalKey? buttonKey;

  const InfoCard({
    super.key, required this.system, required this.title, required this.description,
    required this.buttonText, this.titleColor = const Color(0xFF2DD4BF), this.buttonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, spreadRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(system, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: titleColor, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
          const SizedBox(height: 20),
          ElevatedButton(
            key: buttonKey,
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DD4BF), foregroundColor: const Color(0xFF0A0F1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final Offset? cursorPosition;
  final bool isPinching;
  final Offset Function(double, double, Size, Size) transformPoint;

  PosePainter({
    required this.poses, required this.imageSize, required this.cursorPosition,
    required this.isPinching, required this.transformPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 2.0..color = const Color(0xFF2DD4BF).withOpacity(0.7);
    final pointPaint = Paint()..style = PaintingStyle.fill..color = Colors.white;

    for (final pose in poses) {
      final landmarks = pose.landmarks;

      // --- Draw Hand Skeleton ---
      final connections = {
        PoseLandmarkType.leftShoulder: PoseLandmarkType.leftElbow,
        PoseLandmarkType.leftElbow: PoseLandmarkType.leftWrist,
        PoseLandmarkType.leftWrist: PoseLandmarkType.leftThumb,
        PoseLandmarkType.leftWrist: PoseLandmarkType.leftIndex,
        PoseLandmarkType.leftWrist: PoseLandmarkType.leftPinky,
        PoseLandmarkType.leftIndex: PoseLandmarkType.leftPinky,
      };

      connections.forEach((start, end) {
        final p1 = landmarks[start];
        final p2 = landmarks[end];
        if (p1 != null && p2 != null) {
          canvas.drawLine(transformPoint(p1.x, p1.y, size, imageSize), transformPoint(p2.x, p2.y, size, imageSize), linePaint);
        }
      });

      // Draw landmark points for the hand
      final handLandmarks = [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb, PoseLandmarkType.leftIndex, PoseLandmarkType.leftPinky];
      for(var type in handLandmarks) {
        final landmark = landmarks[type];
        if (landmark != null) {
           canvas.drawCircle(transformPoint(landmark.x, landmark.y, size, imageSize), 2.5, pointPaint);
        }
      }
    }

    // Draw the cursor
    if (cursorPosition != null) {
      final cursorPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isPinching ? Colors.cyanAccent.withOpacity(0.9) : const Color(0xFF2DD4BF).withOpacity(0.5);
      final cursorBorderPaint = Paint()
        ..style = PaintingStyle.stroke..strokeWidth = 2.0..color = Colors.cyanAccent;

      canvas.drawCircle(cursorPosition!, isPinching ? 12 : 10, cursorPaint);
      canvas.drawCircle(cursorPosition!, 10, cursorBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.poses != poses || oldDelegate.cursorPosition != cursorPosition;
  }
}
