import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FoodRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Save user macros to Firestore
  Future<void> saveUserMacros(Map<String, double> macros) async {
    if (currentUserId == null) return;

    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('userMacros')
        .doc('macro')
        .set({
      'calories': macros['calories'] ?? 0,
      'carbs': macros['carbs'] ?? 0,
      'protein': macros['protein'] ?? 0,
      'fat': macros['fat'] ?? 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user macros from Firestore
  Future<Map<String, double>> getUserMacros() async {
    if (currentUserId == null) {
      return {
        'calories': 0,
        'carbs': 0,
        'protein': 0,
        'fat': 0,
      };
    }

    try {
      DocumentSnapshot docSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('userMacros')
          .doc('macro')
          .get();

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
        return {
          'calories': (data['calories'] ?? 0).toDouble(),
          'carbs': (data['carbs'] ?? 0).toDouble(),
          'protein': (data['protein'] ?? 0).toDouble(),
          'fat': (data['fat'] ?? 0).toDouble(),
        };
      } else {
        return {
          'calories': 0,
          'carbs': 0,
          'protein': 0,
          'fat': 0,
        };
      }
    } catch (e) {
      print('Error getting user macros: $e');
      return {
        'calories': 0,
        'carbs': 0,
        'protein': 0,
        'fat': 0,
      };
    }
  }

  // Check if user macros exist
  Future<bool> userMacrosExist() async {
    if (currentUserId == null) return false;

    try {
      DocumentSnapshot docSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('userMacros')
          .doc('macro')
          .get();

      return docSnapshot.exists;
    } catch (e) {
      print('Error checking if user macros exist: $e');
      return false;
    }
  }

  // Calculate and save user macros
  Future<Map<String, double>> calculateAndSaveUserMacros(String gender,
      double weight, double height, int age, String goal,
      int workoutDays) async {
    // Calculate BMR
    double bmr = _calculateBMR(gender, weight, height, age);

    // Calculate macros based on BMR, goal, and workout days
    Map<String, double> macros = _calculateMacronutrients(
        goal, bmr, workoutDays);

    // Save calculated macros to Firestore
    await saveUserMacros(macros);

    return macros;
  }

  // BMR calculation helper method
  double _calculateBMR(String gender, double weight, double height, int age) {
    if (gender.toLowerCase() == 'male') {
      return (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      return (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }
  }

  // TDEE calculation helper method
  double _calculateTDEE(double bmr, int workoutDays, String goal) {
    double multiplier;
    double cal = 0;
    if (workoutDays == 1) {
      multiplier = 1.2;
    } else if (workoutDays >= 2 && workoutDays <= 3) {
      multiplier = 1.3;
    } else if (workoutDays >= 4 && workoutDays <= 5) {
      multiplier = 1.5;
    } else {
      multiplier = 1.9;
    }

    if (goal == 'Weight Loss') {
      cal = (bmr * multiplier) - 300;
    } else {
      cal = bmr * multiplier;
    }
    return cal;
  }

  // Macronutrients calculation helper method
  Map<String, double> _calculateMacronutrients(String goal, double bmr,
      int workoutDays) {
    double tdee = _calculateTDEE(bmr, workoutDays, goal);
    Map<String, double> macros = {};

    switch (goal) {
      case 'Weight Loss':
        macros = {
          'calories': tdee,
          'carbs': (tdee * 0.45) / 4,
          'protein': (tdee * 0.30) / 4,
          'fat': (tdee * 0.25) / 9,
        };
        break;
      case 'Gain Muscle':
        macros = {
          'calories': tdee,
          'carbs': (tdee * 0.45) / 4,
          'protein': (tdee * 0.35) / 4,
          'fat': (tdee * 0.20) / 9,
        };
        break;
      case 'Improve Fitness':
      default:
        macros = {
          'calories': tdee,
          'carbs': (tdee * 0.60) / 4,
          'protein': (tdee * 0.15) / 4,
          'fat': (tdee * 0.25) / 9,
        };
        break;
    }
    return macros;
  }
}