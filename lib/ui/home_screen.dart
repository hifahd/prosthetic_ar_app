import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'ar_view_screen.dart';
import 'customize_prosthetic_screen.dart';
import 'saved_configs_screen.dart';
import 'help_screen.dart';
import 'auto_measure_screen.dart'; // Added import for Auto Measure
import 'auth_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Prosthetic AR'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
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
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome to Prosthetic AR',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                ),
                SizedBox(height: 8),
                Text(
                  'Choose an option to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                SizedBox(height: 24),

                // Main Options Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85, // Adjusted for better fit
                  children: [
                    _buildOptionCard(
                      context,
                      'Start AR',
                      Icons.view_in_ar,
                      'Visualize prosthetics in AR',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ARViewScreen()),
                      ),
                    ),
                    _buildOptionCard(
                      context,
                      'Customize',
                      Icons.edit,
                      'Design and modify prosthetics',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CustomizeProstheticScreen()),
                      ),
                    ),
                    _buildOptionCard(
                      context,
                      'Saved Designs',
                      Icons.save,
                      'View saved configurations',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SavedConfigsScreen()),
                      ),
                    ),
                    _buildOptionCard(
                      context,
                      'Auto Measure',
                      Icons.straighten,
                      'AI-powered automatic measurements',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AutoMeasureScreen()),
                      ),
                    ),
                    _buildOptionCard(
                      context,
                      'Help',
                      Icons.help_outline,
                      'View tutorial and guides',
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => HelpScreen()),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                // Recent Activity Section
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    leading: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    title: Text('No recent activity'),
                    subtitle: Text('Your recent actions will appear here'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    IconData icon,
    String description,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
