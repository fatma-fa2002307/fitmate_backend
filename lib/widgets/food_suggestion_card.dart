import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/models/food_suggestion.dart';
import 'package:fitmate/services/food_suggestion_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FoodSuggestionCard extends StatefulWidget {
  final List<FoodSuggestion> suggestions;
  final Function? onLike;
  final Function? onDislike;
  final Function(int)? onPageChanged;
  final int initialIndex;
  final SuggestionMilestone? milestone;

  const FoodSuggestionCard({
    Key? key,
    required this.suggestions,
    this.onLike,
    this.onDislike,
    this.onPageChanged,
    this.initialIndex = 0,
    this.milestone,
  }) : super(key: key);

  @override
  State<FoodSuggestionCard> createState() => _FoodSuggestionCardState();
}

class _FoodSuggestionCardState extends State<FoodSuggestionCard> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;

  // Service to handle food suggestion interactions
  final EnhancedFoodSuggestionService _foodSuggestionService =
      EnhancedFoodSuggestionService();

  // Local state for liked/disliked status
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _isExpanded = false;
  bool _showExtraContent = false; // Flag to control when to show extra content

  // Animation controller
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Add a listener to show content after animation completes
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _isExpanded) {
        setState(() {
          _showExtraContent = true;
        });
      } else if (status == AnimationStatus.dismissed || !_isExpanded) {
        setState(() {
          _showExtraContent = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Handle liking a food suggestion
  void _handleLike() async {
    if (_isLiked) return;

    setState(() {
      _isLiked = true;
      _isDisliked = false;
    });

    // Call service to update preference
    if (widget.suggestions.isNotEmpty) {
      await _foodSuggestionService.rateSuggestion(
          widget.suggestions[_currentIndex].id, true);
    }

    // Call callback if provided
    if (widget.onLike != null) {
      widget.onLike!();
    }
  }

  /// Handle disliking a food suggestion
  void _handleDislike() async {
    if (_isDisliked) return;

    setState(() {
      _isDisliked = true;
      _isLiked = false;
    });

    // Call service to update preference
    if (widget.suggestions.isNotEmpty) {
      await _foodSuggestionService.rateSuggestion(
          widget.suggestions[_currentIndex].id, false);
    }

    // Call callback if provided
    if (widget.onDislike != null) {
      widget.onDislike!();
    }
  }

  /// Open recipe URL in browser with improved error handling
  void _openRecipeUrl() async {
    final suggestion = widget.suggestions[_currentIndex];
    launchRecipeUrl(context, suggestion.sourceUrl);
  }

  /// Helper method to launch URLs with proper error handling
  Future<void> launchRecipeUrl(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recipe URL not available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    try {
      final Uri url = Uri.parse(urlString);
      
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('Could not launch $url');
        
        try {
          await launchUrl(
            url, 
            mode: LaunchMode.platformDefault,
          );
        } catch (innerError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Could not open recipe URL'),
                  const SizedBox(height: 4),
                  Text(
                    urlString,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              action: SnackBarAction(
                label: 'Dismiss',
                onPressed: () {},
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening URL: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Handle the expand/collapse toggle
  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      
      // Important: Hide content immediately when collapsing
      if (!_isExpanded) {
        _showExtraContent = false;
      }
    });
    
    // Run the animation
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine if we're displaying suggestions for a user who's reached their calorie goal
    final isCompletedMilestone =
        widget.milestone == SuggestionMilestone.COMPLETED;

    // To improve visual consistency, use a common border radius
    const double cardRadius = 16;
    
    return Column(
      children: [
        // Food suggestion card with swipe functionality
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // Calculate height based on animation value (improved dimensions)
            final double height = 180 + (55 * _animationController.value);
            
            return SizedBox(
              height: height,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.suggestions.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                    _isLiked = false;
                    _isDisliked = false;
                    _isExpanded = false;
                    _showExtraContent = false;
                  });
                  
                  // Reset animation when changing page
                  _animationController.reset();
                  
                  if (widget.onPageChanged != null) {
                    widget.onPageChanged!(index);
                  }
                },
                itemBuilder: (context, index) {
                  final suggestion = widget.suggestions[index];
                  return _buildSuggestionCard(suggestion, isCompletedMilestone, cardRadius);
                },
              ),
            );
          }
        ),

        // Indicator dots - made more visually appealing
        if (widget.suggestions.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.suggestions.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: index == _currentIndex ? 10 : 8,
                  height: index == _currentIndex ? 10 : 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index == _currentIndex
                        ? const Color(0xFFD2EB50)
                        : Colors.grey[300],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestionCard(
      FoodSuggestion suggestion, bool isCompletedMilestone, double borderRadius) {
    // Determine if this is an ultra-low calorie option
    final bool isUltraLowCalorie = suggestion.calories <= 50;
    
    // Get appropriate food type icon
    IconData foodTypeIcon = Icons.restaurant;
    if (suggestion.isDrink) {
      foodTypeIcon = Icons.local_drink;
    } else if (suggestion.isIngredient) {
      foodTypeIcon = Icons.eco;
    } else if (suggestion.isRecipe) {
      foodTypeIcon = Icons.menu_book;
    }

    return Card(
      elevation: 1, // Reduced elevation for a more modern look
      clipBehavior: Clip.antiAlias, // Ensures any overflow is clipped neatly
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: isCompletedMilestone && isUltraLowCalorie
            ? BorderSide(color: Colors.green[300]!, width: 1.0)
            : BorderSide(color: Colors.grey[200]!, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with image and basic info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food type badge and image
                Stack(
                  children: [
                    // Food image
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          suggestion.image,
                          width: 75,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 75,
                              height: 75,
                              color: Colors.grey[200],
                              child: Icon(
                                foodTypeIcon,
                                size: 28,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Food type badge
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: suggestion.isDrink
                              ? Colors.blue[700]
                              : suggestion.isIngredient
                                  ? Colors.green[700]
                                  : Colors.orange[700],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(10),
                            bottomRight: Radius.circular(10),
                          ),
                        ),
                        child: Icon(
                          foodTypeIcon,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 14),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with recipe tag
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              suggestion.title,
                              style: GoogleFonts.raleway(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Recipe badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              suggestion.displayType,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // LLaMA-generated explanation
                      // Only display the full text when expanded, otherwise limit it
                      Text(
                        suggestion.explanation ?? "A balanced nutritional option.",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                          height: 1.3,
                        ),
                        maxLines: _isExpanded ? 3 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Thin Divider with proper spacing
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(
                color: Colors.grey[200],
                height: 1,
              ),
            ),

            // Bottom section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Calories
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: suggestion.calories <= 50
                          ? Colors.green[600]
                          : Colors.orange[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${suggestion.calories} cal',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: suggestion.calories <= 50
                            ? Colors.green[600]
                            : Colors.black87,
                      ),
                    ),
                  ],
                ),

                // Macros summary
                Text(
                  '${suggestion.protein.toStringAsFixed(1)}p · ${suggestion.carbs.toStringAsFixed(1)}c · ${suggestion.fat.toStringAsFixed(1)}f',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),

                // Button row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle details button
                    InkWell(
                      onTap: _toggleExpand,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey[500],
                          size: 22,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Like button
                    InkWell(
                      onTap: _handleLike,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: _isLiked
                              ? const Color(0xFFD2EB50)
                              : Colors.grey[500],
                          size: 22,
                        ),
                      ),
                    ),

                    const SizedBox(width: 4),

                    // Dislike button
                    InkWell(
                      onTap: _handleDislike,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          _isDisliked
                              ? Icons.thumb_down
                              : Icons.thumb_down_outlined,
                          color:
                              _isDisliked ? Colors.red[400] : Colors.grey[500],
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Show the extra content in a cleaner, more polished design
            if (_showExtraContent) ...[
              // Extra details section with more modern styling
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Ready in
                    _buildDetailItemEnhanced(
                      Icons.timer_outlined,
                      '${suggestion.readyInMinutes ?? "--"} min',
                      'Ready in'
                    ),
                    
                    // Vertical divider
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey[200],
                    ),
                    
                    // Servings
                    _buildDetailItemEnhanced(
                      Icons.room_service_outlined,
                      '${suggestion.servings ?? "--"}',
                      'Servings'
                    ),
                    
                    // Vertical divider
                    Container(
                      height: 30,
                      width: 1,
                      color: Colors.grey[200],
                    ),
                    
                    // View Recipe button if URL is available
                    if (suggestion.sourceUrl != null &&
                        suggestion.sourceUrl!.isNotEmpty)
                      TextButton.icon(
                        onPressed: _openRecipeUrl,
                        icon: const Icon(Icons.open_in_new, size: 14),
                        label: Text(
                          'View Recipe',
                          style: GoogleFonts.inter(fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFD2EB50),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItemEnhanced(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}