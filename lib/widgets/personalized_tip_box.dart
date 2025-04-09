import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/viewmodels/tip_viewmodel.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

/// A widget that displays a highly personalized fitness or nutrition tip
/// with a premium, modern design and fluid animations
class PersonalizedTipBox extends StatefulWidget {
  final Function? onRefresh;
  final double elevation;
  final bool showAnimation;

  const PersonalizedTipBox({
    Key? key,
    this.onRefresh,
    this.elevation = 3.0,
    this.showAnimation = true,
  }) : super(key: key);

  @override
  State<PersonalizedTipBox> createState() => _PersonalizedTipBoxState();
}

class _PersonalizedTipBoxState extends State<PersonalizedTipBox>
    with SingleTickerProviderStateMixin {
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _refreshAnimation;
  late Animation<double> _iconAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Setup animations - longer duration for smoother feel
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Refresh animation for rotating icon
    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Enhanced scale animation for icon with bounce effect
    _iconAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.2).chain(
          CurveTween(curve: Curves.easeOutBack),
        ),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(
          CurveTween(curve: Curves.elasticOut),
        ),
        weight: 60,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6),
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

    // Slide animation for text content
    _slideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    // Initialize tip data through the ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<TipViewModel>(context, listen: false);
      
      // Only load if there's no existing tip data
      if (viewModel.tipData.isEmpty) {
        viewModel.init().then((_) {
          // Play animation when tip is loaded
          if (mounted && viewModel.tipData.isNotEmpty && widget.showAnimation) {
            _animationController.forward();
          }
        });
      } else if (widget.showAnimation) {
        // If data is already loaded, just play the animation
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Refresh the tip with a nice animation
  Future<void> _refreshTip() async {
    final viewModel = Provider.of<TipViewModel>(context, listen: false);
    
    if (viewModel.isLoading || viewModel.isRefreshing) return;

    // Haptic feedback for better user experience
    HapticFeedback.lightImpact();

    // Play the refresh animation
    _animationController.reset();
    _animationController.repeat();

    // Call parent's refresh handler if provided
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }

    // Refresh tip using the ViewModel
    await viewModel.refreshTip();
    
    // Play content animation when new tip is loaded
    if (widget.showAnimation && mounted) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TipViewModel>(
      builder: (context, viewModel, child) {
        // If initially loading and not refreshing show the loading skeleton
        if (viewModel.isLoading && !viewModel.isRefreshing && viewModel.tipData.isEmpty) {
          return _buildLoadingTip();
        }

        if (viewModel.hasError) {
          return _buildErrorTip(viewModel);
        }

        // Extract necessary data from the ViewModel
        final String tip = viewModel.tipText;
        final String category = viewModel.category;
        final IconData iconData = viewModel.getIconData(viewModel.iconName);
        final List<Color> categoryGradient = viewModel.getGradientColors(category);
        final String categoryTitle = viewModel.categoryTitle;

        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: categoryGradient[1].withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Card(
                  elevation: widget.elevation,
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: _refreshTip,
                    borderRadius: BorderRadius.circular(16),
                    splashColor: categoryGradient[0].withOpacity(0.1),
                    highlightColor: categoryGradient[0].withOpacity(0.05),
                    child: Container(
                      padding: const EdgeInsets.all(18.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          stops: const [0.0, 1.0],
                          colors: [
                            Colors.white,
                            categoryGradient[0].withOpacity(0.08),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row with icon, category, and refresh indicator
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Category icon and title
                              Row(
                                children: [
                                  // Category icon with gradient
                                  Transform.scale(
                                    scale: widget.showAnimation ? _iconAnimation.value : 1.0,
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: categoryGradient,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: categoryGradient[1].withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Icon(
                                          iconData,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Category title
                                  const SizedBox(width: 12),
                                  Opacity(
                                    opacity: widget.showAnimation ? _fadeAnimation.value : 1.0,
                                    child: Transform.translate(
                                      offset: Offset(0, widget.showAnimation ? _slideAnimation.value : 0),
                                      child: Text(
                                        categoryTitle,
                                        style: GoogleFonts.bebasNeue(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: categoryGradient[1],
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Refresh button with rotation animation
                              _buildRefreshButton(categoryGradient, viewModel.isRefreshing),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Decorative gradient line
                          Container(
                            height: 3,
                            width: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: categoryGradient,
                              ),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // If refreshing, show animated loading lines, otherwise show content
                          viewModel.isRefreshing
                              ? _buildContentSkeleton(categoryGradient)
                              : _buildTipContent(tip),

                          const SizedBox(height: 12),

                          // Custom "Did you know?" badge at the bottom
                          _buildInfoBadge(categoryGradient),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Build the refresh button with animation
  Widget _buildRefreshButton(List<Color> categoryGradient, bool isRefreshing) {
    return Transform.rotate(
      angle: isRefreshing ? _refreshAnimation.value : 0,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _refreshTip,
            child: Center(
              child: Icon(
                Icons.refresh_rounded,
                color: isRefreshing
                    ? categoryGradient[1]
                    : Colors.grey[400],
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Build the tip content with animations
  Widget _buildTipContent(String tip) {
    return Opacity(
      opacity: widget.showAnimation ? _fadeAnimation.value : 1.0,
      child: Transform.translate(
        offset: Offset(0, widget.showAnimation ? _slideAnimation.value : 0),
        child: Text(
          tip,
          style: GoogleFonts.bebasNeue(
            fontSize: 16,
            height: 1.5,
            color: Colors.black87,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // Build "Did you know?" info badge
  Widget _buildInfoBadge(List<Color> categoryGradient) {
    return Opacity(
      opacity: widget.showAnimation ? _fadeAnimation.value : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: categoryGradient[0].withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 14,
              color: categoryGradient[1],
            ),
            const SizedBox(width: 6),
            Text(
              'Did you know?',
              style: GoogleFonts.bebasNeue(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: categoryGradient[1],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build skeleton content for when refresh is happening
  Widget _buildContentSkeleton(List<Color> categoryGradient) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLoadingLine(width: double.infinity, color: categoryGradient[0]),
        const SizedBox(height: 12),
        _buildLoadingLine(width: double.infinity, color: categoryGradient[0]),
        const SizedBox(height: 12),
        _buildLoadingLine(width: double.infinity, color: categoryGradient[0]),
        const SizedBox(height: 12),
        _buildLoadingLine(width: MediaQuery.of(context).size.width * 0.7, color: categoryGradient[0]),
      ],
    );
  }
  
  // Build a shimmer loading line with animation
  Widget _buildLoadingLine({required double width, required Color color}) {
    return Container(
      width: width,
      height: 16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment(-2.0 + _loadingAnimationValue() * 3, 0),
          end: Alignment(-1.0 + _loadingAnimationValue() * 3, 0),
          colors: [
            Colors.grey[200]!,
            color.withOpacity(0.3),
            Colors.grey[200]!,
          ],
        ),
      ),
    );
  }

  // Animation value for loading shimmer effect
  double _loadingAnimationValue() {
    return (DateTime.now().millisecondsSinceEpoch % 1500) / 1500;
  }
  
  // Build an enhanced loading state for the tip
  Widget _buildLoadingTip() {
    final defaultGradient = [const Color(0xFFE1F976), const Color(0xFFCAE350)];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[300]!,
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        elevation: widget.elevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              stops: const [0.0, 1.0],
              colors: [
                Colors.white,
                Colors.grey[100]!,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row with shimmer elements
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icon placeholder
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-2.0 + _loadingAnimationValue() * 3, 0),
                            end: Alignment(-1.0 + _loadingAnimationValue() * 3, 0),
                            colors: [
                              Colors.grey[300]!,
                              Colors.grey[200]!,
                              Colors.grey[300]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),

                      // Category title placeholder
                      const SizedBox(width: 12),
                      Container(
                        width: 90,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment(-2.0 + _loadingAnimationValue() * 3, 0),
                            end: Alignment(-1.0 + _loadingAnimationValue() * 3, 0),
                            colors: [
                              Colors.grey[300]!,
                              Colors.grey[200]!,
                              Colors.grey[300]!,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ],
                  ),

                  // Refresh button placeholder
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-2.0 + _loadingAnimationValue() * 3, 0),
                        end: Alignment(-1.0 + _loadingAnimationValue() * 3, 0),
                        colors: [
                          Colors.grey[300]!,
                          Colors.grey[200]!,
                          Colors.grey[300]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Shimmer decorative line
              Container(
                width: 48,
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-2.0 + _loadingAnimationValue() * 3, 0),
                    end: Alignment(-1.0 + _loadingAnimationValue() * 3, 0),
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                      Colors.grey[300]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),

              const SizedBox(height: 16),

              // Shimmer text lines with varied lengths for more natural look
              _buildLoadingLine(width: double.infinity, color: defaultGradient[0]),
              const SizedBox(height: 12),
              _buildLoadingLine(width: double.infinity, color: defaultGradient[0]),
              const SizedBox(height: 12),
              _buildLoadingLine(width: double.infinity, color: defaultGradient[0]),
              const SizedBox(height: 12),
              _buildLoadingLine(width: MediaQuery.of(context).size.width * 0.7, color: defaultGradient[0]),

              const SizedBox(height: 12),

              // Shimmer info badge
              Container(
                width: 110,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-2.0 + _loadingAnimationValue() * 3, 0),
                    end: Alignment(-1.0 + _loadingAnimationValue() * 3, 0),
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                      Colors.grey[300]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build a premium error state
  Widget _buildErrorTip(TipViewModel viewModel) {
    final errorGradient = [const Color(0xFFFF9B9B), const Color(0xFFFF5252)];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: errorGradient[1].withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Card(
        elevation: widget.elevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: _refreshTip,
          borderRadius: BorderRadius.circular(16),
          splashColor: errorGradient[0].withOpacity(0.1),
          highlightColor: errorGradient[0].withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                stops: const [0.0, 1.0],
                colors: [
                  Colors.white,
                  errorGradient[0].withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: errorGradient,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: errorGradient[1].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tip unavailable',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: errorGradient[1],
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap anywhere to try again',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}