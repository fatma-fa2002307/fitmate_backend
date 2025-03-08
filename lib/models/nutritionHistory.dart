import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/models/dailyNutrition.dart';

class NutritionHistory {
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final List<DailyNutrition> dailyNutrition;

  NutritionHistory({
    required this.userId,
    required this.startDate,
    required this.endDate,
    required this.dailyNutrition,
  });

  // Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startDate': startDate,
      'endDate': endDate,
      'dailyNutrition': dailyNutrition.map((item) => item.toMap()).toList(),
    };
  }

  factory NutritionHistory.fromMap(Map<String, dynamic> map) {
    return NutritionHistory(
      userId: map['userId'],
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      dailyNutrition: (map['dailyNutrition'] as List)
          .map((item) => DailyNutrition.fromMap(item))
          .toList(),
    );
  }
}
