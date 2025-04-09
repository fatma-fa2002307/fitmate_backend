import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:fitmate/config/provider_setup.dart';
import 'package:fitmate/screens/login_screens/login_screen.dart';
import 'package:fitmate/screens/login_screens/forgot_password_screen.dart';
import 'package:fitmate/screens/login_screens/welcome_screen.dart';
import 'package:fitmate/screens/register_screens/age_question.dart';
import 'package:fitmate/screens/login_screens/home_page.dart';

void main() async {
  // Ensure widgets are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  enableOfflinePersistence();

  // Run the app with MultiProvider
  runApp(const MyApp());
}

void enableOfflinePersistence() {
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FitMate',
        home: const AuthCheck(), // Check if user is logged in
        routes: {
          '/login': (context) => const LoginPage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
          '/register': (context) => const AgeQuestionPage(),
          '/home': (context) => HomePage(),
        },
      ),
    );
  }
}
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Loading state
        }
        if (snapshot.hasData) {
          return HomePage(); // User is logged in
        } else {
          return const WelcomePage(); // User is not logged in
        }
      },
    );
  }
}