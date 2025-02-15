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

  @override
  void initState() {
    super.initState();
    _length = widget.config?.length ?? 50;
    _width = widget.config?.width ?? 10;
    _circumferenceTop = widget.config?.circumferenceTop ?? 30;
    _circumferenceBottom = widget.config?.circumferenceBottom ?? 25;
    _kneeFlexion = widget.config?.kneeFlexion ?? 0;
    _mainColor = widget.config?.color ?? Colors.grey;
    _material = widget.config?.material ?? 'Titanium';
    _currentModelPath = widget.config?.modelPath ?? _currentModelPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.config == null ? 'Customize Prosthetic' : 'Edit Prosthetic'),
      ),
      body: Row(
        children: [
          // Left panel - 3D Preview
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: Prosthetic3DPreview(
                modelPath: _currentModelPath,
                length: _length,
                width: _width,
                color: _mainColor,
              ),
            ),
          ),
          // Right panel - Controls
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Model Selection'),
                  DropdownButton<String>(
                    value: _currentModelPath,
                    isExpanded: true,
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
                  const SizedBox(height: 20),
                  _buildSectionTitle('Basic Measurements'),
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
                  const SizedBox(height: 20),
                  _buildSectionTitle('Detailed Measurements'),
                  _buildSlider(
                    'Top Circumference',
                    _circumferenceTop,
                    20,
                    50,
                    (value) => setState(() => _circumferenceTop = value),
                    'cm',
                  ),
                  _buildSlider(
                    'Bottom Circumference',
                    _circumferenceBottom,
                    15,
                    40,
                    (value) => setState(() => _circumferenceBottom = value),
                    'cm',
                  ),
                  _buildSlider(
                    'Knee Flexion',
                    _kneeFlexion,
                    0,
                    120,
                    (value) => setState(() => _kneeFlexion = value),
                    '°',
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Material'),
                  DropdownButton<String>(
                    value: _material,
                    isExpanded: true,
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
                  const SizedBox(height: 20),
                  _buildSectionTitle('Color'),
                  _buildColorPicker(),
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton(
                      onPressed: _saveConfiguration,
                      child: Text(widget.config == null
                          ? 'Save Configuration'
                          : 'Update Configuration'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
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
        Text('$label: ${value.toStringAsFixed(1)}$unit'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 2).toInt(),
          label: value.round().toString(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildColorPicker() {
    final List<Color> colors = [
      Colors.grey[400]!,
      Colors.grey[600]!,
      Colors.grey[800]!,
      Colors.black,
      Colors.blue[900]!,
      Colors.blue[700]!,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((Color color) {
        return GestureDetector(
          onTap: () => setState(() => _mainColor = color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: _mainColor == color
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _saveConfiguration() async {
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
      // Update existing config
      final index =
          configs.indexWhere((config) => config.id == widget.config!.id);
      if (index != -1) {
        configs[index] = newConfig;
      }
    } else {
      // Add new config
      configs.add(newConfig);
    }

    await prefs.setString(
        'prosthetic_configs', ProstheticConfig.encode(configs));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(widget.config == null
              ? 'Configuration saved!'
              : 'Configuration updated!')),
    );

    Navigator.pop(context);
  }
}
