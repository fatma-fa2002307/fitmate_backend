import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/models/users.dart';
import 'package:fitmate/services/workout_service.dart';

class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email address is required';
    } else if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    } else if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<Users> createUserWithEmailAndPassword(
      String email,
      String password,
      String fullName,
      int age,
      double weight,
      double height,
      String gender,
      String selectedGoal,
      int workoutDays,
      ) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUser = Users(
        id: userCredential.user!.uid,
        email: email,
        gender: gender,
        fullName: fullName,
        age: age,
        weight: weight,
        height: height,
        workoutDays: workoutDays,
        goal: selectedGoal,
        fitnessLevel: 'Beginner',
        totalWorkouts: 0,
        workoutsUntilNextLevel: 20,
      );

      await _firestore.collection('users').doc(userCredential.user?.uid).set(newUser.toMap());

      await WorkoutService.generateAndSaveWorkoutOptions(
        age: age,
        gender: gender,
        height: height,
        weight: weight,
        goal: selectedGoal,
        workoutDays: workoutDays,
        fitnessLevel: 'Beginner',
        lastWorkoutCategory: null,
      );

      return newUser;
    } catch (e) {
      rethrow;
    }
  }
}