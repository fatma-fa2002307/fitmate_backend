import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/screens/home_page.dart';

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

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // void _submitForm() async {
  //   if (_formKey.currentState?.validate() ?? false) {
  //     String fullName = _fullNameController.text;
  //     String email = _emailController.text;
  //     String password = _passwordController.text;

  //     try {
  //       // Create user with Firebase Authentication
  //       UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  //         email: email,
  //         password: password,
  //       );

  //       // Save additional user data to Firestore
  //       await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
  //         'fullName': fullName,
  //         'email': email,
  //         'age': widget.age,
  //         'weight': widget.weight,
  //         'height': widget.height,
  //         'gender': widget.gender,
  //         'goal': widget.selectedGoal,
  //         'workoutDays': widget.workoutDays,
  //       });

  //       // Navigate to EditProfilePage after successful registration
  //       if (mounted) {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => EditProfilePage(), // Changed to EditProfilePage
  //           ),
  //         );
  //       }
  //     } on FirebaseAuthException catch (e) {
  //       if (mounted) {
  //         showDialog(
  //           context: context,
  //           builder: (BuildContext context) {
  //             return AlertDialog(
  //               backgroundColor: Color(0xFF0D0E11),
  //               title: Text('Registration Failed', 
  //                    style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50))),
  //               content: Text(e.message ?? 'An error occurred. Please try again.',
  //                    style: TextStyle(color: Color(0xFFFFFFFF))),
  //               actions: [
  //                 TextButton(
  //                   child: Text('OK', 
  //                        style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50))),
  //                   onPressed: () => Navigator.pop(context),
  //                 ),
  //               ],
  //             );
  //           },
  //         );
  //       }
  //     }
  //   }
  // }

void _submitForm() async {
  if (_formKey.currentState?.validate() ?? false) {
    String fullName = _fullNameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    try {
      // Create user with Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user data to Firestore with new fields
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
        'fullName': fullName,
        'email': email,
        'age': widget.age,
        'weight': widget.weight,
        'height': widget.height,
        'gender': widget.gender,
        'goal': widget.selectedGoal,
        'workoutDays': widget.workoutDays,
        //-------- fields for workout tracking --------
        'fitnessLevel': 'Beginner',
        'WorkoutsUntilNextLevel': 20,
        'lastWorkout': {
          'category': '',
          'date': null,
          'duration': 0,
          'completion': 0,
          'totalExercises': 0
        },
        'lastWorkout': {
          'category': '',
          'date': null,
          'duration': 0,
          'completion': 0,
          'totalExercises': 0
        },
        'workoutHistory': [], // Empty array for workout history
        'totalWorkouts': 0,
        'nextWorkoutCategory': 'Legs' // Default starting category
      });

      // Navigate to HomePage after successful registration
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xFF0D0E11),
              title: Text('Registration Failed', 
                   style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50))),
              content: Text('Error Code: ${e.code}\n${e.message}',
                   style: TextStyle(color: Color(0xFFFFFFFF))),
              actions: [
                TextButton(
                  child: Text('OK', 
                       style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50))),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('General Error: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Color(0xFF0D0E11),
              title: Text('Error', 
                   style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50))),
              content: Text('An unexpected error occurred: $e',
                   style: TextStyle(color: Color(0xFFFFFFFF))),
              actions: [
                TextButton(
                  child: Text('OK', 
                       style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50))),
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
      backgroundColor: Color(0xFF0e0f16),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFFFFF)),
                  onPressed: () {
                    Navigator.pop(context); // Navigate back to the previous page
                  },
                ),
                SizedBox(height: 10),
                Text(
                  'CREATE YOUR ACCOUNT',
                  style: GoogleFonts.bebasNeue(
                    color: Color(0xFFFFFFFF),
                    fontSize: 36,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Please enter your credentials to proceed',
                  style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 16),
                ),
                SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          hintText: 'John Doe',
                          hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                          filled: true,
                          fillColor: Color(0xFF0D0E11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Color(0xFFB0B0B0)),
                          ),
                        ),
                        style: TextStyle(color: Color(0xFFFFFFFF)),
                        validator: validateFullName,
                      ),
                      SizedBox(height: 20),
                      TextFormField(
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
                        validator: validateEmail,
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
                          filled: true,
                          fillColor: Color(0xFF0D0E11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide(color: Color(0xFFB0B0B0)),
                          ),
                          suffixIcon: Icon(Icons.visibility, color: Color(0xFFFFFFFF)),
                        ),
                        style: TextStyle(color: Color(0xFFFFFFFF)),
                        validator: validatePassword,
                      ),
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              child: Text(
                                'READY!',
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

