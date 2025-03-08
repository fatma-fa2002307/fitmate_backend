import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/models/users.dart';
import 'package:fitmate/models/users.dart';

class UsersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Users?> getUser(String userEmail) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userEmail).get();
      if (doc.exists) {
        return Users.fromMap(doc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('Error fetching user: $e');
    }
    return null;
  }

  Future<void> updateUser(Users user) async {
    try {
      await _firestore.collection('users').doc(user.email).update(user.toMap());
    } catch (e) {
      print('Error updating user: $e');
    }
  }
}
