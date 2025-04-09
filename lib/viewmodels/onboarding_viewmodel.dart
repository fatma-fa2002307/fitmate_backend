import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitmate/viewmodels/base_viewmodel.dart';

class OnboardingViewModel extends BaseViewModel {
  // State for onboarding flow
  int _age = 16;
  double _weight = 60.0;
  double _height = 170.0;
  String _gender = "Male";
  String _goal = "Weight Loss";
  int _workoutDays = 3;
  bool _isKg = true;
  bool _isCm = true;
  
  // Getters
  int get age => _age;
  double get weight => _weight;
  double get height => _height;
  String get gender => _gender;
  String get goal => _goal;
  int get workoutDays => _workoutDays;
  bool get isKg => _isKg;
  bool get isCm => _isCm;
  
  // Age methods
  void setAge(int age) {
    _age = age;
    notifyListenersSafely();
  }
  
  // Weight methods
  void setWeight(double weight) {
    _weight = weight;
    notifyListenersSafely();
  }
  
  void toggleWeightUnit(bool isKg) {
    if (_isKg == isKg) return;
    
    _isKg = isKg;
    
    // Convert weight based on the unit change
    if (_isKg) {
      // Convert from lbs to kg
      _weight = (_weight / 2.20462).roundToDouble();
    } else {
      // Convert from kg to lbs
      _weight = (_weight * 2.20462).roundToDouble();
    }
    
    notifyListenersSafely();
    _saveUnitPreference();
  }
  
  // Height methods
  void setHeight(double height) {
    _height = height;
    notifyListenersSafely();
  }
  
  void toggleHeightUnit(bool isCm) {
    if (_isCm == isCm) return;
    
    _isCm = isCm;
    
    // Convert height based on the unit change
    if (_isCm) {
      // Convert from feet to cm
      _height = (_height * 30.48).roundToDouble();
    } else {
      // Convert from cm to feet
      _height = (_height / 30.48).roundToDouble();
    }
    
    notifyListenersSafely();
    _saveUnitPreference();
  }
  
  // Gender methods
  void setGender(String gender) {
    _gender = gender;
    notifyListenersSafely();
  }
  
  // Goal methods
  void setGoal(String goal) {
    _goal = goal;
    notifyListenersSafely();
  }
  
  // Workout days methods
  void setWorkoutDays(int days) {
    _workoutDays = days;
    notifyListenersSafely();
  }
  
  // Save unit preferences
  Future<void> _saveUnitPreference() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isKg', _isKg);
      await prefs.setBool('isCm', _isCm);
    } catch (e) {
      print('Error saving unit preferences: $e');
    }
  }
  
  // Load unit preferences
  Future<void> loadUnitPreferences() async {
    setLoading(true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      _isKg = prefs.getBool('isKg') ?? true;
      _isCm = prefs.getBool('isCm') ?? true;
      notifyListenersSafely();
    } catch (e) {
      print('Error loading unit preferences: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Validate user input for height
  bool validateHeightInput(String value) {
    if (_isCm) {
      // Simple validation for cm
      return double.tryParse(value) != null;
    } else {
      // Validate feet and inches format
      List<String> parts = value.split("'");
      if (parts.length != 2) return false;
      int? feet = int.tryParse(parts[0]);
      int? inches = int.tryParse(parts[1]);
      return feet != null && inches != null;
    }
  }
  
  // Calculate metric BMI
  double calculateBMI() {
    // Convert height to meters
    double heightInMeters = (_isCm ? _height : _height * 30.48) / 100;
    // Convert weight to kg
    double weightInKg = _isKg ? _weight : _weight / 2.20462;
    
    if (heightInMeters <= 0) return 0;
    return weightInKg / (heightInMeters * heightInMeters);
  }
  
  // Get BMI category
  String getBMICategory() {
    double bmi = calculateBMI();
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 25) {
      return 'Normal weight';
    } else if (bmi < 30) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }
  
  // Check if all required fields are completed
  bool isOnboardingComplete() {
    return _age > 0 && _weight > 0 && _height > 0 && _gender.isNotEmpty && _goal.isNotEmpty && _workoutDays > 0;
  }
}