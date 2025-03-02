import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitmate/screens/login_screens/forgot_password_screen.dart';
import 'package:fitmate/screens/login_screens/login_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Password Reset Flow Tests', () {
    testWidgets('Initial page load and UI elements', (WidgetTester tester) async {
      // Step 1: Load forgot password page
      await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));
      await tester.pumpAndSettle();

      // Verify UI elements
      expect(find.text('RESET PASSWORD'), findsOneWidget);
      expect(find.text('Please enter your email below to receive your password reset code.'), 
             findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('RESET PASSWORD'), findsOneWidget);
    });

    testWidgets('Valid email reset process', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));
      await tester.pumpAndSettle();

      // Step 2: Enter valid email
      await tester.enterText(
        find.byType(TextField),
        'alt23032@gmail.com'
      );
      
      // Step 3: Click reset button
      await tester.tap(find.widgetWithText(ElevatedButton, 'RESET PASSWORD'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Password reset email sent!'), findsOneWidget);
    });

    testWidgets('Invalid email handling', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));
      await tester.pumpAndSettle();

      // Step 13: Enter unregistered email
      await tester.enterText(
        find.byType(TextField),
        'wrong@email.com'
      );
      
      await tester.tap(find.widgetWithText(ElevatedButton, 'RESET PASSWORD'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('An error occurred'), findsOneWidget);
    });

    testWidgets('Empty email validation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));
      await tester.pumpAndSettle();

      // Try resetting without email
      await tester.tap(find.widgetWithText(ElevatedButton, 'RESET PASSWORD'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Please enter an email address'), findsOneWidget);
    });

    testWidgets('Back navigation works', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ForgotPasswordPage(),
        routes: {
          '/login': (context) => LoginPage(),
        },
      ));
      await tester.pumpAndSettle();

      // Test back button
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      // Verify navigation (widget is removed from screen)
      expect(find.byType(ForgotPasswordPage), findsNothing);
    });

    testWidgets('Email field accessibility', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));
      await tester.pumpAndSettle();

      // Verify email field is accessible
      final emailField = find.byType(TextField);
      expect(emailField, findsOneWidget);
      
      // Test hint text
      expect(find.text('example@email.com'), findsOneWidget);
      
      // Test email input works
      await tester.enterText(emailField, 'test@example.com');
      expect(find.text('test@example.com'), findsOneWidget);
    });
  });
}
