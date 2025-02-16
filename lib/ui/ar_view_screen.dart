import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ARViewScreen extends StatefulWidget {
  const ARViewScreen({Key? key}) : super(key: key);

  @override
  _ARViewScreenState createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR View'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ModelViewer(
              src: 'https://modelviewer.dev/shared-assets/models/Astronaut.glb',
              alt: 'A 3D test model',
              ar: true,
              autoRotate: true,
              cameraControls: true,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Tip: Click the AR button in bottom right to use camera view',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
