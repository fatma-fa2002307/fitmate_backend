import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class SleekFoodLoading extends StatefulWidget {
  const SleekFoodLoading({Key? key}) : super(key: key);

  @override
  State<SleekFoodLoading> createState() => _SleekFoodLoadingState();
}

class _SleekFoodLoadingState extends State<SleekFoodLoading> with TickerProviderStateMixin {
  // Animation controllers
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Colors from the app's theme
  final Color primaryColor = const Color(0xFFD2EB50);
  final Color textColor = Colors.grey[700]!;

  @override
  void initState() {
    super.initState();
    
    // Progress bar animation that loops
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    
    _progressAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.95).chain(
          CurveTween(curve: Curves.easeOutQuart),
        ),
        weight: 7,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 0.2).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 3,
      ),
    ]).animate(_progressController);
    
    // Subtle fade animation for text and elements
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.6).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 1,
      ),
    ]).animate(_fadeController);
    
    // Start animations
    _progressController.repeat();
    _fadeController.repeat();
  }
  
  @override
  void dispose() {
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnimation, _fadeAnimation]),
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SizedBox(
            height: 180, // Fixed height to match food suggestion card
            child: Card(
              elevation: 2,
              margin: EdgeInsets.zero, // Remove any margin causing overflow
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Ensure column doesn't force expansion
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side - Food placeholder with animated polish
                          _buildFoodImagePlaceholder(),
                          
                          const SizedBox(width: 16),
                          
                          // Right side - Content with clean loading indicators
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title row
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 7,
                                      child: _buildPlaceholderLine(height: 20, width: null),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 3,
                                      child: _buildPlaceholderLine(height: 20, width: null, opacity: 0.7),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 12),
                                
                                // Description lines with staggered fade animation
                                Opacity(
                                  opacity: (_fadeAnimation.value * 0.3) + 0.7,
                                  child: _buildPlaceholderLine(height: 14, width: double.infinity),
                                ),
                                
                                const SizedBox(height: 8),
                                
                                Opacity(
                                  opacity: (_fadeAnimation.value * 0.4) + 0.6,
                                  child: _buildPlaceholderLine(height: 14, width: MediaQuery.of(context).size.width * 0.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Bottom section with status bar - keeping this compact
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Sleek progress indicator
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _progressAnimation.value,
                            backgroundColor: Colors.grey[100],
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                            minHeight: 3, // Thinner progress bar
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Status text - more compact
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Personalizing recommendations",
                              style: GoogleFonts.inter(
                                fontSize: 12, // Smaller font
                                fontWeight: FontWeight.w500,
                                color: textColor,
                              ),
                            ),
                            // Animated dots
                            _buildAnimatedDots(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Building placeholder lines with rounded corners
  Widget _buildPlaceholderLine({required double height, double? width, double opacity = 0.9}) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.grey[200]!.withOpacity(opacity),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
  
  // Animated food image placeholder with polish
  Widget _buildFoodImagePlaceholder() {
    return Stack(
      children: [
        Container(
          width: 70, // Smaller image
          height: 70, // Smaller image
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[100],
          ),
          child: Center(
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Icon(
                Icons.restaurant_menu,
                size: 28, // Smaller icon
                color: primaryColor.withOpacity(0.7),
              ),
            ),
          ),
        ),
        // Food category badge in top-left corner
        Positioned(
          top: 0,
          left: 0,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            width: 20, // Smaller badge
            height: 20, // Smaller badge
            child: Center(
              child: Opacity(
                opacity: _fadeAnimation.value,
                child: Icon(
                  Icons.fastfood,
                  size: 12, // Smaller icon
                  color: primaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Animated triple dots
  Widget _buildAnimatedDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        // Calculate a staggered delay for each dot
        final delay = index * 0.2;
        final adjustedValue = (_progressAnimation.value + delay) % 1.0;
        
        // Pulse effect
        final size = 3.0 + 1.0 * math.sin(adjustedValue * math.pi); // Smaller dots
        
        return Container(
          width: size,
          height: size,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: textColor.withOpacity(0.5 + (0.5 * adjustedValue)),
          ),
        );
      }),
    );
  }
}