import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prosthetic_config.dart';
import '../theme/app_theme.dart';
import 'customize_prosthetic_screen.dart';
import 'mediapipe_ar_view.dart';

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

  void _selectConfig(ProstheticConfig config) {
    setState(() {
      _selectedConfig = config;
    });
  }

  void _startAR() {
    if (_selectedConfig == null) {
      _showErrorSnackBar('Please select a configuration first');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MediaPipeARView(selectedConfig: _selectedConfig),
      ),
    );
  }

  Widget _buildModelViewer({required String src}) {
    return ModelViewer(
      src: src,
      alt: "A 3D model",
      ar: false,
      autoRotate: true,
      cameraControls: true,
      disableZoom: false,
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
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
    // Get the safe area bottom padding
    final bottomPadding = MediaQuery.of(context).padding.bottom;

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
            child: Stack(
              children: [
                _selectedConfig == null
                    ? _buildModelViewer(src: 'assets/cyborg.glb')
                    : _buildModelViewer(src: _selectedConfig!.modelPath),

                // AR Status Indicator - Only show when a model is selected
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
                                      'Select Configuration',
                                      'Choose a prosthetic configuration from the bottom panel',
                                      Icons.settings,
                                    ),
                                    _buildInstructionStep(
                                      'Start AR Mode',
                                      'Press the Start AR button to open the camera view',
                                      Icons.play_arrow,
                                    ),
                                    _buildInstructionStep(
                                      'Place the Prosthetic',
                                      'Tap near body joints to anchor the prosthetic. If joints aren\'t being detected, use Manual Mode.',
                                      Icons.touch_app,
                                    ),
                                    _buildInstructionStep(
                                      'Try Different Positions',
                                      'Stand in a well-lit area with a neutral background for best results',
                                      Icons.accessibility_new,
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

                // Start AR Button - Only show when a model is selected and instructions are dismissed
                if (_selectedConfig != null && !_showInstructions)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 120,
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: ElevatedButton(
                          onPressed: _startAR,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Start AR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom configuration panel - Fixed height with safe area handling
          Container(
            // Account for bottom safe area in the height calculation
            height: 110 + bottomPadding, // Reduced from 120 to prevent overflow
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
            child: Column(
              children: [
                // Content area
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 6),
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
                                icon: Icon(Icons.add, size: 20),
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
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            )
                          : Container(
                              height: 70,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _savedConfigs.length,
                                itemBuilder: (context, index) {
                                  final config = _savedConfigs[index];
                                  final isSelected =
                                      _selectedConfig?.id == config.id;
                                  return Padding(
                                    padding: EdgeInsets.only(
                                        right: 8), // Reduced from 12 to 8
                                    child: _buildConfigCard(config, isSelected),
                                  );
                                },
                              ),
                            ),
                    ],
                  ),
                ),

                // Add SafeArea padding at the bottom
                SizedBox(height: bottomPadding),
              ],
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
          width: 100, // Reduced from 110 to 100 to prevent overflow
          height: 70, // Fixed height
          padding: EdgeInsets.all(6),
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
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.view_in_ar,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Config ${_savedConfigs.indexOf(config) + 1}',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1),
              Text(
                'Age: ${config.patientAge}',
                style: TextStyle(
                  color: isSelected
                      ? Colors.white.withOpacity(0.8)
                      : AppTheme.subtitleColor,
                  fontSize: 9,
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
                'Tap the Start AR button to open camera view',
                Icons.play_arrow,
              ),
              _buildInstructionStep(
                '3. Find Body Joints',
                'The camera will automatically detect your pose',
                Icons.person_outline,
              ),
              _buildInstructionStep(
                '4. Try Good Lighting',
                'Stand in a well-lit area with minimal background clutter',
                Icons.wb_sunny,
              ),
              _buildInstructionStep(
                '5. Use Manual Mode',
                'If detection fails, tap the Manual Mode button in the top bar',
                Icons.touch_app,
              ),
              _buildInstructionStep(
                '6. Tap to Anchor',
                'Tap near joints (or anywhere in Manual Mode) to attach prosthetic',
                Icons.touch_app,
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
