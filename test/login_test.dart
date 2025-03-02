import 'package:flutter_test/flutter_test.dart';
import 'package:fitmate/utils/login_validation.dart';

void main() {
  group('Login Validation Tests', () {
    group('Email Validation', () {
      test('valid email passes validation', () {
        final result = LoginValidation.validateEmail("test@example.com");
        expect(result, null);
      });

      test('empty email returns error message', () {
        final result = LoginValidation.validateEmail("");
        expect(result, 'Email address is required');
      });

      test('invalid email format returns error message', () {
        final result = LoginValidation.validateEmail("invalidemail.com");
        expect(result, 'Enter a valid email address');
      });
    });

    group('Password Validation', () {
      test('valid password passes validation', () {
        final result = LoginValidation.validatePassword("password123");
        expect(result, null);
      });

      test('empty password returns error message', () {
        final result = LoginValidation.validatePassword("");
        expect(result, 'Password is required');
      });

      test('short password returns error message', () {
        final result = LoginValidation.validatePassword("12345");
        expect(result, 'Password must be at least 6 characters');
      });
    });
  });
}