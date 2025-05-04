import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prosthetic_config.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_bottom_nav.dart';

class CustomizeProstheticScreen extends StatefulWidget {
  final ProstheticConfig? initialConfig;
  const CustomizeProstheticScreen({Key? key, this.initialConfig})
      : super(key: key);

  @override
  _CustomizeProstheticScreenState createState() =>
      _CustomizeProstheticScreenState();
}

class _CustomizeProstheticScreenState extends State<CustomizeProstheticScreen> {
  late double _length;
  late double _width;
  late double _circumferenceTop;
  late double _circumferenceBottom;
  late double _kneeFlexion;
  late Color _mainColor;
  late String _material;
  late int _patientAge;
  String _currentModelPath = 'assets/cyborg.glb';
  bool _isExpanded = false;
  bool _isSaving = false;
  int _currentNavIndex = 0;

  final List<String> _modelPaths = [
    'assets/cyborg.glb',
    'assets/experiment.obj',
    'assets/prosthetic_leg.obj',
    'assets/detailed_prosthetic_leg.obj',
  ];

  final List<String> _materials = [
    'Titanium',
    'Carbon Fiber',
    'Stainless Steel',
    'Aluminum'
  ];

  final List<Color> _colorOptions = [
    Colors.grey[400]!,
    Colors.grey[600]!,
    Colors.grey[800]!,
    Colors.black,
    Colors.blue[900]!,
    Colors.blue[700]!,
  ];

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    // Make sure initial values are within slider ranges
    _length = widget.initialConfig?.length ?? 50.0;
    // Ensure value is in bounds
    if (_length < 30.0) _length = 30.0;
    if (_length > 70.0) _length = 70.0;

    _width = widget.initialConfig?.width ?? 10.0;
    // Ensure value is in bounds
    if (_width < 5.0) _width = 5.0;
    if (_width > 15.0) _width = 15.0;

    _circumferenceTop = widget.initialConfig?.circumferenceTop ?? 30.0;
    // Ensure value is in bounds
    if (_circumferenceTop < 20.0) _circumferenceTop = 20.0;
    if (_circumferenceTop > 50.0) _circumferenceTop = 50.0;

    _circumferenceBottom = widget.initialConfig?.circumferenceBottom ?? 25.0;
    // Ensure value is in bounds
    if (_circumferenceBottom < 15.0) _circumferenceBottom = 15.0;
    if (_circumferenceBottom > 40.0) _circumferenceBottom = 40.0;

    _kneeFlexion = widget.initialConfig?.kneeFlexion ?? 0.0;
    // Ensure value is in bounds
    if (_kneeFlexion < 0.0) _kneeFlexion = 0.0;
    if (_kneeFlexion > 120.0) _kneeFlexion = 120.0;

    // Initialize patient age
    _patientAge = widget.initialConfig?.patientAge ?? 30;

