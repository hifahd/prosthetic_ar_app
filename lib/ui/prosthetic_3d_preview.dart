import 'package:flutter/material.dart';
import 'package:flutter_cube/flutter_cube.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

class Prosthetic3DPreview extends StatelessWidget {
  final double length;
  final double width;
  final Color color;

  const Prosthetic3DPreview({
    Key? key,
    required this.length,
    required this.width,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 300,
      child: Cube(
        onSceneCreated: (Scene scene) {
          scene.world.add(Object(
            fileName: 'assets/experiment.obj',
            scale: vector.Vector3(width / 10, length / 50, width / 10),
            position: vector.Vector3(0, 0, 0),
            rotation: vector.Vector3(0, 0, 0),
            lighting: true,
          ));
          scene.camera.zoom = 10;
          scene.camera.position.z = 15;
          scene.light.position.setFrom(vector.Vector3(0, 10, 10));
          scene.world.rotation.setValues(0, 90, 0);
          
          // Apply color to the object
          if (scene.world.children.isNotEmpty) {
            Object obj = scene.world.children.first;
            if (obj.mesh.material != null) {
              vector.Vector3 colorVector = vector.Vector3(
                color.red / 255,
                color.green / 255,
                color.blue / 255
              );
              obj.mesh.material!.ambient = colorVector;
              obj.mesh.material!.diffuse = colorVector;
            }
          }
        },
      ),
    );
  }
}