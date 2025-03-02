// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:fitmate/screens/user_details.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fitmate/screens/edit_profile.dart';
// // import 'package:fitmate/screens/edit_profile.dart';

// class LoginPage extends StatefulWidget {
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();

//   // Default currentIndex and onTap
//   int currentIndex = 0;
//   void onTap(int index) {
//     setState(() {
//       currentIndex = index;
//     });
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   Future<void> _loginUser() async {
//   if (_formKey.currentState?.validate() ?? false) {
//     try {
//       // Sign in with email and password
//       UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//       );

//       // If successful, navigate to EditProfilePage
//       User? user = userCredential.user;
//       if (user != null) {
//         // Fetch additional user details from Firestore
//         var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
//         var userData = userDoc.data();

//         if (userData != null) {
//           Navigator.pushReplacement(
//             context,
//             MaterialPageRoute(
//               builder: (context) => EditProfilePage(), // Navigate to EditProfilePage
//             ),
//           );
//         }
//       }
//     } on FirebaseAuthException catch (e) {
//       // Handle login errors
//       showDialog(
//         context: context,
//         builder: (BuildContext context) {
//           return AlertDialog(
//             backgroundColor: Color(0xFF0D0E11),
//             title: Text('Login Failed', style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50))),
//             content: Text(e.message ?? 'An error occurred. Please try again.', style: TextStyle(color: Color(0xFFFFFFFF))),
//             actions: [
//               TextButton(
//                 child: Text('OK', style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50))),
//                 onPressed: () {
//                   Navigator.pop(context); // Close the dialog
//                 },
//               ),
//             ],
//           );
//         },
//       );
//     }
//   }
// }


//   // Future<void> _loginUser() async {
//   //   if (_formKey.currentState?.validate() ?? false) {
//   //     try {
//   //       // Sign in with email and password
//   //       UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
//   //         email: _emailController.text.trim(),
//   //         password: _passwordController.text.trim(),
//   //       );

//   //       // If successful, navigate to UserDetailsScreen
//   //       User? user = userCredential.user;
//   //       if (user != null) {
//   //         // Fetch additional user details from Firestore
//   //         var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
//   //         var userData = userDoc.data();

//   //         if (userData != null) {
//   //           Navigator.pushReplacement(
//   //             context,
//   //             MaterialPageRoute(
//   //               builder: (context) => UserDetailsScreen(
//   //                 fullName: userData['fullName'],
//   //                 email: userData['email'],
//   //                 age: userData['age'],
//   //                 weight: userData['weight'],
//   //                 height: userData['height'],
//   //                 gender: userData['gender'],
//   //                 selectedGoal: userData['goal'],
//   //                 workoutDays: userData['workoutDays'],
//   //                 currentIndex: currentIndex, // Pass currentIndex
//   //                 onTap: onTap, // Pass onTap
//   //               ),
//   //             ),
//   //           );
//   //         }
//   //       }
//   //     } on FirebaseAuthException catch (e) {
//   //       // Handle login errors
//   //       showDialog(
//   //         context: context,
//   //         builder: (BuildContext context) {
//   //           return AlertDialog(
//   //             backgroundColor: Color(0xFF0D0E11),
//   //             title: Text('Login Failed', style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50))),
//   //             content: Text(e.message ?? 'An error occurred. Please try again.', style: TextStyle(color: Color(0xFFFFFFFF))),
//   //             actions: [
//   //               TextButton(
//   //                 child: Text('OK', style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50))),
//   //                 onPressed: () {
//   //                   Navigator.pop(context); // Close the dialog
//   //                 },
//   //               ),
//   //             ],
//   //           );
//   //         },
//   //       );
//   //     }
//   //   }
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF0e0f16),
//       body: Center(
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               IconButton(
//                 icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFFFFF)),
//                 onPressed: () {
//                   Navigator.pop(context); // Navigate back to the previous page
//                 },
//               ),
//               SizedBox(height: 10),
//               Text(
//                 'WELCOME BACK!',
//                 style: GoogleFonts.bebasNeue(
//                   color: Color(0xFFFFFFFF),
//                   fontSize: 36,
//                 ),
//               ),
//               SizedBox(height: 40),
//               Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     TextFormField(
//                       controller: _emailController,
//                       decoration: InputDecoration(
//                         hintText: 'example@email.com',
//                         hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
//                         filled: true,
//                         fillColor: Color(0xFF0D0E11),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                           borderSide: BorderSide(color: Color(0xFFB0B0B0)),
//                         ),
//                       ),
//                       style: TextStyle(color: Color(0xFFFFFFFF)),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Email address is required';
//                         } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
//                           return 'Enter a valid email address';
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(height: 20),
//                     TextFormField(
//                       controller: _passwordController,
//                       obscureText: true,
//                       decoration: InputDecoration(
//                         hintText: 'Password',
//                         hintStyle: TextStyle(color: Color(0xFFB0B0B0)),
//                         filled: true,
//                         fillColor: Color(0xFF0D0E11),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(10.0),
//                           borderSide: BorderSide(color: Color(0xFFB0B0B0)),
//                         ),
//                         suffixIcon: Icon(Icons.visibility, color: Color(0xFFFFFFFF)),
//                       ),
//                       style: TextStyle(color: Color(0xFFFFFFFF)),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Password is required';
//                         } else if (value.length < 6) {
//                           return 'Password must be at least 6 characters';
//                         }
//                         return null;
//                       },
//                     ),
//                     SizedBox(height: 10),
//                     Align(
//                       alignment: Alignment.centerRight,
//                       child: TextButton(
//                         onPressed: () {
//                           Navigator.pushNamed(context, '/forgot-password'); // Add Forgot Password functionality
//                         },
//                         child: Text(
//                           'Forgot Password?',
//                           style: TextStyle(color: Color(0xFFB0B0B0)),
//                         ),
//                       ),
//                     ),
//                     SizedBox(height: 20),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: ElevatedButton(
//                             onPressed: _loginUser,
//                             child: Text(
//                               'LOGIN',
//                               style: GoogleFonts.bebasNeue(
//                                 color: Color(0xFFFFFFFF),
//                                 fontSize: 22,
//                               ),
//                             ),
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Color(0xFFD2EB50),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(5.0),
//                               ),
//                               padding: EdgeInsets.symmetric(vertical: 15.0),
//                             ),
//                           ),
//                         ),
//                         SizedBox(width: 10),
//                         Expanded(
//                           child: OutlinedButton(
//                             onPressed: () {
//                               // Redirect to the first page of the registration process (age question)
//                               Navigator.pushNamed(context, '/register');
//                             },
//                             child: Text(
//                               'SIGN UP',
//                               style: GoogleFonts.bebasNeue(
//                                 color: Color(0xFFFFFFFF),
//                                 fontSize: 22,
//                               ),
//                             ),
//                             style: OutlinedButton.styleFrom(
//                               side: BorderSide(color: Color(0xFFB2C937)),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(5.0),
//                               ),
//                               padding: EdgeInsets.symmetric(vertical: 15.0),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// lib/screens/login_screens/login_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/utils/login_validation.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login method
  Future<void> _loginUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        User? user = userCredential.user;
        if (user != null && mounted) {
          // Fetch user data from Firestore
          var userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          
          if (userDoc.exists && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>  HomePage(),
              ),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF0D0E11),
                title: Text(
                  'Login Failed',
                  style: GoogleFonts.bebasNeue(color: const Color(0xFFD2EB50)),
                ),
                content: Text(
                  e.message ?? 'An error occurred. Please try again.',
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'OK',
                      style: GoogleFonts.bebasNeue(color: const Color(0xFFD2EB50)),
                    ),
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
                        validator: LoginValidation.validateEmail,
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
                        validator: LoginValidation.validatePassword,
                        obscureText: !_isPasswordVisible,
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
                              _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFFFFFFFF),
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
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
                              onPressed: _loginUser,
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
  }
}