    _mainColor = widget.initialConfig?.color ?? Colors.grey[600]!;
    _material = widget.initialConfig?.material ?? 'Titanium';
    _currentModelPath = widget.initialConfig?.modelPath ?? _currentModelPath;
  }

  Future<void> _saveConfiguration() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedConfigs = prefs.getString('prosthetic_configs');
      List<ProstheticConfig> configs = [];

      if (savedConfigs != null) {
        configs = ProstheticConfig.decode(savedConfigs);
      }

      final newConfig = ProstheticConfig(
        id: widget.initialConfig?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        length: _length,
        width: _width,
        circumferenceTop: _circumferenceTop,
        circumferenceBottom: _circumferenceBottom,
        kneeFlexion: _kneeFlexion,
        color: _mainColor,
        material: _material,
        modelPath: _currentModelPath,
        patientAge: _patientAge, // Added age parameter
      );

      if (widget.initialConfig != null) {
        final index =
            configs.indexWhere((c) => c.id == widget.initialConfig!.id);
        if (index != -1) {
          configs[index] = newConfig;
        } else {
          configs.add(newConfig);
        }
      } else {
        configs.add(newConfig);
      }

      await prefs.setString(
          'prosthetic_configs', ProstheticConfig.encode(configs));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Configuration saved successfully',
            style: AppTheme.captionStyle.copyWith(color: Colors.white),
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.all(16),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving configuration',
            style: AppTheme.captionStyle.copyWith(color: Colors.white),
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    Function(double) onChanged,
    String unit,
  ) {
    // Ensure value is within bounds to prevent slider errors
    double safeValue = value;
    if (safeValue < min) safeValue = min;
    if (safeValue > max) safeValue = max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${safeValue.toStringAsFixed(1)} $unit',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.primaryColor.withOpacity(0.1),
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: safeValue,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.initialConfig == null
              ? 'Create New Prosthetic'
              : 'Edit Prosthetic',
          style: AppTheme.subheadingStyle.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(
                Icons.save_outlined,
                color: AppTheme.primaryColor,
              ),
              onPressed: _isSaving ? null : _saveConfiguration,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // 3D Preview Section - replaced with a placeholder
                Container(
                  height: MediaQuery.of(context).size.height * 0.35,
                  padding: EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.view_in_ar,
                            size: 64,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Prosthetic Preview',
                            style: AppTheme.subheadingStyle,
                          ),
                          SizedBox(height: 8),
                          Text(
                            _currentModelPath.split('/').last,
                            style: AppTheme.captionStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Customization Controls
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 80, // Add padding for bottom nav
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Patient Information Section - NEW SECTION
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Patient Information',
                                  style: AppTheme.subheadingStyle.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Age',
                                      style: AppTheme.bodyStyle.copyWith(
                                        color: AppTheme.textColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Container(
                                      width: 100,
                                      child: TextFormField(
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: AppTheme.surfaceColor,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            borderSide: BorderSide(
                                              color: AppTheme.primaryColor
                                                  .withOpacity(0.1),
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                        ),
                                        initialValue: _patientAge.toString(),
                                        onChanged: (value) {
                                          setState(() {
                                            _patientAge =
                                                int.tryParse(value) ?? 30;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Prosthetic size will automatically scale based on age',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.subtitleColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Model Selection
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Model Selection',
                                  style: AppTheme.subheadingStyle.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _currentModelPath,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppTheme.surfaceColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  style: AppTheme.bodyStyle,
                                  dropdownColor: Colors.white,
                                  items: _modelPaths.map((String path) {
                                    return DropdownMenuItem<String>(
                                      value: path,
                                      child: Text(
                                        path.split('/').last,
                                        style: AppTheme.bodyStyle,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(
                                          () => _currentModelPath = newValue);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Basic Measurements
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Basic Measurements',
                                  style: AppTheme.subheadingStyle.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 20),
                                _buildSlider(
                                  'Length',
                                  _length,
                                  30,
                                  70,
                                  (value) => setState(() => _length = value),
                                  'cm',
                                ),
                                _buildSlider(
                                  'Width',
                                  _width,
                                  5,
                                  15,
                                  (value) => setState(() => _width = value),
                                  'cm',
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Detailed Measurements
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              dividerColor: Colors.transparent,
                            ),
                            child: ExpansionTile(
                              title: Text(
                                'Detailed Measurements',
                                style: AppTheme.subheadingStyle.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                              childrenPadding: EdgeInsets.all(20),
                              children: [
                                _buildSlider(
                                  'Top Circumference',
                                  _circumferenceTop,
                                  20,
                                  50,
                                  (value) =>
                                      setState(() => _circumferenceTop = value),
                                  'cm',
                                ),
                                _buildSlider(
                                  'Bottom Circumference',
                                  _circumferenceBottom,
                                  15,
                                  40,
                                  (value) => setState(
                                      () => _circumferenceBottom = value),
                                  'cm',
                                ),
                                _buildSlider(
                                  'Knee Flexion',
                                  _kneeFlexion,
                                  0,
                                  120,
                                  (value) =>
                                      setState(() => _kneeFlexion = value),
                                  '°',
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Material Selection
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Material & Color',
                                  style: AppTheme.subheadingStyle.copyWith(
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _material,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: AppTheme.surfaceColor,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppTheme.primaryColor,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                  ),
                                  style: AppTheme.bodyStyle,
                                  dropdownColor: Colors.white,
                                  items: _materials.map((String material) {
                                    return DropdownMenuItem<String>(
                                      value: material,
                                      child: Text(
                                        material,
                                        style: AppTheme.bodyStyle,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    if (newValue != null) {
                                      setState(() => _material = newValue);
                                    }
                                  },
                                ),
                                SizedBox(height: 20),
                                Text(
                                  'Color',
                                  style: AppTheme.bodyStyle.copyWith(
                                    color: AppTheme.textColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: _colorOptions.map((Color color) {
                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => _mainColor = color),
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: _mainColor == color
                                              ? Border.all(
                                                  color: AppTheme.primaryColor,
                                                  width: 2,
                                                )
                                              : null,
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: _mainColor == color
                                            ? Icon(
                                                Icons.check,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNav(
              currentIndex: _currentNavIndex,
              onTap: (index) {
                setState(() => _currentNavIndex = index);
                // Handle navigation here
                switch (index) {
                  case 0:
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    break;
                  case 1:
                    // Navigate to notifications
                    break;
                  case 2:
                    // Navigate to profile
                    break;
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
