import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/prosthetic_config.dart';
import '../utils/prosthetic_scaler.dart';
import 'dart:typed_data';
import 'dart:io';
import 'dart:ui' as ui;

class MediaPipeARView extends StatefulWidget {
  final ProstheticConfig? selectedConfig;

  const MediaPipeARView({Key? key, this.selectedConfig}) : super(key: key);

  @override
  _MediaPipeARViewState createState() => _MediaPipeARViewState();
}

class _MediaPipeARViewState extends State<MediaPipeARView>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  // Simplified PoseDetector initialization without problematic parameters
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
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
    if (_cameraController != null &&
        _cameraController!.value.isStreamingImages) {
      _cameraController!.stopImageStream();
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
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      _showError('No camera available');
      return;
    }

    // Try to use back camera for better results
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.medium, // Use medium resolution for better performance
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21 // Android
          : ImageFormatGroup.bgra8888, // iOS
    );

    try {
      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() {});

      await _cameraController!.startImageStream(_processCameraImage);
    } catch (e) {
      _showError('Error initializing camera: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
    print('Error: $message');
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting) return;

    _isDetecting = true;
    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        print('Failed to convert camera image');
        return;
      }

      final poses = await _poseDetector.processImage(inputImage);

      // Debug logging
      if (_showDebugInfo) {
        if (poses.isNotEmpty) {
          print('Number of poses detected: ${poses.length}');

          // Check visibility of key landmarks
          final landmarks = poses.first.landmarks;
          [
            'nose',
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
          ].forEach((joint) {
            final type = PoseLandmarkType.values.firstWhere(
              (e) =>
                  e.toString().split('.').last.toLowerCase() ==
                  joint.toLowerCase(),
              orElse: () => PoseLandmarkType.nose,
            );
            if (landmarks.containsKey(type) && landmarks[type] != null) {
              final landmark = landmarks[type]!;
              print(
                  '$joint: (${landmark.x.toStringAsFixed(2)}, ${landmark.y.toStringAsFixed(2)}) '
                  'confidence: ${landmark.likelihood.toStringAsFixed(2)}');
            } else {
              print('$joint: not detected');
            }
          });
        } else {
          print('No poses detected');
        }
      }

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
      // Create a buffer
      final buffer = Uint8List.fromList(
          image.planes.fold<List<int>>([], (allBytes, plane) {
        allBytes.addAll(plane.bytes);
        return allBytes;
      }));

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final imageRotation = InputImageRotationValue.fromRawValue(
              _cameraController!.description.sensorOrientation) ??
          InputImageRotation.rotation0deg;

      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.nv21;

      // Create image metadata
      final metadata = InputImageMetadata(
        size: imageSize,
        rotation: imageRotation,
        format: inputImageFormat,
        bytesPerRow: image.planes[0].bytesPerRow,
      );

      return InputImage.fromBytes(bytes: buffer, metadata: metadata);
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

    final screenSize = MediaQuery.of(context).size;
    final RenderBox renderBox =
        _cameraKey.currentContext?.findRenderObject() as RenderBox;
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
                'No joint detected nearby. Try again closer to a body joint.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No body pose detected. Try adjusting your position.'),
          duration: Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Manual Mode',
            onPressed: _enableManualPlacementMode,
          ),
        ),
      );
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

    // Calculate scale and offset to maintain aspect ratio and center the image
    final scaleX = screenSize.width / _imageSize!.width;
    final scaleY = screenSize.height / _imageSize!.height;
    final scale = math.min(scaleX, scaleY);

    final offsetX = (screenSize.width - _imageSize!.width * scale) / 2;
    final offsetY = (screenSize.height - _imageSize!.height * scale) / 2;

    return Offset(
      offsetX + landmark.x * _imageSize!.width * scale,
      offsetY + landmark.y * _imageSize!.height * scale,
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
      if (!pose.landmarks.containsKey(type) || pose.landmarks[type] == null) {
        continue;
      }

      final landmark = pose.landmarks[type]!;
      final landmarkScreenPos = _landmarkToScreenPosition(landmark);
      final distance = (landmarkScreenPos - screenPosition).distance;

      // Increased tap radius from 50 to 100 for easier detection
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
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('AR View')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              scaleFactor: _scaleFactor,
              showDebugInfo: _showDebugInfo,
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
                _manualPlacementMode
                    ? 'Manual Mode: Tap anywhere to place prosthetic'
                    : _anchorPosition == null
                        ? 'Tap near a body joint to anchor'
                        : 'Prosthetic anchored',
                style: TextStyle(color: Colors.white, fontSize: 12),
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
      ),
      floatingActionButton: _manualPlacementMode
          ? null
          : FloatingActionButton(
              onPressed: _enableManualPlacementMode,
              child: Icon(Icons.touch_app),
              backgroundColor: AppTheme.primaryColor,
              tooltip: 'Switch to Manual Mode',
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
  final double scaleFactor;
  final bool showDebugInfo;

  const _PoseOverlay({
    required this.poses,
    required this.imageSize,
    required this.screenSize,
    this.selectedLimb,
    this.anchorPosition,
    required this.scaleFactor,
    this.showDebugInfo = false,
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

  _PosePainter({
    required this.poses,
    required this.imageSize,
    required this.screenSize,
    this.selectedLimb,
    this.anchorPosition,
    required this.scaleFactor,
    this.showDebugInfo = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = AppTheme.primaryColor.withOpacity(0.7);

    final Paint pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primaryColor;

    final Paint selectedPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.red;

    for (final pose in poses) {
      // Draw pose landmarks
      pose.landmarks.forEach((type, landmark) {
        if (landmark != null) {
          final point = _translatePoint(landmark.x, landmark.y);
          final isSelected = selectedLimb != null &&
              _fuzzyLandmarkMatch(selectedLimb!, landmark);

          // Draw confidence indicator if in debug mode
          if (showDebugInfo) {
            final confidencePaint = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.0
              ..color = _getConfidenceColor(landmark.likelihood);

            canvas.drawCircle(
              point,
              15,
              confidencePaint,
            );
          }

          // Draw the joint point
          canvas.drawCircle(
            point,
            isSelected ? 8 : 5,
            isSelected ? selectedPaint : pointPaint,
          );

          // In debug mode, draw the joint name
          if (showDebugInfo) {
            final textSpan = TextSpan(
              text: type.toString().split('.').last,
              style: TextStyle(
                color: Colors.yellow,
                fontSize: 10,
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

      canvas.drawCircle(anchorPosition!, 12, anchorPaint);
      canvas.drawCircle(anchorPosition!, 6, Paint()..color = Colors.red);
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

      if (landmark1 != null && landmark2 != null) {
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
    final scaleX = screenSize.width / imageSize.width;
    final scaleY = screenSize.height / imageSize.height;
    final scale = math.min(scaleX, scaleY);

    // Calculate offset to center image
    final offsetX = (screenSize.width - imageSize.width * scale) / 2;
    final offsetY = (screenSize.height - imageSize.height * scale) / 2;

    // Map from normalized coordinates (0-1) to screen coordinates
    return Offset(
      offsetX + x * imageSize.width * scale,
      offsetY + y * imageSize.height * scale,
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

class _ProstheticOverlay extends StatelessWidget {
  final Offset anchorPosition;
  final ProstheticConfig config;

  const _ProstheticOverlay({
    required this.anchorPosition,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Get scale factors based on the prosthetic config
    final limbType =
        ProstheticScaler.getLimbTypeFromModelPath(config.modelPath);
    final scaleFactors =
        ProstheticScaler.getScaleFactorsForAge(config.patientAge, limbType);

    return Positioned(
      left: anchorPosition.dx - 50 * scaleFactors['x']!,
      top: anchorPosition.dy - 50 * scaleFactors['y']!,
      child: IgnorePointer(
        child: Container(
          width: 100 * scaleFactors['x']!,
          height: 100 * scaleFactors['y']!,
          decoration: BoxDecoration(
            color: config.color.withOpacity(0.3),
            border: Border.all(color: config.color, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.view_in_ar,
                  color: config.color,
                  size: 32,
                ),
                Text(
                  limbType.toUpperCase(),
                  style: TextStyle(
                    color: config.color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
