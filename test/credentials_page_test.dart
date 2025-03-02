import 'package:flutter_test/flutter_test.dart';
import 'package:fitmate/screens/register_screens/credentials.dart';  // Import the correct file

void main() {
  test('Email validation works', () {
    expect(validateEmail("test@example.com"), null);  // Valid email
    expect(validateEmail("invalidemail.com"), 'Enter a valid email address');  // Invalid email
  });

  test('Full name validation works', () {
    expect(validateFullName("John Doe"), null);  // Valid name
    expect(validateFullName(""), 'Full name is required');  // Empty name
  });

  test('Password validation works', () {
    expect(validatePassword("password123"), null);  // Valid password
    expect(validatePassword("123"), 'Password must be at least 6 characters');  // Short password
  });
}
