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
      width: 300,
      height: 400,
      child: Cube(
        onSceneCreated: (Scene scene) {
          scene.world.add(Object(
            fileName: 'assets/detailed_prosthetic_leg.obj',
            scale: vector.Vector3(width / 10, length / 70, width / 10),
            position: vector.Vector3(0, -0.5, 0),
            rotation: vector.Vector3(0, 0, 0),
            lighting: true,
          ));
          scene.camera.zoom = 8;
          scene.camera.position.setValues(8, 5, 8);
          scene.camera.target.setValues(0, 2, 0);
          scene.light.setPosition(5, 5, 5);
          scene.light.setColor(Colors.white);
          scene.world.rotation.setValues(-20, 30, 0);
          
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
              obj.mesh.material!.specular = vector.Vector3(1, 1, 1);
              obj.mesh.material!.shininess = 50;
            }
          }
        },
      ),
    );
  }
}