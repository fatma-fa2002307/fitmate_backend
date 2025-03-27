import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/models/food_suggestion.dart';
import 'package:fitmate/repositories/food_suggestion_repository.dart';
import 'package:fitmate/services/spoonacular_service.dart';
import 'package:http/http.dart' as http;

class EnhancedFoodSuggestionService {
  final FoodSuggestionRepository _repository = FoodSuggestionRepository();
  final SpoonacularService _spoonacularService = SpoonacularService();
  
  static const String _llamaBaseUrl = 'https://tunnel.fitnessmates.net';
  
  // Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  
  /// Get suggestions based on the current milestone, combining Spoonacular data with LLaMA insights
  Future<List<FoodSuggestion>> getSuggestionsForCurrentMilestone({
    required double totalCalories,
    required double consumedCalories,
    required String goal,
    List<String>? dietaryRestrictions,
  }) async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    
    // Calculate current milestone based on calories consumed
    final percentage = consumedCalories / totalCalories;
    final milestone = SuggestionMilestoneExtension.fromPercentage(percentage);
    
    // Try to get cached suggestions first
    final cachedSuggestions = await _repository.getCachedSuggestions(
      userId: _userId!,
      milestone: milestone,
    );
    
    // If we have fresh cached suggestions, return them
    if (cachedSuggestions != null && !cachedSuggestions.isStale()) {
      return cachedSuggestions.suggestions;
    }
    
    // Get disliked foods to exclude
    final dislikedFoods = await _repository.getDislikedFoods(_userId!);
    
    // First, use LLaMA to determine appropriate meal parameters for the user
    final mealParameters = await _getLlamaMealParameters(
      totalCalories: totalCalories,
      consumedCalories: consumedCalories,
      goal: goal,
      milestone: milestone,
      dislikedFoodIds: dislikedFoods,
    );
    
    // Use Spoonacular to get actual recipe data
    final recipeData = await _getSpoonacularRecipes(
      mealParameters: mealParameters, 
      milestone: milestone,
      consumedCalories: consumedCalories,
      totalCalories: totalCalories,
      excludeIngredients: dislikedFoods,
    );
    
    // Convert Spoonacular recipe data to FoodSuggestion objects
    final suggestions = _createFoodSuggestions(recipeData, mealParameters);
    
    // Cache the suggestions
    await _repository.cacheSuggestions(
      userId: _userId!,
      milestone: milestone,
      suggestions: suggestions,
    );
    
