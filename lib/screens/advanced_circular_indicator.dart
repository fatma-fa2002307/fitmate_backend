import 'package:flutter/material.dart';
import 'dart:math' as math;

class AdvancedCircularProgressIndicator extends StatefulWidget {
  final double progress;
  final double radius;
  final double lineWidth;
  final Color progressColor;
  final Color backgroundColor;
  final Widget? center;
  final bool animate;
  final Duration animationDuration;
  final bool allowOverflow;

  const AdvancedCircularProgressIndicator({
    Key? key,
    required this.progress,
    required this.radius,
    this.lineWidth = 10.0,
    required this.progressColor,
    required this.backgroundColor,
    this.center,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 1200),
    this.allowOverflow = true,
  }) : super(key: key);

  @override
  State<AdvancedCircularProgressIndicator> createState() => _AdvancedCircularProgressIndicatorState();
}

class _AdvancedCircularProgressIndicatorState extends State<AdvancedCircularProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late double _targetProgress;
  late double _startProgress;

  @override
  void initState() {
    super.initState();
    _targetProgress = widget.progress;
    _startProgress = 0.0;
    
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    _progressAnimation = Tween<double>(
      begin: _startProgress,
      end: _targetProgress,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    if (widget.animate) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AdvancedCircularProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.progress != widget.progress) {
      _startProgress = _progressAnimation.value;
      _targetProgress = widget.progress;
      
      _progressAnimation = Tween<double>(
        begin: _startProgress,
        end: _targetProgress,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      
      if (widget.animate) {
        _animationController.reset();
        _animationController.forward();
      } else {
        _animationController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.radius * 2, widget.radius * 2),
          painter: CircularProgressPainter(
            progress: _progressAnimation.value,
            progressColor: widget.progressColor,
            backgroundColor: widget.backgroundColor,
            strokeWidth: widget.lineWidth,
            allowOverflow: widget.allowOverflow,
          ),
          child: Center(
            child: widget.center ?? Container(),
          ),
        );
      },
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;
  final double strokeWidth;
  final bool allowOverflow;
  final double shadowBlurRadius;

  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
    this.strokeWidth = 10.0,
    this.allowOverflow = true,
    this.shadowBlurRadius = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Determine how to draw the progress
    final effectiveProgress = allowOverflow ? progress : progress.clamp(0.0, 1.0);
    
    // Draw shadow for "tail" effect if progress > 100%
    if (allowOverflow && progress > 1.0) {
      final overflowProgress = progress - 1.0;
      final maxOverflow = 0.25; // Limit overflow to 25% extra
      final tailProgress = math.min(overflowProgress, maxOverflow);
      
      // Shadow paint for the tail
      final shadowPaint = Paint()
        ..color = progressColor.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 1.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlurRadius);
      
      // Draw the tail shadow
      canvas.drawArc(
        rect.inflate(2), // Slightly larger for shadow effect
        -math.pi / 2, // Start from top (90 degrees)
        2 * math.pi * tailProgress,
        false,
        shadowPaint,
      );
    }
    
    // Progress Arc with potential shadow effect
    if (effectiveProgress > 0) {
      // Draw shadow under the progress arc for depth
      final shadowPaint = Paint()
        ..color = progressColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlurRadius / 2);
      
      // Draw shadow slightly offset
      canvas.drawArc(
        rect.translate(1, 1),
        -math.pi / 2, // Start from top (90 degrees)
        2 * math.pi * (effectiveProgress > 1.0 ? 1.0 : effectiveProgress),
        false,
        shadowPaint,
      );
      
      // Main progress arc
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        rect,
        -math.pi / 2, // Start from top (90 degrees)
        2 * math.pi * (effectiveProgress > 1.0 ? 1.0 : effectiveProgress),
        false,
        progressPaint,
      );
    }
    
    // Additional visual indicator for overflow
    if (allowOverflow && progress > 1.0) {
      // Draw a glowing pulse at the end position
      final overflowPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
      
      // Calculate the position at the end of the circle (top)
      final endPointX = center.dx;
      final endPointY = center.dy - radius;
      
      // Draw a pulsing circle indicator
      canvas.drawCircle(
        Offset(endPointX, endPointY),
        strokeWidth / 1.5,
        overflowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.allowOverflow != allowOverflow ||
        oldDelegate.shadowBlurRadius != shadowBlurRadius;
  }
}