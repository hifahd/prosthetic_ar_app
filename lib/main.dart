import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'ui/auth_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProstheticARApp());
}

class ProstheticARApp extends StatelessWidget {
  const ProstheticARApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prosthetic AR App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: AuthScreen(),
    );
  }
}
