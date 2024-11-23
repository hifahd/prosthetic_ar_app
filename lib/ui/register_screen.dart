import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String error = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create an Account', style: GoogleFonts.poppins()),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email,
                        color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.roboto(),
                  validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                  onChanged: (val) => setState(() => email = val),
                ),
                SizedBox(height: 20),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon:
                        Icon(Icons.lock, color: Theme.of(context).primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  style: GoogleFonts.roboto(),
                  obscureText: true,
                  validator: (val) =>
                      val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                  onChanged: (val) => setState(() => password = val),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  child: Text('Register', style: GoogleFonts.poppins()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      dynamic result = await _auth.signUp(email, password);
                      if (result == null) {
                        setState(() =>
                            error = 'Registration failed. Please try again.');
                      } else {
                        Navigator.pop(context); // Go back to login screen
                      }
                    }
                  },
                ),
                SizedBox(height: 12),
                Text(
                  error,
                  style: GoogleFonts.roboto(color: Colors.red, fontSize: 14.0),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
