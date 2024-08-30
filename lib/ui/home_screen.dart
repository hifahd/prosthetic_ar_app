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
        title: Text('Prosthetic AR'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
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
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome to Prosthetic AR',
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            _buildMenuButton(
              context,
              'Start AR Session',
              Icons.camera,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => ARViewScreen())),
            ),
            SizedBox(height: 20),
            _buildMenuButton(
              context,
              'Customize Prosthetic',
              Icons.edit,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => CustomizeProstheticScreen())),
            ),
            SizedBox(height: 20),
            _buildMenuButton(
              context,
              'Saved Configurations',
              Icons.save,
              () => Navigator.push(context, MaterialPageRoute(builder: (context) => SavedConfigsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(title),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}