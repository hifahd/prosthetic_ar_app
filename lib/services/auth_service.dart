import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign up with email and password
  Future<User?> signUp(String email, String password) async {
    try {
      print("Doing the signup");
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      print(result.runtimeType);
      print("Made it to here");
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign up: ${e.code} - ${e.message}');
      return null;
    } catch (error) {
      print('Error during sign up: $error');
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      return null;
    } catch (error) {
      print('Error during sign in: $error');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
