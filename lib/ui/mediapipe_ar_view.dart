import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import for WriteBuffer
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/prosthetic_config.dart';
import '../utils/prosthetic_scaler.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:model_viewer_plus/model_viewer_plus.dart';

class MediaPipeARView extends StatefulWidget {
  final ProstheticConfig? selectedConfig;

  const MediaPipeARView({Key? key, this.selectedConfig}) : super(key: key);

  @override
  _MediaPipeARViewState createState() => _MediaPipeARViewState();
}

class _MediaPipeARViewState extends State<MediaPipeARView>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.accurate,
      mode: PoseDetectionMode.stream,
    ),
  );
  bool _isDetecting = false;
  List<Pose> _poses = [];
  Offset? _anchorPosition;
  PoseLandmark? _selectedLimb;
  final GlobalKey _cameraKey = GlobalKey();
  Size? _imageSize;
  double _scaleFactor = 1.0;
  bool _manualPlacementMode = false;
  bool _showDebugInfo = false;
  bool _isCameraInitialized = false;
  bool _showError = false;
  String _errorMessage = '';

  // Track if camera has been completely initialized
  bool _cameraReady = false;

  // Track if 3D model has been loaded
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();

    // Pre-load the 3D model
    if (widget.selectedConfig != null) {
      _preloadModel(widget.selectedConfig!.modelPath);
    }
  }

  Future<void> _preloadModel(String modelPath) async {
    try {
      // Simulate model loading
      await Future.delayed(Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _modelLoaded = true;
        });
      }
    } catch (e) {
      print('Error preloading model: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopImageStream();
    _cameraController?.dispose();
    _poseDetector.close();
    super.dispose();
  }

  void _stopImageStream() {
    try {
      if (_cameraController != null &&
          _cameraController!.value.isInitialized &&
          _cameraController!.value.isStreamingImages) {
        _cameraController!.stopImageStream();
      }
    } catch (e) {
      print('Error stopping image stream: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameraController != null &&
          !_cameraController!.value.isInitialized) {
        _initializeCamera();
      }
    }
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isCameraInitialized = false;
      _showError = false;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _displayError('No camera available');
        return;
      }

      // Try to use back camera for better results
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Close any existing controller first
      await _cameraController?.dispose();

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium, // Use medium resolution for better performance
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21 // Android
            : ImageFormatGroup.bgra8888, // iOS
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      // Add a delay to ensure camera is fully initialized
      await Future.delayed(Duration(milliseconds: 500));

      _cameraReady = true;

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      // Add another small delay before starting image stream
      await Future.delayed(Duration(milliseconds: 200));

      if (!mounted) return;

      await _startImageStream();
    } catch (e) {
      _displayError('Error initializing camera: $e');
    }
  }

  Future<void> _startImageStream() async {
    if (!_cameraReady || !mounted) return;

    try {
      await _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      _displayError('Failed to start camera stream: $e');
    }
  }

  void _displayError(String message) {
    if (!mounted) return;

    setState(() {
      _showError = true;
      _errorMessage = message;
    });

    print('Error: $message');
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;

    _isDetecting = true;
    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _poses = poses;
          _imageSize = Size(image.width.toDouble(), image.height.toDouble());

          // Calculate scaling factor to adjust for resolution differences
          if (_imageSize != null) {
            final screenSize = MediaQuery.of(context).size;
            final scaleX = screenSize.width / _imageSize!.width;
            final scaleY = screenSize.height / _imageSize!.height;
            _scaleFactor = math.min(scaleX, scaleY);
          }
        });
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isDetecting = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      // For NV21 format (Android)
      if (Platform.isAndroid) {
        final bytes = Uint8List.fromList(image.planes[0].bytes);
        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg, // Default rotation
            format: InputImageFormat.nv21,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }
      // For BGRA8888 format (iOS)
      else {
        final bytes = Uint8List.fromList(image.planes[0].bytes);
        return InputImage.fromBytes(
          bytes: bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: InputImageRotation.rotation0deg,
            format: InputImageFormat.bgra8888,
            bytesPerRow: image.planes[0].bytesPerRow,
          ),
        );
      }
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  void _handleTapDown(TapDownDetails details) {
    if (_manualPlacementMode) {
      setState(() {
        _anchorPosition = details.localPosition;
        _selectedLimb = null;
      });
      return;
    }

    final renderBox =
        _cameraKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPosition = renderBox.globalToLocal(details.globalPosition);

    // Find the nearest landmark with a larger detection radius
    if (_poses.isNotEmpty) {
      final landmark = _findNearestLandmark(localPosition);
      if (landmark != null) {
        setState(() {
          _selectedLimb = landmark;
          _anchorPosition = _landmarkToScreenPosition(landmark);
        });
      } else if (_selectedLimb == null) {
        // Show guidance to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'No joint detected nearby. Try again closer to a body joint or use Manual Mode.'),
            duration: Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Manual Mode',
              onPressed: _enableManualPlacementMode,
            ),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No body pose detected. Switching to Manual Mode.'),
          duration: Duration(seconds: 2),
        ),
      );
      _enableManualPlacementMode();
    }
  }

  void _enableManualPlacementMode() {
    setState(() {
      _manualPlacementMode = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Manual mode enabled. Tap anywhere to place prosthetic.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  Offset _landmarkToScreenPosition(PoseLandmark landmark) {
    if (_imageSize == null) return Offset.zero;

    final screenSize = MediaQuery.of(context).size;

    // Account for camera preview's fit mode
    double scale;
    double dx = 0, dy = 0;

    if (_cameraController != null) {
      final cameraAspectRatio = _cameraController!.value.aspectRatio;
      final screenAspectRatio = screenSize.width / screenSize.height;

      if (screenAspectRatio < cameraAspectRatio) {
        // Camera is wider than screen, so scale based on width
        scale = screenSize.width / _imageSize!.width;
        final scaledHeight = _imageSize!.height * scale;
        dy = (screenSize.height - scaledHeight) / 2;
      } else {
        // Camera is taller than screen, so scale based on height
        scale = screenSize.height / _imageSize!.height;
        final scaledWidth = _imageSize!.width * scale;
        dx = (screenSize.width - scaledWidth) / 2;
      }
    } else {
      scale = _scaleFactor;
    }

    // Convert normalized coordinates (0-1) to screen coordinates
    return Offset(
      dx + landmark.x * _imageSize!.width * scale,
      dy + landmark.y * _imageSize!.height * scale,
    );
  }

  PoseLandmark? _findNearestLandmark(Offset screenPosition) {
    if (_poses.isEmpty || _imageSize == null) return null;

    final pose = _poses.first;
    double minDistance = double.infinity;
    PoseLandmark? nearestLandmark;

    // Check key landmarks for prosthetic attachment
    final landmarkTypes = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];

    for (final type in landmarkTypes) {
      if (!pose.landmarks.containsKey(type)) {
        continue;
      }

      final landmark = pose.landmarks[type]!;
      final landmarkScreenPos = _landmarkToScreenPosition(landmark);
      final distance = (landmarkScreenPos - screenPosition).distance;

      // Increased tap radius for easier detection
      if (distance < minDistance && distance < 100) {
        minDistance = distance;
        nearestLandmark = landmark;
      }
    }

    return nearestLandmark;
  }

  void _showDebugDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('AR Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Poses detected: ${_poses.length}',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (_poses.isNotEmpty) ...[
                Text('Joint Visibility:'),
                SizedBox(height: 4),
                ...[
                  'leftShoulder',
                  'rightShoulder',
                  'leftElbow',
                  'rightElbow',
                  'leftWrist',
                  'rightWrist',
                  'leftHip',
                  'rightHip',
                  'leftKnee',
                  'rightKnee',
                  'leftAnkle',
                  'rightAnkle'
                ].map((joint) {
                  final type = PoseLandmarkType.values.firstWhere(
                    (e) =>
                        e.toString().split('.').last.toLowerCase() ==
                        joint.toLowerCase(),
                    orElse: () => PoseLandmarkType.nose,
                  );

                  final landmark = _poses.first.landmarks[type];
                  final visibility = landmark?.likelihood ?? 0;

                  return Padding(
                    padding: EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        Text('$joint: '),
                        Container(
                          width: 100,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey[200],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 100 * visibility,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: visibility > 0.7
                                      ? Colors.green
                                      : visibility > 0.5
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('${(visibility * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                  );
                }).toList(),
              ],
              SizedBox(height: 16),
              Text('AR Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(
                  'Camera resolution: ${_imageSize?.width.toInt() ?? 0}x${_imageSize?.height.toInt() ?? 0}'),
              Text('Scale factor: ${_scaleFactor.toStringAsFixed(2)}'),
              Text('Mode: ${_manualPlacementMode ? "Manual" : "Auto"}'),
              Text(
                  'Selected joint: ${_selectedLimb?.type.toString().split('.').last ?? "None"}'),
              Text('Model loaded: ${_modelLoaded ? "Yes" : "No"}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _manualPlacementMode = !_manualPlacementMode;
              });
              Navigator.of(context).pop();
            },
            child: Text(_manualPlacementMode
                ? 'Switch to Auto Mode'
                : 'Switch to Manual Mode'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR View'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          // Debug toggle
          IconButton(
            icon: Icon(
                _showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () => setState(() => _showDebugInfo = !_showDebugInfo),
            tooltip: 'Toggle debug info',
          ),
          // Manual mode toggle
          IconButton(
            icon: Icon(
                _manualPlacementMode ? Icons.touch_app : Icons.auto_awesome),
            onPressed: () =>
                setState(() => _manualPlacementMode = !_manualPlacementMode),
            tooltip: _manualPlacementMode
                ? 'Switch to Auto Mode'
                : 'Switch to Manual Mode',
          ),
          // Debug dialog
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showDebugDialog,
            tooltip: 'Show Debug Info',
          ),
        ],
      ),
      body: _showError
          ? _buildErrorView()
          : !_isCameraInitialized
              ? _buildLoadingView()
              : _buildARView(),
      floatingActionButton: _manualPlacementMode
          ? FloatingActionButton(
              onPressed: () => setState(() => _manualPlacementMode = false),
              child: Icon(Icons.auto_awesome),
              backgroundColor: AppTheme.primaryColor,
              tooltip: 'Switch to Auto Mode',
            )
          : null,
    );
  }

  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 20),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            SizedBox(height: 16),
            Text(
              'Camera Error',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildARView() {
    return Stack(
      children: [
        // Camera preview
        GestureDetector(
          key: _cameraKey,
          onTapDown: _handleTapDown,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_cameraController!),
          ),
        ),

        // Pose overlay
        if (_poses.isNotEmpty && _imageSize != null)
          _PoseOverlay(
            poses: _poses,
            imageSize: _imageSize!,
            screenSize: MediaQuery.of(context).size,
            selectedLimb: _selectedLimb,
            anchorPosition: _anchorPosition,
            scaleFactor: _scaleFactor,
            showDebugInfo: _showDebugInfo,
            cameraController: _cameraController,
          ),

        // Prosthetic model overlay
        if (_anchorPosition != null && widget.selectedConfig != null)
          _ARModelOverlay(
            anchorPosition: _anchorPosition!,
            config: widget.selectedConfig!,
            limbType: ProstheticScaler.getLimbTypeFromModelPath(
                widget.selectedConfig!.modelPath),
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _poses.isEmpty ? Icons.person_off : Icons.person,
                  color: _poses.isEmpty ? Colors.red : Colors.green,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  _manualPlacementMode
                      ? 'Manual Mode: Tap anywhere to place prosthetic'
                      : _poses.isEmpty
                          ? 'No body detected'
                          : _anchorPosition == null
                              ? 'Body detected - Tap near a joint to anchor'
                              : 'Prosthetic anchored',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),

        // Show debug info if enabled
        if (_showDebugInfo)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.all(8),
              color: Colors.black54,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Debug Info:',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Poses detected: ${_poses.length}',
                    style: TextStyle(color: Colors.white),
                  ),
                  if (_imageSize != null)
                    Text(
                      'Image size: ${_imageSize!.width.toInt()}x${_imageSize!.height.toInt()}',
                      style: TextStyle(color: Colors.white),
                    ),
                  Text(
                    'Scale factor: ${_scaleFactor.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Mode: ${_manualPlacementMode ? "Manual" : "Auto"}',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PoseOverlay extends StatelessWidget {
  final List<Pose> poses;
  final Size imageSize;
  final Size screenSize;
  final PoseLandmark? selectedLimb;
  final Offset? anchorPosition;
  final double scaleFactor;
  final bool showDebugInfo;
  final CameraController? cameraController;

  const _PoseOverlay({
    required this.poses,
    required this.imageSize,
    required this.screenSize,
    this.selectedLimb,
    this.anchorPosition,
    required this.scaleFactor,
    this.showDebugInfo = false,
    this.cameraController,
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
        scaleFactor: scaleFactor,
        showDebugInfo: showDebugInfo,
        cameraController: cameraController,
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
  final double scaleFactor;
  final bool showDebugInfo;
  final CameraController? cameraController;

  _PosePainter({
    required this.poses,
    required this.imageSize,
    required this.screenSize,
    this.selectedLimb,
    this.anchorPosition,
    required this.scaleFactor,
    this.showDebugInfo = false,
    this.cameraController,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 // Make lines thicker for better visibility
      ..color = Colors.green
          .withOpacity(0.7); // Changed to green for better visibility

    final Paint pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue; // Changed to blue for better visibility

    final Paint selectedPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red;

    for (final pose in poses) {
      // Draw pose landmarks
      pose.landmarks.forEach((type, landmark) {
        if (landmark != null && landmark.likelihood > 0.5) {
          // Only draw high confidence landmarks
          final point = _translatePoint(landmark.x, landmark.y);
          final isSelected = selectedLimb != null &&
              _fuzzyLandmarkMatch(selectedLimb!, landmark);

          // Draw confidence indicator if in debug mode
          if (showDebugInfo) {
            final confidencePaint = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0
              ..color = _getConfidenceColor(landmark.likelihood);

            canvas.drawCircle(
              point,
              15,
              confidencePaint,
            );
          }

          // Draw the joint point with larger radius for better visibility
          canvas.drawCircle(
            point,
            isSelected ? 10 : 8,
            isSelected ? selectedPaint : pointPaint,
          );

          // Draw a white outline for better visibility
          final outlinePaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..color = Colors.white;

          canvas.drawCircle(
            point,
            isSelected ? 10 : 8,
            outlinePaint,
          );

          // In debug mode, draw the joint name
          if (showDebugInfo) {
            final textSpan = TextSpan(
              text: type.toString().split('.').last,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                background: Paint()..color = Colors.black54,
              ),
            );

            final textPainter = TextPainter(
              text: textSpan,
              textDirection: TextDirection.ltr,
            );

            textPainter.layout();
            textPainter.paint(
              canvas,
              Offset(point.dx + 10, point.dy + 10),
            );
          }
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

      canvas.drawCircle(anchorPosition!, 15, anchorPaint);
      canvas.drawCircle(anchorPosition!, 8, Paint()..color = Colors.red);
    }
  }

  bool _fuzzyLandmarkMatch(PoseLandmark a, PoseLandmark b) {
    // Compare x,y coordinates with small tolerance
    const double tolerance = 0.01;
    return (a.x - b.x).abs() < tolerance && (a.y - b.y).abs() < tolerance;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) {
      return Colors.green;
    } else if (confidence > 0.5) {
      return Colors.yellow;
    } else {
      return Colors.red;
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

      if (landmark1 != null &&
          landmark2 != null &&
          landmark1.likelihood > 0.5 &&
          landmark2.likelihood > 0.5) {
        final point1 = _translatePoint(landmark1.x, landmark1.y);
        final point2 = _translatePoint(landmark2.x, landmark2.y);

// Use confidence-based color if in debug mode
        if (showDebugInfo) {
          final avgConfidence =
              (landmark1.likelihood + landmark2.likelihood) / 2;
          paint.color = _getConfidenceColor(avgConfidence);
        }

        canvas.drawLine(point1, point2, paint);
      }
    }
  }

  Offset _translatePoint(double x, double y) {
    // Calculate proper scaling to maintain aspect ratio
    double scale;
    double dx = 0, dy = 0;

    if (cameraController != null) {
      final cameraAspectRatio = cameraController!.value.aspectRatio;
      final screenAspectRatio = screenSize.width / screenSize.height;

      // Correctly map the image coordinates to the screen
      if (screenAspectRatio < cameraAspectRatio) {
        // Camera preview is wider than screen
        scale = screenSize.width / imageSize.width;
        final scaledHeight = imageSize.height * scale;
        dy = (screenSize.height - scaledHeight) / 2;
      } else {
        // Camera preview is taller than screen
        scale = screenSize.height / imageSize.height;
        final scaledWidth = imageSize.width * scale;
        dx = (screenSize.width - scaledWidth) / 2;
      }
    } else {
      scale = scaleFactor;
    }

    // Map from normalized coordinates (0-1) to screen coordinates
    // Flip x-coordinate for front camera
    double adjustedX = x;

    // If using front camera, we need to flip horizontally
    if (cameraController != null &&
        cameraController!.description.lensDirection ==
            CameraLensDirection.front) {
      adjustedX = 1.0 - x;
    }

    return Offset(
      dx + adjustedX * imageSize.width * scale,
      dy + y * imageSize.height * scale,
    );
  }

  @override
  bool shouldRepaint(_PosePainter oldDelegate) {
    return poses != oldDelegate.poses ||
        selectedLimb != oldDelegate.selectedLimb ||
        anchorPosition != oldDelegate.anchorPosition ||
        scaleFactor != oldDelegate.scaleFactor ||
        showDebugInfo != oldDelegate.showDebugInfo;
  }
}

class _ARModelOverlay extends StatelessWidget {
  final Offset anchorPosition;
  final ProstheticConfig config;
  final String limbType;

  const _ARModelOverlay({
    required this.anchorPosition,
    required this.config,
    required this.limbType,
  });

  @override
  Widget build(BuildContext context) {
    // Get scale factors based on the prosthetic config
    final scaleFactors =
        ProstheticScaler.getScaleFactorsForAge(config.patientAge, limbType);

    // Calculate model size based on limb type and config
    final baseWidth = limbType.contains('arm') ? 100 : 120;
    final baseHeight = limbType.contains('arm') ? 180 : 240;

    final modelWidth = baseWidth * scaleFactors['x']!;
    final modelHeight = baseHeight * scaleFactors['y']!;

    // Position model at anchor point, adjusting to center
    return Positioned(
      left: anchorPosition.dx - (modelWidth / 2),
      top: anchorPosition.dy - (modelHeight / 2),
      child: Container(
        width: modelWidth,
        height: modelHeight,
        child: Stack(
          children: [
            // Render 3D model
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: config.color.withOpacity(0.1),
                  border: Border.all(
                    color: config.color,
                    width: 2,
                  ),
                ),
                child: _buildModelContent(context),
              ),
            ),
            // Display limb type name
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${limbType.toUpperCase()}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelContent(BuildContext context) {
    // Create a more visually informative visualization
    return CustomPaint(
      size: Size.infinite,
      painter: _ProstheticPainter(
        limbType: limbType,
        color: config.color,
      ),
    );
  }
}

// Custom painter for prosthetic visualization
class _ProstheticPainter extends CustomPainter {
  final String limbType;
  final Color color;

  _ProstheticPainter({
    required this.limbType,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (limbType.contains('hand')) {
      _drawHand(canvas, size, paint, outlinePaint, highlightPaint);
    } else if (limbType.contains('arm')) {
      _drawArm(canvas, size, paint, outlinePaint, highlightPaint);
    } else if (limbType.contains('leg')) {
      _drawLeg(canvas, size, paint, outlinePaint, highlightPaint);
    } else {
      // Generic prosthetic representation
      _drawGenericProsthetic(canvas, size, paint, outlinePaint, highlightPaint);
    }
  }

  void _drawGenericProsthetic(Canvas canvas, Size size, Paint paint,
      Paint outlinePaint, Paint highlightPaint) {
    // Draw a basic cylindrical shape
    final path = Path();

    // Main cylinder body
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.1, size.width * 0.5,
          size.height * 0.8),
      Radius.circular(size.width * 0.25),
    ));

    // Draw the shape
    canvas.drawPath(path, paint);
    canvas.drawPath(path, outlinePaint);

    // Add details
    final detailPath = Path();

    // Add connector rings
    detailPath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.2),
      radius: size.width * 0.2,
    ));

    detailPath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.5),
      radius: size.width * 0.2,
    ));

    detailPath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.8),
      radius: size.width * 0.2,
    ));

    canvas.drawPath(detailPath, highlightPaint);

    // Add text to indicate it's a prosthetic
    final textStyle = TextStyle(
      color: paint.color,
      fontSize: size.width * 0.1,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(
      text: 'PROSTHETIC',
      style: textStyle,
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(
      minWidth: size.width * 0.8,
      maxWidth: size.width * 0.8,
    );

    textPainter.paint(
      canvas,
      Offset(size.width * 0.1, size.height * 0.45),
    );
  }

  void _drawHand(Canvas canvas, Size size, Paint paint, Paint outlinePaint,
      Paint highlightPaint) {
    final path = Path();

    // Draw palm
    final palmRect = Rect.fromLTWH(size.width * 0.2, size.height * 0.2,
        size.width * 0.6, size.height * 0.4);
    path.addRRect(RRect.fromRectAndRadius(
      palmRect,
      Radius.circular(12),
    ));

    // Draw fingers
    final fingerWidth = size.width * 0.08;
    for (int i = 0; i < 5; i++) {
      final fingerX = size.width * 0.25 + (i * size.width * 0.125);

      // Vary finger height
      double fingerHeight = size.height * 0.3;
      if (i == 0) fingerHeight *= 0.8; // Thumb
      if (i == 2) fingerHeight *= 1.1; // Middle finger

      final fingerRect =
          Rect.fromLTWH(fingerX, size.height * 0.1, fingerWidth, fingerHeight);

      path.addRRect(RRect.fromRectAndRadius(
        fingerRect,
        Radius.circular(fingerWidth / 2),
      ));
    }

    // Draw wrist attachment
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.6, size.width * 0.5,
          size.height * 0.35),
      Radius.circular(8),
    ));

    // Draw the shape
    canvas.drawPath(path, paint);
    canvas.drawPath(path, outlinePaint);

    // Add highlights/details
    final detailPath = Path();

    // Knuckle details
    for (int i = 0; i < 5; i++) {
      final knuckleX =
          size.width * 0.25 + (i * size.width * 0.125) + fingerWidth / 2;
      final knuckleY = size.height * 0.25;

      detailPath.addOval(Rect.fromCircle(
        center: Offset(knuckleX, knuckleY),
        radius: fingerWidth * 0.6,
      ));
    }

    // Wrist joint detail
    detailPath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.62),
      radius: size.width * 0.1,
    ));

    canvas.drawPath(detailPath, highlightPaint);
  }

  void _drawArm(Canvas canvas, Size size, Paint paint, Paint outlinePaint,
      Paint highlightPaint) {
    final path = Path();

    // Upper arm section
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.1, size.width * 0.4,
          size.height * 0.3),
      Radius.circular(10),
    ));

    // Elbow joint
    final elbowCenter = Offset(size.width * 0.5, size.height * 0.45);
    path.addOval(Rect.fromCircle(
      center: elbowCenter,
      radius: size.width * 0.15,
    ));

    // Forearm section
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.5, size.width * 0.4,
          size.height * 0.4),
      Radius.circular(10),
    ));

    // Draw the shape
    canvas.drawPath(path, paint);
    canvas.drawPath(path, outlinePaint);

    // Add highlights/details
    final detailPath = Path();

    // Elbow mechanism
    detailPath.addOval(Rect.fromCircle(
      center: elbowCenter,
      radius: size.width * 0.08,
    ));

    // Upper attachment
    detailPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.12, size.width * 0.3,
          size.height * 0.05),
      Radius.circular(4),
    ));

    // Lower attachment
    detailPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.82, size.width * 0.3,
          size.height * 0.05),
      Radius.circular(4),
    ));

    canvas.drawPath(detailPath, highlightPaint);
  }

  void _drawLeg(Canvas canvas, Size size, Paint paint, Paint outlinePaint,
      Paint highlightPaint) {
    final path = Path();

    // Thigh section
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.3, size.height * 0.05, size.width * 0.4,
          size.height * 0.35),
      Radius.circular(12),
    ));

    // Knee joint
    final kneeCenter = Offset(size.width * 0.5, size.height * 0.45);
    path.addOval(Rect.fromCircle(
      center: kneeCenter,
      radius: size.width * 0.15,
    ));

    // Lower leg section
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.25, size.height * 0.5, size.width * 0.5,
          size.height * 0.45),
      Radius.circular(8),
    ));

    // Draw the shape
    canvas.drawPath(path, paint);
    canvas.drawPath(path, outlinePaint);

    // Add highlights/details
    final detailPath = Path();

    // Knee mechanism
    detailPath.addOval(Rect.fromCircle(
      center: kneeCenter,
      radius: size.width * 0.1,
    ));

    // Upper attachment
    detailPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.35, size.height * 0.08, size.width * 0.3,
          size.height * 0.05),
      Radius.circular(4),
    ));

    // Ankle mechanism
    detailPath.addOval(Rect.fromCircle(
      center: Offset(size.width * 0.5, size.height * 0.9),
      radius: size.width * 0.08,
    ));

    canvas.drawPath(detailPath, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
