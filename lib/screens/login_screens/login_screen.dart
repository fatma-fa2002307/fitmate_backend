import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/screens/login_screens/home_page.dart';
import 'package:fitmate/viewmodels/auth_viewmodel.dart';
import 'package:fitmate/widgets/auth_loading_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthViewModel(),
      child: Consumer<AuthViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: const Color(0xFF0e0f16),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFFFFF)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'WELCOME BACK!',
                        style: GoogleFonts.bebasNeue(
                          color: const Color(0xFFFFFFFF),
                          fontSize: 36,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              validator: (value) => viewModel.hasError ? null : null,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Color(0xFFFFFFFF)),
                              decoration: InputDecoration(
                                hintText: 'example@email.com',
                                hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                                filled: true,
                                fillColor: const Color(0xFF0D0E11),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(color: Color(0xFFB0B0B0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(color: Color(0xFFB0B0B0)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _passwordController,
                              validator: (value) => viewModel.hasError ? null : null,
                              obscureText: !viewModel.isPasswordVisible,
                              style: const TextStyle(color: Color(0xFFFFFFFF)),
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                                filled: true,
                                fillColor: const Color(0xFF0D0E11),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(color: Color(0xFFB0B0B0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: const BorderSide(color: Color(0xFFB0B0B0)),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    viewModel.isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xFFFFFFFF),
                                  ),
                                  onPressed: viewModel.togglePasswordVisibility,
                                ),
                              ),
                            ),
                            
                            // Error message if any
                            if (viewModel.hasError)
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Text(
                                  viewModel.errorMessage,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(color: Color(0xFFB0B0B0)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: viewModel.isLoading 
                                      ? null 
                                      : () async {
                                          if (_formKey.currentState?.validate() ?? false) {
                                            // Show loading overlay
                                            showDialog(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (context) => const AuthLoadingWidget(
                                                message: 'Signing in...',
                                              ),
                                            );
                                            
                                            final success = await viewModel.login(
                                              _emailController.text,
                                              _passwordController.text,
                                            );
                                            
                                            // Remove loading overlay
                                            if (mounted) {
                                              Navigator.of(context).pop();
                                            }
                                            
                                            if (success && mounted) {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => HomePage(),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD2EB50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                                    ),
                                                                          child: Text(
                                          'LOGIN',
                                          style: GoogleFonts.bebasNeue(
                                            color: const Color(0xFFFFFFFF),
                                            fontSize: 22,
                                          ),
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pushNamed(context, '/register'),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFB2C937)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 15.0),
                                    ),
                                    child: Text(
                                      'SIGN UP',
                                      style: GoogleFonts.bebasNeue(
                                        color: const Color(0xFFFFFFFF),
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}