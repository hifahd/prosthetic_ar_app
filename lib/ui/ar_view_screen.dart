import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prosthetic_config.dart';
import '../theme/app_theme.dart';
import '../utils/prosthetic_scaler.dart';
import '../widgets/body_anchor_overlay.dart';
import 'customize_prosthetic_screen.dart';

class ARViewScreen extends StatefulWidget {
  const ARViewScreen({Key? key}) : super(key: key);

  @override
  _ARViewScreenState createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen>
    with SingleTickerProviderStateMixin {
  List<ProstheticConfig> _savedConfigs = [];
  ProstheticConfig? _selectedConfig;
  bool _isLoading = true;
  bool _showInstructions = true;
  bool _isAnchored = false;
  bool _isInARMode = false; // Make sure this is initialized to false
  Offset? _anchorPosition;
  late AnimationController _controller;
  late Animation<double> _animation;

  // Scale factors for the model
  Map<String, double> _scaleFactors = {
    'x': 1.0,
    'y': 1.0,
    'z': 1.0,
  };

  @override
  void initState() {
    super.initState();
    _loadSavedConfigs();
    _controller = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSavedConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedConfigs = prefs.getString('prosthetic_configs');

      setState(() {
        if (savedConfigs != null) {
          _savedConfigs = ProstheticConfig.decode(savedConfigs);
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading configurations: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading configurations');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _selectConfig(ProstheticConfig config) {
    setState(() {
      _selectedConfig = config;
      _isAnchored = false;
      _isInARMode = false; // Important: Reset AR mode when selecting a config

      // Update scale factors based on age and limb type
      final limbType =
          ProstheticScaler.getLimbTypeFromModelPath(config.modelPath);
      _scaleFactors =
          ProstheticScaler.getScaleFactorsForAge(config.patientAge, limbType);

      print('Selected config with age: ${config.patientAge}');
      print('Applied scale factors: $_scaleFactors for limb type: $limbType');
    });
  }

  void _handleAnchorSelected(Offset position) {
    setState(() {
      _anchorPosition = position;
      _isAnchored = true;
    });
  }

  void _toggleARMode() {
    setState(() {
      _isInARMode = !_isInARMode;
      // Reset anchoring when toggling AR mode
      if (!_isInARMode) {
        _isAnchored = false;
        _anchorPosition = null;
      }
    });
  }

  Widget _buildModelViewer({required String src}) {
    return Stack(
      children: [
        // Base model viewer
        ModelViewer(
          src: src,
          alt: "A 3D model",
          ar: true,
          arModes: const ['scene-viewer', 'webxr', 'quick-look'],
          autoRotate: !_isAnchored,
          cameraControls: !_isAnchored,
          disableZoom: _isAnchored,
          backgroundColor: const Color.fromARGB(255, 245, 245, 245),
          relatedCss: '''
           model-viewer {
             --poster-color: transparent;
             transform: scale3d(${_scaleFactors['x']}, ${_scaleFactors['y']}, ${_scaleFactors['z']});
           }
         ''',
        ),

        // AR mode toggle button - only show if not in AR mode
        if (_selectedConfig != null && !_isInARMode)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: _toggleARMode,
              icon: Icon(Icons.view_in_ar),
              label: Text('Start AR'),
              backgroundColor: AppTheme.primaryColor,
            ),
          ),

        // Only show body anchor overlay when in AR mode and not yet anchored
        if (_selectedConfig != null && _isInARMode && !_isAnchored)
          Positioned.fill(
            child: BodyAnchorOverlay(
              limbType: ProstheticScaler.getLimbTypeFromModelPath(
                  _selectedConfig!.modelPath),
              onAnchorSelected: _handleAnchorSelected,
            ),
          ),

        // AR mode close button - only when in AR mode and not anchored
        if (_selectedConfig != null && _isInARMode && !_isAnchored)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _toggleARMode,
              backgroundColor: Colors.white,
              child: Icon(Icons.close, color: AppTheme.errorColor),
            ),
          ),

        // Reset anchor button - only when anchored
        if (_isAnchored)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () {
                setState(() {
                  _isAnchored = false;
                  _anchorPosition = null;
                });
              },
              backgroundColor: Colors.white,
              child: Icon(Icons.refresh, color: AppTheme.primaryColor),
            ),
          ),

        // Anchored position indicator
        if (_isAnchored && _anchorPosition != null)
          Positioned(
            left: _anchorPosition!.dx - 5,
            top: _anchorPosition!.dy - 5,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInstructionStep(
      String title, String description, IconData icon) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 26,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Visualization'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            onPressed: () => _showInstructionsDialog(context),
          ),
        ],
      ),
      extendBodyBehindAppBar: false,
      body: Column(
        children: [
          // Main content area (AR viewer)
          Expanded(
            flex: 85, // Takes up most of the space
            child: Stack(
              children: [
                _selectedConfig == null
                    ? _buildModelViewer(src: 'assets/cyborg.glb')
                    : _buildModelViewer(src: _selectedConfig!.modelPath),

                // AR Overlay Element - Guide Lines
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: ARGuidePainter(
                        visible: !_showInstructions &&
                            _selectedConfig != null &&
                            _isInARMode &&
                            !_isAnchored,
                      ),
                    ),
                  ),
                ),

                if (_isLoading)
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                if (_showInstructions)
                  FadeTransition(
                    opacity: _animation,
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Card(
                          margin: EdgeInsets.symmetric(horizontal: 32),
                          elevation: 8,
                          shadowColor: Colors.black38,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight:
                                  MediaQuery.of(context).size.height * 0.8,
                            ),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Icon(
                                        Icons.view_in_ar,
                                        size: 36,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'AR Instructions',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryColor,
                                          ),
                                    ),
                                    SizedBox(height: 24),
                                    _buildInstructionStep(
                                      'Select a Configuration',
                                      'Choose a saved prosthetic configuration from the bottom panel',
                                      Icons.settings,
                                    ),
                                    _buildInstructionStep(
                                      'Start AR Mode',
                                      'Press the Start AR button that appears',
                                      Icons.play_arrow,
                                    ),
                                    _buildInstructionStep(
                                      'Place the Prosthetic',
                                      'Tap on the screen where you want to position the prosthetic',
                                      Icons.touch_app,
                                    ),
                                    _buildInstructionStep(
                                      'Verify Fit',
                                      'Check that the prosthetic is properly sized based on patient age',
                                      Icons.check_circle_outline,
                                    ),
                                    SizedBox(height: 24),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(
                                            () => _showInstructions = false);
                                        _controller.reverse();
                                      },
                                      child: Text('Got it'),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 40, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // AR Status Indicator
                if (!_showInstructions && !_isLoading)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isInARMode
                                ? (_isAnchored ? Icons.link : Icons.touch_app)
                                : Icons.view_in_ar,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _selectedConfig != null
                                ? _isInARMode
                                    ? (_isAnchored
                                        ? 'Anchored to Body'
                                        : 'Tap to Place')
                                    : 'Press Start AR'
                                : 'No Model Selected',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom configuration panel
          Container(
            height: 110, // Reduced from 120 to fix overflow
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: Offset(0, -3),
                ),
              ],
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              bottom: true, // Ensure safe area at the bottom
              maintainBottomViewPadding: true, // Helps with bottom overflow
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                          left: 8, bottom: 6), // Reduced padding
                      child: Text(
                        _savedConfigs.isEmpty
                            ? 'Create Your First Configuration'
                            : 'Select Configuration',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    _savedConfigs.isEmpty && !_isLoading
                        ? Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.add, size: 20), // Smaller icon
                              label: Text('Create Configuration'),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        CustomizeProstheticScreen(),
                                  ),
                                ).then((_) => _loadSavedConfigs());
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    vertical: 12), // Reduced padding
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          )
                        : Container(
                            height: 75, // Reduced height
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _savedConfigs.length,
                              itemBuilder: (context, index) {
                                final config = _savedConfigs[index];
                                final isSelected =
                                    _selectedConfig?.id == config.id;
                                return Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: _buildConfigCard(config, isSelected),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard(ProstheticConfig config, bool isSelected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectConfig(config),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 110, // Reduced width
          height: 75, // Reduced height
          padding: EdgeInsets.all(6), // Reduced padding
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(5), // Reduced padding
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.view_in_ar,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  size: 20, // Reduced size
                ),
              ),
              SizedBox(height: 4), // Reduced spacing
              Text(
                'Config ${config.id.substring(0, 4)}',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11, // Reduced font size
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1), // Reduced spacing
              Text(
                'Age: ${config.patientAge}', // Display age
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : AppTheme.subtitleColor,
                  fontSize: 9, // Reduced font size
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Icon(
              Icons.view_in_ar,
              size: 36,
              color: AppTheme.primaryColor,
            ),
            SizedBox(height: 8),
            Text(
              'How to Use AR View',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInstructionStep(
                '1. Select Configuration',
                'Choose a saved prosthetic configuration',
                Icons.list,
              ),
              _buildInstructionStep(
                '2. Press Start AR',
                'Tap the Start AR button to enter AR mode',
                Icons.play_arrow,
              ),
              _buildInstructionStep(
                '3. Place Prosthetic',
                'Tap where you want to attach the prosthetic',
                Icons.touch_app,
              ),
              _buildInstructionStep(
                '4. Check Sizing',
                'Verify the prosthetic is properly scaled for patient age',
                Icons.person_outline,
              ),
              _buildInstructionStep(
                '5. Adjust Position',
                'Use reset button to reposition if needed',
                Icons.refresh,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// AR Guide Painter class
class ARGuidePainter extends CustomPainter {
  final bool visible;

  ARGuidePainter({required this.visible});

  @override
  void paint(Canvas canvas, Size size) {
    if (!visible) return;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw grid lines
    final gridSpacing = 30.0;
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Horizontal grid lines
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical grid lines
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw center crosshair
    final crossPaint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final crossSize = 30.0;

    // Horizontal line
    canvas.drawLine(
      Offset(centerX - crossSize, centerY),
      Offset(centerX + crossSize, centerY),
      crossPaint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(centerX, centerY - crossSize),
      Offset(centerX, centerY + crossSize),
      crossPaint,
    );

    // Draw center circle
    canvas.drawCircle(
      Offset(centerX, centerY),
      10.0,
      Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );

    // Draw tap hint text
    final textSpan = TextSpan(
      text: "Tap to place model",
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            offset: Offset(1, 1),
            blurRadius: 3,
            color: Colors.black45,
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        centerY + crossSize + 10,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
