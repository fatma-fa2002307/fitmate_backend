import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

///repo for home page ops
class HomeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  //get curr user ID
  String? get currentUserId => _auth.currentUser?.uid;
  
  //get cutt user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      if (currentUserId == null) return null;
      
      DocumentSnapshot userData = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
          
      if (!userData.exists) return null;
      
      return userData.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
  
  //get user progress data
  Future<Map<String, dynamic>?> getUserProgress() async {
    try {
      if (currentUserId == null) return null;
      
      DocumentSnapshot userProgress = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('userProgress')
          .doc('progress')
          .get();
          
      if (!userProgress.exists) {
        //create default progress document if it doesn't exist
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('userProgress')
            .doc('progress')
            .set({
          'fitnessLevel': 'Beginner',
          'fitnessSubLevel': 1,
          'workoutsCompleted': 0,
          'workoutsUntilNextLevel': 20,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
        
        userProgress = await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('userProgress')
            .doc('progress')
            .get();
      }
      
      return userProgress.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error getting user progress: $e');
      return null;
    }
  }
  
  //get today's food logs
  Future<List<Map<String, dynamic>>> getTodaysFoodLogs() async {
    try {
      if (currentUserId == null) return [];
      
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime tomorrow = today.add(const Duration(days: 1));
      
      QuerySnapshot foodLogs = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('foodLogs')
          .where('date', isGreaterThanOrEqualTo: today)
          .where('date', isLessThan: tomorrow)
          .orderBy('date', descending: true)
          .get();
          
      return foodLogs.docs
          .map((doc) => {
            ...doc.data() as Map<String, dynamic>,
            'id': doc.id,
          })
          .toList();
    } catch (e) {
      print('Error getting food logs: $e');
      return [];
    }
  }
  
  //get user's daily calorie goal
  Future<double> getUserDailyCalories() async {
    try {
      if (currentUserId == null) return 2500.0;
      
      DocumentSnapshot macrosDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('userMacros')
          .doc('macro')
          .get();
          
      if (!macrosDoc.exists) return 2500.0;
      
      final data = macrosDoc.data() as Map<String, dynamic>;
      return (data['calories'] ?? 2500).toDouble();
    } catch (e) {
      print('Error getting daily calories: $e');
      return 2500.0;
    }
  }
}