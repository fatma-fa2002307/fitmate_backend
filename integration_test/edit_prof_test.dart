import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitmate/screens/edit_profile.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Edit Profile Tests', () {
    testWidgets('Valid profile updates', (WidgetTester tester) async {
      // Setup initial state with pre-filled data
      await tester.pumpWidget(MaterialApp(home: EditProfilePage()));
      await tester.pumpAndSettle();

      // Step 1 & 2: Profile is displayed and fields are editable
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4)); // Name, Weight, Height, Age fields

      // Step 3: Edit full name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'), 
        'Fatima Abdulla'
      );

      // Step 4: Change weight
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Weight'), 
        '65'
      );

      // Step 5: Toggle weight unit
      await tester.tap(find.text('LBS'));
      await tester.pumpAndSettle();

      // Step 6: Change height
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Height'), 
        '172'
      );

      // Step 7: Toggle height unit
      await tester.tap(find.text('FEET'));
      await tester.pumpAndSettle();

      // Step 8: Change age
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Age'), 
        '23'
      );

      // Step 9: Save changes
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // Verify success message
      expect(find.text('Profile updated successfully!'), findsOneWidget);
    });

    testWidgets('Invalid weight validation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: EditProfilePage()));
      await tester.pumpAndSettle();

      // Step 11: Enter invalid weight
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Weight'), 
        '-50'
      );

      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Weight must be greater than 0'), findsOneWidget);
    });

    testWidgets('Invalid height validation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: EditProfilePage()));
      await tester.pumpAndSettle();

      // Step 13: Enter invalid height
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Height'), 
        '0'
      );

      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Height must be greater than 0'), findsOneWidget);
    });

    testWidgets('Invalid age validation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: EditProfilePage()));
      await tester.pumpAndSettle();

      // Step 15: Enter invalid age
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Age'), 
        '-10'
      );

      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Age must be greater than 0'), findsOneWidget);
    });

    testWidgets('Empty name validation', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: EditProfilePage()));
      await tester.pumpAndSettle();

      // Step 17: Clear name field
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name'), 
        ''
      );

      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // Verify error message
      expect(find.text('Full name is required'), findsOneWidget);
    });

    testWidgets('Unit conversion tests', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: EditProfilePage()));
      await tester.pumpAndSettle();

      // Test KG to LBS conversion
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Weight'), 
        '65'
      );
      await tester.tap(find.text('LBS'));
      await tester.pumpAndSettle();

      // Test CM to FEET conversion
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Height'), 
        '172'
      );
      await tester.tap(find.text('FEET'));
      await tester.pumpAndSettle();
    });

    testWidgets('Gender selection works', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: EditProfilePage()));
      await tester.pumpAndSettle();

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Select gender
      await tester.tap(find.text('Male').last);
      await tester.pumpAndSettle();

      // Verify selection
      expect(find.text('Male'), findsOneWidget);
    });

    testWidgets('Profile persistence after refresh', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: EditProfilePage()));
      await tester.pumpAndSettle();

      // Enter new values
      await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Fatima Abdulla');
      await tester.enterText(find.widgetWithText(TextFormField, 'Age'), '23');

      // Save changes
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      // Refresh page (rebuild widget)
      await tester.pumpWidget(MaterialApp(home: EditProfilePage()));
      await tester.pumpAndSettle();

      // Verify data persists
      expect(find.text('Fatima Abdulla'), findsOneWidget);
      expect(find.text('23'), findsOneWidget);
    });
  });
}
