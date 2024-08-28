import 'package:flutter/material.dart';
import 'ui/home_screen.dart';

void main() {
  runApp(const ProstheticARApp());
}

class ProstheticARApp extends StatelessWidget {
  const ProstheticARApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prosthetic AR App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}