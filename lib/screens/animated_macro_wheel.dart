import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedMacroWheel extends StatefulWidget {
  final String label;
  final int current;
  final int target;
  final double percentage;
  final Color color;
  final bool animate;
  final bool allowOverflow;
  final Duration animationDuration;

  const AnimatedMacroWheel({
    Key? key,
    required this.label,
    required this.current,
    required this.target,
    required this.percentage,
    required this.color,
    this.animate = true,
    this.allowOverflow = true,
    this.animationDuration = const Duration(milliseconds: 1200),
  }) : super(key: key);

  @override
  State<AnimatedMacroWheel> createState() => _AnimatedMacroWheelState();
}

class _AnimatedMacroWheelState extends State<AnimatedMacroWheel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late double _targetPercentage;
  late double _startPercentage;
  bool _valueChanged = false;

  @override
  void initState() {
    super.initState();
    _targetPercentage = widget.percentage;
    _startPercentage = 0.0;
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    
    // Create progress animation
    _progressAnimation = Tween<double>(
      begin: _startPercentage,
      end: _targetPercentage,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // Create pulse animation for when values change
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 10,
      ),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5),
    ));
    
    if (widget.animate) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedMacroWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If percentage changed, animate to new value
    if (oldWidget.percentage != widget.percentage ||
        oldWidget.current != widget.current) {
      _startPercentage = _progressAnimation.value;
      _targetPercentage = widget.percentage;
      _valueChanged = true;
      
      _progressAnimation = Tween<double>(
        begin: _startPercentage,
        end: _targetPercentage,
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
    return Column(
      children: [
        SizedBox(
          height: 70,
          width: 70,
          child: Stack(
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _valueChanged ? _pulseAnimation.value : 1.0,
                      child: CustomPaint(
                        size: const Size(56, 56),
                        painter: MacroWheelPainter(
                          progress: _progressAnimation.value,
                          color: widget.color,
                          backgroundColor: Colors.grey[200]!,
                          allowOverflow: widget.allowOverflow,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Center(
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Animate the text value from previous to current
                    int displayValue = widget.current;
                    if (_valueChanged && _animationController.isAnimating) {
                      final currentValue = _animationController.value;
                      final oldValue = widget.current - (widget.current - widget.target * widget.percentage);
                      displayValue = (oldValue + (widget.current - oldValue) * currentValue).round();
                    }
                    
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          displayValue.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _valueChanged && _animationController.isAnimating 
                                ? widget.color
                                : Colors.black,
                          ),
                        ),
                        Text(
                          'g',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '${widget.current}/${widget.target}',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class MacroWheelPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final bool allowOverflow;
  final double strokeWidth;
  final double shadowBlurRadius;
  final Color shadowColor;

  MacroWheelPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.allowOverflow = true,
    this.strokeWidth = 6.0,
    this.shadowBlurRadius = 3.0,
    this.shadowColor = Colors.black26,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    
    // Background Circle with subtle gradient
    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          backgroundColor.withOpacity(0.7),
          backgroundColor,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Determine how to draw the progress
    final effectiveProgress = allowOverflow ? progress : progress.clamp(0.0, 1.0);
    
    // Calculate shadow offset based on progress
    final double shadowOffset = effectiveProgress > 0.5 ? 2.0 : 1.0;
    
    // Draw shadow for "tail" effect if progress > 100%
    if (allowOverflow && progress > 1.0) {
      // Calculate tail progress with dynamic effect
      final tailProgress = (progress - 1.0) * 0.6; // 60% of overflow
      
      final shadowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.6),
            color.withOpacity(0.2),
          ],
          stops: const [0.0, 1.0],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlurRadius);
      
      // Draw shadow arc with "tail" for overflow effect
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * tailProgress,
        false,
        shadowPaint,
      );
    }
    
    // Draw shadow under the progress for more depth
    if (effectiveProgress > 0) {
      final shadowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlurRadius / 2);
      
      // Draw shadow slightly offset
      canvas.drawArc(
        rect.translate(0.5, 0.5),
        -math.pi / 2,
        2 * math.pi * (effectiveProgress > 1.0 ? 1.0 : effectiveProgress),
        false,
        shadowPaint,
      );
      
      // Main progress arc with gradient for more depth
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            color.withOpacity(0.9),
            color,
          ],
          startAngle: -math.pi / 2,
          endAngle: 2 * math.pi * effectiveProgress - math.pi / 2,
        ).createShader(rect)
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
      
      // Add a subtle highlight at the progress tip
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.3
        ..strokeCap = StrokeCap.round;
      
      // Calculate the angle for the current progress
      final progressAngle = -math.pi / 2 + (2 * math.pi * (effectiveProgress > 1.0 ? 1.0 : effectiveProgress));
      
      // Calculate the position at that angle
      final tipX = center.dx + radius * math.cos(progressAngle);
      final tipY = center.dy + radius * math.sin(progressAngle);
      
      // Draw a small highlight at the tip
      final highlightRadius = strokeWidth * 0.5;
      canvas.drawCircle(
        Offset(tipX, tipY),
        highlightRadius,
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..style = PaintingStyle.fill
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.0)
      );
    }
    
    // Enhanced visual indicator for exceeding 100%
    if (allowOverflow && progress > 1.0) {
      // Calculate the pulsing effect based on sine function
      final double pulse = 1.0 + (math.sin(DateTime.now().millisecondsSinceEpoch * 0.005) + 1) * 0.2;
      
      // Glowing overflow indicator
      final overflowPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
      
      // Position at the top of the circle (start point)
      final endPointX = center.dx;
      final endPointY = center.dy - radius;
      
      // Draw the pulsing indicator
      canvas.drawCircle(
        Offset(endPointX, endPointY),
        strokeWidth * 0.6 * pulse,
        overflowPaint,
      );
      
      // Add a white highlight to make it stand out
      canvas.drawCircle(
        Offset(endPointX, endPointY),
        strokeWidth * 0.3 * pulse,
        Paint()
          ..color = Colors.white.withOpacity(0.7)
          ..style = PaintingStyle.fill
      );
    }
  }

  @override
  bool shouldRepaint(covariant MacroWheelPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.allowOverflow != allowOverflow ||
        oldDelegate.shadowBlurRadius != shadowBlurRadius ||
        oldDelegate.shadowColor != shadowColor;
  }
}