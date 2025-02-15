import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class ARViewScreen extends StatefulWidget {
  const ARViewScreen({Key? key}) : super(key: key);

  @override
  _ARViewScreenState createState() => _ARViewScreenState();
}

class _ARViewScreenState extends State<ARViewScreen> {
  String currentModel = 'assets/experiment.obj';
  bool isModelVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AR View'),
        actions: [
          IconButton(
            icon:
                Icon(isModelVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                isModelVisible = !isModelVisible;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isModelVisible
                ? ModelViewer(
                    backgroundColor: const Color.fromARGB(255, 245, 245, 245),
                    src: currentModel,
                    alt: 'A 3D model of a prosthetic',
                    ar: true,
                    arModes: const ['scene-viewer'],
                    autoRotate: true,
                    cameraControls: true,
                    disableZoom: false,
                  )
                : const Center(
                    child: Text('Model hidden. Tap the eye icon to show.'),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentModel = 'assets/prosthetic_leg.obj';
                    });
                  },
                  child: const Text('Basic Model'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentModel = 'assets/detailed_prosthetic_leg.obj';
                    });
                  },
                  child: const Text('Detailed Model'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentModel = 'assets/experiment.obj';
                    });
                  },
                  child: const Text('Experiment'),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Tip: Use two fingers to rotate and pinch to zoom. In AR mode, find a flat surface to place the model.',
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
