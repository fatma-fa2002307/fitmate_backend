import 'package:fitmate/viewmodels/base_viewmodel.dart';

class WelcomeViewModel extends BaseViewModel {
  //animation state
  bool _showContentAnimation = false;
  bool _showCatAnimation = false;
  
  // Getters
  bool get showContentAnimation => _showContentAnimation;
  bool get showCatAnimation => _showCatAnimation;
  
  // Initialize animation states
  void initAnimations() {
    // Start with animations disabled
    _showContentAnimation = false;
    _showCatAnimation = false;
    notifyListenersSafely();
    
    // Schedule content animation
    Future.delayed(const Duration(milliseconds: 200), () {
      _showContentAnimation = true;
      notifyListenersSafely();
      
      // Schedule cat animation after content starts
      Future.delayed(const Duration(milliseconds: 600), () {
        _showCatAnimation = true;
        notifyListenersSafely();
      });
    });
  }
  
  //helper methods for navigation (could be used with Navigator 2.0 if implemented)
  void navigateToLogin() {
    //nav logic would go here if using more complex navigation pattern. for now UI directly handles
  }
  
  void navigateToRegister() {
    //nav logic would go here if using more complex navigation pattern. for now UI directly handles
  }
}