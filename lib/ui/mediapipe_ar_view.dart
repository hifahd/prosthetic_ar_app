import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../theme/app_theme.dart';
import '../models/prosthetic_config.dart';
import '../utils/prosthetic_scaler.dart';
import 'dart:typed_data';

class MediaPipeARView extends StatefulWidget {
  final ProstheticConfig? selectedConfig;

  const MediaPipeARView({Key? key, this.selectedConfig}) : super(key: key);

  @override
  _MediaPipeARViewState createState() => _MediaPipeARViewState();
}

class _MediaPipeARViewState extends State<MediaPipeARView>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  final PoseDetector _poseDetector =
      PoseDetector(options: PoseDetectorOptions());
  bool _isDetecting = false;
  List<Pose> _poses = [];
  Offset? _anchorPosition;
  PoseLandmark? _selectedLimb;
  final GlobalKey _cameraKey = GlobalKey();
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() {});

    _cameraController!.startImageStream(_processCameraImage);
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;

    _isDetecting = true;
    try {
      final inputImage = _convertCameraImage(image);
      final poses = await _poseDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _poses = poses;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());
        });
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage _convertCameraImage(CameraImage image) {
    final bytes = <int>[];
    for (final Plane plane in image.planes) {
      bytes.addAll(plane.bytes);
    }
    final byteData = Uint8List.fromList(bytes);

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    const imageRotation = InputImageRotation.rotation0deg;
    const inputImageFormat = InputImageFormat.nv21;

    // Create InputImage metadata
    final metadata = InputImageMetadata(
      bytesPerRow: image.planes[0].bytesPerRow,
      size: imageSize,
      format: inputImageFormat,
      rotation: imageRotation,
    );

    return InputImage.fromBytes(
      bytes: byteData,
      metadata: metadata,
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final screenSize = MediaQuery.of(context).size;
    final RenderBox renderBox =
        _cameraKey.currentContext?.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Convert screen coordinates to image coordinates
    final imagePoint = _getImagePoint(localPosition, screenSize);

    // Find the nearest landmark
    if (_poses.isNotEmpty) {
      final landmark = _findNearestLandmark(imagePoint);
      if (landmark != null) {
        setState(() {
          _selectedLimb = landmark;
          _anchorPosition = localPosition;
        });
      }
    }
  }

  Offset _getImagePoint(Offset screenPoint, Size screenSize) {
    final keyContext = _cameraKey.currentContext;
    if (keyContext == null || _imageSize == null) return screenPoint;

    final renderBox = keyContext.findRenderObject() as RenderBox;
    final size = renderBox.size;

    // Convert from screen coordinates to image coordinates
    final double scaleX = _imageSize!.width / size.width;
    final double scaleY = _imageSize!.height / size.height;

    return Offset(
      screenPoint.dx * scaleX,
      screenPoint.dy * scaleY,
    );
  }

  PoseLandmark? _findNearestLandmark(Offset point) {
    if (_poses.isEmpty) return null;

    final pose = _poses.first;
    double minDistance = double.infinity;
    PoseLandmark? nearestLandmark;

    // Check key landmarks for prosthetic attachment
    final landmarks = [
      pose.landmarks[PoseLandmarkType.leftShoulder],
      pose.landmarks[PoseLandmarkType.rightShoulder],
      pose.landmarks[PoseLandmarkType.leftElbow],
      pose.landmarks[PoseLandmarkType.rightElbow],
      pose.landmarks[PoseLandmarkType.leftWrist],
      pose.landmarks[PoseLandmarkType.rightWrist],
      pose.landmarks[PoseLandmarkType.leftHip],
      pose.landmarks[PoseLandmarkType.rightHip],
      pose.landmarks[PoseLandmarkType.leftKnee],
      pose.landmarks[PoseLandmarkType.rightKnee],
      pose.landmarks[PoseLandmarkType.leftAnkle],
      pose.landmarks[PoseLandmarkType.rightAnkle],
    ];

    for (final landmark in landmarks) {
      if (landmark == null) continue;

      final landmarkPoint = Offset(landmark.x, landmark.y);
      final distance = (landmarkPoint - point).distance;

      if (distance < minDistance && distance < 50) {
        // Within 50 pixels
        minDistance = distance;
        nearestLandmark = landmark;
      }
    }

    return nearestLandmark;
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('AR View')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('MediaPipe AR'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Stack(
        children: [
          // Camera preview
          GestureDetector(
            key: _cameraKey,
            onTapDown: _handleTapDown,
            child: CameraPreview(_cameraController!),
          ),

          // Pose overlay
          if (_poses.isNotEmpty && _imageSize != null)
            _PoseOverlay(
              poses: _poses,
              imageSize: _imageSize!,
              screenSize: MediaQuery.of(context).size,
              selectedLimb: _selectedLimb,
              anchorPosition: _anchorPosition,
            ),

          // Prosthetic model overlay
          if (_anchorPosition != null && widget.selectedConfig != null)
            _ProstheticOverlay(
              anchorPosition: _anchorPosition!,
              config: widget.selectedConfig!,
            ),

          // Status indicator
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _anchorPosition == null
                    ? 'Tap near a body joint to anchor'
                    : 'Prosthetic anchored',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoseOverlay extends StatelessWidget {
  final List<Pose> poses;
  final Size imageSize;
  final Size screenSize;
  final PoseLandmark? selectedLimb;
  final Offset? anchorPosition;

  const _PoseOverlay({
    required this.poses,
    required this.imageSize,
    required this.screenSize,
    this.selectedLimb,
    this.anchorPosition,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PosePainter(
        poses: poses,
        imageSize: imageSize,
        screenSize: screenSize,
        selectedLimb: selectedLimb,
        anchorPosition: anchorPosition,
      ),
      child: Container(),
    );
  }
}

class _PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final Size screenSize;
  final PoseLandmark? selectedLimb;
  final Offset? anchorPosition;

  _PosePainter({
    required this.poses,
    required this.imageSize,
    required this.screenSize,
    this.selectedLimb,
    this.anchorPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = AppTheme.primaryColor;

    final Paint pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primaryColor;

    final Paint selectedPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red;

    for (final pose in poses) {
      // Draw pose landmarks
      pose.landmarks.forEach((_, landmark) {
        if (landmark != null) {
          final point = _translatePoint(landmark.x, landmark.y);
          final isSelected = selectedLimb != null &&
              selectedLimb!.x == landmark.x &&
              selectedLimb!.y == landmark.y;

          canvas.drawCircle(
            point,
            isSelected ? 8 : 5,
            isSelected ? selectedPaint : pointPaint,
          );
        }
      });

      // Draw connections
      _drawLines(canvas, pose.landmarks, paint);
    }

    // Draw anchor target if present
    if (anchorPosition != null) {
      final anchorPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.red;

      canvas.drawCircle(anchorPosition!, 12, anchorPaint);
      canvas.drawCircle(anchorPosition!, 6, Paint()..color = Colors.red);
    }
  }

  void _drawLines(Canvas canvas, Map<PoseLandmarkType, PoseLandmark?> landmarks,
      Paint paint) {
    // Define connections for the pose
    final connections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];

    for (final connection in connections) {
      final landmark1 = landmarks[connection[0]];
      final landmark2 = landmarks[connection[1]];

      if (landmark1 != null && landmark2 != null) {
        final point1 = _translatePoint(landmark1.x, landmark1.y);
        final point2 = _translatePoint(landmark2.x, landmark2.y);
        canvas.drawLine(point1, point2, paint);
      }
    }
  }

  Offset _translatePoint(double x, double y) {
    // Convert from camera image coordinates to screen coordinates
    final scaleX = screenSize.width / imageSize.width;
    final scaleY = screenSize.height / imageSize.height;

    return Offset(x * scaleX, y * scaleY);
  }

  @override
  bool shouldRepaint(_PosePainter oldDelegate) {
    return poses != oldDelegate.poses ||
        selectedLimb != oldDelegate.selectedLimb ||
        anchorPosition != oldDelegate.anchorPosition;
  }
}

class _ProstheticOverlay extends StatelessWidget {
  final Offset anchorPosition;
  final ProstheticConfig config;

  const _ProstheticOverlay({
    required this.anchorPosition,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Scale factors based on the prosthetic config
    final scale = config.patientAge < 12 ? 0.8 : 1.0;

    return Positioned(
      left: anchorPosition.dx - 50 * scale,
      top: anchorPosition.dy - 50 * scale,
      child: IgnorePointer(
        child: Container(
          width: 100 * scale,
          height: 100 * scale,
          decoration: BoxDecoration(
            border: Border.all(color: config.color, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              'Prosthetic',
              style: TextStyle(
                color: config.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
