import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/models/workout.dart';

/// Repository that handles all workout-related data operations
class WorkoutRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Get the last completed workout for the current user
  Future<Map<String, dynamic>?> getLastWorkout() async {
    try {
      if (currentUserId == null) return null;

      DocumentSnapshot userData = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userData.exists) {
        Map<String, dynamic>? lastWorkout = userData.get('lastWorkout') as Map<
            String,
            dynamic>?;
        return lastWorkout;
      }
      return null;
    } catch (e) {
      print("Error getting last workout: $e");
      return null;
    }
  }

  /// Get workout history for the current user
  Future<List<Map<String, dynamic>>> getWorkoutHistory() async {
    try {
      if (currentUserId == null) return [];

      DocumentSnapshot userData = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userData.exists && userData.data() != null) {
        List<dynamic> history = userData.get('workoutHistory') ?? [];
        return List<Map<String, dynamic>>.from(history);
      }
      return [];
    } catch (e) {
      print("Error getting workout history: $e");
      return [];
    }
  }

  /// Get current user data needed for workouts
  Future<Map<String, dynamic>?> getUserWorkoutData() async {
    try {
      if (currentUserId == null) return null;

      DocumentSnapshot userData = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userData.exists) {
        return userData.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print("Error getting user workout data: $e");
      return null;
    }
  }

  /// Get workout options from Firestore
  Future<Map<String, List<Map<String, dynamic>>>> getWorkoutOptions() async {
    try {
      if (currentUserId == null) return {};

      DocumentSnapshot userData = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userData.exists) {
        Map<String, dynamic>? workoutOptionsMap = userData.get(
            'workoutOptions') as Map<String, dynamic>?;
        String? nextCategory = userData.get('nextWorkoutCategory') as String?;

        if (workoutOptionsMap != null && workoutOptionsMap.isNotEmpty &&
            nextCategory != null) {
          // Convert Firebase map to our expected format
          Map<String, List<Map<String, dynamic>>> typedWorkoutOptions = {};

          workoutOptionsMap.forEach((key, workoutList) {
            if (workoutList is List) {
              typedWorkoutOptions[key] =
              List<Map<String, dynamic>>.from(workoutList);
            }
          });

          return typedWorkoutOptions;
        }
      }
      return {};
    } catch (e) {
      print("Error getting workout options: $e");
      return {};
    }
  }

  /// Check if workout options exist and are valid
  Future<bool> hasValidWorkoutOptions() async {
    try {
      if (currentUserId == null) return false;

      DocumentSnapshot userData = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!userData.exists) return false;

      Map<String, dynamic>? workoutOptions = userData.get(
          'workoutOptions') as Map<String, dynamic>?;
      String? nextCategory = userData.get('nextWorkoutCategory') as String?;

      return workoutOptions != null && workoutOptions.isNotEmpty &&
          nextCategory != null;
    } catch (e) {
      print("Error checking workout options: $e");
      return false;
    }
  }

  /// Get the next workout category
  Future<String?> getNextWorkoutCategory() async {
    try {
      if (currentUserId == null) return null;

      DocumentSnapshot userData = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (userData.exists) {
        return userData.get('nextWorkoutCategory') as String?;
      }
      return null;
    } catch (e) {
      print("Error getting next workout category: $e");
      return null;
    }
  }

  /// Record completed workout
  /// Record completed workout with detailed exercise tracking
  Future<void> recordCompletedWorkout({
    required String category,
    required int completedExercises,
    required int totalExercises,
    required String duration,
    List<Map<String, dynamic>>? performedExercises,
    List<Map<String, dynamic>>? notPerformedExercises,
  }) async {
    try {
      if (currentUserId == null) return;

      // Get current timestamp
      final now = Timestamp.now();

      // Create workout entry
      final workoutEntry = {
        'category': category,
        'date': now,
        'duration': duration,
        'completion': completedExercises / totalExercises,
        'totalExercises': totalExercises,
        'completedExercises': completedExercises,
        // Add the new fields for detailed exercise tracking
        'performedExercises': performedExercises ?? [],
        'notPerformedExercises': notPerformedExercises ?? [],
      };

      // Get user data for fitness level calculations
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!userDoc.exists) return;

      // The rest of your existing code for progress tracking remains the same...
      // Extract current progress values
      final userData = userDoc.data() as Map<String, dynamic>;
      final currentLevel = userData['fitnessLevel'] ?? 'Beginner';
      final totalWorkouts = userData['totalWorkouts'] ?? 0;

      // Get user progress document
      final userProgressDoc = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('userProgress')
          .doc('progress');

      final userProgressData = await userProgressDoc.get();

      // Extract sub-level data or create defaults
      int currentSubLevel = 1;
      int workoutsCompleted = 0;
      int workoutsUntilNextLevel = 20;

      if (userProgressData.exists) {
        final progressData = userProgressData.data() as Map<String, dynamic>;
        currentSubLevel = progressData['fitnessSubLevel'] ?? 1;
        workoutsCompleted = progressData['workoutsCompleted'] ?? 0;
        workoutsUntilNextLevel = progressData['workoutsUntilNextLevel'] ?? 20;
      }

      // Calculate new fitness level and sub-level
      String newLevel = currentLevel;
      int newSubLevel = currentSubLevel;
      int newWorkoutsCompleted = workoutsCompleted + 1;
      int newWorkoutsUntilNext = workoutsUntilNextLevel;
      bool levelUpOccurred = false;

      // Check if sub-level should increase
      if (newWorkoutsCompleted >=
          workoutsUntilNextLevel / 3 * currentSubLevel) {
        if (currentSubLevel < 3) {
          // Move to next sub-level
          newSubLevel = currentSubLevel + 1;
          levelUpOccurred = true;
        } else {
          // Move to next main level and reset sub-level
          switch (currentLevel) {
            case 'Beginner':
              newLevel = 'Intermediate';
              newWorkoutsUntilNext = 50; // 50 workouts for intermediate level
              newSubLevel = 1; // Reset sub-level
              levelUpOccurred = true;
              break;
            case 'Intermediate':
              newLevel = 'Advanced';
              newWorkoutsUntilNext = 100; // 100 workouts for advanced level
              newSubLevel = 1; // Reset sub-level
              levelUpOccurred = true;
              break;
            case 'Advanced':
            // Keep at Advanced 3, but continue counting
              break;
          }
        }
      }

      // Update user document
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .update({
        'lastWorkout': workoutEntry,
        'workoutHistory': FieldValue.arrayUnion([workoutEntry]),
        'totalWorkouts': FieldValue.increment(1),
        'lastWorkoutCategory': category,
        'fitnessLevel': newLevel,
        // Clear workout options to force a refresh when returning to workout screen
        'workoutOptions': {},
        'nextWorkoutCategory': '',
      });

      // Update the progress sub-document
      await userProgressDoc.set({
        'fitnessLevel': newLevel,
        'fitnessSubLevel': newSubLevel,
        'workoutsCompleted': newWorkoutsCompleted,
        'workoutsUntilNextLevel': newWorkoutsUntilNext,
        'lastUpdated': now,
      });
    } catch (e) {
      print("Error recording completed workout: $e");
      throw e;
    }
  }
}