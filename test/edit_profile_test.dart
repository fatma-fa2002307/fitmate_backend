// import 'package:flutter_test/flutter_test.dart';
// import 'package:fitmate/screens/login_screens/edit_profile.dart';
//
// void main() {
//   test('Full Name validation works', () {
//     expect(validateFullName("John Doe"), null); // Valid name
//     expect(validateFullName(""), 'Full name is required'); // Empty name
//   });
//
//   test('Weight validation works', () {
//     expect(validateWeight("70"), null); // Valid weight
//     expect(validateWeight(""), 'Weight is required'); // Empty weight
//     expect(validateWeight("abc"), 'Please enter a valid number'); // Non-numeric
//     expect(validateWeight("0"), 'Weight must be greater than 0'); // Zero weight
//   });
//
//   test('Height validation works', () {
//     expect(validateHeight("175"), null); // Valid height
//     expect(validateHeight(""), 'Height is required'); // Empty height
//     expect(validateHeight("abc"), 'Please enter a valid number'); // Non-numeric
//     expect(validateHeight("0"), 'Height must be greater than 0'); // Zero height
//   });
//
//   test('Age validation works', () {
//     expect(validateAge("25"), null); // Valid age
//     expect(validateAge(""), 'Age is required'); // Empty age
//     expect(validateAge("abc"), 'Please enter a valid number'); // Non-numeric
//     expect(validateAge("0"), 'Age must be greater than 0'); // Zero age
//     expect(validateAge("150"), 'Please enter a reasonable age'); // Unreasonable age
//   });
// }