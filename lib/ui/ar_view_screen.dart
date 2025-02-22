import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prosthetic_config.dart';
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
      duration: Duration(milliseconds: 300),
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
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
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
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(description),
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
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () => _showInstructionsDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main content area (AR viewer)
          Expanded(
            flex: 85, // Takes up most of the space
            child: Stack(
              children: [
                _selectedConfig == null
                    ? _buildModelViewer(
                        src:
                            'https://modelviewer.dev/shared-assets/models/Astronaut.glb')
                    : _buildModelViewer(src: _selectedConfig!.modelPath),
                if (_isLoading)
                  Container(
                    color: Colors.black45,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (_showInstructions)
                  FadeTransition(
                    opacity: _animation,
                    child: Container(
                      color: Colors.black54,
                      child: Center(
                        child: Card(
                          margin: EdgeInsets.all(32),
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'AR Instructions',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                SizedBox(height: 16),
                                _buildInstructionStep(
                                  'Start AR Mode',
                                  'Look for the AR button above the bottom panel',
                                  Icons.view_in_ar,
                                ),
                                _buildInstructionStep(
                                  'Scan Area',
                                  'Move device to scan area',
                                  Icons.camera,
                                ),
                                _buildInstructionStep(
                                  'Place Model',
                                  'Tap to place model',
                                  Icons.touch_app,
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => _showInstructions = false);
                                    _controller.reverse();
                                  },
                                  child: Text('Got it'),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: _savedConfigs.isEmpty && !_isLoading
                    ? Container(
                        width: 240,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    CustomizeProstheticScreen(),
                              ),
                            ).then((_) => _loadSavedConfigs());
                          },
                          child: Text('Create Configuration'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _savedConfigs.length,
                          itemBuilder: (context, index) {
                            final config = _savedConfigs[index];
                            final isSelected = _selectedConfig?.id == config.id;
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: _buildConfigCard(config, isSelected),
                            );
                          },
                        ),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 100,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.view_in_ar,
                color:
                    isSelected ? Colors.white : Theme.of(context).primaryColor,
                size: 24,
              ),
              SizedBox(height: 8),
              Text(
                'Config ${config.id.substring(0, 4)}',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${config.length.toStringAsFixed(1)}cm',
                style: TextStyle(
                  color: isSelected ? Colors.white70 : Colors.grey[600],
                  fontSize: 10,
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
        title: Text('How to Use AR View'),
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
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }
}
