import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/models/food_suggestion.dart';
import 'package:fitmate/repositories/food_suggestion_repository.dart';
import 'package:http/http.dart' as http;

class EnhancedFoodSuggestionService {
  final FoodSuggestionRepository _repository = FoodSuggestionRepository();
  
  static const String _baseUrl = 'https://tunnel.fitnessmates.net';
  
  // Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  
  /// Get AI-powered suggestions based on the current milestone
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
    
    // Get fresh suggestions from the API every time
    final suggestions = await _getAIPoweredSuggestions(
      totalCalories: totalCalories,
      consumedCalories: consumedCalories,
      goal: goal,
      dislikedFoodIds: dislikedFoods,
    );
    
    return suggestions;
  }
  
  /// Get AI-powered food suggestions from the backend
  Future<List<FoodSuggestion>> _getAIPoweredSuggestions({
    required double totalCalories,
    required double consumedCalories,
    required String goal,
    List<String>? dislikedFoodIds,
  }) async {
    try {
      // Prepare request payload
      final requestBody = {
        'userId': _userId,
        'totalCalories': totalCalories,
        'consumedCalories': consumedCalories,
        'goal': goal,
        'dislikedFoodIds': dislikedFoodIds ?? [],
      };
      
      // Make API call to backend
      final response = await http.post(
        Uri.parse('$_baseUrl/generate_food_suggestions/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Parse the suggestions array
        final suggestionsJson = jsonResponse['suggestions'] as List;
        final suggestions = suggestionsJson
            .map((json) => FoodSuggestion.fromMap(json))
            .toList();
        
        return suggestions;
      } else {
        print('Error getting food suggestions: ${response.statusCode}');
        print('Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error getting AI-powered food suggestions: $e');
      return [];
    }
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