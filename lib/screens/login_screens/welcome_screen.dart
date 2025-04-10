import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/viewmodels/welcome_viewmodel.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with TickerProviderStateMixin {
  late AnimationController _contentController;
  late Animation<double> _fadeAnimation;
  late AnimationController _catController;
  late WelcomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();

    // Get the ViewModel
    _viewModel = context.read<WelcomeViewModel>();

    // Main content animation controller (fade only, no slide)
    _contentController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1200)
    );

    _catController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500)
    );

    // Fade animation for buttons only
    _fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0
    ).animate(CurvedAnimation(
        parent: _contentController,
        curve: Interval(0.3, 1.0, curve: Curves.easeOutCubic)
    ));

    // Initialize the view model's animations, which will trigger our animations
    _viewModel.initAnimations();

    // Listen for animation changes from the ViewModel
    _setupAnimationListeners();
  }

  void _setupAnimationListeners() {
    // Listen for content animation changes
    _viewModel.addListener(() {
      if (_viewModel.showContentAnimation && _contentController.status != AnimationStatus.forward) {
        _contentController.forward();
      }

      if (_viewModel.showCatAnimation && _catController.status != AnimationStatus.forward) {
        _catController.forward();
      }
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    _catController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // FitMate theme colors
    final primaryColor = Color(0xFFD2EB50);
    final secondaryColor = Color(0xFF333333);
    final backgroundColor = Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(flex: 1),

            // Main content area - exact same structure as splash screen
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title - static position, no animation
                    Column(
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

                    SizedBox(height: 60),

                    // Buttons fade in but no sliding
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              child: Text(
                                'LOG IN',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryColor,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: primaryColor, width: 2),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'GET STARTED',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              flex: 3,
              child: Transform.scale(
                scale: 1.6,
                child: Lottie.asset(
                  'assets/data/lottie/6.json',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}