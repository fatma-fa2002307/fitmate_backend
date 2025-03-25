import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/models/food_suggestion.dart';

class FoodSuggestionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Get cached suggestions for a specific milestone
  Future<MilestoneSuggestions?> getCachedSuggestions({
    required String userId,
    required SuggestionMilestone milestone,
  }) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('foodSuggestions')
          .doc('milestones')
          .get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data();
      if (data == null) {
        return null;
      }
      
      // Get milestone data
      final milestonePath = milestone.toString().split('.').last.toLowerCase();
      final milestoneData = data[milestonePath] as Map<String, dynamic>?;
      
      if (milestoneData == null) {
        return null;
      }
      
      return MilestoneSuggestions.fromFirestore(milestoneData, milestone);
    } catch (e) {
      print('Error getting cached suggestions: $e');
      return null;
    }
  }
  
  /// Cache suggestions for a specific milestone
  Future<void> cacheSuggestions({
    required String userId,
    required SuggestionMilestone milestone,
    required List<FoodSuggestion> suggestions,
  }) async {
    try {
      final milestoneSuggestions = MilestoneSuggestions(
        milestone: milestone,
        suggestions: suggestions,
        generatedAt: DateTime.now(),
      );
      
      final milestonePath = milestone.toString().split('.').last.toLowerCase();
      
      // Use FieldValue.serverTimestamp() for the generated timestamp
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('foodSuggestions')
          .doc('milestones')
          .set({
            milestonePath: milestoneSuggestions.toMap(),
          }, SetOptions(merge: true));
          
      // Also update the current milestone
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('foodSuggestions')
          .doc('metadata')
          .set({
            'currentMilestone': milestonePath,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error caching suggestions: $e');
    }
  }
  
  /// Get list of disliked food IDs
  Future<List<String>> getDislikedFoods(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('food')
          .get();
      
      if (!docSnapshot.exists) {
        return [];
      }
      
      final data = docSnapshot.data();
      if (data == null) {
        return [];
      }
      
      final dislikedFoods = data['dislikedFoods'] as List?;
      if (dislikedFoods == null) {
        return [];
      }
      
      return dislikedFoods.cast<String>();
    } catch (e) {
      print('Error getting disliked foods: $e');
      return [];
    }
  }
  
  /// Add a food ID to the disliked list
  Future<void> addDislikedFood(String userId, String foodId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('food')
          .set({
            'dislikedFoods': FieldValue.arrayUnion([foodId]),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error adding disliked food: $e');
    }
  }
  
  /// Remove a food ID from the disliked list
  Future<void> removeDislikedFood(String userId, String foodId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('food')
          .set({
            'dislikedFoods': FieldValue.arrayRemove([foodId]),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error removing disliked food: $e');
    }
  }
}