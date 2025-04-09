import 'package:fitmate/screens/workout_screens/workout_page.dart';
import 'package:flutter/material.dart';
import 'package:fitmate/screens/login_screens/home_page.dart';
import 'package:fitmate/screens/login_screens/edit_profile.dart';
import 'package:fitmate/screens/nutrition_screens/nutrition_screen.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Handle back button press
      onWillPop: () async {
        // If not on home screen, navigate to home screen
        if (currentIndex != 0) {
          // Clear the navigation stack and push the home page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomePage()),
                (route) => false,
          );
          onTap(0); // Update the selected index to home
          return false; // Prevent default back button behavior
        }
        // If already on home screen, allow normal back button behavior
        return true;
      },
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          // Only navigate if selecting a different tab
          if (index != currentIndex) {
            Widget targetPage;

            switch (index) {
              case 0:
                targetPage = HomePage();
                break;
              case 1:
                targetPage = WorkoutPage();
                break;
              case 2:
                targetPage = NutritionPage();
                break;
              case 3:
                targetPage = EditProfilePage();
                break;
              default:
                targetPage = HomePage();
            }

            // Clear navigation stack and push the new screen
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => targetPage),
                  (route) => false,
            );
          }

          onTap(index); // Update the selected index
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
      ),
    );
  }
}