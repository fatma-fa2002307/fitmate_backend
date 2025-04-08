import 'package:fitmate/models/workout.dart';
import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/services/workout_service.dart';
import 'package:fitmate/viewmodels/base_viewmodel.dart';

//for main workout screen
class WorkoutViewModel extends BaseViewModel {
  final WorkoutRepository _repository;
  final WorkoutService _workoutService;

  // State
  CompletedWorkout? _lastWorkout;
  List<CompletedWorkout> _workoutHistory = [];
  
  // Getters
  CompletedWorkout? get lastWorkout => _lastWorkout;
  List<CompletedWorkout> get workoutHistory => _workoutHistory;
  double get completionRatio => _lastWorkout != null 
      ? _lastWorkout!.completion.clamp(0.0, 1.0)
      : 0.0;
  String get duration => _lastWorkout?.duration ?? "00:00";

  //constructor with dependency injection
  WorkoutViewModel({
    required WorkoutRepository repository,
    required WorkoutService workoutService,
  }) : _repository = repository,
       _workoutService = workoutService;

  @override
  Future<void> init() async {
    setLoading(true);
    
    try {
      await _loadWorkoutData();
      clearError();
    } catch (e) {
      setError("Failed to load workout data: $e");
    } finally {
      setLoading(false);
    }
  }

  ///load workout data from the repo
  Future<void> _loadWorkoutData() async {
    //fetch th last workout
    final lastWorkoutData = await _repository.getLastWorkout();
    if (lastWorkoutData != null) {
      _lastWorkout = CompletedWorkout.fromMap(lastWorkoutData);
    }
    
    //fetch workout history
    final historyData = await _repository.getWorkoutHistory();
    _workoutHistory = historyData
        .map((workout) => CompletedWorkout.fromMap(workout))
        .toList();
    
    notifyListenersSafely();
  }

  ///Navigate to today's workout (gen new ones if needed)
  Future<bool> navigateToTodaysWorkout() async {
    setLoading(true);
    
    try {
      // Check if valid workout options exist
      bool hasValidOptions = await _repository.hasValidWorkoutOptions();
      
      //gen new workout options
      if (!hasValidOptions) {
        //Get data needed for workout gen
        final userData = await _repository.getUserWorkoutData();
        if (userData == null) {
          setError("Failed to load user data");
          setLoading(false);
          return false;
        }
        
        //extract and convert types
        final int age = userData['age'] is int ? userData['age'] : 30;
        final String gender = userData['gender'] is String ? userData['gender'] : 'Male';
        final double height = userData['height'] is num ? (userData['height'] as num).toDouble() : 170.0;
        final double weight = userData['weight'] is num ? (userData['weight'] as num).toDouble() : 70.0;
        final String goal = userData['goal'] is String ? userData['goal'] : 'Improve Fitness';
        final int workoutDays = userData['workoutDays'] is int ? userData['workoutDays'] : 3;
        final String fitnessLevel = userData['fitnessLevel'] is String ? userData['fitnessLevel'] : 'Beginner';
        final String? lastWorkoutCategory = userData['lastWorkoutCategory'] is String ? userData['lastWorkoutCategory'] : null;
        
        //gen new workout options
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
        
        // Check if generation was successful
        hasValidOptions = await _repository.hasValidWorkoutOptions();
        if (!hasValidOptions) {
          setError("Failed to generate workout options");
          setLoading(false);
          return false;
        }
      }
      
      setLoading(false);
      return true;
    } catch (e) {
      setError("Error preparing today's workout: $e");
      setLoading(false);
      return false;
    }
  }
}