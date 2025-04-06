import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/models/food_suggestion.dart';
import 'package:fitmate/services/food_suggestion_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NutritionViewModel with ChangeNotifier {
  // Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EnhancedFoodSuggestionService _foodSuggestionService =
      EnhancedFoodSuggestionService();

  // State
  bool _isLoading = true;
  bool _isRetrying = false;
  List<Map<String, dynamic>> _todaysFoodLogs = [];
  DateTime _selectedDate = DateTime.now();
  double _totalCalories = 0;
  double _totalCarbs = 0;
  double _totalProtein = 0;
  double _totalFat = 0;
  Map<String, double> _dailyMacros = {};
  String _userGoal = '';

  // Food suggestions state
  List<FoodSuggestion> _suggestions = [];
  bool _suggestionsLoading = true;
  String _suggestionsError = '';
  int _currentSuggestionIndex = 0;
  SuggestionMilestone _currentMilestone = SuggestionMilestone.START;
  
  // Flag to track if suggestions were loaded in the current session
  bool _suggestionsLoaded = false;
  // Timestamp for when suggestions were last loaded
  DateTime? _suggestionsLoadedTime;
  // Duration after which suggestions should be considered stale (e.g., 4 hours)
  final Duration _suggestionStaleDuration = const Duration(hours: 4);

  // Getters
  bool get isLoading => _isLoading;
  bool get isRetrying => _isRetrying;
  List<Map<String, dynamic>> get todaysFoodLogs => _todaysFoodLogs;
  DateTime get selectedDate => _selectedDate;
  double get totalCalories => _totalCalories;
  double get totalCarbs => _totalCarbs;
  double get totalProtein => _totalProtein;
  double get totalFat => _totalFat;
  Map<String, double> get dailyMacros => _dailyMacros;
  String get userGoal => _userGoal;

  List<FoodSuggestion> get suggestions => _suggestions;
  bool get suggestionsLoading => _suggestionsLoading;
  String get suggestionsError => _suggestionsError;
  int get currentSuggestionIndex => _currentSuggestionIndex;
  SuggestionMilestone get currentMilestone => _currentMilestone;
  
  // New getter to check if suggestions are from cache
  bool get areSuggestionsCached => _suggestionsLoaded && _suggestionsLoadedTime != null;

  // Calculated properties
  double get caloriePercentage => (_dailyMacros['calories'] ?? 2000) > 0
      ? (_totalCalories / (_dailyMacros['calories'] ?? 2000))
      : 0.0;

  double get proteinPercentage => (_dailyMacros['protein'] ?? 150) > 0
      ? (_totalProtein / (_dailyMacros['protein'] ?? 150))
      : 0.0;

  double get carbsPercentage => (_dailyMacros['carbs'] ?? 225) > 0
      ? (_totalCarbs / (_dailyMacros['carbs'] ?? 225))
      : 0.0;

  double get fatPercentage => (_dailyMacros['fat'] ?? 65) > 0
      ? (_totalFat / (_dailyMacros['fat'] ?? 65))
      : 0.0;

  bool get isToday =>
      _selectedDate.year == DateTime.now().year &&
          _selectedDate.month == DateTime.now().month &&
          _selectedDate.day == DateTime.now().day;

  String get formattedDate =>
      isToday ? 'Today' : DateFormat('EEEE, MMMM d').format(_selectedDate);

  // Initialize ViewModel
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load essential data first
      await _loadUserData();
      await _loadFoodLogs();

      // Now that essential data is loaded, set isLoading to false
      // This allows the main UI to render while food suggestions are still loading
      _isLoading = false;
      notifyListeners();

      // Then start loading food suggestions separately if needed
      // This will only affect the food suggestions part of the UI
      if (isToday) {
        // Calculate the new milestone
        SuggestionMilestone newMilestone = 
            SuggestionMilestoneExtension.fromPercentage(caloriePercentage);
        
        // Determine if we need to load new suggestions
        bool needsNewSuggestions = false;
        
        // Check if we have cached suggestions
        if (_suggestions.isEmpty || !_suggestionsLoaded) {
          // We have no suggestions or they weren't loaded this session
          needsNewSuggestions = true;
        } else if (newMilestone != _currentMilestone) {
          // Milestone has changed, load new suggestions
          needsNewSuggestions = true;
        } else if (_suggestionsLoadedTime != null) {
          // Check if suggestions are stale (older than staleDuration)
          DateTime now = DateTime.now();
          if (now.difference(_suggestionsLoadedTime!) > _suggestionStaleDuration) {
            needsNewSuggestions = true;
          }
        }
        
        if (needsNewSuggestions) {
          await _loadFoodSuggestions();
        } else {
          // Use existing suggestions but update loading state
          _suggestionsLoading = false;
          notifyListeners();
        }
      } else {
        _suggestionsLoading = false;
        _suggestions = [];
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      print('Error in init: $e');
      notifyListeners();
    }
  }

  // Load user data
  Future<void> _loadUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userData =
        await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;
          _userGoal = data['goal'] as String? ?? 'Improve Fitness';

          // Check for user macros in Firebase
          bool macrosExist = await _checkMacrosExist(user.uid);

          if (macrosExist) {
            // Load macros from Firebase
            _dailyMacros = await _getUserMacros(user.uid);
          } else {
            // Calculate and save macros
            _dailyMacros = await _calculateAndSaveMacros(
                data['gender'] as String? ?? 'Male',
                (data['weight'] as num?)?.toDouble() ?? 70.0,
                (data['height'] as num?)?.toDouble() ?? 170.0,
                data['age'] as int? ?? 30,
                _userGoal,
                data['workoutDays'] as int? ?? 3);
          }
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Set default macros in case of error
      _dailyMacros = {
        'calories': 2000.0,
        'carbs': 225.0,
        'protein': 150.0,
        'fat': 65.0,
      };
    }
  }

  // Check if user macros exist in Firestore
  Future<bool> _checkMacrosExist(String userId) async {
    try {
      DocumentSnapshot docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('userMacros')
          .doc('macro')
          .get();

      return docSnapshot.exists;
    } catch (e) {
      print('Error checking if user macros exist: $e');
      return false;
    }
  }

  // Get user macros from Firestore
  Future<Map<String, double>> _getUserMacros(String userId) async {
    try {
      DocumentSnapshot docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('userMacros')
          .doc('macro')
          .get();

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        return {
          'calories': (data['calories'] ?? 0).toDouble(),
          'carbs': (data['carbs'] ?? 0).toDouble(),
          'protein': (data['protein'] ?? 0).toDouble(),
          'fat': (data['fat'] ?? 0).toDouble(),
        };
      }
    } catch (e) {
      print('Error getting user macros: $e');
    }

    // Default values if fetch fails
    return {
      'calories': 2000.0,
      'carbs': 225.0,
      'protein': 150.0,
      'fat': 65.0,
    };
  }

  // Calculate and save user macros
  Future<Map<String, double>> _calculateAndSaveMacros(
      String gender,
      double weight,
      double height,
      int age,
      String goal,
      int workoutDays) async {
    try {
      // Calculate BMR
      double bmr = _calculateBMR(gender, weight, height, age);

      // Calculate macros based on BMR, goal, and workout days
      Map<String, double> macros =
      _calculateMacronutrients(goal, bmr, workoutDays);

      // Save calculated macros to Firestore
      await _saveMacros(macros);

      return macros;
    } catch (e) {
      print('Error calculating and saving macros: $e');
      // Return default values if calculation fails
      return {
        'calories': 2000.0,
        'carbs': 225.0,
        'protein': 150.0,
        'fat': 65.0,
      };
    }
  }

  // BMR calculation helper method
  double _calculateBMR(String gender, double weight, double height, int age) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // TDEE calculation helper method
  double _calculateTDEE(double bmr, int workoutDays, String goal) {
    double multiplier;
    if (workoutDays == 1) {
      multiplier = 1.2;
    } else if (workoutDays >= 2 && workoutDays <= 3) {
      multiplier = 1.3;
    } else if (workoutDays >= 4 && workoutDays <= 5) {
      multiplier = 1.5;
    } else {
      multiplier = 1.9;
    }

    if (goal == 'Weight Loss') {
      return (bmr * multiplier) - 300;
    } else {
      return bmr * multiplier;
    }
  }

  // Macronutrients calculation helper method
  Map<String, double> _calculateMacronutrients(
      String goal, double bmr, int workoutDays) {
    double tdee = _calculateTDEE(bmr, workoutDays, goal);
    Map<String, double> macros = {};

    switch (goal) {
      case 'Weight Loss':
        macros = {
          'calories': tdee,
          'carbs': (tdee * 0.45) / 4,
          'protein': (tdee * 0.30) / 4,
          'fat': (tdee * 0.25) / 9,
        };
        break;
      case 'Gain Muscle':
        macros = {
          'calories': tdee,
          'carbs': (tdee * 0.45) / 4,
          'protein': (tdee * 0.35) / 4,
          'fat': (tdee * 0.20) / 9,
        };
        break;
      case 'Improve Fitness':
      default:
        macros = {
          'calories': tdee,
          'carbs': (tdee * 0.60) / 4,
          'protein': (tdee * 0.15) / 4,
          'fat': (tdee * 0.25) / 9,
        };
        break;
    }
    return macros;
  }

  // Save macros to Firestore
  Future<void> _saveMacros(Map<String, double> macros) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('userMacros')
          .doc('macro')
          .set({
        'calories': macros['calories'] ?? 0,
        'carbs': macros['carbs'] ?? 0,
        'protein': macros['protein'] ?? 0,
        'fat': macros['fat'] ?? 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving macros: $e');
    }
  }

  // Load food logs for selected date
  Future<void> _loadFoodLogs() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Create date range for selected date
        DateTime startDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        DateTime endDate = startDate.add(const Duration(days: 1));

        QuerySnapshot foodLogs = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('foodLogs')
            .where('date', isGreaterThanOrEqualTo: startDate)
            .where('date', isLessThan: endDate)
            .orderBy('date', descending: true)
            .get();

        _todaysFoodLogs = foodLogs.docs
            .map((doc) => {
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        })
            .toList();

        // Reset totals
        _totalCalories = 0;
        _totalCarbs = 0;
        _totalProtein = 0;
        _totalFat = 0;

        // Calculate totals
        for (var food in _todaysFoodLogs) {
          _totalCalories += (food['calories'] as num?)?.toDouble() ?? 0;
          _totalCarbs += (food['carbs'] as num?)?.toDouble() ?? 0;
          _totalProtein += (food['protein'] as num?)?.toDouble() ?? 0;
          _totalFat += (food['fat'] as num?)?.toDouble() ?? 0;
        }
      }
    } catch (e) {
      print('Error loading food logs: $e');
      _todaysFoodLogs = [];
    }
  }

  // Load food suggestions with retry functionality
  Future<void> _loadFoodSuggestions() async {
    _suggestionsLoading = true;
    _suggestionsError = '';
    notifyListeners();

    try {
      // Calculate current milestone
      final percentage = _totalCalories / (_dailyMacros['calories'] ?? 2000);
      _currentMilestone = SuggestionMilestoneExtension.fromPercentage(percentage);

      // First check if we have cached suggestions for this milestone in SharedPreferences
      bool usedCache = await _loadCachedSuggestions(_currentMilestone);

      if (!usedCache) {
        // Get suggestions from the enhanced service
        final suggestions = await _foodSuggestionService.getSuggestionsForCurrentMilestone(
          totalCalories: _dailyMacros['calories'] ?? 2000,
          consumedCalories: _totalCalories,
          goal: _userGoal,
        );

        _suggestions = suggestions;
        
        // Cache the suggestions for future use
        await _cacheSuggestions(suggestions, _currentMilestone);
      }
      
      // Reset current index when loading new suggestions
      _currentSuggestionIndex = 0;
      
      // Mark suggestions as loaded in this session
      _suggestionsLoaded = true;
      _suggestionsLoadedTime = DateTime.now();
      
      _suggestionsLoading = false;
      notifyListeners();
    } catch (e) {
      _suggestionsError = 'Unable to load suggestions. Tap to retry.';
      _suggestionsLoading = false;
      notifyListeners();
      print('Error loading suggestions: $e');
    }
  }

  // Cache suggestions in SharedPreferences
  Future<void> _cacheSuggestions(List<FoodSuggestion> suggestions, SuggestionMilestone milestone) async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();
      
      // Convert suggestions to JSON
      final suggestionsJson = suggestions.map((s) => {
        'id': s.id,
        'title': s.title,
        'image': s.image,
        'calories': s.calories,
        'protein': s.protein,
        'carbs': s.carbs,
        'fat': s.fat,
        'sourceUrl': s.sourceUrl,
        'readyInMinutes': s.readyInMinutes,
        'servings': s.servings,
        'explanation': s.explanation,
        'foodType': s.foodType,
      }).toList();
      
      // Save to SharedPreferences with milestone and timestamp
      final cacheData = {
        'milestone': milestone.toString(),
        'suggestions': suggestionsJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      // Convert to JSON string and save
      final cacheString = jsonEncode(cacheData);
      await prefs.setString('cached_food_suggestions', cacheString);
      
      print('Cached ${suggestions.length} suggestions for milestone: ${milestone.name}');
    } catch (e) {
      print('Error caching suggestions: $e');
    }
  }
  
  // Load cached suggestions from SharedPreferences
  Future<bool> _loadCachedSuggestions(SuggestionMilestone currentMilestone) async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();
      
      // Get cached data
      final cacheString = prefs.getString('cached_food_suggestions');
      if (cacheString == null) {
        return false;
      }
      
      // Parse JSON
      final cacheData = jsonDecode(cacheString);
      
      // Check if milestone matches
      final cachedMilestone = cacheData['milestone'] as String;
      if (cachedMilestone != currentMilestone.toString()) {
        return false;
      }
      
      // Check if cache is stale
      final timestamp = cacheData['timestamp'] as int;
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      if (DateTime.now().difference(cacheTime) > _suggestionStaleDuration) {
        return false;
      }
      
      // Convert JSON to suggestions
      final suggestionsJson = cacheData['suggestions'] as List;
      _suggestions = suggestionsJson.map((json) {
        return FoodSuggestion(
          id: json['id'],
          title: json['title'],
          image: json['image'],
          calories: json['calories'],
          protein: json['protein'],
          carbs: json['carbs'],
          fat: json['fat'],
          sourceUrl: json['sourceUrl'],
          readyInMinutes: json['readyInMinutes'],
          servings: json['servings'],
          explanation: json['explanation'],
          foodType: json['foodType'],
        );
      }).toList();
      
      // Mark as loaded from cache
      _suggestionsLoaded = true;
      _suggestionsLoadedTime = cacheTime;
      
      print('Loaded ${_suggestions.length} suggestions from cache for milestone: ${currentMilestone.name}');
      return true;
    } catch (e) {
      print('Error loading cached suggestions: $e');
      return false;
    }
  }

  // Force reload food suggestions (for user-initiated refresh)
  Future<void> forceFoodSuggestionsRefresh() async {
    if (!isToday) return;
    
    _suggestionsLoaded = false;
    await _loadFoodSuggestions();
  }

  // Retry loading food suggestions
  Future<void> retryLoadFoodSuggestions() async {
    if (!isToday) return;

    _isRetrying = true;
    _suggestionsLoading = true;
    _suggestionsError = '';
    notifyListeners();

    try {
      // Calculate current milestone
      final percentage = _totalCalories / (_dailyMacros['calories'] ?? 2000);
      _currentMilestone = SuggestionMilestoneExtension.fromPercentage(percentage);

      // Get suggestions from the enhanced service
      final suggestions = await _foodSuggestionService.getSuggestionsForCurrentMilestone(
        totalCalories: _dailyMacros['calories'] ?? 2000,
        consumedCalories: _totalCalories,
        goal: _userGoal,
      );

      _suggestions = suggestions;
      _suggestionsError = '';
      _currentSuggestionIndex = 0;
      
      // Update cache with new suggestions
      await _cacheSuggestions(suggestions, _currentMilestone);
      
      // Mark as loaded
      _suggestionsLoaded = true;
      _suggestionsLoadedTime = DateTime.now();
    } catch (e) {
      _suggestionsError = 'Unable to load suggestions. Tap to retry.';
      print('Error retrying food suggestions: $e');
    } finally {
      _suggestionsLoading = false;
      _isRetrying = false;
      notifyListeners();
    }
  }

  // Handle like/dislike of food suggestion
  Future<void> handleFoodPreference(bool isLike) async {
    try {
      if (_suggestions.isEmpty) return;

      // Get current suggestion
      final suggestion = _suggestions[_currentSuggestionIndex];

      // Call service to update preference
      await _foodSuggestionService.rateSuggestion(suggestion.id, isLike);

      // Move to next suggestion if available
      if (_suggestions.length > 1) {
        _currentSuggestionIndex = (_currentSuggestionIndex + 1) % _suggestions.length;
        notifyListeners();
      }
    } catch (e) {
      print('Error handling food preference: $e');
    }
  }

  // Select different date
  Future<void> selectDate(DateTime date) async {
    _selectedDate = date;
    await _loadFoodLogs();

    // Only load suggestions for the current day
    if (isToday) {
      // Calculate the new milestone
      SuggestionMilestone newMilestone = 
          SuggestionMilestoneExtension.fromPercentage(caloriePercentage);
      
      // If milestone changed or we don't have suggestions, load new ones
      if (newMilestone != _currentMilestone || _suggestions.isEmpty || !_suggestionsLoaded) {
        await _loadFoodSuggestions();
      } else {
        // Otherwise, just notify UI update with existing suggestions
        notifyListeners();
      }
    } else {
      _suggestions = [];
      _suggestionsLoading = false;
      notifyListeners();
    }
  }

  // Navigate to previous day
  Future<void> previousDay() async {
    await selectDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  // Navigate to next day
  Future<void> nextDay() async {
    if (!isToday) {
      await selectDate(_selectedDate.add(const Duration(days: 1)));
    }
  }

  // Delete a food log entry
  Future<void> deleteFood(String foodId) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('foodLogs')
            .doc(foodId)
            .delete();

        await _loadFoodLogs();

        // Reload suggestions if we're on today and milestone changed
        if (isToday) {
          // Calculate the new milestone after food deletion
          SuggestionMilestone newMilestone = 
              SuggestionMilestoneExtension.fromPercentage(caloriePercentage);
          
          // If milestone changed, reload suggestions
          if (newMilestone != _currentMilestone) {
            await _loadFoodSuggestions();
          } else {
            // Otherwise just notify UI update
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error deleting food: $e');
    }
  }
}