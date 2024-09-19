import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prosthetic_config.dart';
import 'prosthetic_3d_preview.dart';

class CustomizeProstheticScreen extends StatefulWidget {
  final ProstheticConfig? config;
  const CustomizeProstheticScreen({Key? key, this.config}) : super(key: key);

  @override
  _CustomizeProstheticScreenState createState() => _CustomizeProstheticScreenState();
}

class _CustomizeProstheticScreenState extends State<CustomizeProstheticScreen> {
  late double _length;
  late double _width;
  String _currentModelPath = 'assets/experiment.obj'; // Default model path

  final List<String> _modelPaths = [
    'assets/experiment.obj',
    // You can add other .obj files here if you want to switch between them
  ];

  @override
  void initState() {
    super.initState();
    _length = widget.config?.length ?? 50;
    _width = widget.config?.width ?? 10;
    _currentModelPath = widget.config?.modelPath ?? _currentModelPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config == null ? 'Customize Prosthetic' : 'Edit Prosthetic'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Prosthetic3DPreview(
                modelPath: _currentModelPath,
                length: _length,
                width: _width,
                color: Colors.grey, // Default color
              ),
            ),
            const SizedBox(height: 20),
            Text('Select Model:', style: Theme.of(context).textTheme.titleMedium),
            DropdownButton<String>(
              value: _currentModelPath,
              items: _modelPaths.map((String path) {
                return DropdownMenuItem<String>(
                  value: path,
                  child: Text(path.split('/').last),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _currentModelPath = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            Text('Length: ${_length.toStringAsFixed(1)} cm', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _length,
              min: 30,
              max: 70,
              divisions: 40,
              label: _length.round().toString(),
              onChanged: (value) {
                setState(() => _length = value);
              },
            ),
            const SizedBox(height: 20),
            Text('Width: ${_width.toStringAsFixed(1)} cm', style: Theme.of(context).textTheme.titleMedium),
            Slider(
              value: _width,
              min: 5,
              max: 15,
              divisions: 20,
              label: _width.round().toString(),
              onChanged: (value) {
                setState(() => _width = value);
              },
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _saveConfiguration,
                child: Text(widget.config == null ? 'Save Configuration' : 'Update Configuration'),
              ),
            ),
          ],
        ),
      ),
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
      color: Colors.grey, // Default color
      modelPath: _currentModelPath,
    );

    if (widget.config != null) {
      // Update existing config
      final index = configs.indexWhere((config) => config.id == widget.config!.id);
      if (index != -1) {
        configs[index] = newConfig;
      }
    } else {
      // Add new config
      configs.add(newConfig);
    }

    await prefs.setString('prosthetic_configs', ProstheticConfig.encode(configs));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.config == null ? 'Configuration saved!' : 'Configuration updated!')),
    );

    Navigator.pop(context);
  }
}