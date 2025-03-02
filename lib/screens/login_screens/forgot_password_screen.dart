import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';  // Import FirebaseAuth

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Function to handle password reset
  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an email address';
      });
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      // Show success message or navigate to another page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent!')),
      );
      // Optionally navigate back to the login page
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0e0f16),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFFFFF)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            SizedBox(height: 10),
            Text(
              'RESET PASSWORD',
              style: GoogleFonts.bebasNeue(
                color: Color(0xFFFFFFFF),
                fontSize: 36,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Please enter your email below to receive your password reset code.',
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 16,
              ),
            ),
            SizedBox(height: 40),
            Text(
              'Email address',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                hintText: 'example@email.com',
                hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                filled: true,
                fillColor: Color(0xFF0D0E11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Color(0xFFB0B0B0)),
                ),
              ),
              style: TextStyle(color: Color(0xFFFFFFFF)),
            ),
            SizedBox(height: 10),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _resetPassword,
                child: Text(
                  'RESET PASSWORD',
                  style: GoogleFonts.bebasNeue(
                    color: Color(0xFFFFFFFF),
                    fontSize: 22,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFD2EB50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

