// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:fitmate/models/food.dart';
//
// class FoodRepository {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Future<void> saveFood(Food food) async {
//     try {
//       await _firestore.collection('foods').add(food.toMap());
//     } catch (e) {
//       print('Error saving food: $e');
//     }
//   }
//
//   Future<List<Food>> getFoods() async {
//     try {
//       QuerySnapshot snapshot = await _firestore.collection('foods').get();
//
//       return snapshot.docs
//           .map((doc) => Food.fromMap(doc.data() as Map<String, dynamic>))
//           .toList();
//     } catch (e) {
//       print('Error fetching foods: $e');
//       return [];
//     }
//   }
// }
