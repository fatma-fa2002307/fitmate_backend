import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing different milestones of calorie consumption
enum SuggestionMilestone {
  START,            // 0% of daily calories consumed
  QUARTER,          // 25% of daily calories consumed
  HALF,             // 50% of daily calories consumed
  THREE_QUARTERS,   // 75% of daily calories consumed
  ALMOST_COMPLETE,  // 90% of daily calories consumed
  COMPLETED,        // 100%+ of daily calories consumed
}

/// Extension to provide helper methods for SuggestionMilestone
extension SuggestionMilestoneExtension on SuggestionMilestone {
  String get displayName {
    switch (this) {
      case SuggestionMilestone.START:
        return 'Breakfast';
      case SuggestionMilestone.QUARTER:
        return 'Mid-morning Snack';
      case SuggestionMilestone.HALF:
        return 'Lunch';
      case SuggestionMilestone.THREE_QUARTERS:
        return 'Dinner';
      case SuggestionMilestone.ALMOST_COMPLETE:
        return 'Evening Snack';
      case SuggestionMilestone.COMPLETED:
        return 'Ultra-Low Calorie Option';
    }
  }
  
  /// Get the milestone based on percentage of calories consumed
  static SuggestionMilestone fromPercentage(double percentage) {
    if (percentage < 0.1) {
      return SuggestionMilestone.START;
    } else if (percentage < 0.35) {
      return SuggestionMilestone.QUARTER;
    } else if (percentage < 0.6) {
      return SuggestionMilestone.HALF;
    } else if (percentage < 0.85) {
      return SuggestionMilestone.THREE_QUARTERS;
    } else if (percentage < 1.0) {
      return SuggestionMilestone.ALMOST_COMPLETE;
    } else {
      return SuggestionMilestone.COMPLETED;
    }
  }
  
  /// Convert the enum to a string for API requests
  String toApiString() {
    return toString().split('.').last;
  }
}

/// Model class for food suggestion details
class FoodSuggestion {
  final String id;
  final String title;
  final String image;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  
  // Additional fields
  final String? sourceUrl;
  final int? readyInMinutes;
  final int? servings;
  final String? explanation;
  final bool isSimpleIngredient;  // Flag to distinguish between recipes and simple ingredients
  
  FoodSuggestion({
    required this.id,
    required this.title,
    required this.image,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.sourceUrl,
    this.readyInMinutes,
    this.servings,
    this.explanation,
    this.isSimpleIngredient = false,
  });
  
  /// Create a FoodSuggestion from a map (API or Firestore)
  factory FoodSuggestion.fromMap(Map<String, dynamic> map) {
    return FoodSuggestion(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      image: map['image'] ?? '',
      calories: (map['calories'] ?? 0),
      protein: (map['protein'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      fat: (map['fat'] ?? 0).toDouble(),
      sourceUrl: map['sourceUrl'],
      readyInMinutes: map['readyInMinutes'],
      servings: map['servings'],
      explanation: map['explanation'],
      isSimpleIngredient: map['isSimpleIngredient'] ?? false,
    );
  }
  
  /// Convert the food suggestion to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'sourceUrl': sourceUrl,
      'readyInMinutes': readyInMinutes,
      'servings': servings,
      'explanation': explanation,
      'isSimpleIngredient': isSimpleIngredient,
    };
  }
}

/// Model representing a collection of food suggestions for a milestone
class MilestoneSuggestions {
  final SuggestionMilestone milestone;
  final List<FoodSuggestion> suggestions;
  final DateTime generatedAt;
  
  MilestoneSuggestions({
    required this.milestone,
    required this.suggestions,
    required this.generatedAt,
  });
  
  /// Create MilestoneSuggestions from Firestore data
  factory MilestoneSuggestions.fromFirestore(Map<String, dynamic> data, SuggestionMilestone milestone) {
    final List<dynamic> suggestionsList = data['suggestions'] ?? [];
    final List<FoodSuggestion> suggestions = suggestionsList
        .map((item) => FoodSuggestion.fromMap(item))
        .toList();
    
    return MilestoneSuggestions(
      milestone: milestone,
      suggestions: suggestions,
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
  
  /// Convert the milestone suggestions to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'suggestions': suggestions.map((s) => s.toMap()).toList(),
      'generatedAt': FieldValue.serverTimestamp(),
    };
  }
  
  /// Check if the suggestions are stale (older than a certain time period)
  bool isStale({Duration stalePeriod = const Duration(hours: 12)}) {
    final now = DateTime.now();
    return now.difference(generatedAt) > stalePeriod;
  }
}