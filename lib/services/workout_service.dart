
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/services/api_service.dart';

class WorkoutService {
  // Track the last generation timestamp in memory to prevent duplicate API calls
  static DateTime? _lastGenerationTime;
  
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
        throw Exception("No user is logged in");
      }
      
      // Check if we've recently generated a workout to prevent duplicates
      if (_lastGenerationTime != null) {
        DateTime now = DateTime.now();
        Duration difference = now.difference(_lastGenerationTime!);
        
        // If we've generated a workout in the last 5 seconds, skip generation
        if (difference.inSeconds < 5) {
          print("Skipping workout generation - too soon after last generation");
          return;
        }
      }
      
      // Update the timestamp before making the API call
      _lastGenerationTime = DateTime.now();
      
      // First, mark that we're starting generation
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'workoutsLastGenerated': FieldValue.serverTimestamp(),
      });
      
      // Make API call to get all workout options
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
      
      // Save workout options and next category to Firestore with retry logic
      int retries = 3;
      while (retries > 0) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'workoutOptions': workoutOptionsMap,
            'nextWorkoutCategory': nextCategory,
            'workoutsLastGenerated': FieldValue.serverTimestamp(),
          });
          print("Successfully generated and saved workout options for category: $nextCategory");
          return; // Success, exit the function
        } catch (e) {
          retries--;
          print("Error saving workout options, retries left: $retries");
          if (retries <= 0) throw e; // Rethrow if all retries failed
          await Future.delayed(Duration(seconds: 1)); // Wait before retrying
        }
      }
    } catch (e) {
      print("Error in generateAndSaveWorkoutOptions: $e");
      throw e;
    }
  }

  // Check if workout generation has been done recently
  static Future<bool> hasRecentWorkoutGeneration() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (!userData.exists) return false;
      
      Timestamp? lastGenerated = userData.data()?['workoutsLastGenerated'] as Timestamp?;
      
      if (lastGenerated == null) return false;
      
      DateTime lastGeneratedTime = lastGenerated.toDate();
      DateTime now = DateTime.now();
      Duration difference = now.difference(lastGeneratedTime);
      
      // Consider generation "recent" if it was less than 10 seconds ago
      return difference.inSeconds < 10;
    } catch (e) {
      print("Error checking recent workout generation: $e");
      return false;
    }
  }
  
  // Check if workout options exist and are valid
  static Future<bool> hasValidWorkoutOptions() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (!userData.exists) return false;
      
      Map<String, dynamic>? workoutOptions = userData.data()?['workoutOptions'] as Map<String, dynamic>?;
      String? nextCategory = userData.data()?['nextWorkoutCategory'] as String?;
      
      return workoutOptions != null && workoutOptions.isNotEmpty && nextCategory != null;
    } catch (e) {
      print("Error checking workout options: $e");
      return false;
    }
  }
  
  // Get user data for workout generation
  static Future<Map<String, dynamic>?> getUserWorkoutData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      
      final userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (!userData.exists) return null;
      
      return userData.data();
    } catch (e) {
      print("Error getting user workout data: $e");
      return null;
    }
  }
}