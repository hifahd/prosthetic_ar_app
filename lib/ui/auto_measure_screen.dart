import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import '../models/prosthetic_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camera_overlay.dart';
import 'measurement_overlay.dart';

class AutoMeasureScreen extends StatefulWidget {
  const AutoMeasureScreen({Key? key}) : super(key: key);

  @override
  _AutoMeasureScreenState createState() => _AutoMeasureScreenState();
}

class _AutoMeasureScreenState extends State<AutoMeasureScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _status = '';
  File? _imageFile;
  Map<String, dynamic>? _measurements;
  final ImagePicker _picker = ImagePicker();
  bool _showGuide = true;
  bool _showOverlay = true;
  bool _showMeasurements = true;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Size? _imageSize;

  // Update this to your computer's IP address and port
  final String backendUrl = 'http://192.168.98.208:8000/analyze/image';

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _getImageSize(File image) async {
    final decodedImage = await decodeImageFromList(await image.readAsBytes());
    setState(() {
      _imageSize =
          Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
    });
  }

  Future<void> _takePicture() async {
    setState(() => _showOverlay = false);
    await Future.delayed(Duration(milliseconds: 100));

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
      imageQuality: 95,
      preferredCameraDevice: CameraDevice.front,
    );

    setState(() => _showOverlay = true);

    if (photo != null) {
      final imageFile = File(photo.path);
      await _getImageSize(imageFile);

      setState(() {
        _imageFile = imageFile;
        _status = 'Analyzing image...';
        _isLoading = true;
        _showMeasurements = true;
      });

      await _analyzePicture();
    }
  }

  Future<void> _analyzePicture() async {
    try {
      if (_imageFile == null) return;

      // Show analysis progress dialog
      setState(() {
        _status = 'Sending image for analysis...';
      });

      var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      request.files
          .add(await http.MultipartFile.fromPath('file', _imageFile!.path));

      setState(() {
        _status = 'Processing image...';
      });

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var result = json.decode(responseData);

      setState(() {
        _measurements = result;
        _isLoading = false;
        _status = 'Analysis complete';
      });

      // Check if the server returned a message to display
      if (result.containsKey('message')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: result['success'] == true ? Colors.green : Colors.orange,
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      if (result['success'] == false) {
        // Notify user but don't show results dialog if analysis failed
        return;
      }

      if (result['missing_limbs'] != null && result['missing_limbs'].isNotEmpty) {
        _showMeasurementResults(result['missing_limbs'][0]);
      } else {
        _showNoLimbsDetectedDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _status = 'Error: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection error. Make sure the server is running.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _analyzePicture,
            textColor: Colors.white,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildAnalyzedImage() {
    if (_imageFile == null || _imageSize == null) return Container();

    return Stack(
      children: [
        Image.file(_imageFile!),
        if (_showMeasurements &&
            _measurements != null &&
            _measurements!['missing_limbs'].isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: MeasurementOverlay(
                measurements: _measurements!['missing_limbs'][0],
                imageSize: _imageSize!,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildConfidenceIndicator(double confidence) {
    Color indicatorColor = confidence > 0.7
        ? Colors.green
        : confidence > 0.5
            ? Colors.orange
            : Colors.red;
            
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detection Confidence',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: confidence,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
        SizedBox(height: 2),
        Text(
          '${(confidence * 100).toStringAsFixed(1)}%',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showNoLimbsDetectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('No Prosthetic Needs Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('The system did not detect any specific prosthetic needs. This could be because:'),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• The full body wasn\'t clearly visible in the image'),
                  Text('• There were no significant asymmetries detected'),
                  Text('• The person doesn\'t need prosthetic support'),
                  Text('• The image quality or lighting was insufficient'),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text('Would you like to try again with a different image or pose?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _imageFile = null;
                _showOverlay = true;
              });
            },
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionReasonsList(List<dynamic> reasons) {
    if (reasons == null || reasons.isEmpty) {
      return Text("No specific detection criteria met - showing for demonstration");
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detection criteria:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 6),
        ...reasons.map((reason) => Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  reason.toString(),
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  void _showMeasurementResults(Map<String, dynamic> measurements) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Measurement Results',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _showMeasurements
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () => setState(
                              () => _showMeasurements = !_showMeasurements),
                          tooltip:
                              '${_showMeasurements ? 'Hide' : 'Show'} measurements',
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(16),
                  children: [
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.accessibility_new,
                                    color: Theme.of(context).primaryColor),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Detected ${measurements['limb_type'].toString().replaceAll('_', ' ')}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      SizedBox(height: 8),
                                      _buildConfidenceIndicator(
                                          measurements['confidence'] ?? 0.5),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 24),
                            
                            // Detection reasons (if available)
                            if (measurements.containsKey('detection_reasons'))
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDetectionReasonsList(measurements['detection_reasons']),
                                  SizedBox(height: 16),
                                ],
                              ),
                              
                            _buildMeasurementRow(
                              'Length',
                              '${measurements['recommended_size']['length'].toStringAsFixed(1)} cm',
                              Icons.height,
                            ),
                            _buildMeasurementRow(
                              'Width',
                              '${measurements['recommended_size']['width'].toStringAsFixed(1)} cm',
                              Icons.width_normal,
                            ),
                            _buildMeasurementRow(
                              'Circumference',
                              '${measurements['recommended_size']['circumference'].toStringAsFixed(1)} cm',
                              Icons.radio_button_unchecked,
                            ),
                            
                            // Asymmetry data if available
                            if (measurements.containsKey('asymmetry_data') && 
                                measurements['asymmetry_data'] != null) ...[
                              Divider(height: 24),
                              Text(
                                'Asymmetry Analysis',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildMeasurementRow(
                                'Hip-Knee Asymmetry',
                                '${(measurements['asymmetry_data']['hip_knee_asymmetry'] * 100).toStringAsFixed(1)}%',
                                Icons.compare_arrows,
                              ),
                              _buildMeasurementRow(
                                'Knee-Ankle Asymmetry',
                                '${(measurements['asymmetry_data']['knee_ankle_asymmetry'] * 100).toStringAsFixed(1)}%',
                                Icons.compare_arrows,
                              ),
                            ],
                            
                            if (measurements['distances'] != null) ...[
                              Divider(height: 24),
                              Text(
                                'Measured Distances',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                              SizedBox(height: 8),
                              ...List.generate(
                                measurements['distances'].length,
                                (index) => _buildMeasurementRow(
                                  'Distance ${index + 1}',
                                  '${measurements['distances'][index].toStringAsFixed(1)} cm',
                                  Icons.straighten,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _createConfiguration(measurements),
                      icon: Icon(Icons.add),
                      label: Text('Create Configuration'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _imageFile = null;
                          _showOverlay = true;
                        });
                      },
                      icon: Icon(Icons.camera_alt),
                      label: Text('Take Another Picture'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createConfiguration(Map<String, dynamic> measurements) async {
    try {
      final config = ProstheticConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        length: measurements['recommended_size']['length'] ?? 50.0,
        width: measurements['recommended_size']['width'] ?? 10.0,
        circumferenceTop: measurements['recommended_size']['circumference'] ?? 30.0,
        circumferenceBottom: (measurements['recommended_size']['circumference'] ?? 30.0) * 0.8,
        kneeFlexion: 0.0, // Default value since it's not measured
        color: Colors.grey[600]!,
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
      await prefs.setString('prosthetic_configs', ProstheticConfig.encode(configs));

      Navigator.of(context).pop(); // Close bottom sheet
      Navigator.of(context).pop(); // Return to previous screen

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Configuration created successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

  Widget _buildGuide() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How to Take the Picture',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.accessibility_new),
                title: Text('Align with Guide'),
                subtitle: Text('Match your position to the outline'),
              ),
              ListTile(
                leading: Icon(Icons.wb_sunny),
                title: Text('Good Lighting'),
                subtitle: Text('Ensure the area is well lit'),
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text('Clear View'),
                subtitle: Text('Keep arms slightly away from body'),
              ),
              ListTile(
                leading: Icon(Icons.contrast),
                title: Text('Background'),
                subtitle: Text('Use a plain, contrasting background'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => setState(() => _showGuide = false),
                child: Text('Got it'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Auto Measurements'),
        actions: [
          if (!_showGuide)
            IconButton(
              icon: Icon(Icons.help_outline),
              onPressed: () => setState(() => _showGuide = true),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Main Content
          _showGuide
              ? Center(child: _buildGuide())
              : Stack(
                  children: [
                    Center(
                      child: _imageFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Take a picture to start measurements',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            )
                          : _buildAnalyzedImage(),
                    ),
                    if (_showOverlay && _imageFile == null)
                      IgnorePointer(
                        child: CustomPaint(
                          painter: CameraOverlay(),
                          size: Size(
                            MediaQuery.of(context).size.width,
                            MediaQuery.of(context).size.height,
                          ),
                        ),
                      ),
                  ],
                ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      _status,
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: !_showGuide
          ? FloatingActionButton.extended(
              onPressed: _takePicture,
              icon: Icon(Icons.camera_alt),
              label: Text('Take Picture'),
            )
          : null,
    );
  }
}