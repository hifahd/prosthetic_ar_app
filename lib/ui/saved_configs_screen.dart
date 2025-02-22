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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedConfigs = prefs.getString('prosthetic_configs');

      setState(() {
        if (savedConfigs != null) {
          _configs = ProstheticConfig.decode(savedConfigs);
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading configurations: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Error loading configurations');
    }
  }

  Future<void> _deleteConfig(ProstheticConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _configs.removeWhere((c) => c.id == config.id);
      });
      await prefs.setString(
          'prosthetic_configs', ProstheticConfig.encode(_configs));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuration deleted'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _undoDelete(config),
          ),
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Error deleting configuration');
    }
  }

  Future<void> _undoDelete(ProstheticConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _configs.add(config);
        _configs.sort((a, b) => b.id.compareTo(a.id)); // Sort by newest first
      });
      await prefs.setString(
          'prosthetic_configs', ProstheticConfig.encode(_configs));
    } catch (e) {
      _showErrorSnackBar('Error restoring configuration');
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.save_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No saved configurations',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Create your first prosthetic configuration',
            style: TextStyle(color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: 240, // Fixed width for better button sizing
            child: ElevatedButton.icon(
              onPressed: () => _navigateToCustomize(),
              icon: Icon(Icons.add),
              label: Text('Create New Configuration'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _configs.length,
      itemBuilder: (context, index) {
        final config = _configs[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: InkWell(
            onTap: () => _navigateToCustomize(config: config),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: config.color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configuration ${index + 1}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              config.material,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline),
                        onPressed: () => _showDeleteConfirmation(config),
                        color: Colors.red[400],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Divider(height: 1),
                  SizedBox(height: 16),
                  _buildSpecificationRow(
                    'Length',
                    '${config.length.toStringAsFixed(1)} cm',
                    Icons.straighten,
                  ),
                  _buildSpecificationRow(
                    'Width',
                    '${config.width.toStringAsFixed(1)} cm',
                    Icons.width_normal,
                  ),
                  _buildSpecificationRow(
                    'Top Circumference',
                    '${config.circumferenceTop.toStringAsFixed(1)} cm',
                    Icons.radio_button_unchecked,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecificationRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(ProstheticConfig config) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Configuration'),
          content: Text('Are you sure you want to delete this configuration?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteConfig(config);
              },
              child: Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToCustomize({ProstheticConfig? config}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomizeProstheticScreen(config: config),
      ),
    ).then((_) => _loadConfigs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Configurations'),
        actions: [
          if (_configs.isNotEmpty)
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _navigateToCustomize(),
              tooltip: 'Create new configuration',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _configs.isEmpty
              ? _buildEmptyState()
              : _buildConfigList(),
    );
  }
}
