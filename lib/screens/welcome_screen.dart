import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: SingleChildScrollView( // Make the body scrollable
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end, // Align buttons to the bottom
              children: [
                Image.asset(
                  'assets/data/images/fit_robot.png',
                  fit: BoxFit.cover, // Adjust the image to cover the available space
                  height: 250, // Set a fixed height for the image
                ),
                SizedBox(height: 40), // Spacer for top area
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to login screen
                      Navigator.pushNamed(context, '/login');
                    },
                    child: Text(
                      'LOGIN',
                      style: GoogleFonts.bebasNeue(
                        color: Color(0xFFFFFFFF),
                        fontSize: 22,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD2EB50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15.0),
                    ),
                  ),
                ),
                SizedBox(height: 20), // Spacer between buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to register screen
                      Navigator.pushNamed(context, '/register');
                    },
                    child: Text(
                      'GET STARTED',
                      style: GoogleFonts.bebasNeue(
                        color: Color(0xFFFFFFFF),
                        fontSize: 22,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD2EB50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15.0),
                    ),
                  ),
                ),
                SizedBox(height: 50), // Spacer for bottom area
              ],
            ),
          ),
        ),
      ),
    );
  }
}
