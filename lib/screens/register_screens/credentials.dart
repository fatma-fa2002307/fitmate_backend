// lib/screens/register_screens/credentials.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/viewmodels/onboarding_viewmodel.dart';
import 'package:fitmate/viewmodels/registration_viewmodel.dart';
import 'package:fitmate/screens/login_screens/home_page.dart';
import 'package:fitmate/screens/hidden/easter_egg.dart';

class CredentialsPage extends StatelessWidget {
  final OnboardingViewModel viewModel;

  const CredentialsPage({
    Key? key,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegistrationViewModel(),
      child: ChangeNotifierProvider.value(
        value: viewModel,
        child: _CredentialsPageContent(),
      ),
    );
  }
}

class _CredentialsPageContent extends StatefulWidget {
  @override
  _CredentialsPageContentState createState() => _CredentialsPageContentState();
}

class _CredentialsPageContentState extends State<_CredentialsPageContent> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    } else if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<OnboardingViewModel, RegistrationViewModel>(
      builder: (context, onboardingViewModel, registrationViewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0e0f16),
          body: SingleChildScrollView(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFFFFF)),
                      onPressed: () {
                        Navigator.pop(context); // Navigate back to the previous page
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'CREATE YOUR ACCOUNT',
                      style: GoogleFonts.bebasNeue(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 36,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Please enter your credentials to proceed',
                      style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 16),
                    ),
                    const SizedBox(height: 40),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              hintText: 'John Doe',
                              hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                              filled: true,
                              fillColor: const Color(0xFF0D0E11),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(color: Color(0xFFB0B0B0)),
                              ),
                              labelText: 'Full Name',
                              labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                            ),
                            style: const TextStyle(color: Color(0xFFFFFFFF)),
                            validator: _validateFullName,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'example@email.com',
                              hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                              filled: true,
                              fillColor: const Color(0xFF0D0E11),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(color: Color(0xFFB0B0B0)),
                              ),
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                            ),
                            style: const TextStyle(color: Color(0xFFFFFFFF)),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !registrationViewModel.isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                              filled: true,
                              fillColor: const Color(0xFF0D0E11),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: const BorderSide(color: Color(0xFFB0B0B0)),
                              ),
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  registrationViewModel.isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFFFFFFFF),
                                ),
                                onPressed: () {
                                  registrationViewModel.togglePasswordVisibility();
                                },
                              ),
                            ),
                            style: const TextStyle(color: Color(0xFFFFFFFF)),
                            validator: _validatePassword,
                          ),
                          
                          // Show error message if any
                          if (registrationViewModel.hasError)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Text(
                                registrationViewModel.errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: registrationViewModel.isLoading 
                                ? null 
                                : () async {
                                    if (_formKey.currentState!.validate()) {
                                      // First, set the user data from onboarding viewModel in the registration viewModel
                                      registrationViewModel.setAge(onboardingViewModel.age);
                                      registrationViewModel.setWeight(onboardingViewModel.weight);
                                      registrationViewModel.setHeight(onboardingViewModel.height);
                                      registrationViewModel.setGender(onboardingViewModel.gender);
                                      registrationViewModel.setGoal(onboardingViewModel.goal);
                                      registrationViewModel.setWorkoutDays(onboardingViewModel.workoutDays);
                                      
                                      // Trigger registration with user data
                                      final success = await registrationViewModel.registerUser(
                                        fullName: _fullNameController.text,
                                        email: _emailController.text,
                                        password: _passwordController.text,
                                      );
                                      
                                      if (success && mounted) {
                                        //trigger the Easter egg
                                        if (registrationViewModel.shouldShowEasterEgg()) {
                                          Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(builder: (context) => const EasterEggPage()),
                                            (Route<dynamic> route) => false,
                                          );
                                        } else {
                                          Navigator.of(context).pushAndRemoveUntil(
                                            MaterialPageRoute(builder: (context) => HomePage()),
                                            (Route<dynamic> route) => false,
                                          );
                                        }
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
                              child: registrationViewModel.isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'READY!',
                                    style: GoogleFonts.bebasNeue(
                                      color: Colors.black,
                                      fontSize: 22,
                                    ),
                                  ),
                            ),
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
    );
  }
}