// lib/services/workout_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/services/api_service.dart';

class WorkoutService {
  // Generate multiple workout options and save to Firebase
  static Future<void> generateAndSaveWorkoutOptions({
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String goal,
    required int workoutDays,
    required String fitnessLevel,
    String? lastWorkoutCategory,
  }) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user is logged in.");
        return;
      }
      
      // Make a single API call to get all workout options
      final workoutOptionsData = await ApiService.generateWorkoutOptions(
        age: age,
        gender: gender,
        height: height,
        weight: weight,
        goal: goal,
        workoutDays: workoutDays,
        fitnessLevel: fitnessLevel,
        lastWorkoutCategory: lastWorkoutCategory,
      );
      
      // Get the category and options
      String nextCategory = workoutOptionsData['category'];
      List<dynamic> optionsList = workoutOptionsData['options'];
      
      // Convert to Firestore-friendly format (Map instead of nested arrays)
      Map<String, dynamic> workoutOptionsMap = {};
      
      for (int i = 0; i < optionsList.length; i++) {
        // Store each workout option list as a separate entry in the map
        workoutOptionsMap['option${i+1}'] = optionsList[i];
      }
      
      // Save workout options and next category to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'workoutOptions': workoutOptionsMap,
        'nextWorkoutCategory': nextCategory,
        'workoutsLastGenerated': FieldValue.serverTimestamp(),
      });
      
      print("Successfully generated and saved workout options for category: $nextCategory");
    } catch (e) {
      print("Error in generateAndSaveWorkoutOptions: $e");
      throw e;
    }
  }
}