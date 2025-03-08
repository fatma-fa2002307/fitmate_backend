import 'package:cloud_firestore/cloud_firestore.dart';

class DailyNutrition {
  final String userId;
  final DateTime date;
  final double totalCalories;
  final double totalCarbs;
  final double totalProtein;
  final double totalFat;
  final String goal;

  DailyNutrition({
    required this.userId,
    required this.date,
    required this.totalCalories,
    required this.totalCarbs,
    required this.totalProtein,
    required this.totalFat,
    required this.goal,
  });

  // Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'date': date,
      'totalCalories': totalCalories,
      'totalCarbs': totalCarbs,
      'totalProtein': totalProtein,
      'totalFat': totalFat,
      'goal': goal,
    };
  }

  factory DailyNutrition.fromMap(Map<String, dynamic> map) {
    return DailyNutrition(
      userId: map['userId'],
      date: (map['date'] as Timestamp).toDate(),
      totalCalories: map['totalCalories'],
      totalCarbs: map['totalCarbs'],
      totalProtein: map['totalProtein'],
      totalFat: map['totalFat'],
      goal: map['goal'],
    );
  }
}
