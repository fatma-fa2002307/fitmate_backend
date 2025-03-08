import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/models/dailyNutrition.dart';


class DailyNutritionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveDailyNutrition(DailyNutrition nutrition) async {
    try {
      await _firestore.collection('daily_nutrition').add(nutrition.toMap());
    } catch (e) {
      print('Error saving daily nutrition: $e');
    }
  }

  Future<List<DailyNutrition>> getNutritionHistory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('daily_nutrition')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => DailyNutrition.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching daily nutrition: $e');
      return [];
    }
  }
}
