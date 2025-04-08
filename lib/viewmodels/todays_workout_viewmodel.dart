import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/models/workout.dart';
import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/services/workout_service.dart';
import 'package:fitmate/viewmodels/base_viewmodel.dart';

class TodaysWorkoutViewModel extends BaseViewModel {
  final WorkoutRepository _repository;
  final WorkoutService _workoutService;
  
  // State
  WorkoutOptions? _workoutOptions;
  int _currentPage = 0;
  bool _isRetrying = false;
  bool _hasRetriedAfterError = false;
  int _retryCount = 0;
  String _workoutCategory = '';
  bool _isCardioWorkout = false;
  final int _maxRetries = 5;
  
  // Loading messages for better UX
  final List<String> _loadingMessages = [
    'Getting your workout ready...',
    'Creating your personalized plan...',
    'Almost there...',
    'Putting together your exercises...',
    'Final touches on your workout...',
  ];
  
  String _statusMessage = 'Getting your workout ready...';
  
  // Getters
  WorkoutOptions? get workoutOptions => _workoutOptions;
  int get currentPage => _currentPage;
  bool get isRetrying => _isRetrying;
  String get statusMessage => _statusMessage;
  bool get hasError => errorMessage.isNotEmpty;
  String get workoutCategory => _workoutCategory;
  bool get isCardioWorkout => _isCardioWorkout;
  
  List<List<WorkoutExercise>> get workoutOptionsList {
    if (_workoutOptions == null) return [];
    return _workoutOptions!.options;
  }
  
  //constructor with dependency injection
  TodaysWorkoutViewModel({
    required WorkoutRepository repository,
    required WorkoutService workoutService,
  }) : _repository = repository,
       _workoutService = workoutService;
  
  @override
  Future<void> init() async {
    setLoading(true);
    setError(''); // Clear any previous errors
    _statusMessage = 'Getting your workout ready...';
    _currentPage = 0;
    
    try {
      await _loadWorkoutOptions();
    } catch (e) {
      // We still want to set loading to false here even on error
      setError("Failed to load workout options: $e");
      setLoading(false);
    }
  }
  
  ///load workout options from repository
  Future<void> _loadWorkoutOptions() async {
    try {
      // Get current user data
      final user = await _repository.getUserWorkoutData();
      if (user == null) {
        setError("Please sign in to view your workouts");
        setLoading(false);
        return;
      }
      
      //check if workout generation is already in progress
      Timestamp? lastGenerated = user['workoutsLastGenerated'] as Timestamp?;
      bool recentlyGenerated = false;
      
      if (lastGenerated != null) {
        DateTime lastGeneratedTime = lastGenerated.toDate();
        DateTime now = DateTime.now();
        Duration difference = now.difference(lastGeneratedTime);
        
        //if workout was generated < 20 seconds ago, consider it "in progress"
        if (difference.inSeconds < 20) {
          recentlyGenerated = true;
          await _retryLoadingWorkout(user);
          return;
        }
      }
      
      //get workout options
      final workoutOptionsMap = await _repository.getWorkoutOptions();
      final nextCategory = await _repository.getNextWorkoutCategory();
      
      if (workoutOptionsMap.isNotEmpty && nextCategory != null) {
        _processWorkoutData(workoutOptionsMap, nextCategory);
      } else {
        //no workout options found, generate new ones
        await _generateWorkouts(user);
      }
    } catch (e) {
      throw Exception("Error loading workout options: $e");
    }
  }
  
  ///retry loading workout with progressive delay
  Future<void> _retryLoadingWorkout(Map<String, dynamic> userData) async {
    _isRetrying = true;
    notifyListenersSafely();
    
    for (_retryCount = 0; _retryCount < _maxRetries; _retryCount++) {
      // Update loading message
      _statusMessage = _loadingMessages[_retryCount % _loadingMessages.length];
      notifyListenersSafely();
      
      // Wait with increasing delay between attempts
      await Future.delayed(Duration(seconds: _retryCount + 1));
      
      // Fetch the updated data
      try {
        // Get workout options
        final workoutOptionsMap = await _repository.getWorkoutOptions();
        final nextCategory = await _repository.getNextWorkoutCategory();
        
        if (workoutOptionsMap.isNotEmpty && nextCategory != null) {
          _processWorkoutData(workoutOptionsMap, nextCategory);
          _isRetrying = false;
          return;
        }
      } catch (e) {
        print("Error in retry attempt $_retryCount: $e");
        // Continue to next attempt
      }
    }
    
    // If we get here, all retries failed
    _isRetrying = false;
    setError("We're having trouble creating your workout. Please try again");
    setLoading(false);
  }
  
