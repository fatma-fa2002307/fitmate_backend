import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/models/food_suggestion.dart';
import 'package:fitmate/services/food_suggestion_service.dart';

class FoodSuggestionCard extends StatefulWidget {
  final FoodSuggestion suggestion;
  final Function? onLike;
  final Function? onDislike;
  final String? customReason; // Custom reason why this food is suggested

  const FoodSuggestionCard({
    Key? key,
    required this.suggestion,
    this.onLike,
    this.onDislike,
    this.customReason,
  }) : super(key: key);

  @override
  State<FoodSuggestionCard> createState() => _FoodSuggestionCardState();
}

class _FoodSuggestionCardState extends State<FoodSuggestionCard> {
  // Service to handle food suggestion interactions
  final FoodSuggestionService _foodSuggestionService = FoodSuggestionService();
  
  // Local state for liked/disliked status
  bool _isLiked = false;
  bool _isDisliked = false;
  
  /// Generate a custom reason if one isn't provided
  String _getSuggestionReason() {
    if (widget.customReason != null && widget.customReason!.isNotEmpty) {
      return widget.customReason!;
    }
    
    // Generate a reason based on macros
    if (widget.suggestion.protein > 20) {
      return "Excellent source of protein to help with your fitness goals";
    } else if (widget.suggestion.carbs > 40) {
      return "Good source of energy to fuel your workouts";
    } else if (widget.suggestion.fat < 10) {
      return "Low in fat and fits well in your calorie budget";
    } else if (widget.suggestion.calories < 300) {
      return "Low calorie option that leaves room in your daily budget";
    } else {
      return "Balanced option that fits your nutritional needs";
    }
  }
  
  /// Handle liking a food suggestion
  void _handleLike() async {
    if (_isLiked) return;
    
    setState(() {
      _isLiked = true;
      _isDisliked = false;
    });
    
    // Call service to update preference
    await _foodSuggestionService.rateSuggestion(widget.suggestion.id, true);
    
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
    await _foodSuggestionService.rateSuggestion(widget.suggestion.id, false);
    
    // Call callback if provided
    if (widget.onDislike != null) {
      widget.onDislike!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Base URL for food images
    final baseUrl = 'https://tunnel.fitnessmates.net';
    final imageUrl = '$baseUrl/food-images/${widget.suggestion.image}';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Small image on the side
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 30,
                        color: Colors.grey[400],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.suggestion.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Reason text
                  Text(
                    _getSuggestionReason(),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Calories
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 16,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.suggestion.calories} cal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Like button
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: _isLiked ? const Color(0xFFD2EB50) : Colors.grey[500],
                          size: 20,
                        ),
                        onPressed: _handleLike,
                        tooltip: 'Like',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Dislike button
                      IconButton(
                        icon: Icon(
                          _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                          color: _isDisliked ? Colors.red[400] : Colors.grey[500],
                          size: 20,
                        ),
                        onPressed: _handleDislike,
                        tooltip: 'Dislike',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
}