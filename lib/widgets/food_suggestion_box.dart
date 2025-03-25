import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/models/food_suggestion.dart';
import 'package:fitmate/services/food_suggestion_service.dart';
import 'package:fitmate/widgets/food_suggestion_card.dart';

class FoodSuggestionBox extends StatefulWidget {
  final double totalCalories;
  final double consumedCalories;
  final String goal;
  
  const FoodSuggestionBox({
    Key? key,
    required this.totalCalories, 
    required this.consumedCalories,
    required this.goal,
  }) : super(key: key);

  @override
  State<FoodSuggestionBox> createState() => _FoodSuggestionBoxState();
}

class _FoodSuggestionBoxState extends State<FoodSuggestionBox> {
  final FoodSuggestionService _foodSuggestionService = FoodSuggestionService();
  List<FoodSuggestion> _suggestions = [];
  bool _isLoading = true;
  String _errorMessage = '';
  late SuggestionMilestone _currentMilestone;
  int _currentSuggestionIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }
  
  @override
  void didUpdateWidget(FoodSuggestionBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if calories have changed significantly
    final oldPercentage = oldWidget.consumedCalories / oldWidget.totalCalories;
    final newPercentage = widget.consumedCalories / widget.totalCalories;
    
    // If milestone changed, reload suggestions
    final oldMilestone = SuggestionMilestoneExtension.fromPercentage(oldPercentage);
    final newMilestone = SuggestionMilestoneExtension.fromPercentage(newPercentage);
    
    if (oldMilestone != newMilestone) {
      _loadSuggestions();
    }
  }
  
  /// Load food suggestions based on current milestone
  Future<void> _loadSuggestions() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
    }
    
    try {
      // Get current milestone
      final percentage = widget.consumedCalories / widget.totalCalories;
      _currentMilestone = SuggestionMilestoneExtension.fromPercentage(percentage);
      
      // Get suggestions
      final suggestions = await _foodSuggestionService.getSuggestionsForCurrentMilestone(
        totalCalories: widget.totalCalories,
        consumedCalories: widget.consumedCalories,
        goal: widget.goal,
      );
      
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _isLoading = false;
          _currentSuggestionIndex = 0; // Reset to first suggestion
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to load suggestions. Please try again later.';
          _isLoading = false;
        });
      }
      print('Error loading suggestions: $e');
    }
  }
  
  /// Go to next suggestion
  void _nextSuggestion() {
    if (_suggestions.isEmpty) return;
    
    setState(() {
      _currentSuggestionIndex = (_currentSuggestionIndex + 1) % _suggestions.length;
    });
  }
  
  /// Go to previous suggestion
  void _prevSuggestion() {
    if (_suggestions.isEmpty) return;
    
    setState(() {
      _currentSuggestionIndex = (_currentSuggestionIndex - 1 + _suggestions.length) % _suggestions.length;
    });
  }
  
  /// Handle when a suggestion is liked or disliked
  void _handlePreferenceChange() {
    // Move to next suggestion when preference changes
    if (_suggestions.length > 1) {
      _nextSuggestion();
    }
  }
  
  /// Generate a personalized reason for the current suggestion
  String _getPersonalizedReason(FoodSuggestion suggestion) {
    // Calculate remaining calories
    final remainingCalories = widget.totalCalories - widget.consumedCalories;
    
    // Calculate macro percentages for the day
    final macroPercentages = _calculateDailyMacroPercentages();
    
    // Generate reason based on milestone, remaining calories, and macros
    switch (_currentMilestone) {
      case SuggestionMilestone.START:
        return "Great breakfast option to start your day with energy";
      
      case SuggestionMilestone.QUARTER:
        if (macroPercentages['protein']! < 0.25) {
          return "Good protein source for your mid-morning snack";
        } else {
          return "Perfect mid-morning snack that fits your calorie budget";
        }
      
      case SuggestionMilestone.HALF:
        if (suggestion.calories < remainingCalories * 0.4) {
          return "Balanced lunch option that leaves plenty of calories for later";
        } else if (macroPercentages['protein']! < 0.3) {
          return "Protein-rich lunch to help you reach your daily goals";
        } else {
          return "Nutritious lunch option to keep you going through the day";
        }
      
      case SuggestionMilestone.THREE_QUARTERS:
        if (remainingCalories < 500) {
          return "Light dinner option that fits within your remaining calories";
        } else {
          return "Dinner option with balanced nutrients for your evening meal";
        }
      
      case SuggestionMilestone.ALMOST_COMPLETE:
        return "Light snack to complete your day without exceeding your calorie goal";
    }
  }
  
  /// Calculate the percentage of macros consumed so far today
  Map<String, double> _calculateDailyMacroPercentages() {
    // Dummy values - in a real app, these would come from actual user data
    return {
      'protein': 0.25, // 25% of protein goal met
      'carbs': 0.35,   // 35% of carbs goal met
      'fat': 0.3,      // 30% of fat goal met
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFD2EB50).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.restaurant_menu,
                  color: Color(0xFFD2EB50),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Food Suggestion',
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                ),
              ),
            )
          else if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.grey[400],
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _loadSuggestions,
                      child: Text(
                        'Try Again',
                        style: TextStyle(
                          color: const Color(0xFFD2EB50),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_suggestions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'No suggestions available. Try again later.',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: FoodSuggestionCard(
                suggestion: _suggestions[_currentSuggestionIndex],
                customReason: _getPersonalizedReason(_suggestions[_currentSuggestionIndex]),
                onLike: _handlePreferenceChange,
                onDislike: _handlePreferenceChange,
              ),
            ),
            
          // Footer with navigation dots/arrows if multiple suggestions
          if (!_isLoading && _errorMessage.isEmpty && _suggestions.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, size: 16),
                    color: Colors.grey[600],
                    onPressed: _prevSuggestion,
                    splashRadius: 20,
                  ),
                  
                  // Dots indicating current position
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      _suggestions.length,
                      (index) => Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentSuggestionIndex
                              ? const Color(0xFFD2EB50)
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ),
                  
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    color: Colors.grey[600],
                    onPressed: _nextSuggestion,
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          
          // Refresh button at the bottom
          if (!_isLoading)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: TextButton.icon(
                onPressed: _loadSuggestions,
                icon: const Icon(
                  Icons.refresh,
                  size: 16,
                  color: Color(0xFFD2EB50),
                ),
                label: Text(
                  'Refresh Suggestion',
                  style: TextStyle(
                    color: const Color(0xFFD2EB50),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}