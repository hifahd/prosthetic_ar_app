import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prosthetic_config.dart';

class CustomizeProstheticScreen extends StatefulWidget {
  final ProstheticConfig? config;
  const CustomizeProstheticScreen({Key? key, this.config}) : super(key: key);

  @override
  _CustomizeProstheticScreenState createState() => _CustomizeProstheticScreenState();
}

class _CustomizeProstheticScreenState extends State<CustomizeProstheticScreen> {
  late double _length;
  late double _width;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _length = widget.config?.length ?? 50;
    _width = widget.config?.width ?? 10;
    _color = widget.config?.color ?? Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config == null ? 'Customize Prosthetic' : 'Edit Prosthetic'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 20),
            Text('Color:', style: Theme.of(context).textTheme.titleMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ColorButton(Colors.grey, _color == Colors.grey, () => _setColor(Colors.grey)),
                ColorButton(Colors.brown, _color == Colors.brown, () => _setColor(Colors.brown)),
                ColorButton(Colors.pink, _color == Colors.pink, () => _setColor(Colors.pink)),
              ],
            ),
            const Spacer(),
            Center(
              child: Container(
                width: _width * 10,
                height: _length * 2,
                color: _color,
                child: Center(
                  child: Text(
                    'Prosthetic\nPreview',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            const Spacer(),
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

  void _setColor(Color color) {
    setState(() => _color = color);
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
      color: _color,
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

class ColorButton extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const ColorButton(this.color, this.isSelected, this.onTap, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}