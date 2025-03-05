// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class UserDetailsScreen extends StatelessWidget {
//   final String fullName;
//   final String email;
//   final int age;
//   final double weight;
//   final double height;
//   final String gender;
//   final String selectedGoal;
//   final int workoutDays;

//   UserDetailsScreen({
//     required this.fullName,
//     required this.email,
//     required this.age,
//     required this.weight,
//     required this.height,
//     required this.gender,
//     required this.selectedGoal,
//     required this.workoutDays,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF0e0f16),
//       appBar: AppBar(
//         backgroundColor: Color(0xFF0D0E11),
//         title: Text(
//           'User Details',
//           style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50)),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Full Name: $fullName',
//               style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
//             ),
//             Text(
//               'Email: $email',
//               style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
//             ),
//             Text(
//               'Age: $age',
//               style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
//             ),
//             Text(
//               'Weight: $weight',
//               style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
//             ),
//             Text(
//               'Height: $height',
//               style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
//             ),
//             Text(
//               'Gender: $gender',
//               style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
//             ),
//             Text(
//               'Goal: $selectedGoal',
//               style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
//             ),
//             Text(
//               'Workout Days: $workoutDays',
//               style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';

class UserDetailsScreen extends StatelessWidget {
  final String fullName;
  final String email;
  final int age;
  final double weight;
  final double height;
  final String gender;
  final String selectedGoal;
  final int workoutDays;
  final int currentIndex; // To manage the selected index in the Bottom Navigation Bar
  final Function(int) onTap; // Callback function for tapping on Bottom Navigation items

  UserDetailsScreen({
    required this.fullName,
    required this.email,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.selectedGoal,
    required this.workoutDays,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0e0f16),
      appBar: AppBar(
        backgroundColor: Color(0xFF0D0E11),
        title: Text(
          'User Details',
          style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Full Name: $fullName',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Email: $email',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Age: $age',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Weight: $weight',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Height: $height',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Gender: $gender',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Goal: $selectedGoal',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Workout Days: $workoutDays',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentIndex,
        onTap: onTap,
      ),
    );
  }
}
