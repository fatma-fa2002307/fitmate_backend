import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:fitmate/config/provider_setup.dart';
import 'package:fitmate/screens/login_screens/login_screen.dart';
import 'package:fitmate/screens/login_screens/forgot_password_screen.dart';
import 'package:fitmate/screens/welcome_screen.dart';
import 'package:fitmate/screens/register_screens/age_question.dart';
import 'package:fitmate/screens/home_page.dart';

void main() async {
  // Ensure widgets are initialized before Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run the app with MultiProvider
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'FitMate',
        home: WelcomePage(),
        routes: {
          '/login': (context) => LoginPage(),
          '/forgot-password': (context) => ForgotPasswordPage(),
          '/register': (context) => AgeQuestionPage(age: 0),
          '/home': (context) => HomePage(),
        },
      ),
    );
  }
}