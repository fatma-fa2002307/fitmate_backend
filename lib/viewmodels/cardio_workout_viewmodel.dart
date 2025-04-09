import 'dart:async';
import 'package:fitmate/models/workout.dart';
import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/viewmodels/base_viewmodel.dart';

class CardioWorkoutViewModel extends BaseViewModel {
  final WorkoutRepository _repository;
  final WorkoutExercise workout;
  final String category;
  
  // State
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _isCompleted = false;
  bool _isPaused = false;
  String _targetDuration = "30 min";  // Default
  int _targetSeconds = 1800;  // Default (30 min * 60)
  double _progress = 0.0;
  
  // Getters
  int get elapsedSeconds => _elapsedSeconds;
  bool get isCompleted => _isCompleted;
  bool get isPaused => _isPaused;
  String get targetDuration => _targetDuration;
  int get targetSeconds => _targetSeconds;
  double get progress => _progress;
  int get remainingSeconds => _targetSeconds - _elapsedSeconds > 0 ? _targetSeconds - _elapsedSeconds : 0;
  
  CardioWorkoutViewModel({
    required WorkoutRepository repository,
    required this.workout,
    required this.category,
  }) : _repository = repository {
    _parseDuration();
  }
  
  @override
  Future<void> init() async {
    await super.init();
    startTimer();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  ///parse duration of workout (e.g., "30 min" to seconds)
  void _parseDuration() {
    String duration = workout.duration ?? "30 min";
    duration = duration.replaceAll(' ', '').toLowerCase();
    
    if (duration.contains('min')) {
      String minValue = duration.replaceAll('min', '');
      try {
        if (minValue.contains('-')) {
          // Handle range like "20-30 min"
          minValue = minValue.split('-').last;
        }
        int minutes = int.parse(minValue);
        _targetSeconds = minutes * 60;
        _targetDuration = "$minutes min";
      } catch (e) {
        // Use default if parsing fails
        _targetSeconds = 1800;
        _targetDuration = "30 min";
      }
    }
    notifyListenersSafely();
  }
  
  ///start or resume  workout timer
  void startTimer() {
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        _elapsedSeconds++;
        _progress = _elapsedSeconds / _targetSeconds;
        
        // Cap progress at 100%
        if (_progress > 1.0) {
          _progress = 1.0;
        }
        
        notifyListenersSafely();
      }
    });
  }
  
  ///pause workout timer
  void pauseTimer() {
    _isPaused = true;
    notifyListenersSafely();
  }
  
  ///resume  workout timer
  void resumeTimer() {
    _isPaused = false;
    notifyListenersSafely();
  }
  
  ///toggles pause state of the timer
  void togglePause() {
    _isPaused = !_isPaused;
    notifyListenersSafely();
  }
  
  ///formats time as mm:ss
  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  ///completes workout and records it
  Future<bool> completeWorkout() async {
    _timer?.cancel();
    _isCompleted = true;

    try {
      // For cardio, we only have one exercise
      List<Map<String, dynamic>> performedExercises = [];
      List<Map<String, dynamic>> notPerformedExercises = [];
      bool isWorkoutCompleted = _progress >= 0;

      Map<String, dynamic> exerciseData = {
        'name': workout.workout,
        'duration': _targetDuration,
        'actualDuration': formatTime(_elapsedSeconds),
        'progressPercentage': (_progress * 100).toStringAsFixed(0) + '%',
      };

      if (isWorkoutCompleted) {
        performedExercises.add(exerciseData);
      } else {
        notPerformedExercises.add(exerciseData);
      }

      await _repository.recordCompletedWorkout(
        category: category,
        completedExercises: isWorkoutCompleted ? 1 : 0,
        totalExercises: 1,
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
}