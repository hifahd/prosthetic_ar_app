import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prosthetic_config.dart';
import 'customize_prosthetic_screen.dart';

class SavedConfigsScreen extends StatefulWidget {
  const SavedConfigsScreen({Key? key}) : super(key: key);

  @override
  _SavedConfigsScreenState createState() => _SavedConfigsScreenState();
}

class _SavedConfigsScreenState extends State<SavedConfigsScreen> {
  List<ProstheticConfig> _configs = [];

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  void _loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedConfigs = prefs.getString('prosthetic_configs');
    if (savedConfigs != null) {
      setState(() {
        _configs = ProstheticConfig.decode(savedConfigs);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Configurations'),
      ),
      body: ListView.builder(
        itemCount: _configs.length,
        itemBuilder: (context, index) {
          final config = _configs[index];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              color: config.color,
            ),
            title: Text('Config ${index + 1}'),
            subtitle: Text('Length: ${config.length.toStringAsFixed(1)} cm, Width: ${config.width.toStringAsFixed(1)} cm'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomizeProstheticScreen(config: config),
                ),
              ).then((_) => _loadConfigs());
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CustomizeProstheticScreen(),
            ),
          ).then((_) => _loadConfigs());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}