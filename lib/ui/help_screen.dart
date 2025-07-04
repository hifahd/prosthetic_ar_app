import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Guide',
          style: AppTheme.subheadingStyle.copyWith(
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Getting Started',
              'Welcome to Prosthetic AR! This guide will help you understand how to use the app effectively.',
              Icons.rocket_launch,
            ),
            _buildSection(
              context,
              'AR Visualization',
              'View and place prosthetic models in your environment using AR:',
              Icons.view_in_ar,
              bulletPoints: [
                'Tap "Start AR" on the home screen',
                'Choose a saved configuration or create a new one',
                'Tap the AR button and scan your environment',
                'Tap to place the prosthetic model',
                'Use pinch gestures to resize and rotate the model'
              ],
            ),
            _buildSection(
              context,
              'Customizing Prosthetics',
              'Create and modify prosthetic configurations:',
              Icons.edit,
              bulletPoints: [
                'Adjust dimensions like length and width',
                'Choose materials and colors',
                'Preview changes in real-time',
                'Save configurations for later use'
              ],
            ),
            _buildSection(
              context,
              'Managing Configurations',
              'Save and organize your prosthetic designs:',
              Icons.save,
              bulletPoints: [
                'View all saved configurations',
                'Edit existing configurations',
                'Delete unwanted configurations',
                'Create new configurations from scratch'
              ],
            ),
            _buildSection(
              context,
              'Tips & Best Practices',
              'For the best experience:',
              Icons.tips_and_updates,
              bulletPoints: [
                'Ensure good lighting for AR visualization',
                'Keep your device steady while scanning',
                'Take accurate measurements for better results',
                'Save configurations for quick access'
              ],
            ),
            _buildSection(
              context,
              'Need More Help?',
              'Contact our support team or visit our website for additional assistance.',
              Icons.support_agent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String description,
    IconData icon, {
    List<String>? bulletPoints,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.subheadingStyle.copyWith(
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              description,
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.textColor,
              ),
            ),
            if (bulletPoints != null) ...[
              SizedBox(height: 16),
              ...bulletPoints.map((point) => Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 6),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            point,
                            style: AppTheme.bodyStyle.copyWith(
                              color: AppTheme.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
