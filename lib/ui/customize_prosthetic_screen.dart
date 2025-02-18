import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prosthetic_config.dart';
import 'prosthetic_3d_preview.dart';

class CustomizeProstheticScreen extends StatefulWidget {
  final ProstheticConfig? config;
  const CustomizeProstheticScreen({Key? key, this.config}) : super(key: key);

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
  String _currentModelPath = 'assets/experiment.obj';
  bool _isExpanded = false;
  bool _isSaving = false;

  final List<String> _modelPaths = [
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
    _length = widget.config?.length ?? 50;
    _width = widget.config?.width ?? 10;
    _circumferenceTop = widget.config?.circumferenceTop ?? 30;
    _circumferenceBottom = widget.config?.circumferenceBottom ?? 25;
    _kneeFlexion = widget.config?.kneeFlexion ?? 0;
    _mainColor = widget.config?.color ?? Colors.grey[600]!;
    _material = widget.config?.material ?? 'Titanium';
    _currentModelPath = widget.config?.modelPath ?? _currentModelPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config == null
            ? 'Create New Prosthetic'
            : 'Edit Prosthetic'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving ? null : _saveConfiguration,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 3D Preview Section
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              padding: EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Prosthetic3DPreview(
                    modelPath: _currentModelPath,
                    length: _length,
                    width: _width,
                    color: _mainColor,
                  ),
                ),
              ),
            ),

            // Customization Controls
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Model Selection
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Model Selection',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _currentModelPath,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                              ),
                              items: _modelPaths.map((String path) {
                                return DropdownMenuItem<String>(
                                  value: path,
                                  child: Text(path.split('/').last),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() => _currentModelPath = newValue);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Basic Measurements
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Basic Measurements',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 16),
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
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ExpansionTile(
                        title: Text(
                          'Detailed Measurements',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
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
                        ],
                      ),
                    ),

                    // Material Selection
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Material',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _material,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                              ),
                              items: _materials.map((String material) {
                                return DropdownMenuItem<String>(
                                  value: material,
                                  child: Text(material),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() => _material = newValue);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Color Selection
                    Card(
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Color',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 16),
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
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _mainColor == color
                                            ? Theme.of(context).primaryColor
                                            : Colors.transparent,
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String unit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${value.toStringAsFixed(1)}$unit'),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).primaryColor,
            thumbColor: Theme.of(context).primaryColor,
            overlayColor: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 2).toInt(),
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
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
        id: widget.config?.id ?? DateTime.now().toString(),
        length: _length,
        width: _width,
        circumferenceTop: _circumferenceTop,
        circumferenceBottom: _circumferenceBottom,
        kneeFlexion: _kneeFlexion,
        color: _mainColor,
        material: _material,
        modelPath: _currentModelPath,
      );

      if (widget.config != null) {
        final index =
            configs.indexWhere((config) => config.id == widget.config!.id);
        if (index != -1) {
          configs[index] = newConfig;
        }
      } else {
        configs.add(newConfig);
      }

      await prefs.setString(
          'prosthetic_configs', ProstheticConfig.encode(configs));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.config == null
                ? 'Configuration saved successfully!'
                : 'Configuration updated successfully!',
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving configuration: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
}
