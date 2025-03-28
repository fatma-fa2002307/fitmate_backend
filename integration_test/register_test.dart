import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitmate/screens/register_screens/age_question.dart';
import 'package:fitmate/screens/register_screens/weight_question.dart';
import 'package:fitmate/screens/register_screens/height_question.dart';
import 'package:fitmate/screens/register_screens/gender_question.dart';
import 'package:fitmate/screens/register_screens/goal_question.dart';
import 'package:fitmate/screens/register_screens/credentials.dart';
import 'package:fitmate/screens/login_screens/edit_profile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Registration Flow Tests', () {
    testWidgets('Complete successful registration flow', (WidgetTester tester) async {
      // Start with age question
      await tester.pumpWidget(MaterialApp(home: AgeQuestionPage(age: 0)));
      await tester.pumpAndSettle();

      // Step 1: Age Input
      expect(find.text('HOW OLD ARE YOU?'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '27');
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // Step 2: Weight Input
      expect(find.text('WHAT IS YOUR WEIGHT?'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '70');
      await tester.tap(find.text('KG'));
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // Step 3: Height Input
      expect(find.text('WHAT IS YOUR HEIGHT?'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '175');
      await tester.tap(find.text('CM'));
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // Step 4: Gender Selection
      expect(find.text('WHAT IS YOUR GENDER?'), findsOneWidget);
      await tester.tap(find.text('Male'));
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // Step 5: Goal Selection
      expect(find.text('WHAT IS YOUR GOAL?'), findsOneWidget);
      await tester.tap(find.text('Improve fitness'));
      await tester.tap(find.text('NEXT'));
      await tester.pumpAndSettle();

      // Final Registration Form
      expect(find.text('CREATE YOUR ACCOUNT'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextFormField, 'John Doe'), 'Rashid Ali');
      await tester.enterText(find.widgetWithText(TextFormField, 'example@email.com'), 'alt23032@gmail.com');
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'StrongPass123!');
      await tester.tap(find.text('READY!'));
      await tester.pumpAndSettle();

      // Verify navigation to EditProfilePage
      expect(find.byType(EditProfilePage), findsOneWidget);
    });

    // testWidgets('Duplicate email registration attempt', (WidgetTester tester) async {
    //   // Navigate to final registration page with pre-filled data
    //   await tester.pumpWidget(MaterialApp(
    //     home: CredentialsPage(
    //       age: 27,
    //       weight: 70,
    //       height: 175,
    //       gender: 'Male',
    //       selectedGoal: 'Improve fitness',
    //       workoutDays: 5,
    //     ),
    //   ));
    //
    //   // Try registering with existing email
    //   await tester.enterText(find.widgetWithText(TextFormField, 'John Doe'), 'Test User');
    //   await tester.enterText(find.widgetWithText(TextFormField, 'example@email.com'), 'alt23032@gmail.com');
    //   await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'ValidPass123!');
    //   await tester.tap(find.text('READY!'));
    //   await tester.pumpAndSettle();
    //
    //   // Verify error dialog
    //   expect(find.text('Registration Failed'), findsOneWidget);
    //   expect(find.textContaining('email already exists'), findsOneWidget);
    // });

    testWidgets('Invalid email format validation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CredentialsPage(
          age: 27,
          weight: 70,
          height: 175,
          gender: 'Male',
          selectedGoal: 'Improve fitness',
          workoutDays: 5,
        ),
      ));

      // Enter invalid email
      await tester.enterText(find.widgetWithText(TextFormField, 'example@email.com'), 'alt23032@gmail');
      await tester.tap(find.text('READY!'));
      await tester.pumpAndSettle();

      // Verify validation message
      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('Weak password validation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: CredentialsPage(
          age: 27,
          weight: 70,
          height: 175,
          gender: 'Male',
          selectedGoal: 'Improve fitness',
          workoutDays: 5,
        ),
      ));

      // Enter weak password
      await tester.enterText(find.widgetWithText(TextFormField, 'Password'), '123');
      await tester.tap(find.text('READY!'));
      await tester.pumpAndSettle();

      // Verify validation message
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });
  });
}
