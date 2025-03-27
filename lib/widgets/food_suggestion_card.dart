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

class _FoodSuggestionCardState extends State<FoodSuggestionCard> {
  late PageController _pageController;
  int _currentIndex = 0;

  // Service to handle food suggestion interactions
  final EnhancedFoodSuggestionService _foodSuggestionService =
      EnhancedFoodSuggestionService();

  // Local state for liked/disliked status
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
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

  /// Open recipe URL in browser
  void _openRecipeUrl() async {
    final suggestion = widget.suggestions[_currentIndex];
    if (suggestion.sourceUrl != null && suggestion.sourceUrl!.isNotEmpty) {
      try {
        final url = Uri.parse(suggestion.sourceUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        print('Could not launch URL: $e');
      }
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

    return Column(
      children: [
        // Milestone header
        if (widget.milestone != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Icon(
                  _getMilestoneIcon(widget.milestone!),
                  size: 16,
                  color: _getMilestoneColor(widget.milestone!),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.milestone!.displayName,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _getMilestoneColor(widget.milestone!),
                  ),
                ),
              ],
            ),
          ),

        // Food suggestion card with swipe functionality
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isExpanded ? 230 : 160, // Increased height for expanded view
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.suggestions.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _isLiked = false;
                _isDisliked = false;
                _isExpanded = false;
              });
              if (widget.onPageChanged != null) {
                widget.onPageChanged!(index);
              }
            },
            itemBuilder: (context, index) {
              final suggestion = widget.suggestions[index];
              return _buildSuggestionCard(suggestion, isCompletedMilestone);
            },
          ),
        ),

        // Indicator dots
        if (widget.suggestions.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.suggestions.length,
                (index) => Container(
                  width: 8,
                  height: 8,
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

  // Get appropriate icon for the current milestone
  IconData _getMilestoneIcon(SuggestionMilestone milestone) {
    switch (milestone) {
      case SuggestionMilestone.START:
        return Icons.wb_sunny_outlined; // Sunrise/morning icon
      case SuggestionMilestone.QUARTER:
        return Icons.coffee_outlined; // Mid-morning snack icon
      case SuggestionMilestone.HALF:
        return Icons.restaurant_outlined; // Lunch icon
      case SuggestionMilestone.THREE_QUARTERS:
        return Icons.dinner_dining_outlined; // Dinner icon
      case SuggestionMilestone.ALMOST_COMPLETE:
        return Icons.nightlight_outlined; // Evening icon
      case SuggestionMilestone.COMPLETED:
        return Icons.check_circle_outline; // Completed icon
      default:
        return Icons.restaurant_menu;
    }
  }

  // Get appropriate color for the current milestone
  Color _getMilestoneColor(SuggestionMilestone milestone) {
    switch (milestone) {
      case SuggestionMilestone.START:
        return Colors.orange[700]!;
      case SuggestionMilestone.QUARTER:
        return Colors.amber[700]!;
      case SuggestionMilestone.HALF:
        return Colors.green[700]!;
      case SuggestionMilestone.THREE_QUARTERS:
        return Colors.blue[700]!;
      case SuggestionMilestone.ALMOST_COMPLETE:
        return Colors.indigo[700]!;
      case SuggestionMilestone.COMPLETED:
        return Colors.green[700]!;
      default:
        return Colors.black87;
    }
  }

  Widget _buildSuggestionCard(
      FoodSuggestion suggestion, bool isCompletedMilestone) {
    // Determine if this is an ultra-low calorie option
    final bool isUltraLowCalorie = suggestion.calories <= 50;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCompletedMilestone && isUltraLowCalorie
            ? BorderSide(color: Colors.green[300]!, width: 1.5)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Top section with image and basic info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Food image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Image.network(
                        suggestion.image,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.restaurant,
                              size: 24,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      ),
                      // Ultra-low calorie badge
                      if (isUltraLowCalorie)
                        Positioned(
                          top: 0,
                          left: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(8),
                              ),
                            ),
                            child: const Icon(
                              Icons.eco,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title with optional tag
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              suggestion.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCompletedMilestone && isUltraLowCalorie)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Ultra-Low Cal',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      // LLaMA-generated explanation
                      Text(
                        suggestion.explanation ??
                            _getDefaultReason(suggestion, isCompletedMilestone),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Divider
            Divider(color: Colors.grey[200]),

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
                      size: 14,
                      color: suggestion.calories <= 50
                          ? Colors.green[600]
                          : Colors.orange[600],
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${suggestion.calories} cal',
                      style: TextStyle(
                        fontSize: 12,
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
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),

                // Button row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Toggle details button
                    InkWell(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey[500],
                          size: 18,
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
                          size: 18,
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
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Expanded section with recipe details and link
            if (_isExpanded) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDetailItem(Icons.timer, 'Ready in',
                      '${suggestion.readyInMinutes ?? "--"} min'),
                  _buildDetailItem(Icons.room_service, 'Servings',
                      '${suggestion.servings ?? "--"}'),

                  // View Recipe button if URL is available
                  if (suggestion.sourceUrl != null &&
                      suggestion.sourceUrl!.isNotEmpty)
                    TextButton.icon(
                      onPressed: _openRecipeUrl,
                      icon: const Icon(Icons.open_in_new, size: 14),
                      label: const Text('View Recipe'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD2EB50),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getDefaultReason(
      FoodSuggestion suggestion, bool isCompletedMilestone) {
    if (isCompletedMilestone) {
      return "Ultra-low calorie option that won't impact your daily goals.";
    }

    if (suggestion.protein > 20) {
      return "High in protein to support muscle recovery and growth.";
    }

    if (suggestion.carbs > 40) {
      return "Rich in carbs to provide energy for your activities.";
    }

    if (suggestion.fat > 15) {
      return "Contains healthy fats to keep you satisfied longer.";
    }

    return "Balanced nutrition to support your fitness goals.";
  }
}
