import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/prosthetic_config.dart';
import '../utils/prosthetic_scaler.dart';

class MediaPipeARView extends StatefulWidget {
  final ProstheticConfig? selectedConfig;

  const MediaPipeARView({Key? key, this.selectedConfig}) : super(key: key);

  @override
  _MediaPipeARViewState createState() => _MediaPipeARViewState();
}

class _MediaPipeARViewState extends State<MediaPipeARView>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  Offset? _anchorPosition;
  final GlobalKey _cameraKey = GlobalKey();
  bool _showDebugInfo = false;
  bool _isCameraInitialized = false;
  bool _showError = false;
  String _errorMessage = '';
  bool _cameraReady = false;
  bool _modelLoaded = false;
  String _statusMessage = 'Detecting hand position...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _startFakeDetection();

    // Pre-load the 3D model
    if (widget.selectedConfig != null) {
      _preloadModel(widget.selectedConfig!.modelPath);
    }
  }

  Future<void> _preloadModel(String modelPath) async {
    try {
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

  void _startFakeDetection() {
    // Simulate auto-detection with changing status messages
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Hand detected - Analyzing joints...';
        });
      }
    });

    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Calculating optimal position...';
        });
      }
    });

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Ready - Tap near detected hand to anchor';
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopImageStream();
    _cameraController?.dispose();
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

      // Use back camera for better AR experience
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      await _cameraController?.dispose();

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      await Future.delayed(Duration(milliseconds: 500));
      _cameraReady = true;

      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      _displayError('Error initializing camera: $e');
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

  void _handleTapDown(TapDownDetails details) {
    // Place prosthetic at tap location
    setState(() {
      _anchorPosition = details.localPosition;
      _statusMessage = 'Prosthetic anchored successfully';
    });
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
              Text('AR Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text('Mode: Auto Detection (Simulated)'),
              Text('Model loaded: ${_modelLoaded ? "Yes" : "No"}'),
              Text('Camera: ${_isCameraInitialized ? "Ready" : "Not Ready"}'),
              Text(
                  'Prosthetic anchored: ${_anchorPosition != null ? "Yes" : "No"}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Hand Prosthetic'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: Icon(
                _showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined),
            onPressed: () => setState(() => _showDebugInfo = !_showDebugInfo),
            tooltip: 'Toggle debug info',
          ),
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

        // Prosthetic model overlay
        if (_anchorPosition != null && widget.selectedConfig != null)
          _ARHandOverlay(
            anchorPosition: _anchorPosition!,
            config: widget.selectedConfig!,
          ),

        // Status indicator with fake auto-detection
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
                  _anchorPosition == null ? Icons.search : Icons.check_circle,
                  color: _anchorPosition == null ? Colors.orange : Colors.green,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  _statusMessage,
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
                    'Mode: Auto Detection (Simulated)',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Model loaded: ${_modelLoaded ? "Yes" : "No"}',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    'Status: $_statusMessage',
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

class _ARHandOverlay extends StatelessWidget {
  final Offset anchorPosition;
  final ProstheticConfig config;

  const _ARHandOverlay({
    required this.anchorPosition,
    required this.config,
  });

  @override
  Widget build(BuildContext context) {
    // Get scale factors based on the prosthetic config
    final scaleFactors =
        ProstheticScaler.getScaleFactorsForAge(config.patientAge, 'hand');

    // Good proportioned size for demo
    const baseWidth = 280;
    const baseHeight = 360;

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
            // Render detailed hand prosthetic
            CustomPaint(
              size: Size(modelWidth, modelHeight),
              painter: _RealisticHandPainter(
                color: config.color,
                material: config.material,
              ),
            ),
            // Display hand type and material
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PROSTHETIC HAND',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      config.material,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RealisticHandPainter extends CustomPainter {
  final Color color;
  final String material;

  _RealisticHandPainter({
    required this.color,
    required this.material,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Create sophisticated color scheme
    final baseColor = color.withOpacity(0.9);
    final lightColor = _lightenColor(color, 0.2);
    final darkColor = _darkenColor(color, 0.3);
    final metalColor = Colors.grey[400]!;

    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Draw shadow
    _drawCompleteHand(canvas, size, shadowPaint, 2.0, 2.0);

    // Draw main hand
    _drawCompleteHand(canvas, size, basePaint, 0, 0);
    _drawCompleteHand(canvas, size, outlinePaint, 0, 0);

    // Add highlights and details
    _drawHandHighlights(canvas, size, lightColor);
    _drawJointDetails(canvas, size, metalColor, darkColor);
    _drawFingerNails(canvas, size);
  }

  void _drawCompleteHand(
      Canvas canvas, Size size, Paint paint, double offsetX, double offsetY) {
    // Much smaller, refined palm
    final palmPath = Path();
    palmPath.moveTo(size.width * 0.25 + offsetX, size.height * 0.4 + offsetY);
    palmPath.quadraticBezierTo(
        size.width * 0.15 + offsetX,
        size.height * 0.37 + offsetY,
        size.width * 0.2 + offsetX,
        size.height * 0.33 + offsetY);
    palmPath.lineTo(size.width * 0.8 + offsetX, size.height * 0.33 + offsetY);
    palmPath.quadraticBezierTo(
        size.width * 0.85 + offsetX,
        size.height * 0.37 + offsetY,
        size.width * 0.75 + offsetX,
        size.height * 0.4 + offsetY);
    palmPath.lineTo(size.width * 0.75 + offsetX, size.height * 0.56 + offsetY);
    palmPath.quadraticBezierTo(
        size.width * 0.8 + offsetX,
        size.height * 0.6 + offsetY,
        size.width * 0.74 + offsetX,
        size.height * 0.62 + offsetY);
    palmPath.lineTo(size.width * 0.26 + offsetX, size.height * 0.62 + offsetY);
    palmPath.quadraticBezierTo(
        size.width * 0.2 + offsetX,
        size.height * 0.6 + offsetY,
        size.width * 0.25 + offsetX,
        size.height * 0.56 + offsetY);
    palmPath.close();
    canvas.drawPath(palmPath, paint);

    // Prominent, properly sized thumb
    final thumbPath = Path();
    thumbPath.moveTo(size.width * 0.12 + offsetX, size.height * 0.45 + offsetY);
    thumbPath.quadraticBezierTo(
        size.width * 0.08 + offsetX,
        size.height * 0.42 + offsetY,
        size.width * 0.1 + offsetX,
        size.height * 0.35 + offsetY);
    thumbPath.lineTo(size.width * 0.17 + offsetX, size.height * 0.28 + offsetY);
    thumbPath.quadraticBezierTo(
        size.width * 0.2 + offsetX,
        size.height * 0.27 + offsetY,
        size.width * 0.21 + offsetX,
        size.height * 0.3 + offsetY);
    thumbPath.lineTo(size.width * 0.21 + offsetX, size.height * 0.58 + offsetY);
    thumbPath.quadraticBezierTo(
        size.width * 0.2 + offsetX,
        size.height * 0.61 + offsetY,
        size.width * 0.17 + offsetX,
        size.height * 0.61 + offsetY);
    thumbPath.lineTo(size.width * 0.14 + offsetX, size.height * 0.59 + offsetY);
    thumbPath.quadraticBezierTo(
        size.width * 0.12 + offsetX,
        size.height * 0.55 + offsetY,
        size.width * 0.12 + offsetX,
        size.height * 0.45 + offsetY);
    thumbPath.close();
    canvas.drawPath(thumbPath, paint);

    // Longer, more refined fingers
    _drawElegantFinger(
        canvas, size, paint, offsetX, offsetY, 0.28, 0.08, 0.11, 0.42); // Index
    _drawElegantFinger(canvas, size, paint, offsetX, offsetY, 0.445, 0.05, 0.11,
        0.47); // Middle
    _drawElegantFinger(
        canvas, size, paint, offsetX, offsetY, 0.61, 0.07, 0.11, 0.44); // Ring
    _drawElegantFinger(
        canvas, size, paint, offsetX, offsetY, 0.76, 0.1, 0.09, 0.38); // Pinky

    // Refined wrist attachment
    final wristPath = Path();
    wristPath.moveTo(size.width * 0.22 + offsetX, size.height * 0.62 + offsetY);
    wristPath.lineTo(size.width * 0.78 + offsetX, size.height * 0.62 + offsetY);
    wristPath.quadraticBezierTo(
        size.width * 0.82 + offsetX,
        size.height * 0.65 + offsetY,
        size.width * 0.78 + offsetX,
        size.height * 0.72 + offsetY);
    wristPath.lineTo(size.width * 0.22 + offsetX, size.height * 0.72 + offsetY);
    wristPath.quadraticBezierTo(
        size.width * 0.18 + offsetX,
        size.height * 0.65 + offsetY,
        size.width * 0.22 + offsetX,
        size.height * 0.62 + offsetY);
    wristPath.close();
    canvas.drawPath(wristPath, paint);
  }

  void _drawElegantFinger(
      Canvas canvas,
      Size size,
      Paint paint,
      double offsetX,
      double offsetY,
      double xStart,
      double yStart,
      double width,
      double height) {
    final fingerPath = Path();

    // Create more elegant finger shape with proper taper
    fingerPath.moveTo(size.width * (xStart + width / 2) + offsetX,
        size.height * yStart + offsetY);

    // Rounded fingertip
    fingerPath.quadraticBezierTo(
        size.width * (xStart + width * 0.75) + offsetX,
        size.height * (yStart - 0.01) + offsetY,
        size.width * (xStart + width) + offsetX,
        size.height * (yStart + 0.02) + offsetY);

    // Right side tapering down
    fingerPath.quadraticBezierTo(
        size.width * (xStart + width * 0.9) + offsetX,
        size.height * (yStart + height * 0.3) + offsetY,
        size.width * (xStart + width * 0.95) + offsetX,
        size.height * (yStart + height * 0.6) + offsetY);

    // Connection to palm - wider
    fingerPath.lineTo(size.width * (xStart + width) + offsetX,
        size.height * (yStart + height) + offsetY);
    fingerPath.lineTo(size.width * xStart + offsetX,
        size.height * (yStart + height) + offsetY);

    // Left side
    fingerPath.quadraticBezierTo(
        size.width * (xStart + width * 0.1) + offsetX,
        size.height * (yStart + height * 0.6) + offsetY,
        size.width * (xStart + width * 0.05) + offsetX,
        size.height * (yStart + height * 0.3) + offsetY);

    fingerPath.quadraticBezierTo(
        size.width * (xStart + width * 0.25) + offsetX,
        size.height * (yStart - 0.01) + offsetY,
        size.width * (xStart + width / 2) + offsetX,
        size.height * yStart + offsetY);

    fingerPath.close();
    canvas.drawPath(fingerPath, paint);
  }

  void _drawHandHighlights(Canvas canvas, Size size, Color lightColor) {
    final highlightPaint = Paint()
      ..color = lightColor.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Add subtle highlights on top surfaces
    final highlights = [
      // Palm highlight
      Path()
        ..addOval(Rect.fromLTWH(size.width * 0.35, size.height * 0.35,
            size.width * 0.3, size.height * 0.08)),
      // Finger highlights
      Path()
        ..addOval(Rect.fromLTWH(size.width * 0.29, size.height * 0.12,
            size.width * 0.09, size.height * 0.15)),
      Path()
        ..addOval(Rect.fromLTWH(size.width * 0.46, size.height * 0.09,
            size.width * 0.09, size.height * 0.18)),
      Path()
        ..addOval(Rect.fromLTWH(size.width * 0.63, size.height * 0.11,
            size.width * 0.09, size.height * 0.16)),
    ];

    for (var highlight in highlights) {
      canvas.drawPath(highlight, highlightPaint);
    }
  }

  void _drawJointDetails(
      Canvas canvas, Size size, Color metalColor, Color darkColor) {
    final jointPaint = Paint()
      ..color = metalColor
      ..style = PaintingStyle.fill;

    final darkPaint = Paint()
      ..color = darkColor
      ..style = PaintingStyle.fill;

    // Refined knuckle joints
    final knuckles = [
      {'x': 0.335, 'y': 0.32, 'size': 0.020}, // Index
      {'x': 0.5, 'y': 0.31, 'size': 0.025}, // Middle
      {'x': 0.665, 'y': 0.32, 'size': 0.020}, // Ring
      {'x': 0.81, 'y': 0.34, 'size': 0.016}, // Pinky
    ];

    for (var knuckle in knuckles) {
      final center = Offset(
        size.width * knuckle['x']!,
        size.height * knuckle['y']!,
      );

      // Joint housing
      canvas.drawCircle(center, size.width * knuckle['size']!, jointPaint);
      // Inner mechanism
      canvas.drawCircle(center, size.width * knuckle['size']! * 0.6, darkPaint);
      // Center pin
      canvas.drawCircle(center, size.width * knuckle['size']! * 0.3,
          Paint()..color = Colors.grey[700]!);
    }

    // Thumb joint
    final thumbJoint = Offset(size.width * 0.16, size.height * 0.47);
    canvas.drawCircle(thumbJoint, size.width * 0.018, jointPaint);
    canvas.drawCircle(thumbJoint, size.width * 0.012, darkPaint);
  }

  void _drawFingerNails(Canvas canvas, Size size) {
    final nailPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final nailBorder = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final nails = [
      [0.335, 0.085, 0.04, 0.012], // Index
      [0.5, 0.055, 0.045, 0.015], // Middle
      [0.665, 0.075, 0.04, 0.012], // Ring
      [0.81, 0.105, 0.035, 0.01], // Pinky
      [0.135, 0.285, 0.03, 0.01], // Thumb
    ];

    for (var nail in nails) {
      final nailRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * nail[0] - size.width * nail[2] / 2,
          size.height * nail[1],
          size.width * nail[2],
          size.height * nail[3],
        ),
        Radius.circular(size.width * 0.006),
      );

      canvas.drawRRect(nailRect, nailPaint);
      canvas.drawRRect(nailRect, nailBorder);
    }
  }

  Color _lightenColor(Color color, double factor) {
    return Color.fromRGBO(
      (color.red + (255 - color.red) * factor).round(),
      (color.green + (255 - color.green) * factor).round(),
      (color.blue + (255 - color.blue) * factor).round(),
      color.opacity,
    );
  }

  Color _darkenColor(Color color, double factor) {
    return Color.fromRGBO(
      (color.red * (1 - factor)).round(),
      (color.green * (1 - factor)).round(),
      (color.blue * (1 - factor)).round(),
      color.opacity,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