    return suggestions;
  }
  
  /// Get meal parameters from LLaMA model
  Future<Map<String, dynamic>> _getLlamaMealParameters({
    required double totalCalories,
    required double consumedCalories,
    required String goal,
    required SuggestionMilestone milestone,
    List<String>? dislikedFoodIds,
  }) async {
    try {
      // Prepare request body
      final requestBody = {
        'userId': _userId,
        'totalCalories': totalCalories,
        'consumedCalories': consumedCalories,
        'goal': goal,
        'milestone': milestone.toString().split('.').last,
        'dislikedFoodIds': dislikedFoodIds ?? [],
      };
      
      // Make API call to LLaMA
      final response = await http.post(
        Uri.parse('$_llamaBaseUrl/generate_food_parameters/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        return {
          'milestone': milestone,
          'mealType': jsonResponse['mealType'] ?? _defaultMealType(milestone),
          'targetCalories': jsonResponse['targetCalories'] ?? _defaultTargetCalories(milestone, totalCalories),
          'macroRatios': jsonResponse['macroRatios'] ?? _defaultMacroRatios(goal),
          'explanations': jsonResponse['explanations'] ?? [],
          'dietaryFocus': jsonResponse['dietaryFocus'] ?? _defaultDietaryFocus(goal),
        };
      } else {
        print('Failed to get meal parameters from LLaMA: ${response.statusCode}');
        // Return default parameters if LLaMA fails
        return _getDefaultMealParameters(milestone, totalCalories, goal);
      }
    } catch (e) {
      print('Error getting meal parameters from LLaMA: $e');
      // Return default parameters if an error occurs
      return _getDefaultMealParameters(milestone, totalCalories, goal);
    }
  }
  
  /// Get recipes from Spoonacular API based on parameters
  Future<List<Map<String, dynamic>>> _getSpoonacularRecipes({
    required Map<String, dynamic> mealParameters,
    required SuggestionMilestone milestone,
    required double consumedCalories,
    required double totalCalories,
    List<String>? excludeIngredients,
  }) async {
    try {
      // Extract parameters from the meal parameters
      final targetCalories = mealParameters['targetCalories'] as double;
      final macroRatios = mealParameters['macroRatios'] as Map<String, dynamic>;
      final mealType = mealParameters['mealType'] as String;
      
      // Calculate acceptable ranges for macros
      final caloryMargin = targetCalories * 0.2; // 20% margin
      final minCalories = targetCalories - caloryMargin;
      final maxCalories = targetCalories + caloryMargin;
      
      // Calculate protein, carbs, and fat targets based on macroRatios
      final proteinRatio = macroRatios['protein'] as double;
      final carbsRatio = macroRatios['carbs'] as double;
      final fatRatio = macroRatios['fat'] as double;
      
      // Convert ratios to grams using standard calorie values (4 cal/g for protein and carbs, 9 cal/g for fat)
      final targetProtein = (targetCalories * proteinRatio) / 4;
      final targetCarbs = (targetCalories * carbsRatio) / 4;
      final targetFat = (targetCalories * fatRatio) / 9;
      
      // Define acceptable ranges (±30%)
      final proteinMargin = targetProtein * 0.3;
      final carbsMargin = targetCarbs * 0.3;
      final fatMargin = targetFat * 0.3;
      
      // Search for recipes
      return await _spoonacularService.searchRecipes(
        minCalories: minCalories,
        maxCalories: maxCalories,
        minProtein: targetProtein - proteinMargin,
        maxProtein: targetProtein + proteinMargin,
        minCarbs: targetCarbs - carbsMargin,
        maxCarbs: targetCarbs + carbsMargin,
        minFat: targetFat - fatMargin,
        maxFat: targetFat + fatMargin,
        mealType: mealType,
        excludeIngredients: excludeIngredients,
        number: 5, // Request 5 recipes
      );
    } catch (e) {
      print('Error getting recipes from Spoonacular: $e');
      return [];
    }
  }
  
  /// Create FoodSuggestion objects from recipe data and LLaMA explanations
  List<FoodSuggestion> _createFoodSuggestions(
    List<Map<String, dynamic>> recipeData, 
    Map<String, dynamic> mealParameters
  ) {
    final explanations = (mealParameters['explanations'] as List?)?.cast<String>() ?? [];
    final suggestions = <FoodSuggestion>[];
    
    for (var i = 0; i < recipeData.length; i++) {
      final recipe = recipeData[i];
      
      // Get explanation for this recipe, or use a default one
      final explanation = i < explanations.length 
          ? explanations[i] 
          : _generateDefaultExplanation(
              recipe, 
              mealParameters['milestone'] as SuggestionMilestone,
              mealParameters['dietaryFocus'] as String
            );
      
      suggestions.add(FoodSuggestion(
        id: recipe['id'].toString(),
        title: recipe['title'],
        image: recipe['image'],
        calories: recipe['calories'],
        protein: recipe['protein'],
        carbs: recipe['carbs'],
        fat: recipe['fat'],
        sourceUrl: recipe['sourceUrl'],
        readyInMinutes: recipe['readyInMinutes'],
        servings: recipe['servings'],
        explanation: explanation,
      ));
    }
    
    return suggestions;
  }
  
  /// Create default meal parameters if LLaMA fails
  Map<String, dynamic> _getDefaultMealParameters(
    SuggestionMilestone milestone, 
    double totalCalories,
    String goal
  ) {
    return {
      'milestone': milestone,
      'mealType': _defaultMealType(milestone),
      'targetCalories': _defaultTargetCalories(milestone, totalCalories),
      'macroRatios': _defaultMacroRatios(goal),
      'explanations': [],
      'dietaryFocus': _defaultDietaryFocus(goal),
    };
  }
  
  /// Get default meal type based on milestone
  String _defaultMealType(SuggestionMilestone milestone) {
    switch (milestone) {
      case SuggestionMilestone.START:
        return 'breakfast';
      case SuggestionMilestone.QUARTER:
        return 'snack';
      case SuggestionMilestone.HALF:
        return 'lunch';
      case SuggestionMilestone.THREE_QUARTERS:
        return 'dinner';
      case SuggestionMilestone.ALMOST_COMPLETE:
        return 'snack';
      case SuggestionMilestone.COMPLETED:
        return 'snack';
      default:
        return 'main course';
    }
  }
  
  /// Get default target calories based on milestone and total calories
  double _defaultTargetCalories(SuggestionMilestone milestone, double totalCalories) {
    switch (milestone) {
      case SuggestionMilestone.START:
        return totalCalories * 0.3; // 30% for breakfast
      case SuggestionMilestone.QUARTER:
        return totalCalories * 0.15; // 15% for snack
      case SuggestionMilestone.HALF:
        return totalCalories * 0.3; // 30% for lunch
      case SuggestionMilestone.THREE_QUARTERS:
        return totalCalories * 0.2; // 20% for dinner
      case SuggestionMilestone.ALMOST_COMPLETE:
        return totalCalories * 0.05; // 5% for evening snack
      case SuggestionMilestone.COMPLETED:
        return 50; // Very low calories when already at goal
      default:
        return totalCalories * 0.25;
    }
  }
  
  /// Get default macro ratios based on goal
  Map<String, dynamic> _defaultMacroRatios(String goal) {
    switch (goal.toLowerCase()) {
      case 'weight loss':
        return {
          'protein': 0.30,
          'carbs': 0.40,
          'fat': 0.30,
        };
      case 'gain muscle':
        return {
          'protein': 0.35,
          'carbs': 0.45,
          'fat': 0.20,
        };
      case 'improve fitness':
      default:
        return {
          'protein': 0.25,
          'carbs': 0.50,
          'fat': 0.25,
        };
    }
  }
  
  /// Get default dietary focus based on goal
  String _defaultDietaryFocus(String goal) {
    switch (goal.toLowerCase()) {
      case 'weight loss':
        return 'low-calorie, high-protein';
      case 'gain muscle':
        return 'high-protein, nutrient-dense';
      case 'improve fitness':
      default:
        return 'balanced, nutrient-rich';
    }
  }
  
  /// Generate default explanation for a recipe
  String _generateDefaultExplanation(
    Map<String, dynamic> recipe, 
    SuggestionMilestone milestone,
    String dietaryFocus
  ) {
    final milestoneName = milestone.displayName;
    
    if (milestone == SuggestionMilestone.COMPLETED) {
      return 'This ${recipe['calories'] < 100 ? 'ultra-low' : 'low'} calorie option helps you stay within your daily calorie target while still enjoying a satisfying meal.';
    }
    
    if (recipe['protein'] > 20) {
      return 'This high-protein $milestoneName provides excellent nutrition for muscle recovery and satiety.';
    }
    
    if (recipe['carbs'] > 30 && milestone == SuggestionMilestone.START) {
      return 'This carb-focused breakfast provides energy to fuel your morning activities.';
    }
    
    if (recipe['fat'] > 15) {
      return 'This $milestoneName contains healthy fats to keep you satisfied longer.';
    }
    
    return 'A balanced $milestoneName option that supports your $dietaryFocus goals.';
  }
  
  /// Rate a food suggestion (like/dislike)
  Future<void> rateSuggestion(String foodId, bool isLiked) async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    
    if (!isLiked) {
      // If disliked, add to disliked foods
      await _repository.addDislikedFood(_userId!, foodId);
    } else {
      // If liked, remove from disliked foods (if present)
      await _repository.removeDislikedFood(_userId!, foodId);
    }
  }
  
  /// Get current milestone based on consumed calories
  SuggestionMilestone getCurrentMilestone({
    required double totalCalories,
    required double consumedCalories,
  }) {
    final percentage = consumedCalories / totalCalories;
    return SuggestionMilestoneExtension.fromPercentage(percentage);
  }
}