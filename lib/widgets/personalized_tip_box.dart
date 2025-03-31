import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/services/tip_service.dart';
import 'dart:math' as math;

/// A widget that displays a highly personalized fitness or nutrition tip
/// with a sleek, minimal design and smooth animations
class PersonalizedTipBox extends StatefulWidget {
  final Function? onRefresh;
  final double elevation;
  final bool showAnimation;

  const PersonalizedTipBox({
    Key? key,
    this.onRefresh,
    this.elevation = 2.0,
    this.showAnimation = true,
  }) : super(key: key);

  @override
  State<PersonalizedTipBox> createState() => _PersonalizedTipBoxState();
}

class _PersonalizedTipBoxState extends State<PersonalizedTipBox>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _tipData = {};
  bool _hasError = false;
  bool _isRefreshing = false;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _refreshAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations - longer duration for smoother feel
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Refresh animation for rotating icon
    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutBack,
      ),
    );

    // Subtle scale animation for icon
    _iconAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5),
      ),
    );
    
    // Fade animation for text content
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _loadTip();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Load personalized tip from service
  Future<void> _loadTip() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final tipData = await TipService.getPersonalizedTip(useCache: !_isRefreshing);
      setState(() {
        _tipData = tipData;
        _isLoading = false;
        _isRefreshing = false;
      });
      
      // Play fade-in animation when tip loads
      if (widget.showAnimation) {
        _animationController.forward(from: 0.3);
      }
    } catch (e) {
      print('Error loading tip: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }
  
  // Refresh the tip with a nice animation
  Future<void> _refreshTip() async {
    if (_isLoading || _isRefreshing) return;
    
    // Immediately show loading state and start refresh animation
    setState(() {
      _isRefreshing = true;
      _isLoading = true;
    });
    
    // Play the refresh animation
    _animationController.reset();
    _animationController.repeat();
    
    // Call parent's refresh handler if provided
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
    
    // Fetch new tip (this happens in background)
    _loadTip();
  }

  // Get the icon for the tip category
  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'nutrition':
        return Icons.restaurant;
      case 'workout':
        return Icons.fitness_center;
      case 'motivation':
        return Icons.emoji_events;
      case 'recovery':
        return Icons.self_improvement;
      case 'habit':
        return Icons.trending_up;
      case 'hydration':
        return Icons.water_drop;
      default:
        return Icons.tips_and_updates;
    }
  }

  // Get the color for the tip category
  Color _getColorForCategory(String category) {
    switch (category) {
      case 'nutrition':
        return Colors.green[400]!;
      case 'workout':
        return Colors.blue[400]!;
      case 'motivation':
        return Colors.amber[400]!;
      case 'recovery':
        return Colors.purple[300]!;
      case 'habit':
        return Colors.teal[400]!;
      case 'hydration':
        return Colors.lightBlue[400]!;
      default:
        return const Color(0xFFD2EB50); // Default FitMate color
    }
  }

  @override
  Widget build(BuildContext context) {
    // If initially loading and not refreshing, show the loading skeleton
    if (_isLoading && !_isRefreshing && _tipData.isEmpty) {
      return _buildLoadingTip();
    }

    if (_hasError) {
      return _buildErrorTip();
    }

    // Extract necessary data
    final String tip = _tipData['tip'] ?? 'Stay consistent and enjoy your fitness journey!';
    final String category = _tipData['category'] ?? 'motivation';
    final IconData iconData = _getIconForCategory(_tipData['icon'] ?? category);
    final Color categoryColor = _getColorForCategory(category);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Card(
          elevation: widget.elevation,
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: _refreshTip,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row with icon and refresh indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category icon
                      Transform.scale(
                        scale: widget.showAnimation ? _iconAnimation.value : 1.0,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              iconData,
                              color: categoryColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      
                      // Refresh button with rotation animation
                      Transform.rotate(
                        angle: _isRefreshing ? _refreshAnimation.value : 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.refresh,
                              color: _isRefreshing ? categoryColor : Colors.grey[400],
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Decorative colored line
                  Container(
                    height: 2,
                    width: 40,
                    color: categoryColor,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // If refreshing, show animated loading lines, otherwise show content
                  _isRefreshing
                      ? _buildContentSkeleton()
                      : Opacity(
                          opacity: widget.showAnimation ? _fadeAnimation.value : 1.0,
                          child: Text(
                            tip,
                            style: GoogleFonts.raleway(
                              fontSize: 16,
                              height: 1.4,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
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

  // Build skeleton content for when refresh is happening
  Widget _buildContentSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLoadingLine(width: double.infinity),
        const SizedBox(height: 10),
        _buildLoadingLine(width: double.infinity),
        const SizedBox(height: 10),
        _buildLoadingLine(width: double.infinity),
        const SizedBox(height: 10),
        _buildLoadingLine(width: MediaQuery.of(context).size.width * 0.7),
      ],
    );
  }

  // Build a shimmer loading line with animation
  Widget _buildLoadingLine({required double width}) {
    return Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey[200]!,
            Colors.grey[300]!,
            Colors.grey[200]!,
          ],
        ),
      ),
    );
  }

  // Build an enhanced loading state for the tip
  Widget _buildLoadingTip() {
    return Card(
      elevation: widget.elevation,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row with shimmer elements
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Shimmer decorative line
            Container(
              width: 40,
              height: 2,
              color: Colors.grey[300],
            ),
            
            const SizedBox(height: 16),
            
            // Shimmer text lines with varied lengths for more natural look
            _buildLoadingLine(width: double.infinity),
            const SizedBox(height: 10),
            _buildLoadingLine(width: double.infinity),
            const SizedBox(height: 10),
            _buildLoadingLine(width: double.infinity),
            const SizedBox(height: 10),
            _buildLoadingLine(width: 240),
          ],
        ),
      ),
    );
  }

  // Build a minimal error state
  Widget _buildErrorTip() {
    return Card(
      elevation: widget.elevation,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _loadTip,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.refresh,
                        color: Colors.red[300],
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Tip unavailable',
                      style: GoogleFonts.raleway(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[300],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Tap to try again',
                style: GoogleFonts.raleway(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}