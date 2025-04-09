import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/repositories/food_repository.dart';
import 'package:fitmate/viewmodels/base_viewmodel.dart';

class EditProfileViewModel extends BaseViewModel {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FoodRepository _foodRepository = FoodRepository();
  
  // Form controllers and data
  String _fullName = '';
  double _weight = 0.0;
  double _height = 0.0;
  int _age = 0;
  String _gender = 'Female';
  String _goal = 'Weight Loss';
  String _workoutDays = '3';
  bool _isKg = true;
  bool _isCm = true;
  String? _profileImage;
  
  // Getters
  String get fullName => _fullName;
  double get weight => _weight;
  double get height => _height;
  int get age => _age;
  String get gender => _gender;
  String get goal => _goal;
  String get workoutDays => _workoutDays;
  bool get isKg => _isKg;
  bool get isCm => _isCm;
  String? get profileImage => _profileImage;
  
  // Setters
  void setFullName(String value) {
    _fullName = value;
    notifyListenersSafely();
  }
  
  void setWeight(String value) {
    try {
      _weight = double.parse(value);
      notifyListenersSafely();
    } catch (e) {
      print('Error parsing weight: $e');
    }
  }
  
  void setHeight(String value) {
    try {
      _height = double.parse(value);
      notifyListenersSafely();
    } catch (e) {
      print('Error parsing height: $e');
    }
  }
  
  void setAge(String value) {
    try {
      _age = int.parse(value);
      notifyListenersSafely();
    } catch (e) {
      print('Error parsing age: $e');
    }
  }
  
  void setGender(String value) {
    _gender = value;
    notifyListenersSafely();
  }
  
  void setGoal(String value) {
    _goal = value;
    notifyListenersSafely();
  }
  
  void setWorkoutDays(String value) {
    _workoutDays = value;
    notifyListenersSafely();
  }
  
  void toggleWeightUnit(bool isKg) {
    if (_isKg == isKg) return;
    
    _isKg = isKg;
    _convertWeight();
    notifyListenersSafely();
  }
  
  void toggleHeightUnit(bool isCm) {
    if (_isCm == isCm) return;
    
    _isCm = isCm;
    _convertHeight();
    notifyListenersSafely();
  }
  
  void setProfileImage(String imagePath) {
    _profileImage = imagePath;
    notifyListenersSafely();
  }
  
  // Load user data from Firestore
  Future<void> loadUserData() async {
    setLoading(true);
    
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          final data = userData.data() as Map<String, dynamic>?;

          if (data != null) {
            final storedWeight = (data['weight'] is double)
                ? data['weight']
                : double.tryParse(data['weight']?.toString() ?? '') ?? 0.0;

            final storedHeight = (data['height'] is double)
                ? data['height']
                : double.tryParse(data['height']?.toString() ?? '') ?? 0.0;

            final storedUnit = data['unitPreference'] ?? 'metric';

            _isKg = storedUnit == 'metric';
            _isCm = storedUnit == 'metric';
            _fullName = data['fullName'] ?? '';
            _age = data['age'] ?? 0;
            _gender = data['gender'] ?? 'Female';
            _goal = data['goal'] ?? 'Weight Loss';
            _workoutDays = data['workoutDays']?.toString() ?? '3';
            _profileImage = data['profileImage'];

            if (_isKg) {
              _weight = storedWeight;
            } else {
              _weight = (storedWeight * 2.20462);
            }

            if (_isCm) {
              _height = storedHeight;
            } else {
              _height = (storedHeight / 30.48);
            }
            
            notifyListenersSafely();
          }
        }
      }
    } catch (e) {
      setError('Error loading profile: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Convert weight between kg and lbs
  void _convertWeight() {
    if (_weight > 0) {
      if (_isKg) {
        _weight = (_weight * 0.453592);
      } else {
        _weight = (_weight * 2.20462);
      }
    }
  }
  
  // Convert height between cm and feet
  void _convertHeight() {
    if (_height > 0) {
      if (_isCm) {
        _height = (_height * 30.48);
      } else {
        _height = (_height / 30.48);
      }
    }
  }
  
  // Save profile data to Firestore
  Future<bool> saveUserData() async {
    setLoading(true);
    clearError();
    
    User? user = _auth.currentUser;
    if (user == null) {
      setError('No user logged in');
      setLoading(false);
      return false;
    }
    
    try {
      // Parse inputs as doubles
      double weight = _weight;
      double height = _height;
      int age = _age;
      int workoutDays = int.parse(_workoutDays);

      // Convert to metric for storage
      if (!_isKg) {
        weight = weight * 0.453592;
      }

      if (!_isCm) {
        height = height * 30.48;
      }

      // Round to 2 decimal places
      weight = double.parse(weight.toStringAsFixed(2));
      height = double.parse(height.toStringAsFixed(2));

      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'fullName': _fullName,
        'weight': weight,
        'height': height,
        'age': age,
        'gender': _gender,
        'goal': _goal,
        'workoutDays': workoutDays,
        'unitPreference': _isKg ? 'metric' : 'imperial',
      });

      // Recalculate and save user macros after profile update
      await _foodRepository.calculateAndSaveUserMacros(
          _gender,
          weight,
          height,
          age,
          _goal,
          workoutDays
      );

      setLoading(false);
      return true;
    } catch (e) {
      setError('Error updating profile: $e');
      setLoading(false);
      return false;
    }
  }
  
  // Update profile image
  Future<bool> updateProfileImage(String imagePath) async {
    setLoading(true);
    clearError();
    
    User? user = _auth.currentUser;
    if (user == null) {
      setError('No user logged in');
      setLoading(false);
      return false;
    }
    
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({
        'profileImage': imagePath,
      });

      _profileImage = imagePath;
      notifyListenersSafely();
      
      setLoading(false);
      return true;
    } catch (e) {
      setError('Error updating profile picture: $e');
      setLoading(false);
      return false;
    }
  }
  
  // Sign out user
  Future<bool> signOut() async {
    setLoading(true);
    clearError();
    
    try {
      await _auth.signOut();
      setLoading(false);
      return true;
    } catch (e) {
      setError('Error signing out: $e');
      setLoading(false);
      return false;
    }
  }
  
  // Validation methods
  String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    return null;
  }

  String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number <= 0) {
      return 'Weight must be greater than 0';
    }
    return null;
  }

  String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Height is required';
    }
    final number = double.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number <= 0) {
      return 'Height must be greater than 0';
    }
    return null;
  }

  String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Age is required';
    }
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number <= 15) {
      return 'Age must be greater than 15';
    }
    if (number > 120) {
      return 'Please enter a reasonable age';
    }
    return null;
  }
}