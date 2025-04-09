import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/viewmodels/base_viewmodel.dart';
import 'package:fitmate/utils/login_validation.dart';

class AuthViewModel extends BaseViewModel {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // State
  bool _isPasswordVisible = false;
  
  // Getters
  bool get isPasswordVisible => _isPasswordVisible;
  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  
  // Toggle password visibility
  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListenersSafely();
  }
  
  // Login with email and password
  Future<bool> login(String email, String password) async {
    setLoading(true);
    clearError();
    
    try {
      // Validate inputs
      String? emailError = LoginValidation.validateEmail(email);
      String? passwordError = LoginValidation.validatePassword(password);
      
      if (emailError != null || passwordError != null) {
        setError(emailError ?? passwordError ?? 'Invalid credentials');
        setLoading(false);
        return false;
      }
      
      // Attempt login
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      setError(e.message ?? 'Failed to sign in');
      setLoading(false);
      return false;
    } catch (e) {
      setError('An unexpected error occurred');
      setLoading(false);
      return false;
    }
  }
  
  // Register a new user
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String goal,
    required int workoutDays,
  }) async {
    setLoading(true);
    clearError();
    
    try {
      // Create the user account with Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      
      String userId = userCredential.user!.uid;
      
      // Store user data in Firestore
      await _firestore.collection('users').doc(userId).set({
        'fullName': fullName,
        'email': email,
        'age': age,
        'weight': weight,
        'height': height,
        'gender': gender,
        'goal': goal,
        'workoutDays': workoutDays,
        'fitnessLevel': 'Beginner',
        'totalWorkouts': 0,
        'workoutsUntilNextLevel': 20,
      });
      
      // Initialize user progress document
      await _firestore.collection('users').doc(userId).collection('userProgress').doc('progress').set({
        'fitnessLevel': 'Beginner',
        'fitnessSubLevel': 1,
        'workoutsCompleted': 0,
        'workoutsUntilNextLevel': 20,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Create initial collections
      await _firestore.collection('users').doc(userId).collection('foodLogs').doc('initial').set({});
      await _firestore.collection('users').doc(userId).collection('workoutLogs').doc('initial').set({});
      await _firestore.collection('users').doc(userId).collection('workoutHistory').doc('initial').set({});
      
      setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      setError(e.message ?? 'Failed to create account');
      setLoading(false);
      return false;
    } catch (e) {
      setError('An unexpected error occurred');
      setLoading(false);
      return false;
    }
  }
  
  // Send password reset email
  Future<bool> resetPassword(String email) async {
    setLoading(true);
    clearError();
    
    try {
      // Validate email
      String? emailError = LoginValidation.validateEmail(email);
      
      if (emailError != null) {
        setError(emailError);
        setLoading(false);
        return false;
      }
      
      await _auth.sendPasswordResetEmail(email: email.trim());
      setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      setError(e.message ?? 'Failed to send reset email');
      setLoading(false);
      return false;
    } catch (e) {
      setError('An unexpected error occurred');
      setLoading(false);
      return false;
    }
  }
  
  // Sign out
  Future<bool> signOut() async {
    setLoading(true);
    clearError();
    
    try {
      await _auth.signOut();
      setLoading(false);
      return true;
    } catch (e) {
      setError('Failed to sign out');
      setLoading(false);
      return false;
    }
  }
  
  // Check authentication state
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}