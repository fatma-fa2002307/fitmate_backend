import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/models/food_suggestion.dart';
import 'package:fitmate/services/food_suggestion_service.dart';

class FoodSuggestionCard extends StatefulWidget {
  final List<FoodSuggestion> suggestions;
  final Function? onLike;
  final Function? onDislike;
  final Function(int)? onPageChanged;
  final int initialIndex;

  const FoodSuggestionCard({
    Key? key,
    required this.suggestions,
    this.onLike,
    this.onDislike,
    this.onPageChanged,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<FoodSuggestionCard> createState() => _FoodSuggestionCardState();
}

class _FoodSuggestionCardState extends State<FoodSuggestionCard> {
  late PageController _pageController;
  int _currentIndex = 0;
  
  // Service to handle food suggestion interactions
  final FoodSuggestionService _foodSuggestionService = FoodSuggestionService();
  
  // Local state for liked/disliked status
  bool _isLiked = false;
  bool _isDisliked = false;
  
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
        widget.suggestions[_currentIndex].id, 
        true
      );
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
        widget.suggestions[_currentIndex].id, 
        false
      );
    }
    
    // Call callback if provided
    if (widget.onDislike != null) {
      widget.onDislike!();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      children: [
        // Food suggestion card with swipe functionality
        SizedBox(
          height: 120, // Standard card height
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.suggestions.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _isLiked = false;
                _isDisliked = false;
              });
              if (widget.onPageChanged != null) {
                widget.onPageChanged!(index);
              }
            },
            itemBuilder: (context, index) {
              final suggestion = widget.suggestions[index];
              return _buildSuggestionCard(suggestion);
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
  
  Widget _buildSuggestionCard(FoodSuggestion suggestion) {
    // Base URL for food images
    final baseUrl = 'https://tunnel.fitnessmates.net';
    final imageUrl = '$baseUrl/food-images/${suggestion.image}';
    
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Reduced padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 60, // Smaller image
                height: 60, // Smaller image
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.restaurant,
                      size: 24,
                      color: Colors.grey[400],
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(width: 8), // Reduced spacing
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    suggestion.title,
                    style: const TextStyle(
                      fontSize: 14, // Smaller font
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 2), // Reduced spacing
                  
                  // Reason text - More strictly limited
                  Text(
                    _getSuggestionReason(suggestion),
                    style: TextStyle(
                      fontSize: 11, // Smaller font
                      color: Colors.grey[700],
                    ),
                    maxLines: 1, // Only 1 line for description
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(), // Use spacer for flexibility
                  
                  // Bottom row with calories and actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Calories
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_fire_department,
                            size: 14, // Smaller icon
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 2), // Reduced spacing
                          Text(
                            '${suggestion.calories} cal',
                            style: const TextStyle(
                              fontSize: 12, // Smaller font
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      
                      // Like/dislike buttons
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: _handleLike,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                color: _isLiked ? const Color(0xFFD2EB50) : Colors.grey[500],
                                size: 16, // Smaller icon
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          InkWell(
                            onTap: _handleDislike,
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                color: _isDisliked ? Colors.red[400] : Colors.grey[500],
                                size: 16, // Smaller icon
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getSuggestionReason(FoodSuggestion suggestion) {
    // Generate a shorter reason based on macros
    String reason;
    
    if (suggestion.protein > 20) {
      reason = "Excellent source of protein for fitness";
    } else if (suggestion.carbs > 40) {
      reason = "Good energy source for workouts";
    } else if (suggestion.fat < 10) {
      reason = "Low in fat, fits your calorie budget";
    } else if (suggestion.calories < 300) {
      reason = "Low calorie option for your daily goals";
    } else {
      reason = "Balanced nutrition for your needs";
    }
    
    // Ensure text is short enough
    if (reason.length > 40) {
      return reason.substring(0, 37) + "...";
    }
    
    return reason;
  }
}