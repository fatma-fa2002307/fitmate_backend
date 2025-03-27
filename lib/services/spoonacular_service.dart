import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fitmate/models/food_suggestion.dart';

class SpoonacularService {
  static const String apiKey = 'eb79020295ab472b9044cb370bceafd0';
  static const String baseUrl = 'https://api.spoonacular.com';

  /// Search for recipes that meet specific macronutrient requirements
  Future<List<Map<String, dynamic>>> searchRecipes({
    required double minCalories, 
    required double maxCalories,
    required double minProtein,
    required double maxProtein,
    required double minCarbs,
    required double maxCarbs,
    required double minFat,
    required double maxFat,
    String? mealType,
    List<String>? excludeIngredients,
    int number = 5
  }) async {
    try {
      final queryParams = {
        'apiKey': apiKey,
        'minCalories': minCalories.toStringAsFixed(0),
        'maxCalories': maxCalories.toStringAsFixed(0),
        'minProtein': minProtein.toStringAsFixed(0),
        'maxProtein': maxProtein.toStringAsFixed(0),
        'minCarbs': minCarbs.toStringAsFixed(0),
        'maxCarbs': maxCarbs.toStringAsFixed(0),
        'minFat': minFat.toStringAsFixed(0),
        'maxFat': maxFat.toStringAsFixed(0),
        'number': number.toString(),
        'addRecipeNutrition': 'true',
        'fillIngredients': 'true',
        'sort': 'random',
      };
      
      // Add optional parameters if provided
      if (mealType != null) {
        queryParams['type'] = mealType;
      }
      
      if (excludeIngredients != null && excludeIngredients.isNotEmpty) {
        queryParams['excludeIngredients'] = excludeIngredients.join(',');
      }
      
      final uri = Uri.parse('$baseUrl/recipes/complexSearch').replace(
        queryParameters: queryParams,
      );
      
      print('Requesting recipes from: $uri');
      
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;
        
        return results.map((result) => _processRecipeData(result)).toList();
      } else {
        print('Error from Spoonacular API: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Exception in searchRecipes: $e');
      return [];
    }
  }
  
  /// Get recipe information by ID
  Future<Map<String, dynamic>?> getRecipeById(int recipeId) async {
    try {
      final uri = Uri.parse('$baseUrl/recipes/$recipeId/information').replace(
        queryParameters: {
          'apiKey': apiKey,
          'includeNutrition': 'true',
        },
      );
      
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _processRecipeData(data);
      } else {
        print('Error fetching recipe: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception in getRecipeById: $e');
      return null;
    }
  }
  
  /// Convert a recipe from Spoonacular format to FoodSuggestion format
  FoodSuggestion convertToFoodSuggestion(Map<String, dynamic> recipeData) {
    return FoodSuggestion(
      id: recipeData['id'].toString(),
      title: recipeData['title'],
      image: recipeData['image'],
      calories: recipeData['calories'],
      protein: recipeData['protein'],
      carbs: recipeData['carbs'],
      fat: recipeData['fat'],
    );
  }
  
  /// Process recipe data to extract the required information
  Map<String, dynamic> _processRecipeData(Map<String, dynamic> data) {
    // Extract nutrients from nutrition data
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    
    if (data.containsKey('nutrition')) {
      final nutrients = data['nutrition']['nutrients'] as List;
      
      for (final nutrient in nutrients) {
        final name = nutrient['name'] as String;
        final amount = nutrient['amount'] as double;
        
        switch (name) {
          case 'Calories':
            calories = amount;
            break;
          case 'Protein':
            protein = amount;
            break;
          case 'Carbohydrates':
            carbs = amount;
            break;
          case 'Fat':
            fat = amount;
            break;
        }
      }
    } else if (data.containsKey('nutrients')) {
      // Handle different API response formats
      final nutrients = data['nutrients'] as List;
      
      for (final nutrient in nutrients) {
        final name = nutrient['name'] as String;
        final amount = nutrient['amount'] as double;
        
        switch (name) {
          case 'Calories':
            calories = amount;
            break;
          case 'Protein':
            protein = amount;
            break;
          case 'Carbohydrates':
            carbs = amount;
            break;
          case 'Fat':
            fat = amount;
            break;
        }
      }
    }
    
    // Return processed data in a consistent format
    return {
      'id': data['id'],
      'title': data['title'],
      'image': data['image'],
      'imageUrl': data['image'],
      'calories': calories.round(),
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sourceUrl': data['sourceUrl'] ?? data['spoonacularSourceUrl'] ?? '',
      'readyInMinutes': data['readyInMinutes'] ?? 0,
      'servings': data['servings'] ?? 1,
    };
  }
  
  /// Get meal type based on time of day and percentage of calories consumed
  String getMealTypeForTimeOfDay(double percentageConsumed) {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (percentageConsumed < 0.1) {
      return 'breakfast';
    } else if (percentageConsumed < 0.35) {
      return hour < 12 ? 'breakfast' : 'snack';
    } else if (percentageConsumed < 0.6) {
      return hour < 15 ? 'lunch' : 'dinner';
    } else if (percentageConsumed < 0.85) {
      return 'dinner';
    } else {
      return 'snack';
    }
  }
}