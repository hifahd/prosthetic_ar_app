import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import '../models/prosthetic_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutoMeasureScreen extends StatefulWidget {
  const AutoMeasureScreen({Key? key}) : super(key: key);

  @override
  _AutoMeasureScreenState createState() => _AutoMeasureScreenState();
}

class _AutoMeasureScreenState extends State<AutoMeasureScreen> {
  bool _isLoading = false;
  String _status = '';
  File? _imageFile;
  Map<String, dynamic>? _measurements;
  final ImagePicker _picker = ImagePicker();

  // TODO: Replace with your actual backend URL
  final String backendUrl = 'http://192.168.1.6:8000/analyze/image';

  Future<void> _takePicture() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
        _status = 'Analyzing image...';
        _isLoading = true;
      });
      await _analyzePicture();
    }
  }

  Future<void> _analyzePicture() async {
    try {
      if (_imageFile == null) return;

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _imageFile!.path,
      ));

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);

      if (response.statusCode == 200 && result['missing_limbs'] != null) {
        setState(() {
          _measurements = result;
          _isLoading = false;
          _status = 'Analysis complete';
        });

        // If measurements are found, create a new configuration
        if (result['missing_limbs'].isNotEmpty) {
          _createConfiguration(result['missing_limbs'][0]);
        }
      } else {
        setState(() {
          _isLoading = false;
          _status = 'Analysis failed: No measurements found';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _createConfiguration(Map<String, dynamic> measurements) async {
    try {
      final config = ProstheticConfig(
        id: DateTime.now().toString(),
        length: measurements['recommended_size']['length'] ?? 50.0,
        width: measurements['recommended_size']['width'] ?? 10.0,
        circumferenceTop:
            measurements['recommended_size']['circumference'] ?? 30.0,
        circumferenceBottom:
            (measurements['recommended_size']['circumference'] ?? 30.0) * 0.8,
        color: Theme.of(context).primaryColor,
        material: 'Titanium',
        modelPath: 'assets/prosthetic_leg.obj',
      );

      final prefs = await SharedPreferences.getInstance();
      final String? savedConfigs = prefs.getString('prosthetic_configs');
      List<ProstheticConfig> configs = [];

      if (savedConfigs != null) {
        configs = ProstheticConfig.decode(savedConfigs);
      }

      configs.add(config);
      await prefs.setString(
          'prosthetic_configs', ProstheticConfig.encode(configs));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuration created from measurements'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate back to AR view with new configuration
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating configuration: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auto Measurements'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              child: _imageFile == null
                  ? Center(
                      child: Text(
                        'Take a picture to start automatic measurements',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.contain,
                          ),
                        ),
                        if (_measurements != null) ...[
                          SizedBox(height: 16),
                          Text(
                            'Detected Measurements:',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: 8),
                          // Display measurements
                          ...(_measurements!['missing_limbs'] as List).map(
                            (limb) => Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Missing Limb: ${limb['limb_type']}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Recommended Size:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                        'Length: ${limb['recommended_size']['length'].toStringAsFixed(1)} cm'),
                                    Text(
                                        'Width: ${limb['recommended_size']['width'].toStringAsFixed(1)} cm'),
                                    Text(
                                        'Circumference: ${limb['recommended_size']['circumference'].toStringAsFixed(1)} cm'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          if (_isLoading)
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(_status),
                ],
              ),
            ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _takePicture,
                      icon: Icon(Icons.camera_alt),
                      label: Text('Take Picture'),
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
}
