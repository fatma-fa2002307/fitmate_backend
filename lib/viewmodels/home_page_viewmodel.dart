import 'package:fitmate/repositories/home_repository.dart';
import 'package:fitmate/viewmodels/base_viewmodel.dart';

class HomePageViewModel extends BaseViewModel {
  final HomeRepository _repository;
  
  // User data
  String _userFullName = "Loading...";
  String _userGoal = "Loading...";
  String? _profileImage;
  double _totalCalories = 0;
  double _dailyCaloriesGoal = 2500;
  bool _animationComplete = false;
  
  // Getters
  String get userFullName => _userFullName;
  String get userGoal => _userGoal;
  String? get profileImage => _profileImage;
  double get totalCalories => _totalCalories;
  double get dailyCaloriesGoal => _dailyCaloriesGoal;
  bool get animationComplete => _animationComplete;
  
  // Constructor with repository
  HomePageViewModel({required HomeRepository repository}) : _repository = repository;
  
  // Set animation completion state
  void setAnimationComplete(bool complete) {
    _animationComplete = complete;
    notifyListenersSafely();
  }
  
  // Load all user data
  Future<void> loadUserData() async {
    setLoading(true);
    clearError();
    
    try {
      // Load user's personal data
      final userData = await _repository.getUserData();
      if (userData != null) {
        _userFullName = userData['fullName'] ?? 'User';
        _userGoal = userData['goal'] ?? 'No goal set';
        _profileImage = userData['profileImage'];
        notifyListenersSafely();
      }
      
      // Load user progress (creates default if not exists)
      await _repository.getUserProgress();
      
      // Load food logs and calorie data
      await _loadFoodAndCalorieData();
    } catch (e) {
      print('Error loading user data: $e');
      _userFullName = 'User';
      _userGoal = 'No goal set';
      setError('Error loading user data: $e');
    } finally {
      setLoading(false);
    }
  }
  
  // Load food logs and calorie data
  Future<void> _loadFoodAndCalorieData() async {
    try {
      // Get today's food logs
      final foodLogs = await _repository.getTodaysFoodLogs();
      
      // Calculate total calories
      _totalCalories = 0;
      for (var food in foodLogs) {
        _totalCalories += (food['calories'] ?? 0).toDouble();
      }
      
      // Get daily calorie goal
      _dailyCaloriesGoal = await _repository.getUserDailyCalories();
      
      notifyListenersSafely();
    } catch (e) {
      print('Error loading food data: $e');
    }
  }
  
  // Refresh food and calorie data only
  Future<void> refreshData() async {
    await _loadFoodAndCalorieData();
  }
}