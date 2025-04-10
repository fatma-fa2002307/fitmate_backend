import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/screens/login_screens/welcome_screen.dart';
import 'package:fitmate/screens/login_screens/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  // FitMate theme colors (matching welcome screen)
  final primaryColor = const Color(0xFFD2EB50);
  final secondaryColor = const Color(0xFF333333);
  final backgroundColor = const Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();

    // Create animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Animation duration
    );

    // Create fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isLoading = false;
        });
        _checkAuthAndNavigate();
      }
    });

    // Start the animation after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    // Get current auth state
    final User? user = FirebaseAuth.instance.currentUser;

    // Navigate to appropriate screen
    if (!mounted) return;

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const WelcomePage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(flex: 1),

            // Main content area - exactly matching WelcomePage
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title exactly positioned
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Text(
                            "FitMate",
                            style: GoogleFonts.montserrat(
                              color: secondaryColor,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          // Adding the subtitle - same as welcome page
                          Text(
                            "Your personal fitness companion",
                            style: GoogleFonts.poppins(
                              color: secondaryColor.withOpacity(0.7),
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Exact same spacing as welcome screen
                    SizedBox(height: 60),

                    // Invisible buttons to maintain spacing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Invisible LOG IN button (same size as welcome page)
                        SizedBox(
                          width: double.infinity,
                          height: 56, // Same height as ElevatedButton with padding
                          child: Opacity(
                            opacity: 0,
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text('LOG IN'),
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        // Invisible GET STARTED button (same size as welcome page)
                        SizedBox(
                          width: double.infinity,
                          height: 56, // Same height as ElevatedButton with padding
                          child: Opacity(
                            opacity: 0,
                            child: ElevatedButton(
                              onPressed: null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Text('GET STARTED'),
                            ),
                          ),
                        ),

                        SizedBox(height: 24),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Animation section - positioned exactly like welcome page
            Expanded(
              flex: 3,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Cat animation in exact same position
                  Transform.scale(
                    scale: 1.6,
                    child: Lottie.asset(
                      'assets/data/lottie/6.json',
                      animate: false, // Static frame in splash
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Loading text appears at bottom without affecting layout
                  Positioned(
                    bottom: 40,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        "Loading your fitness journey...",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: secondaryColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}