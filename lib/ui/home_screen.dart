import 'package:flutter/material.dart';
import 'customize_prosthetic_screen.dart';
import 'ar_view_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prosthetic AR App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ARViewScreen()),
                );
              },
              child: const Text('Start AR Session'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomizeProstheticScreen()),
                );
              },
              child: const Text('Customize Prosthetic'),
            ),
          ],
        ),
      ),
    );
  }
}