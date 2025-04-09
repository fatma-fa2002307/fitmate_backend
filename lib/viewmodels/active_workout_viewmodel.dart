import 'dart:async';
import 'package:fitmate/models/workout.dart';
import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/viewmodels/base_viewmodel.dart';
import 'package:fitmate/services/api_service.dart';


class ActiveWorkoutViewModel extends BaseViewModel {
  final WorkoutRepository _repository;
  final List<WorkoutExercise> workouts;
  final String category;
  
  // State
  int _elapsedSeconds = 0;
  Timer? _timer;
  List<bool> _completedExercises = [];
  double _progress = 0.0;
  bool _isPaused = false;
  
  // Getters
  int get elapsedSeconds => _elapsedSeconds;
  List<bool> get completedExercises => List.unmodifiable(_completedExercises);
  double get progress => _progress;
  bool get isPaused => _isPaused;
  int get completedCount => _completedExercises.where((done) => done).length;
  
  ActiveWorkoutViewModel({
    required WorkoutRepository repository,
    required this.workouts,
    required this.category,
  }) : _repository = repository {
    _completedExercises = List.generate(workouts.length, (_) => false);
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  ///start or resumes workout timer
  void startTimer() {
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _elapsedSeconds++;
        notifyListenersSafely();
      }
    });
    notifyListenersSafely();
  }

  ///pause workout timer
  void pauseTimer() {
    _isPaused = true;
    notifyListenersSafely();
  }
  
  ///resume workout timer
  void resumeTimer() {
    _isPaused = false;
    notifyListenersSafely();
  }
  
  ///toggles the pause of the timer
  void togglePause() {
    _isPaused = !_isPaused;
    notifyListenersSafely();
  }
  
  ///formats  elapsed time as mm:ss
  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  
  ///toggle for completion state of an exercise
  void toggleExerciseCompletion(int index) {
    if (index >= 0 && index < _completedExercises.length) {
      _completedExercises[index] = !_completedExercises[index];
      _updateProgress();
      notifyListenersSafely();
    }
  }
  
  ///update  overall progress based on completed exercises
  void _updateProgress() {
    _progress = completedCount / workouts.length;
  }
  
  ///complete workout and record it
  Future<bool> completeWorkout() async {
    _timer?.cancel();

    try {
      // Create a list of performed and not performed exercises
      List<Map<String, dynamic>> performedExercises = [];
      List<Map<String, dynamic>> notPerformedExercises = [];

      // Populate the lists based on completion state
      for (int i = 0; i < workouts.length; i++) {
        Map<String, dynamic> exerciseData = {
          'name': workouts[i].workout,
          'sets': workouts[i].sets,
          'reps': workouts[i].reps,
        };

        if (_completedExercises[i]) {
          performedExercises.add(exerciseData);
        } else {
          notPerformedExercises.add(exerciseData);
        }
      }

      await _repository.recordCompletedWorkout(
        category: category,
        completedExercises: completedCount,
        totalExercises: workouts.length,
        duration: formatTime(_elapsedSeconds),
        performedExercises: performedExercises,
        notPerformedExercises: notPerformedExercises,
      );
      return true;
    } catch (e) {
      setError("Failed to record workout: $e");
      return false;
    }
  }
  /// Get the full image URL for an exercise
  String getExerciseImageUrl(WorkoutExercise workout) {
    return ApiService.getWorkoutImageUrl(
      '/workout-images/${workout.workout.replaceAll(' ', '-')}.webp'
    );
  }
}