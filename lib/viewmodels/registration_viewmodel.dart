// lib/viewmodels/registration_viewmodel.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/repositories/food_repository.dart';
import 'package:fitmate/services/workout_service.dart';
import 'package:fitmate/viewmodels/base_viewmodel.dart';

class RegistrationViewModel extends BaseViewModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FoodRepository _foodRepository = FoodRepository();
  
  // User data state
  int _age = 16;
  double _weight = 60.0;
  double _height = 170.0;
  String _gender = "Male";
  String _goal = "Weight Loss";
  int _workoutDays = 3;
  bool _isKg = true;
  bool _isCm = true;
  bool _isPasswordVisible = false;
  
  // Easter egg constants
  static const double EASTER_EGG_VALUE = 111.0;
  
  // Getters
  int get age => _age;
  double get weight => _weight;
  double get height => _height;
  String get gender => _gender;
  String get goal => _goal;
  int get workoutDays => _workoutDays;
  bool get isKg => _isKg;
  bool get isCm => _isCm;
  bool get isPasswordVisible => _isPasswordVisible;
  
  // Check if we should show the Easter egg
  bool shouldShowEasterEgg() {
    return _weight == EASTER_EGG_VALUE && _height == EASTER_EGG_VALUE;
  }
  
  // Setters for user data that might come from onboarding
  void setAge(int age) {
    _age = age;
    notifyListenersSafely();
  }
  
  void setWeight(double weight) {
    _weight = weight;
    notifyListenersSafely();
  }
  
  void setHeight(double height) {
    _height = height;
    notifyListenersSafely();
  }
  
  void setGender(String gender) {
    _gender = gender;
    notifyListenersSafely();
  }
  
  void setGoal(String goal) {
    _goal = goal;
    notifyListenersSafely();
  }
  
  void setWorkoutDays(int days) {
    _workoutDays = days;
    notifyListenersSafely();
  }
  
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListenersSafely();
  }
  
  // Register the user with all collected data
  Future<bool> registerUser({
    required String fullName,
    required String email,
    required String password,
  }) async {
    setLoading(true);
    clearError();
    
    try {
      // Convert weight to kg if necessary
      double weightInKg = _isKg ? _weight : _weight / 2.20462;
      
      // Convert height to cm if necessary
      double heightInCm = _isCm ? _height : _height * 30.48;
      
      // Create the user account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      String userId = userCredential.user!.uid;
      
      // Store user data in Firestore
      await _firestore.collection('users').doc(userId).set({
        'fullName': fullName,
        'email': email,
        'age': _age,
        'weight': weightInKg,
        'height': heightInCm,
        'gender': _gender,
        'goal': _goal,
        'workoutDays': _workoutDays,
        'fitnessLevel': 'Beginner',
        'totalWorkouts': 0,
        'workoutsUntilNextLevel': 20,
        'unitPreference': _isKg ? 'metric' : 'imperial',
      });
      
      // Initialize user progress
      await _firestore.collection('users').doc(userId).collection('userProgress').doc('progress').set({
        'fitnessLevel': 'Beginner',
        'fitnessSubLevel': 1,
        'workoutsCompleted': 0,
        'workoutsUntilNextLevel': 20,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Calculate and save user macros
      await _foodRepository.calculateAndSaveUserMacros(
        _gender,
        weightInKg,
        heightInCm,
        _age,
        _goal,
        _workoutDays
      );
      
      // Initialize remaining subcollections
      await _firestore.collection('users').doc(userId).collection('foodLogs').doc('initial').set({});
      await _firestore.collection('users').doc(userId).collection('workoutLogs').doc('initial').set({});
      await _firestore.collection('users').doc(userId).collection('workoutHistory').doc('initial').set({});
      
      // Generate initial workout options in the background
      try {
        WorkoutService.generateAndSaveWorkoutOptions(
          age: _age,
          gender: _gender,
          height: heightInCm,
          weight: weightInKg,
          goal: _goal,
          workoutDays: _workoutDays,
          fitnessLevel: 'Beginner',
          lastWorkoutCategory: null, // No previous workout
        );
      } catch (e) {
        print("Error generating initial workouts: $e");
      }
      
      setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      setError(e.message ?? 'Registration failed');
      setLoading(false);
      return false;
    } catch (e) {
      setError('An unexpected error occurred');
      setLoading(false);
      return false;
    }
  }
}