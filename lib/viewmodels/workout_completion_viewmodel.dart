import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/services/workout_service.dart';
import 'package:fitmate/viewmodels/base_viewmodel.dart';

class WorkoutCompletionViewModel extends BaseViewModel {
  final WorkoutRepository _repository;
  final WorkoutService _workoutService;
  
  // Workout completion data
  final int completedExercises;
  final int totalExercises;
  final String duration;
  final String category;
  
  // Getters
  double get completionRatio => 
      totalExercises > 0 ? (completedExercises / totalExercises).clamp(0.0, 1.0) : 0.0;
  
  WorkoutCompletionViewModel({
    required WorkoutRepository repository,
    required WorkoutService workoutService,
    required this.completedExercises,
    required this.totalExercises,
    required this.duration,
    required this.category,
  }) : _repository = repository,
       _workoutService = workoutService;
  
  @override
  Future<void> init() async {
    try {
      //mark workout complete in Firebase
      await _updateWorkoutHistory();
      //gen next workout options in the background
      _generateNextWorkoutOptions();
    } catch (e) {
      setError("Error finalizing workout: $e");
    }
  }
  
  ///update workout history in Firestore
  Future<void> _updateWorkoutHistory() async {
    try {
      // We don't need to do anything here because the workout was already recorded
      // by either ActiveWorkoutViewModel or CardioWorkoutViewModel
      // This is just in case additional logic needs to be added later
    } catch (e) {
      print("Error updating workout history: $e");
      throw e;
    }
  }
  
  ///gen next workout options in background
  Future<void> _generateNextWorkoutOptions() async {
    try {
      // Get user data needed for workout generation
      final userData = await _repository.getUserWorkoutData();
      if (userData == null) return;
      
      //extract and convert types
      final int age = userData['age'] is int ? userData['age'] : 30;
      final String gender = userData['gender'] is String ? userData['gender'] : 'Male';
      final double height = userData['height'] is num ? (userData['height'] as num).toDouble() : 170.0;
      final double weight = userData['weight'] is num ? (userData['weight'] as num).toDouble() : 70.0;
      final String goal = userData['goal'] is String ? userData['goal'] : 'Improve Fitness';
      final int workoutDays = userData['workoutDays'] is int ? userData['workoutDays'] : 3;
      final String fitnessLevel = userData['fitnessLevel'] is String ? userData['fitnessLevel'] : 'Beginner';
      
      //generate in the background
      await WorkoutService.generateAndSaveWorkoutOptions(
        age: age,
        gender: gender,
        height: height,
        weight: weight,
        goal: goal,
        workoutDays: workoutDays,
        fitnessLevel: fitnessLevel,
        lastWorkoutCategory: category, //use just-completed workout category
      );
    } catch (e) {
      print("Error generating next workout options: $e");
    }
  }
}