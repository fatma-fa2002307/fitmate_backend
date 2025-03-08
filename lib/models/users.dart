import 'package:cloud_firestore/cloud_firestore.dart';

class Users {
  final String email;
  final String gender;
  final int age;
  final double weight; // in kg
  final double height; // in cm
  final int workoutDays; // 1-6
  final DateTime createdAt;
  final DateTime updatedAt;

  Users({
    required this.email,
    required this.gender,
    required this.age,
    required this.weight,
    required this.height,
    required this.workoutDays,
    required this.createdAt,
    required this.updatedAt,
  });

  // BMR calculation
  double calculateBMR() {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // TDEE calculation
  double calculateTDEE(double bmr, int workoutDays) {
    double multiplier;

    if (workoutDays == 1) {
      multiplier = 1.2; // 1 day a week
    } else if (workoutDays >= 2 || workoutDays <= 3) {
      multiplier = 1.3; // 2-3 days a week
    } else if (workoutDays >= 4 || workoutDays <= 5) {
      multiplier = 1.5; // 4-5 days a week
    } else { // 6 days a week
      multiplier = 1.9;
    }
    return bmr * multiplier; // Calories
  }



  // Macronutrient calculation based on TDEE and goals
  Map<String, double> calculateMacronutrients(String goal, double bmr, int workoutDays) {
    double tdee = calculateTDEE(bmr, workoutDays);
    Map<String, double> macros = {};

    if (goal == 'Weight Loss') {
      tdee -= 300; // Deficit for weight loss
    }

    switch (goal) {
      case 'Weight Loss':
        macros = {
          'carbs': (tdee * 0.45) / 4, // carbs per gram = 4 cal
          'protein': (tdee * 0.30) / 4, // protein per gram = 4 cal
          'fat': (tdee * 0.25) / 9, // fat per gram = 9 cal
        };
        break;

      case 'Gain Muscle':
        macros = {
          'carbs': (tdee * 0.45) / 4,
          'protein': (tdee * 0.35) / 4,
          'fat': (tdee * 0.20) / 9,
        };
        break;

      case 'Improve Fitness':
        macros = {
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
      'email': email,
      'gender': gender,
      'age': age,
      'weight': weight,
      'height': height,
      'workoutDays': workoutDays,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Users.fromMap(Map<String, dynamic> map) {
    return Users(
      email: map['email'],
      gender: map['gender'],
      age: map['age'],
      weight: map['weight'],
      height: map['height'],
      workoutDays: map['workoutDays'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}
