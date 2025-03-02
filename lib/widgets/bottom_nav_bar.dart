import 'package:fitmate/screens/workout_screens/workout_page.dart';
import 'package:flutter/material.dart';
import 'package:fitmate/screens/home_page.dart';
import 'package:fitmate/screens/edit_profile.dart';
import 'package:fitmate/screens/nutrition_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
          );
        } else if (index == 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => WorkoutPage()),
          );
        }else if (index == 2) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NutritionPage()),
          );
        }else if (index == 3) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => EditProfilePage()),
          );
        }
        onTap(index); // Call the onTap function to update the selected index
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Workouts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: 'Macros',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      selectedItemColor: Color(0xFFD2EB50),
      unselectedItemColor: Colors.grey,
      backgroundColor: Color(0xFF0e0f16),
    );
  }
}
