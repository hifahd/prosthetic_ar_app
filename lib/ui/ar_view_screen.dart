import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prosthetic_config.dart';
import '../theme/app_theme.dart';
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
  late AnimationController _controller;
  late Animation<double> _animation;

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

  Widget _buildModelViewer({required String src}) {
    return ModelViewer(
      src: src,
      alt: "A 3D model",
      ar: true,
      arModes: const ['scene-viewer', 'webxr', 'quick-look'],
      autoRotate: true,
      cameraControls: true,
      disableZoom: false,
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      //arScale: "fixed",
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
                        visible: !_showInstructions && _selectedConfig != null,
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
                                      'Start AR Mode',
                                      'Look for the AR button above the bottom panel',
                                      Icons.view_in_ar,
                                    ),
                                    _buildInstructionStep(
                                      'Scan Area',
                                      'Move device to scan surfaces in your environment',
                                      Icons.camera,
                                    ),
                                    _buildInstructionStep(
                                      'Place Model',
                                      'Tap on a surface to place the model',
                                      Icons.touch_app,
                                    ),
                                    _buildInstructionStep(
                                      'Resize & Rotate',
                                      'Use pinch gestures to resize and rotate the model',
                                      Icons.pinch,
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
                    right: 16,
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
                            Icons.view_in_ar,
                            size: 18,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _selectedConfig != null
                                ? 'Model Ready'
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
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        _savedConfigs.isEmpty
                            ? 'Create Your First Configuration'
                            : 'Select Configuration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    _savedConfigs.isEmpty && !_isLoading
                        ? Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.add),
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
                                padding: EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                            ),
                          )
                        : Container(
                            height: 100,
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
        onTap: () => setState(() => _selectedConfig = config),
        borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          width: 120,
          padding: EdgeInsets.all(12),
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
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.view_in_ar,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  size: 26,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Config ${config.id.substring(0, 4)}',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4),
              Text(
                '${config.length.toStringAsFixed(1)}cm',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : AppTheme.subtitleColor,
                  fontSize: 12,
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
                '2. Start AR Mode',
                'Tap the AR button above the bottom panel',
                Icons.view_in_ar,
              ),
              _buildInstructionStep(
                '3. Scan Environment',
                'Move your device to scan the area',
                Icons.camera,
              ),
              _buildInstructionStep(
                '4. Place Model',
                'Tap on a surface to place the model',
                Icons.touch_app,
              ),
              _buildInstructionStep(
                '5. Adjust Model',
                'Use pinch gestures to resize and rotate',
                Icons.pinch,
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

// AR Guide Painter for visual guidelines
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
