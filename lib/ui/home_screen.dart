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
    final currentUser = _auth.getCurrentUser();

    // If no user is logged in, redirect to auth screen
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthScreen()),
        );
      });
      return Container(); // Return an empty container while redirecting
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Prosthetic AR'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              try {
                await _auth.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error signing out: ${e.toString()}')),
                );
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome to Prosthetic AR',
              style: Theme.of(context).textTheme.headlineMedium,
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
        foregroundColor: Colors.white,
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}