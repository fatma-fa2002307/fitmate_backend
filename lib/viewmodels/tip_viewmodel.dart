import 'package:flutter/material.dart';
import 'package:fitmate/viewmodels/base_viewmodel.dart';
import 'package:fitmate/repositories/tip_repository.dart';

class TipViewModel extends BaseViewModel {
  final TipRepository _repository;
  
  // Tip data state
  Map<String, dynamic> _tipData = {};
  bool _isRefreshing = false;
  
  // Getters
  Map<String, dynamic> get tipData => _tipData;
  bool get isRefreshing => _isRefreshing;
  
  // Get tip text content
  String get tipText => _tipData['tip'] ?? 'Stay consistent and enjoy your fitness journey!';
  
  // Get tip category
  String get category => _tipData['category'] ?? 'motivation';
  
  // Get tip icon
  String get iconName => _tipData['icon'] ?? category;
  
  // Get formatted category title (capitalized)
  String get categoryTitle => _tipData['categoryTitle'] ?? _capitalizeFirst(category);
  
  // Constructor with repository
  TipViewModel({required TipRepository repository}) : _repository = repository;
  
  @override
  Future<void> init() async {
    // If there's no tip data already loaded, fetch it
    if (_tipData.isEmpty) {
      await loadTip();
    }
  }
  
  // Load personalized tip
  Future<void> loadTip({bool useCache = true}) async {
    setLoading(true);
    clearError();
    
    try {
      final tipData = await _repository.getPersonalizedTip(useCache: useCache);
      _tipData = tipData;
      _isRefreshing = false;
      
      notifyListenersSafely();
    } catch (e) {
      setError('Error loading tip: $e');
      _isRefreshing = false;
    } finally {
      setLoading(false);
    }
  }
  
  // Refresh tip by forcing a new fetch (ignoring cache)
  Future<void> refreshTip() async {
    if (isLoading || _isRefreshing) return;
    
    _isRefreshing = true;
    notifyListenersSafely();
    
    await loadTip(useCache: false);
  }
  
  // Helper method to capitalize first letter of a string
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  // Get the icon for the tip category
  IconData getIconData(String category) {
    switch (category) {
      case 'nutrition':
        return Icons.restaurant_outlined;
      case 'workout':
        return Icons.fitness_center;
      case 'motivation':
        return Icons.emoji_events_outlined;
      case 'recovery':
        return Icons.self_improvement_outlined;
      case 'habit':
        return Icons.trending_up_rounded;
      case 'hydration':
        return Icons.water_drop_outlined;
      case 'sleep':
        return Icons.nightlight_outlined;
      case 'mindfulness':
        return Icons.spa_outlined;
      default:
        return Icons.tips_and_updates_outlined;
    }
  }
  
  // Get the gradient for the tip category
  List<Color> getGradientColors(String category) {
    switch (category) {
      case 'nutrition':
        return [Color(0xFF86EB96), Color(0xFF55C968)];
      case 'workout':
        return [Color(0xFF81C5FF), Color(0xFF3D93EB)];
      case 'motivation':
        return [Color(0xFFFFD679), Color(0xFFFFB52E)];
      case 'recovery':
        return [Color(0xFFD0A5FF), Color(0xFFAC66FF)];
      case 'habit':
        return [Color(0xFF7CECDA), Color(0xFF44C5B2)];
      case 'hydration':
        return [Color(0xFF87CDFF), Color(0xFF4EA4FF)];
      case 'sleep':
        return [Color(0xFFB195EC), Color(0xFF8A63D2)];
      case 'mindfulness':
        return [Color(0xFFFFB5A7), Color(0xFF8A63D2)];
      default:
        return [Color(0xFFE1F976), Color(0xFFCAE350)]; // Default FitMate color
    }
  }
}