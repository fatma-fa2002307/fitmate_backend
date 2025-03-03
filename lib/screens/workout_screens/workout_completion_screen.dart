// lib/screens/workout_screens/workout_completion_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/services/workout_service.dart';

class WorkoutCompletionScreen extends StatefulWidget {
  final int completedExercises;
  final int totalExercises;
  final String duration;
  final String category;

  const WorkoutCompletionScreen({
    Key? key,
    required this.completedExercises,
    required this.totalExercises,
    required this.duration,
    required this.category,
  }) : super(key: key);

  @override
  _WorkoutCompletionScreenState createState() => _WorkoutCompletionScreenState();
}

class _WorkoutCompletionScreenState extends State<WorkoutCompletionScreen> {
  @override
  void initState() {
    super.initState();
    _updateWorkoutHistory();
  }

  Future<void> _updateWorkoutHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      
      // Get current user data
      final userData = await userDoc.get();
      final currentLevel = userData.data()?['fitnessLevel'] ?? 'Beginner';
      final totalWorkouts = userData.data()?['totalWorkouts'] ?? 0;
      final workoutsUntilNext = userData.data()?['workoutsUntilNextLevel'] ?? 20;
      
      // Get current timestamp
      final now = Timestamp.now();
      
      // Create workout entry
      final workoutEntry = {
        'category': widget.category,
        'date': now,
        'duration': widget.duration,
        'completion': widget.completedExercises / widget.totalExercises,
        'totalExercises': widget.totalExercises,
        'completedExercises': widget.completedExercises,
      };

      // Calculate new fitness level
      String newLevel = currentLevel;
      int newWorkoutsUntilNext = workoutsUntilNext;
      
      if (totalWorkouts + 1 >= workoutsUntilNext) {
        switch (currentLevel) {
          case 'Beginner':
            newLevel = 'Intermediate';
            newWorkoutsUntilNext = 50; // Need 50 more workouts to reach Advanced
            break;
          case 'Intermediate':
            newLevel = 'Advanced';
            newWorkoutsUntilNext = 100; // Could keep increasing for Advanced
            break;
        }
      }

      // Update user document
      await userDoc.update({
        'lastWorkout': workoutEntry,
        'workoutHistory': FieldValue.arrayUnion([workoutEntry]),
        'totalWorkouts': FieldValue.increment(1),
        'lastWorkoutCategory': widget.category,
        'fitnessLevel': newLevel,
        'workoutsUntilNextLevel': newWorkoutsUntilNext,
      });
      
      // Generate next workout options in the background - silently
      _generateNextWorkoutOptions(userData.data());
      
      // Show level up notification if level changed
      if (newLevel != currentLevel && mounted) {
        _showLevelUpNotification(newLevel);
      }
    }
  }

  Future<void> _generateNextWorkoutOptions(Map<String, dynamic>? userData) async {
    if (userData == null) return;
    
    try {
      // No UI indication - silent background process
      await WorkoutService.generateAndSaveWorkoutOptions(
        age: userData['age'] ?? 30,
        gender: userData['gender'] ?? 'Male',
        height: (userData['height'] ?? 170).toDouble(),
        weight: (userData['weight'] ?? 70).toDouble(),
        goal: userData['goal'] ?? 'Improve Fitness',
        workoutDays: userData['workoutDays'] ?? 3,
        fitnessLevel: userData['fitnessLevel'] ?? 'Beginner',
        lastWorkoutCategory: widget.category, // Use the just-completed workout category
      );
    } catch (e) {
      print("Error generating next workout options: $e");
      // Silently handle errors without UI feedback
    }
  }

  void _showLevelUpNotification(String newLevel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Congratulations! You\'ve reached $newLevel level!',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFD2EB50),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout Stats',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completion',
                          style: GoogleFonts.dmSans(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${widget.completedExercises}/${widget.totalExercises}',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1.5),
                            color: Colors.grey[800],
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: widget.completedExercises / widget.totalExercises,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1.5),
                                color: const Color(0xFFD2EB50),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duration',
                          style: GoogleFonts.dmSans(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.duration,
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD2EB50),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: Text(
                  'DONE',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}