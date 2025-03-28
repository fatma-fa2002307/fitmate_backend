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

    // Get disliked foods to exclude
    final dislikedFoods = await _repository.getDislikedFoods(_userId!);

    try {
      // Request food suggestions from the backend API
      final requestBody = {
        'userId': _userId,
        'totalCalories': totalCalories,
        'consumedCalories': consumedCalories,
        'goal': goal,
        'milestone': milestone.toString().split('.').last,
        'dislikedFoodIds': dislikedFoods,
      };

      final response = await http
          .post(
            Uri.parse('$_llamaBaseUrl/generate_food_suggestions/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
            // Set timeout to 10 seconds
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['suggestions'] != null) {
          // Parse the suggestions from the response
          final suggestionsData = jsonResponse['suggestions'] as List;

          // If no suggestions returned, use fallback
          if (suggestionsData.isEmpty) {
            return await _getFallbackSuggestions(
              totalCalories: totalCalories,
              consumedCalories: consumedCalories,
              goal: goal,
              milestone: milestone,
              dislikedFoods: dislikedFoods,
            );
          }

          // Convert API response to FoodSuggestion objects
          final suggestions = suggestionsData
              .map((suggestion) => FoodSuggestion(
                    id: suggestion['id'].toString(),
                    title: suggestion['title'],
                    image: suggestion['image'],
                    calories: suggestion['calories'],
                    protein: suggestion['protein'],
                    carbs: suggestion['carbs'],
                    fat: suggestion['fat'],
                    sourceUrl: suggestion['sourceUrl'],
                    readyInMinutes: suggestion['readyInMinutes'],
                    servings: suggestion['servings'],
                    explanation: suggestion['explanation'],
                    isSimpleIngredient:
                        suggestion['isSimpleIngredient'] ?? false,
                  ))
              .toList();

          return suggestions;
        }
      }

      // If API call fails, fallback to Spoonacular + default options
      return await _getFallbackSuggestions(
        totalCalories: totalCalories,
        consumedCalories: consumedCalories,
        goal: goal,
        milestone: milestone,
        dislikedFoods: dislikedFoods,
      );
    } catch (e) {
      print('Error getting food suggestions: $e');
      // Fallback to Spoonacular recipes if LLaMA API fails
      return await _getFallbackSuggestions(
        totalCalories: totalCalories,
        consumedCalories: consumedCalories,
        goal: goal,
        milestone: milestone,
        dislikedFoods: dislikedFoods,
      );
    }
  }

  /// Get fallback suggestions using Spoonacular API directly
  Future<List<FoodSuggestion>> _getFallbackSuggestions({
    required double totalCalories,
    required double consumedCalories,
    required String goal,
    required SuggestionMilestone milestone,
    required List<String> dislikedFoods,
  }) async {
    // Get meal parameters
    final mealParameters =
        _getDefaultMealParameters(milestone, totalCalories, goal);

    // Get recipes from Spoonacular (3 only)
    final recipeData = await _getSpoonacularRecipes(
      mealParameters: mealParameters,
      milestone: milestone,
      consumedCalories: consumedCalories,
      totalCalories: totalCalories,
      excludeIngredients: dislikedFoods,
    );

    // Create food suggestion objects
    final recipeSuggestions = recipeData.map((recipe) {
      final explanation = _generateExplanation(
        recipe,
        milestone,
        mealParameters['dietaryFocus'] as String,
      );

      return FoodSuggestion(
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
        isSimpleIngredient: false,
      );
    }).toList();

    // Create two simple ingredient fallback options based on milestone
    final ingredientSuggestions = _getSimpleIngredientOptions(milestone);

    // Return combined suggestions (limit to 5 total)
    return [...recipeSuggestions, ...ingredientSuggestions].take(5).toList();
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

      // Convert ratios to grams using standard calorie values
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
        number: 3, // Request 3 recipes
      );
    } catch (e) {
      print('Error getting recipes from Spoonacular: $e');
      return [];
    }
  }

  /// Get simple ingredient options based on milestone
  List<FoodSuggestion> _getSimpleIngredientOptions(
      SuggestionMilestone milestone) {
    List<Map<String, dynamic>> options = [];

    // Fallback options for when LLaMA API fails
    switch (milestone) {
      case SuggestionMilestone.START:
        options = [
          {
            'id': 'yogurt-fruit',
            'title': 'Greek Yogurt with Berries',
            'image':
                'https://spoonacular.com/cdn/ingredients_100x100/greek-yogurt.jpg',
            'calories': 150,
            'protein': 15.0,
            'carbs': 20.0,
            'fat': 0.5,
            'explanation':
                'A protein-rich breakfast option that provides sustained energy.',
          },
          {
            'id': 'oatmeal',
            'title': 'Oatmeal with Banana',
            'image':
                'https://spoonacular.com/cdn/ingredients_100x100/porridge-oats.jpg',
            'calories': 220,
            'protein': 5.0,
            'carbs': 45.0,
            'fat': 3.5,
            'explanation':
                'Complex carbs from oatmeal provide lasting energy while banana adds natural sweetness.',
          },
        ];
        break;
      case SuggestionMilestone.QUARTER:
        options = [
          {
            'id': 'apple-almond',
            'title': 'Apple with Almond Butter',
            'image':
                'https://spoonacular.com/cdn/ingredients_100x100/apple.jpg',
            'calories': 180,
            'protein': 4.0,
            'carbs': 20.0,
            'fat': 10.0,
            'explanation':
                'A balanced snack with fiber and healthy fats to keep you satisfied.',
          },
          {
            'id': 'cottage-cheese',
            'title': 'Cottage Cheese with Pineapple',
            'image':
                'https://spoonacular.com/cdn/ingredients_100x100/cottage-cheese.jpg',
            'calories': 140,
            'protein': 14.0,
            'carbs': 12.0,
            'fat': 2.5,
            'explanation':
                'High-protein snack that supports muscle maintenance while providing natural sweetness.',
          },
        ];
        break;
      case SuggestionMilestone.HALF:
        options = [
          {
            'id': 'tuna',
            'title': 'Tuna with Avocado',
            'image': 'https://spoonacular.com/cdn/ingredients_100x100/tuna.jpg',
            'calories': 240,
            'protein': 25.0,
            'carbs': 5.0,
            'fat': 15.0,
            'explanation':
                'Lean protein from tuna paired with healthy fats from avocado creates a satisfying lunch.',
          },
          {
            'id': 'egg-toast',
            'title': 'Boiled Eggs on Whole Grain Toast',
            'image':
                'https://spoonacular.com/cdn/ingredients_100x100/hard-boiled-egg.jpg',
            'calories': 220,
            'protein': 14.0,
            'carbs': 20.0,
            'fat': 10.0,
            'explanation':
                'Complete protein source with complex carbs for sustained energy throughout the afternoon.',
          },
        ];
        break;
      case SuggestionMilestone.THREE_QUARTERS:
        options = [
          {
            'id': 'chicken-veg',
            'title': 'Grilled Chicken with Vegetables',
            'image':
                'https://spoonacular.com/cdn/ingredients_100x100/chicken-breast.jpg',
            'calories': 300,
            'protein': 35.0,
            'carbs': 10.0,
            'fat': 12.0,
            'explanation':
                'Lean protein from chicken with fiber-rich vegetables provides a balanced dinner option.',
          },
          {
            'id': 'salmon-sweet-potato',
            'title': 'Baked Salmon with Sweet Potato',
            'image':
                'https://spoonacular.com/cdn/ingredients_100x100/salmon.jpg',
            'calories': 320,
            'protein': 28.0,
            'carbs': 20.0,
            'fat': 14.0,
            'explanation':
                'Omega-3 rich salmon paired with complex carbs from sweet potato creates a nutritionally complete meal.',
          },
        ];
        break;
      case SuggestionMilestone.ALMOST_COMPLETE:
        options = [
          {
            'id': 'strawberries',
            'title': 'Fresh Strawberries',
            'image':
                'https://spoonacular.com/cdn/ingredients_100x100/strawberries.jpg',
            'calories': 50,
            'protein': 1.0,
            'carbs': 12.0,
            'fat': 0.5,
            'explanation':
                'Low calorie option to satisfy sweet cravings while adding minimal calories to your daily total.',
          },
          {
            'id': 'nuts',
            'title': 'Small Handful of Mixed Nuts',
            'image':
                'https://spoonacular.com/cdn/ingredients_100x100/mixed-nuts.jpg',
            'calories': 120,
            'protein': 5.0,
            'carbs': 4.0,
            'fat': 10.0,
            'explanation':
                'Nutrient-dense snack that provides healthy fats and protein with minimal impact on your remaining calorie budget.',
          },
        ];
        break;
      case SuggestionMilestone.COMPLETED:
        options = [
          {
            'id': 'tea',
            'title': 'Herbal Tea',
            'image': 'https://spoonacular.com/cdn/ingredients_100x100/tea.jpg',
            'calories': 0,
            'protein': 0.0,
            'carbs': 0.0,
            'fat': 0.0,
            'explanation':
                'Zero-calorie option to enjoy when you\'ve reached your calorie goal for the day.',
          },
          {
            'id': 'cucumber',
            'title': 'Cucumber Slices',
            'image':
                'https://spoonacular.com/cdn/ingredients_100x100/cucumber.jpg',
            'calories': 15,
            'protein': 0.5,
            'carbs': 3.0,
            'fat': 0.0,
            'explanation':
                'Ultra-low calorie snack that provides hydration and crunch without impacting your calorie goals.',
          },
        ];
        break;
      default:
        options = [];
    }

    // Convert to FoodSuggestion objects
    return options
        .map((option) => FoodSuggestion(
              id: option['id'] as String,
              title: option['title'] as String,
              image: option['image'] as String,
              calories: option['calories'] as int,
              protein: option['protein'] as double,
              carbs: option['carbs'] as double,
              fat: option['fat'] as double,
              explanation: option['explanation'] as String,
              isSimpleIngredient: true,
            ))
        .toList();
  }

  /// Create default meal parameters if LLaMA fails
  Map<String, dynamic> _getDefaultMealParameters(
      SuggestionMilestone milestone, double totalCalories, String goal) {
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
  double _defaultTargetCalories(
      SuggestionMilestone milestone, double totalCalories) {
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

  /// Generate explanation for a recipe
  String _generateExplanation(Map<String, dynamic> recipe,
      SuggestionMilestone milestone, String dietaryFocus) {
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
