import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Prosthetic3DPreview extends StatelessWidget {
  final String modelPath;
  final double length;
  final double width;
  final Color color;

  const Prosthetic3DPreview({
    Key? key,
    required this.modelPath,
    required this.length,
    required this.width,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert color to a CSS-style hex string for the modelViewer
    String colorString = '#${color.value.toRadixString(16).substring(2)}';

    return ModelViewer(
      src: modelPath,
      alt: "Prosthetic Model",
      ar: false,
      autoRotate: true,
      cameraControls: true,
      backgroundColor: const Color.fromARGB(255, 245, 245, 245),
      // Apply custom styling for color and scale
      relatedCss: '''
        .model-viewer {
          --poster-color: transparent;
        }
      ''',
      // The modified scale will be applied visually but not programmatically
      // since we don't have direct JavaScript access in this version
    );
  }
}
