import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _isLoggedInKey = 'isLoggedIn';
  static const String _userEmailKey = 'userEmail';
  static const String _userNameKey = 'userName';
  static const String _userPhoneKey = 'userPhone';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign up with email and password
  Future<UserCredential> signUp(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save login state and user info
      await _saveLoginState(true);
      await _saveUserInfo(email, 'Fahd Ahmad', '+923229962540');
      
      return userCredential;
    } catch (e) {
      throw Exception('Failed to sign up: ${e.toString()}');
    }
  }

  // Check if biometrics is available
  Future<bool> isBiometricsAvailable() async {
    try {
      final List<BiometricType> availableBiometrics = 
          await _localAuth.getAvailableBiometrics();
      
      return availableBiometrics.isNotEmpty &&
             await _localAuth.canCheckBiometrics &&
             await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
      return false;
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool isAvailable = await isBiometricsAvailable();
      if (!isAvailable) return false;

      // Check if user is logged in before attempting biometric auth
      final bool userIsLoggedIn = await isLoggedIn();
      if (!userIsLoggedIn) return false;

      final bool authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      if (authenticated) {
        // If authentication successful, ensure login state is saved
        await _saveLoginState(true);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error during biometric authentication: $e');
      return false;
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save login state and user info
      await _saveLoginState(true);
      await _saveUserInfo(email, 'Fahd Ahmad', '+923229962540');
      
      return userCredential;
    } catch (e) {
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      
      // Clear all stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Ensure login state is false
      await _saveLoginState(false);
    } catch (e) {
      debugPrint('Error during sign out: $e');
      rethrow;
    }
  }

  // Save login state
  Future<void> _saveLoginState(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  // Save user info
  Future<void> _saveUserInfo(String email, String name, String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userPhoneKey, phone);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Get user info
  Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'email': prefs.getString(_userEmailKey) ?? '',
      'name': prefs.getString(_userNameKey) ?? '',
      'phone': prefs.getString(_userPhoneKey) ?? '',
    };
  }
}