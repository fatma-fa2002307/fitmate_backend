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
  int _retryCount = 0;
  String _workoutCategory = '';
  bool _isCardioWorkout = false;
  final int _maxRetries = 5;
  
  // Timer for cycling through loading messages
  Timer? _messageTimer;
  int _currentMessageIndex = 0;
  
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
    _statusMessage = _loadingMessages[0];
    _currentPage = 0;
    
    // Start cycling messages
    _startMessageCycle();
    
    // Call loadWorkoutOptions without awaiting
    _loadWorkoutOptionsWithoutBlocking();
  }

  // Fire and forget workout loading
  void _loadWorkoutOptionsWithoutBlocking() {
    _loadWorkoutOptions().catchError((e) {
      _stopMessageCycle();
      setError("Failed to load workout options: $e");
      setLoading(false);
    });
  }

  /// Start cycling through loading messages
  void _startMessageCycle() {
    _currentMessageIndex = 0;
    _statusMessage = _loadingMessages[_currentMessageIndex];
    notifyListenersSafely(); // Show first message immediately
    
    // Cancel any existing timer
    _messageTimer?.cancel();
    
    // Create a new timer that changes the message every 3 seconds
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _currentMessageIndex = (_currentMessageIndex + 1) % _loadingMessages.length;
      _statusMessage = _loadingMessages[_currentMessageIndex];
      notifyListenersSafely();
    });
  }

  /// Stop cycling through loading messages
  void _stopMessageCycle() {
    _messageTimer?.cancel();
    _messageTimer = null;
  }

  @override
  void dispose() {
    _stopMessageCycle();
    super.dispose();
  }
    
  
  ///load workout options from repository
  Future<void> _loadWorkoutOptions() async {
    try {
      // Get current user data
      final user = await _repository.getUserWorkoutData();
      if (user == null) {
        _stopMessageCycle();
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
      _stopMessageCycle();
      throw Exception("Error loading workout options: $e");
    }
  }
  
  /// Retry loading workout with progressive delay
  Future<void> _retryLoadingWorkout(Map<String, dynamic> userData) async {
    _isRetrying = true;
    notifyListenersSafely();
    
    for (_retryCount = 0; _retryCount < _maxRetries; _retryCount++) {
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
    _stopMessageCycle();
    _isRetrying = false;
    setError("We're having trouble loading your workout. Please try again");
    setLoading(false);
  }
  
  /// Process workout data w properly typed format
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
    
    // Stop the message cycling now that we have data
    _stopMessageCycle();
    setLoading(false);
    notifyListenersSafely();
  }
  
  /// Generate new workout options
  Future<void> _generateWorkouts(Map<String, dynamic> userData) async {
    try {
      // Keep message cycling running during generation
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
      
      // After generating workouts, retry loading with the new data
      await _retryLoadingWorkout(userData);
    } catch (e) {
      _stopMessageCycle();
      setError("Unable to create your workout. Please try again: $e");
      setLoading(false);
    }
  }
  
  /// Update curr workout page
  void setCurrentPage(int page) {
    if (_currentPage != page) {
      _currentPage = page;
      notifyListenersSafely();
    }
  }
  
  /// Check if valid workout to start
  bool canStartWorkout() {
    return !isLoading && 
           !hasError && 
           _workoutOptions != null && 
           _currentPage < _workoutOptions!.options.length;
  }
  
  /// Get exercises for current selected workout
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
    _retryCount = 0;
    _startMessageCycle(); // Restart the message cycle
    
    // Don't await here to ensure UI updates immediately
    _reloadWorkouts();
  }
  /// Helper method to reload workouts
  Future<void> _reloadWorkouts() async {
    try {
      // Get current user data
      final user = await _repository.getUserWorkoutData();
      if (user == null) {
        _stopMessageCycle();
        setError("Please sign in to view your workouts");
        setLoading(false);
        return;
      }
      
      // Force new workout generation regardless of cache status
      await _generateWorkouts(user);
    } catch (e) {
      _stopMessageCycle();
      setError("Failed to generate workout: $e");
      setLoading(false);
    }
  }
}