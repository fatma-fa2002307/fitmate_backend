import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

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
      color: const Color(0xFF0e0f16).withOpacity(0.92),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: ModernSpinnerWithText(
          message: message,
          color: primaryColor,
        ),
      ),
    );
  }
}

class ModernSpinnerWithText extends StatefulWidget {
  final String message;
  final Color color;
  
  const ModernSpinnerWithText({
    Key? key,
    required this.message,
    required this.color,
  }) : super(key: key);
  
  @override
  State<ModernSpinnerWithText> createState() => _ModernSpinnerWithTextState();
}

class _ModernSpinnerWithTextState extends State<ModernSpinnerWithText> 
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  
  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }
  
  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 60,
          child: AnimatedBuilder(
            animation: _rotationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationController.value * 2 * math.pi,
                child: CustomPaint(
                  painter: _GradientSpinnerPainter(color: widget.color),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 24),
        
        SizedBox(
          width: 220,
          child: _TypewriterText(
            text: widget.message,
            textStyle: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              letterSpacing: 0.5,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _GradientSpinnerPainter extends CustomPainter {
  final Color color;

  _GradientSpinnerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final gradient = SweepGradient(
      colors: [
        color.withOpacity(1),
        color.withOpacity(0.3),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
      transform: GradientRotation(-math.pi / 2),
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Add the TypewriterText classes here
class _TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle textStyle;
  
  const _TypewriterText({
    Key? key,
    required this.text,
    required this.textStyle,
  }) : super(key: key);
  
  @override
  State<_TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<_TypewriterText> 
    with SingleTickerProviderStateMixin {
  String _displayedText = '';
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.text.length * 80),
    );
    
    _controller.addListener(() {
      final textLength = (widget.text.length * _controller.value).round();
      setState(() {
        _displayedText = widget.text.substring(0, textLength);
      });
    });
    
    _controller.forward();
  }
  
  @override
  void didUpdateWidget(_TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.duration = Duration(milliseconds: widget.text.length * 80);
      _controller.reset();
      _controller.forward();
    }
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText,
      style: widget.textStyle,
      textAlign: TextAlign.center,
    );
  }
}