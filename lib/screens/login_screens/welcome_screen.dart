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
  late Animation<Offset> _titleAnimation;
  late Animation<Offset> _buttonsAnimation;
  late AnimationController _catController;
  late WelcomeViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    
    // Get the ViewModel
    _viewModel = context.read<WelcomeViewModel>();
    
    // Main content animation controller
    _contentController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1200)
    );

    // Cat animation controller (separate to control timing)
    _catController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1500)
    );

    // Title slides in from top
    _titleAnimation = Tween<Offset>(
        begin: Offset(0, -0.5),
        end: Offset.zero
    ).animate(CurvedAnimation(
        parent: _contentController,
        curve: Interval(0.0, 0.7, curve: Curves.easeOutCubic)
    ));

    // Buttons slide in from bottom
    _buttonsAnimation = Tween<Offset>(
        begin: Offset(0, 1),
        end: Offset.zero
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
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SlideTransition(
                      position: _titleAnimation,
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
                    ),

                    SizedBox(height: 60),

                    SlideTransition(
                      position: _buttonsAnimation,
                      child: Column(
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

            // Cat animation at the bottom
            FadeTransition(
              opacity: _catController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(0, 1),
                  end: Offset(0, 0),
                ).animate(_catController),
                child: Container(
                  height: 160,
                  width: double.infinity,
                  alignment: Alignment.bottomCenter,
                  child: Lottie.asset(
                    'assets/data/lottie/4.json',
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}