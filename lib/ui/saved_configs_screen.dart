import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prosthetic_config.dart';
import '../theme/app_theme.dart';
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
      await prefs.setString('prosthetic_configs', ProstheticConfig.encode(_configs));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Configuration deleted',
            style: AppTheme.captionStyle.copyWith(color: Colors.white),
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.all(16),
          action: SnackBarAction(
            label: 'Undo',
            textColor: Colors.white,
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
      await prefs.setString('prosthetic_configs', ProstheticConfig.encode(_configs));
    } catch (e) {
      _showErrorSnackBar('Error restoring configuration');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
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
  }

  void _navigateToCustomize({ProstheticConfig? config}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomizeProstheticScreen(
          initialConfig: config,
        ),
      ),
    ).then((_) => _loadConfigs()); // Refresh list when returning
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.save_outlined,
              size: 48,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No saved configurations',
            style: AppTheme.headingStyle.copyWith(
              fontSize: 24,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Create your first prosthetic configuration',
            style: AppTheme.captionStyle,
          ),
          SizedBox(height: 32),
          Container(
            width: 240,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.buttonShadow,
            ),
            child: ElevatedButton.icon(
              onPressed: () => _navigateToCustomize(),
              icon: Icon(Icons.add),
              label: Text(
                'Create New Configuration',
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
        return Container(
          margin: EdgeInsets.only(bottom: 16),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToCustomize(config: config),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: config.color,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: config.color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 4),
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
                                style: AppTheme.subheadingStyle.copyWith(
                                  fontSize: 18,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                config.material,
                                style: AppTheme.captionStyle,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline),
                          onPressed: () => _showDeleteConfirmation(config),
                          color: AppTheme.errorColor,
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Divider(
                      height: 1,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                    SizedBox(height: 20),
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
          ),
        );
      },
    );
  }

  Widget _buildSpecificationRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ),
          SizedBox(width: 12),
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(
              color: AppTheme.subtitleColor,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: AppTheme.bodyStyle.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Delete Configuration',
            style: AppTheme.subheadingStyle,
          ),
          content: Text(
            'Are you sure you want to delete this configuration?',
            style: AppTheme.bodyStyle,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.subtitleColor,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteConfig(config);
              },
              child: Text(
                'Delete',
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
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
          'Saved Configurations',
          style: AppTheme.subheadingStyle.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryColor,
              ),
            )
          : _configs.isEmpty
              ? _buildEmptyState()
              : _buildConfigList(),
      floatingActionButton: _configs.isNotEmpty
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.buttonShadow,
              ),
              child: FloatingActionButton(
                onPressed: () => _navigateToCustomize(),
                child: Icon(Icons.add),
                backgroundColor: AppTheme.primaryColor,
                elevation: 0,
              ),
            )
          : null,
    );
  }
}
