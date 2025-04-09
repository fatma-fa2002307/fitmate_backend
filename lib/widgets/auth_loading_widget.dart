import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthLoadingWidget extends StatelessWidget {
  final String message;
  final Color primaryColor;
  
  const AuthLoadingWidget({
    Key? key, 
    this.message = 'Please wait...',
    this.primaryColor = const Color(0xFFD2EB50),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loading animation
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      Center(
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: primaryColor.withOpacity(0.2),
                          ),
                        ),
                      ),
                      Center(
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          Icons.person,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}