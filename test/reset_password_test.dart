import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitmate/screens/login_screens/forgot_password_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ForgotPasswordPage Tests', () {
    testWidgets('renders ForgotPasswordPage UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));

      // Test header text
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && 
                      widget.data == 'RESET PASSWORD' && 
                      widget.style?.fontSize == 36.0
        ), 
        findsOneWidget
      );
      
      // Test input field
      expect(find.byWidgetPredicate(
        (widget) => widget is TextField &&
                    widget.decoration?.hintText == 'example@email.com'
      ), findsOneWidget);
      
      // Test instruction text
      expect(
        find.text('Please enter your email below to receive your password reset code.'),
        findsOneWidget
      );
      
      // Test button text
      expect(find.widgetWithText(ElevatedButton, 'RESET PASSWORD'), findsOneWidget);
    });

    testWidgets('shows error for empty email', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Please enter an email address'), findsOneWidget);
    });

    testWidgets('handles email input correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: ForgotPasswordPage()));

      const testEmail = 'test@example.com';
      await tester.enterText(find.byType(TextField), testEmail);
      await tester.pump();

      expect(find.text(testEmail), findsOneWidget);
    });

    testWidgets('back button navigates correctly', (WidgetTester tester) async {
      bool popCalled = false;
      
      await tester.pumpWidget(MaterialApp(
        home: ForgotPasswordPage(),
        navigatorObservers: [
          MockNavigatorObserver(onPop: () => popCalled = true),
        ],
      ));

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(popCalled, true);
    });
  });
}

// Helper for navigation testing
class MockNavigatorObserver extends NavigatorObserver {
  final Function? onPop;
  
  MockNavigatorObserver({this.onPop});

  @override
  void didPop(Route route, Route? previousRoute) {
    onPop?.call();
  }
}