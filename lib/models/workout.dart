import 'package:cloud_firestore/cloud_firestore.dart';

///model class representing a workout exercise
class WorkoutExercise {
  final String workout;
  final String image;
  final String sets;
  final String reps;
  final String? instruction;
  final bool isCardio;
  
  //cardio fields
  final String? duration;
  final String? intensity;
  final String? format;
  final String? calories;
  final String? description;

  WorkoutExercise({
    required this.workout,
    required this.image,
    required this.sets,
    required this.reps,
    this.instruction,
    this.isCardio = false,
    this.duration,
    this.intensity,
    this.format,
    this.calories,
    this.description,
  });

  factory WorkoutExercise.fromMap(Map<String, dynamic> map) {
    final bool isCardio = map['is_cardio'] == true || 
                          map['duration'] != null || 
                          map['intensity'] != null;
    
    if (isCardio) {
      return WorkoutExercise(
        workout: map['workout'] ?? '',
        image: map['image'] ?? '',
        sets: '1', // Default for cardio
        reps: '1', // Default for cardio
        isCardio: true,
        duration: map['duration'] ?? '30 min',
        intensity: map['intensity'] ?? 'Moderate',
        format: map['format'] ?? 'Steady-state',
        calories: map['calories'] ?? '300-350',
        description: map['description'] ?? 'Perform at a comfortable pace.',
      );
    } else {
      return WorkoutExercise(
        workout: map['workout'] ?? '',
        image: map['image'] ?? '',
        sets: map['sets'] ?? '3',
        reps: map['reps'] ?? '10',
        instruction: map['instruction'],
        isCardio: false,
      );
    }
  }

  Map<String, dynamic> toMap() {
    if (isCardio) {
      return {
        'workout': workout,
        'image': image,
        'is_cardio': true,
        'duration': duration,
        'intensity': intensity,
        'format': format,
        'calories': calories,
        'description': description,
      };
    } else {
      return {
        'workout': workout,
        'image': image,
        'sets': sets,
        'reps': reps,
        'instruction': instruction,
        'is_cardio': false,
      };
    }
  }
}

///model class for a completed workout
class CompletedWorkout {
  final String category;
  final DateTime date;
  final String duration;
  final double completion;
  final int totalExercises;
  final int completedExercises;

  CompletedWorkout({
    required this.category,
    required this.date,
    required this.duration,
    required this.completion,
    required this.totalExercises,
    required this.completedExercises,
  });

  factory CompletedWorkout.fromMap(Map<String, dynamic> map) {
    return CompletedWorkout(
      category: map['category'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      duration: map['duration'] ?? '00:00',
      completion: (map['completion'] ?? 0.0).toDouble(),
      totalExercises: map['totalExercises'] ?? 0,
      completedExercises: map['completedExercises'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'completion': completion,
      'totalExercises': totalExercises,
      'completedExercises': completedExercises,
    };
  }
}

//model class for workout options
class WorkoutOptions {
  final String category;
  final List<List<WorkoutExercise>> options;

  WorkoutOptions({
    required this.category,
    required this.options,
  });

  factory WorkoutOptions.fromMap(Map<String, dynamic> map, String category) {
    List<List<WorkoutExercise>> optionsList = [];
    
    map.forEach((key, value) {
      if (value is List) {
        List<WorkoutExercise> exercises = [];
        for (var exercise in value) {
          if (exercise is Map<String, dynamic>) {
            exercises.add(WorkoutExercise.fromMap(exercise));
          }
        }
        optionsList.add(exercises);
      }
    });
    
    return WorkoutOptions(
      category: category,
      options: optionsList,
    );
  }
}