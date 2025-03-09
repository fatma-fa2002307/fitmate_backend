import 'package:cloud_firestore/cloud_firestore.dart';

class Users {
  final String uid;
  final String email;
  final String gender;
  final String name;
  final int age;
  final double weight; // in kg
  final double height; // in cm
  final int workoutDays; // 1-6
  final String goal;
  final DateTime createdAt;
  final DateTime updatedAt;

  Users({
    required this.uid,
    required this.email,
    required this.gender,
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.workoutDays,
    required this.goal,
    required this.createdAt,
    required this.updatedAt,
  });

  double calculateBMR(String gender) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // TDEE calculation
  double calculateTDEE(double bmr, int workoutDays, String goal) {
    double multiplier;
    double cal = 0;
    if (workoutDays == 1) {
      multiplier = 1.2; // 1 day a week
    } else if (workoutDays >= 2 || workoutDays <= 3) {
      multiplier = 1.3; // 2-3 days a week
    } else if (workoutDays >= 4 || workoutDays <= 5) {
      multiplier = 1.5; // 4-5 days a week
    } else {
      // 6 days a week
      multiplier = 1.9;
    }
    if (goal == 'Weight Loss') {
      cal = (bmr * multiplier) - 300;
    } else {
      cal = bmr * multiplier;
    }
    return cal;
  } // Calories

  // Macronutrient calculation based on TDEE and goals
  Map<String, double> calculateMacronutrients(String goal, double bmr, int workoutDays) {
    double tdee = calculateTDEE(bmr, workoutDays, goal);
    Map<String, double> macros = {};

    switch (goal) {
      case 'Weight Loss':
        macros = {
          'calories':(tdee),
          'carbs': (tdee * 0.45) / 4, // carbs per gram = 4 cal
          'protein': (tdee * 0.30) / 4, // protein per gram = 4 cal
          'fat': (tdee * 0.25) / 9, // fat per gram = 9 cal
        };
        break;

      case 'Gain Muscle':
        macros = {
          'calories':(tdee),
          'carbs': (tdee * 0.45) / 4,
          'protein': (tdee * 0.35) / 4,
          'fat': (tdee * 0.20) / 9,
        };
        break;

      case 'Improve Fitness':
        macros = {
          'calories':(tdee),
          'carbs': (tdee * 0.60) / 4,
          'protein': (tdee * 0.15) / 4,
          'fat': (tdee * 0.25) / 9,
        };
        break;
    }

    return macros;
  }

  // Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,  // Include uid in the map for Firestore storage
      'email': email,
      'gender': gender,
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'workoutDays': workoutDays,
      'goal': goal,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Users.fromMap(Map<String, dynamic> map) {
    return Users(
      uid: map['uid'] ?? '',  // Ensure the uid is handled when retrieving from Firestore
      email: map['email'] ?? '',
      gender: map['gender'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 16,
      weight: map['weight']?.toDouble() ?? 0.0,
      height: map['height']?.toDouble() ?? 0.0,
      workoutDays: map['workoutDays'] ?? 1,
      goal: map['goal'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(), // Handle null or missing createdAt
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(), // Handle null or missing updatedAt
    );
  }
}