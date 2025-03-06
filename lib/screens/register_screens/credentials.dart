import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/screens/home_page.dart';
import 'package:fitmate/services/workout_service.dart';


class CredentialsPage extends StatefulWidget {
  final int age;
  final double weight;
  final double height;
  final String gender;
  final String selectedGoal;
  final int workoutDays;

  CredentialsPage({
    Key? key,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.selectedGoal,
    required this.workoutDays,
  }) : super(key: key);

  @override
  _CredentialsPageState createState() => _CredentialsPageState();
}

// These functions are now outside of the _CredentialsPageState class, making them public
String? validateFullName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Full name is required';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email address is required';
  } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  } else if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}

class _CredentialsPageState extends State<CredentialsPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // For toggling password visibility

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
            ),
          );
        },
      );

      String fullName = _fullNameController.text;
      String email = _emailController.text;
      String password = _passwordController.text;

      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
          'fullName': fullName,
          'email': email,
          'age': widget.age,
          'weight': widget.weight,
          'height': widget.height,
          'gender': widget.gender,
          'goal': widget.selectedGoal,
          'workoutDays': widget.workoutDays,
          'fitnessLevel': 'Beginner',
          'workoutsUntilNextLevel': 20,
          'lastWorkout': {
            'category': '',
            'date': null,
            'duration': 0,
            'completion': 0,
            'totalExercises': 0
          },
          'workoutHistory': [],
          'totalWorkouts': 0,
          'nextWorkoutCategory': '',
          'workoutsLastGenerated': null,
        });

        // Close the loading dialog
        if (mounted) {
          Navigator.pop(context);
        }

        // Generate initial workout options silently in the background
        try {
          // No dialog display - silent background process
          WorkoutService.generateAndSaveWorkoutOptions(
            age: widget.age,
            gender: widget.gender,
            height: widget.height,
            weight: widget.weight,
            goal: widget.selectedGoal,
            workoutDays: widget.workoutDays,
            fitnessLevel: 'Beginner',
            lastWorkoutCategory: null, // No previous workout
          );
        } catch (e) {
          print("Error generating initial workouts: $e");
          // Silently handle errors - no UI feedback
        }



        // Navigate to HomePage and remove all previous routes
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomePage()),
                (Route<dynamic> route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        // Close the loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        print('Firebase Auth Error: ${e.code} - ${e.message}');
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF0D0E11),
                title: Text('Registration Failed',
                    style: GoogleFonts.bebasNeue(color: const Color(0xFFD2EB50))),
                content: Text('${e.message} Try another email.',
                    style:const TextStyle(color: Colors.white)),
                actions: [
                  TextButton(
                    child: Text('OK', style: GoogleFonts.bebasNeue(color: const Color(0xFFD2EB50))),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        // Close the loading dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        print('General Error: $e');
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF0D0E11),
                title: Text('Error',
                    style: GoogleFonts.bebasNeue(color: const Color(0xFFD2EB50))),
                content: Text('An unexpected error occurred: $e',
                    style: const TextStyle(color: Color(0xFFFFFFFF))),
                actions: [
                  TextButton(
                    child: Text('OK',
                        style: GoogleFonts.bebasNeue(color: const Color(0xFFD2EB50))),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              );
            },
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
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
                        ),
                        style: const TextStyle(color: Color(0xFFFFFFFF)),
                        validator: validateFullName,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress, // Set keyboard type to email
                        decoration: InputDecoration(
                          hintText: 'example@email.com',
                          hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                          filled: true,
                          fillColor: const Color(0xFF0D0E11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFFB0B0B0)),
                          ),
                        ),
                        style: const TextStyle(color: Color(0xFFFFFFFF)),
                        validator: validateEmail,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible, // Toggle password visibility
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
                          filled: true,
                          fillColor: const Color(0xFF0D0E11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: const BorderSide(color: Color(0xFFB0B0B0)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFFFFFFFF),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
                              });
                            },
                          ),
                        ),
                        style: const TextStyle(color: Color(0xFFFFFFFF)),
                        validator: validatePassword,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD2EB50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.0),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 15.0),
                              ),
                              child: Text(
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
