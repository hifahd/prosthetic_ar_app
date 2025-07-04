# Next-Gen Prosthetics: AR Customization and Visualization App

An Augmented Reality mobile application for prosthetic limb customization and fitting processes. This solution integrates MediaPipe-powered pose estimation with real-time AR visualization to provide clinical-grade measurement accuracy and prosthetic customization.

## Overview

This Flutter-based mobile application revolutionizes prosthetic design by combining AR technology with machine learning for precise body measurements and real-time visualization. The system achieves clinical-grade measurement accuracy within ±1.2cm and maintains stable AR rendering at 28+ FPS.

## Key Features

- Real-time AR visualization of prosthetics overlaid on user's body
- Automatic body measurement using AI-powered pose detection
- Interactive 3D prosthetic customization (dimensions, materials, colors)
- Configuration management (save, load, share settings)
- Multi-model support for various prosthetic designs
- Biometric authentication and secure data handling
- Age-adaptive scaling algorithms

## Technology Stack

**Frontend**
- Flutter 3.5.1
- Dart
- Material Design

**AR & Computer Vision**
- ARKit/ARCore
- MediaPipe
- Google ML Kit Pose Detection
- Camera API

**3D Graphics**
- Model Viewer Plus
- Flutter Cube
- Vector Math
- GLB/OBJ model support

**Backend & Cloud**
- Firebase Core
- Cloud Firestore
- Firebase Authentication
- Firebase Storage
- Real-time Database

**Security & Storage**
- Local Authentication (biometric)
- Shared Preferences
- SQLite
- End-to-end encryption

## Project Structure

```
lib/
├── ui/                          # User interface screens
├── models/                      # Data models
├── utils/                       # Utility functions
├── theme/                       # App theming
├── widgets/                     # Reusable widgets
└── main.dart                    # Application entry point

assets/
├── cyborg.glb                   # 3D model files
├── prosthetic_leg.obj
└── detailed_prosthetic_leg.obj
```
