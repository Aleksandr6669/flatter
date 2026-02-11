
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // We don't need to get cameras here anymore, it will be handled in the HomeScreen.
  runApp(const MyApp());
}

// Main App Widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const PermissionWrapper(),
    );
  }
}

class PermissionWrapper extends StatefulWidget {
  const PermissionWrapper({super.key});

  @override
  _PermissionWrapperState createState() => _PermissionWrapperState();
}

class _PermissionWrapperState extends State<PermissionWrapper> {
  PermissionStatus _cameraPermissionStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraPermissionStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_cameraPermissionStatus) {
      case PermissionStatus.granted:
        return const HomeScreen();
      case PermissionStatus.denied:
        return _buildPermissionDeniedUI();
      case PermissionStatus.permanentlyDenied:
        return _buildPermanentlyDeniedUI();
      default:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
    }
  }

  Widget _buildPermissionDeniedUI() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Camera permission is required to use this feature.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _requestCameraPermission,
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermanentlyDeniedUI() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Camera permission was permanently denied.'),
            const Text('Please go to settings to enable it.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: openAppSettings,
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}


// Home Screen Widget
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
  bool _isHandVisible = false;
  List<CameraDescription>? _cameras;

  final GlobalKey _vikaButtonKey = GlobalKey();
  final GlobalKey _leraButtonKey = GlobalKey();
  final GlobalKey _aboutButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    _cameras = await availableCameras();
    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (_cameras == null || _cameras!.isEmpty) {
      print("No cameras available");
      return;
    }
    final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first);

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
      
      // Try to get left hand first, then right hand
      var indexFinger = pose.landmarks[PoseLandmarkType.leftIndex];
      var thumb = pose.landmarks[PoseLandmarkType.leftThumb];

      if (indexFinger == null || thumb == null) {
          indexFinger = pose.landmarks[PoseLandmarkType.rightIndex];
          thumb = pose.landmarks[PoseLandmarkType.rightThumb];
      }

      if (indexFinger != null && thumb != null) {
        handVisible = true;
        newCursorPosition = _transformPoint(indexFinger.x, indexFinger.y, screenSize,
            Size(image.width.toDouble(), image.height.toDouble()));

        final distance = sqrt(pow(indexFinger.x - thumb.x, 2) + pow(indexFinger.y - thumb.y, 2));
        newIsPinching = distance < 50;

        if (newIsPinching && !_isPinching) {
          _handleGesture(newCursorPosition);
        }
      }
    }

    if (mounted) {
      setState(() {
        _poses = poses;
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        _cursorPosition = newCursorPosition;
        _isPinching = newIsPinching;
        _isHandVisible = handVisible;
      });
    }
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
    // Since we are using a front camera, the image is mirrored. We need to flip the X-coordinate.
    final double scaleX = screenSize.width / imageSize.width;
    final double scaleY = screenSize.height / imageSize.height;
    // The image stream from camera package on android is rotated landscape left.
    // So we need to map the coordinates from the landscape image to the portrait screen.
    // This is a common issue and the transformation can be tricky.
    // Let's adjust for front camera mirroring and rotation.
    
    // The image from the stream is landscape. The screen is portrait.
    // image width corresponds to screen height, image height to screen width.
    final double transformedX = y / imageSize.height * screenSize.width;
    final double transformedY = (imageSize.width - x) / imageSize.width * screenSize.height;


    return Offset(transformedX, transformedY);
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final Size screenSize = MediaQuery.of(context).size;
    final double cameraAspectRatio = _cameraController!.value.aspectRatio;
    
    return Scaffold(
      body: Stack(
        children: [
          // Camera Preview
          SizedBox(
            width: screenSize.width,
            height: screenSize.height,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: screenSize.height * cameraAspectRatio,
                height: screenSize.height,
                child: CameraPreview(_cameraController!),
              ),
            ),
          ),
          
          // Pose Painter
          CustomPaint(
            size: screenSize,
            painter: PosePainter(
              poses: _poses,
              imageSize: _imageSize ?? Size.zero,
              cursorPosition: _cursorPosition,
              isPinching: _isPinching,
              transformPoint: _transformPoint,
            ),
          ),

          // UI elements from before
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
              description: 'This is a demo of a futuristic OS\ncontrolled by hand gestures.',
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

          // Diagnostic Widget
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
                  Text('Pinching: $_isPinching', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
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

      // Define connections for a more complete skeleton
      final connections = [
        // Torso
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
        [PoseLandmarkType.rightHip, PoseLandmarkType.leftHip],
        [PoseLandmarkType.leftHip, PoseLandmarkType.leftShoulder],
        
        // Left Arm
        [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
        [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
        
        // Right Arm
        [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
        [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],

        // Left Hand
        [PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb],
        [PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex],
        [PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky],
        [PoseLandmarkType.leftIndex, PoseLandmarkType.leftPinky],

        // Right Hand
        [PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb],
        [PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex],
        [PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky],
        [PoseLandmarkType.rightIndex, PoseLandmarkType.rightPinky],
      ];
      
      // Draw lines
      for (final connection in connections) {
        final p1 = landmarks[connection[0]];
        final p2 = landmarks[connection[1]];
        if (p1 != null && p2 != null) {
          canvas.drawLine(transformPoint(p1.x, p1.y, size, imageSize), transformPoint(p2.x, p2.y, size, imageSize), linePaint);
        }
      }

      // Draw points for all landmarks
      for (final landmark in landmarks.values) {
        canvas.drawCircle(transformPoint(landmark.x, landmark.y, size, imageSize), 2.5, pointPaint);
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
