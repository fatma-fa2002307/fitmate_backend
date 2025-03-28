// integration_test/login_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitmate/screens/login_screens/login_screen.dart';
import 'package:fitmate/screens/login_screens/edit_profile.dart';
import 'package:fitmate/screens/login_screens/forgot_password_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Flow Tests', () {
    testWidgets('Successful login with valid credentials', (WidgetTester tester) async {
      // Step 1: Load login page
      await tester.pumpWidget(MaterialApp(home: LoginPage()));
      await tester.pumpAndSettle();

      // Verify login form is displayed
      expect(find.text('WELCOME BACK!'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));

      // Step 2: Enter valid email
      await tester.enterText(
        find.widgetWithText(TextFormField, 'example@email.com'),
        'alt23032@gmail.com'
      );

      // Step 3: Enter valid password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'validPassword123'
      );

      // Step 4: Click login
      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle();
    });

    testWidgets('Password field starts with visibility off', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Initial state should show visibility icon (meaning password is hidden)
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });

    testWidgets('Failed login with invalid email', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Enter invalid credentials
      await tester.enterText(
        find.widgetWithText(TextFormField, 'example@email.com'),
        'wrong@email.com'
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'validPassword123'
      );

      // Try to login
      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle();

      // Verify error dialog appears
      expect(find.text('Login Failed'), findsOneWidget);
    });

    testWidgets('Navigation to forgot password works', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: LoginPage(),
        routes: {
          '/forgot-password': (context) => ForgotPasswordPage(),
        },
      ));

      // Click forgot password
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      // Verify navigation
      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('Form validation works', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Try to login without entering anything
      await tester.tap(find.widgetWithText(ElevatedButton, 'LOGIN'));
      await tester.pumpAndSettle();

      // Verify validation messages
      expect(find.text('Email address is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('Password visibility toggle works', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: LoginPage()));

      // Check initial state
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);

      // Tap visibility toggle
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pumpAndSettle();

      // Check toggled state
      expect(find.byIcon(Icons.visibility), findsNothing);
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
}