import 'package:flutter/material.dart';
import 'screens/login_screens/login_screen.dart';
import 'screens/login_screens/forgot_password_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/register_screens/age_question.dart';
import 'screens/home_page.dart';
import 'services/workout_service.dart'; // Added for workout generation
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure widgets are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FitMate',
      home: WelcomePage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/forgot-password': (context) => ForgotPasswordPage(),
        '/register': (context) => AgeQuestionPage(age: 0),
        '/home': (context) => HomePage(),
      },
    );
  }
}