import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

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
    return SizedBox(
      width: 300,
      height: 400,
      child: Cube(
        onSceneCreated: (Scene scene) {
          scene.world.add(Object(
            fileName: modelPath,
            scale: vector.Vector3(width / 10, length / 50, width / 10),
            position: vector.Vector3(0, 0, 0),
          ));
          scene.camera.zoom = 10;
          scene.camera.position.z = 15;
          scene.light.position.setFrom(vector.Vector3(0, 10, 10));
        },
      ),
    );
  }
}
