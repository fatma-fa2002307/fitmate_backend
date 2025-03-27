import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/models/food_suggestion.dart';
import 'package:fitmate/services/food_suggestion_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NutritionViewModel with ChangeNotifier {
  // Services
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final EnhancedFoodSuggestionService _foodSuggestionService =
      EnhancedFoodSuggestionService();

  // State
  bool _isLoading = true;
  bool _isRetrying = false;  // New state for retry operation
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

  // Getters
  bool get isLoading => _isLoading;
  bool get isRetrying => _isRetrying;  // New getter for retry state
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
    await _loadUserData();
    await _loadFoodLogs();
    _loadFoodSuggestions();

    _isLoading = false;
    notifyListeners();
  }

  // Load user data
  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userData =
          await _firestore.collection('users').doc(user.uid).get();

      if (userData.exists) {
        _userGoal = userData['goal'] as String? ?? 'Improve Fitness';

        // Check for user macros in Firebase
        bool macrosExist = await _checkMacrosExist(user.uid);

        if (macrosExist) {
          // Load macros from Firebase
          _dailyMacros = await _getUserMacros(user.uid);
        } else {
          // Calculate and save macros
          _dailyMacros = await _calculateAndSaveMacros(
              userData['gender'] as String? ?? 'Male',
              (userData['weight'] as num?)?.toDouble() ?? 70.0,
              (userData['height'] as num?)?.toDouble() ?? 170.0,
              userData['age'] as int? ?? 30,
              _userGoal,
              userData['workoutDays'] as int? ?? 3);
        }
      }
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
    // Calculate BMR
    double bmr = _calculateBMR(gender, weight, height, age);

    // Calculate macros based on BMR, goal, and workout days
    Map<String, double> macros =
        _calculateMacronutrients(goal, bmr, workoutDays);

    // Save calculated macros to Firestore
    await _saveMacros(macros);

    return macros;
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
    double cal = 0;
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
      cal = (bmr * multiplier) - 300;
    } else {
      cal = bmr * multiplier;
    }
    return cal;
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
  }

  // Load food logs for selected date
  Future<void> _loadFoodLogs() async {
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
        _totalCalories += food['calories'] ?? 0;
        _totalCarbs += food['carbs'] ?? 0;
        _totalProtein += food['protein'] ?? 0;
        _totalFat += food['fat'] ?? 0;
      }

      notifyListeners();
    }
  }

  // Load food suggestions with retry functionality
  Future<void> _loadFoodSuggestions() async {
    setState(() {
      _suggestionsLoading = true;
      _suggestionsError = '';
    });

    try {
      // Calculate current milestone
      final percentage = _totalCalories / (_dailyMacros['calories'] ?? 2000);
      _currentMilestone =
          SuggestionMilestoneExtension.fromPercentage(percentage);

      // Get suggestions from the enhanced service
      final suggestions =
          await _foodSuggestionService.getSuggestionsForCurrentMilestone(
        totalCalories: _dailyMacros['calories'] ?? 2000,
        consumedCalories: _totalCalories,
        goal: _userGoal,
      );

      _suggestions = suggestions;
      _suggestionsLoading = false;
      _currentSuggestionIndex = 0;
      notifyListeners();
    } catch (e) {
      _suggestionsError = 'Unable to load suggestions. Tap to retry.';
      _suggestionsLoading = false;
      notifyListeners();
      print('Error loading suggestions: $e');
    }
  }

  // Retry loading food suggestions
  Future<void> retryLoadFoodSuggestions() async {
    setState(() {
      _isRetrying = true;
      _suggestionsLoading = true;
      _suggestionsError = '';
    });

    try {
      // Calculate current milestone
      final percentage = _totalCalories / (_dailyMacros['calories'] ?? 2000);
      _currentMilestone =
          SuggestionMilestoneExtension.fromPercentage(percentage);

      // Get suggestions from the enhanced service
      final suggestions =
          await _foodSuggestionService.getSuggestionsForCurrentMilestone(
        totalCalories: _dailyMacros['calories'] ?? 2000,
        consumedCalories: _totalCalories,
        goal: _userGoal,
      );

      _suggestions = suggestions;
      _suggestionsError = '';
      _currentSuggestionIndex = 0;
    } catch (e) {
      _suggestionsError = 'Unable to load suggestions. Tap to retry.';
      print('Error retrying food suggestions: $e');
    } finally {
      setState(() {
        _suggestionsLoading = false;
        _isRetrying = false;
      });
    }
  }

  // Handle like/dislike of food suggestion
  Future<void> handleFoodPreference(bool isLike) async {
    if (_suggestions.isEmpty) return;

    // Get current suggestion
    final suggestion = _suggestions[_currentSuggestionIndex];

    // Call service to update preference
    await _foodSuggestionService.rateSuggestion(suggestion.id, isLike);

    // Move to next suggestion if available
    if (_suggestions.length > 1) {
      _currentSuggestionIndex =
          (_currentSuggestionIndex + 1) % _suggestions.length;
      notifyListeners();
    }
  }

  // Select different date
  void selectDate(DateTime date) {
    _selectedDate = date;
    _loadFoodLogs();
  }

  // Navigate to previous day
  void previousDay() {
    selectDate(_selectedDate.subtract(const Duration(days: 1)));
  }

  // Navigate to next day
  void nextDay() {
    if (!isToday) {
      selectDate(_selectedDate.add(const Duration(days: 1)));
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
      }
    } catch (e) {
      print('Error deleting food: $e');
    }
  }

  // Helper method for setState with notifyListeners
  void setState(Function function) {
    function();
    notifyListeners();
  }
}