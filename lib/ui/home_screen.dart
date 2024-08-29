import 'package:flutter/material.dart';
import 'ar_view_screen.dart';
import 'customize_prosthetic_screen.dart';
import 'saved_configs_screen.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prosthetic AR App'),
        actions: <Widget>[
          TextButton.icon(
            icon: Icon(Icons.person),
            label: Text('Logout'),
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
              );
            },
          )
        ],
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SavedConfigsScreen()),
                );
              },
              child: const Text('Saved Configurations'),
            ),
          ],
        ),
      ),
    );
  }
}