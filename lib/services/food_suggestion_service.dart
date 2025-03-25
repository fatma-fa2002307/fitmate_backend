import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:fitmate/models/food_suggestion.dart';
import 'package:fitmate/repositories/food_suggestion_repository.dart';

class FoodSuggestionService {
  final FoodSuggestionRepository _repository = FoodSuggestionRepository();
  static const String _baseUrl = 'https://tunnel.fitnessmates.net'; // Replace with your actual API URL
  
  // Get current user ID
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;
  
  /// Get suggestions based on the current milestone
  Future<List<FoodSuggestion>> getSuggestionsForCurrentMilestone({
    required double totalCalories,
    required double consumedCalories,
    required String goal,
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
    
    // Otherwise, fetch from API
    return await fetchFromApi(
      totalCalories: totalCalories,
      consumedCalories: consumedCalories,
      goal: goal,
    );
  }
  
  /// Fetch food suggestions from the API
  Future<List<FoodSuggestion>> fetchFromApi({
    required double totalCalories,
    required double consumedCalories,
    required String goal,
  }) async {
    if (_userId == null) {
      throw Exception('User not logged in');
    }
    
    try {
      // Get disliked foods
      final dislikedFoods = await _repository.getDislikedFoods(_userId!);
      
      // Prepare request body
      final requestBody = {
        'userId': _userId,
        'totalCalories': totalCalories,
        'consumedCalories': consumedCalories,
        'goal': goal,
        'dislikedFoodIds': dislikedFoods,
      };
      
      // Make API call
      final response = await http.post(
        Uri.parse('$_baseUrl/generate_food_suggestions/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Extract milestone and suggestions
        final milestoneStr = jsonResponse['milestone'] as String;
        final suggestionsList = jsonResponse['suggestions'] as List;
        
        // Convert milestone string to enum
        final milestone = SuggestionMilestone.values.firstWhere(
          (m) => m.toString().split('.').last == milestoneStr,
          orElse: () => SuggestionMilestone.HALF,
        );
        
        // Convert suggestions to FoodSuggestion objects
        final suggestions = suggestionsList
            .map((item) => FoodSuggestion.fromMap(item))
            .toList();
        
        // Cache the suggestions
        await _repository.cacheSuggestions(
          userId: _userId!,
          milestone: milestone,
          suggestions: suggestions,
        );
        
        return suggestions;
      } else {
        throw Exception('Failed to fetch food suggestions: ${response.reasonPhrase}');
      }
    } catch (e) {
      // If API call fails, try to get even stale cached suggestions
      final percentage = consumedCalories / totalCalories;
      final milestone = SuggestionMilestoneExtension.fromPercentage(percentage);
      
      final cachedSuggestions = await _repository.getCachedSuggestions(
        userId: _userId!,
        milestone: milestone,
      );
      
      // If we have cached suggestions, return them even if stale
      if (cachedSuggestions != null) {
        return cachedSuggestions.suggestions;
      }
      
      // Re-throw the exception if we couldn't get any suggestions
      rethrow;
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