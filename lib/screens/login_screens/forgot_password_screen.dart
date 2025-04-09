// lib/screens/login_screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/viewmodels/auth_viewmodel.dart';
import 'package:fitmate/widgets/auth_loading_widget.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: Consumer<AuthViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: Color(0xFF0e0f16),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
              child: Form(
                key: _formKey,
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
                    TextFormField(
                      controller: _emailController,
                      validator: (value) => viewModel.hasError ? null : null,
                      keyboardType: TextInputType.emailAddress,
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
                    
                    // Error message
                    if (viewModel.hasError)
                      Text(
                        viewModel.errorMessage,
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    
                    // Success message
                    if (!viewModel.hasError && viewModel.isLoading == false && _emailController.text.isNotEmpty)
                      Text(
                        'Password reset email sent! Check your inbox.',
                        style: TextStyle(color: Colors.green, fontSize: 16),
                      ),
                      
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                // Show loading overlay
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const AuthLoadingWidget(
                                    message: 'Sending password reset email...',
                                  ),
                                );
                                
                                final success = await viewModel.resetPassword(_emailController.text);
                                
                                // Remove loading overlay
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                                
                                if (success && mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Password reset email sent!')),
                                  );
                                  
                                  // Wait a moment before navigating back
                                  Future.delayed(Duration(seconds: 2), () {
                                    if (mounted) {
                                      Navigator.pop(context);
                                    }
                                  });
                                }
                              }
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD2EB50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                        ),
                        child: Text(
                          'RESET PASSWORD',
                          style: GoogleFonts.bebasNeue(
                            color: Color(0xFFFFFFFF),
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}