import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'ui/login_screen.dart';
import 'ui/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  bool _initializing = true;
  bool _shouldShowAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      final bool isLoggedIn = await _authService.isLoggedIn();
      
      if (!isLoggedIn) {
        setState(() {
          _shouldShowAuth = true;
          _initializing = false;
        });
        return;
      }

      // User is logged in, check and prompt biometrics immediately
      final bool canUseBiometrics = await _authService.isBiometricsAvailable();
      if (canUseBiometrics) {
        // Show biometric prompt immediately
        final bool isAuthenticated = await _authService.authenticateWithBiometrics();
        if (isAuthenticated) {
          if (!mounted) return;
          setState(() {
            _shouldShowAuth = false;
            _initializing = false;
          });
          return;
        }
      }

      // If biometrics failed or not available, show login screen
      if (!mounted) return;
      setState(() {
        _shouldShowAuth = true;
        _initializing = false;
      });
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      if (!mounted) return;
      setState(() {
        _shouldShowAuth = true;
        _initializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prosthetic AR App',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: _initializing
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : _shouldShowAuth
              ? const LoginScreen()
              : const HomeScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