  ///process workout data w properly typed format
  void _processWorkoutData(Map<String, List<Map<String, dynamic>>> workoutOptionsMap, String nextCategory) {
    List<List<WorkoutExercise>> optionsList = [];
    
    workoutOptionsMap.forEach((key, workoutList) {
      List<WorkoutExercise> exercises = [];
      
      for (var workout in workoutList) {
        exercises.add(WorkoutExercise.fromMap(workout));
      }
      
      optionsList.add(exercises);
    });
    
    _workoutOptions = WorkoutOptions(
      category: nextCategory,
      options: optionsList,
    );
    
    _workoutCategory = nextCategory;
    _isCardioWorkout = nextCategory.toLowerCase() == 'cardio';
    _currentPage = 0;
    
    setLoading(false);
    notifyListenersSafely();
  }
  
  ///gen new workout options
  Future<void> _generateWorkouts(Map<String, dynamic> userData) async {
    try {
      _statusMessage = 'Creating a new workout just for you...';
      notifyListenersSafely();
      
      final int age = userData['age'] is int ? userData['age'] : 30;
      final String gender = userData['gender'] is String ? userData['gender'] : 'Male';
      final double height = userData['height'] is num ? (userData['height'] as num).toDouble() : 170.0;
      final double weight = userData['weight'] is num ? (userData['weight'] as num).toDouble() : 70.0;
      final String goal = userData['goal'] is String ? userData['goal'] : 'Improve Fitness';
      final int workoutDays = userData['workoutDays'] is int ? userData['workoutDays'] : 3;
      final String fitnessLevel = userData['fitnessLevel'] is String ? userData['fitnessLevel'] : 'Beginner';
      final String? lastWorkoutCategory = userData['lastWorkoutCategory'] is String ? userData['lastWorkoutCategory'] : null;
      
      await WorkoutService.generateAndSaveWorkoutOptions(
        age: age,
        gender: gender,
        height: height,
        weight: weight,
        goal: goal,
        workoutDays: workoutDays,
        fitnessLevel: fitnessLevel,
        lastWorkoutCategory: lastWorkoutCategory,
      );
      
      //after generating workouts, retry loading with the new data
      await _retryLoadingWorkout(userData);
    } catch (e) {
      throw Exception("Unable to create your workout. Please try again: $e");
    }
  }
  
  ///update curr workout page
  void setCurrentPage(int page) {
    if (_currentPage != page) {
      _currentPage = page;
      notifyListenersSafely();
    }
  }
  
  ///check if valid workout to start
  bool canStartWorkout() {
    return !isLoading && 
           !hasError && 
           _workoutOptions != null && 
           _currentPage < _workoutOptions!.options.length;
  }
  
  ///get exercises for current selected workout
  List<WorkoutExercise> getCurrentWorkoutExercises() {
    if (!canStartWorkout()) return [];
    return _workoutOptions!.options[_currentPage];
  }
  
  ///start over and reload workout options
  Future<void> reload() async {
    if (isLoading) return;
    
    setLoading(true);
    setError(''); // Clear errors
    _isRetrying = false;
    _hasRetriedAfterError = true;
    _retryCount = 0;
    _statusMessage = 'Generating new workout...';
    notifyListenersSafely();
    
    try {
      // Get current user data
      final user = await _repository.getUserWorkoutData();
      if (user == null) {
        setError("Please sign in to view your workouts");
        setLoading(false);
        return;
      }
      
      // Force new workout generation regardless of cache status
      await _generateWorkouts(user);
    } catch (e) {
      setError("Failed to generate workout: $e");
      setLoading(false);
    }
  }
}