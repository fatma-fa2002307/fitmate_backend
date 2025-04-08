import 'package:flutter/material.dart';

///this provide common functionality for loading state and errors handling and disposal
class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isDisposed = false;

  bool get isLoading => _isLoading;
  
  ///empty if no error
  String get errorMessage => _errorMessage;
  
  bool get hasError => _errorMessage.isNotEmpty;

  ///set loading state and notify listeners if changed
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListenersSafely();
    }
  }

  ///set error message and notify listeners
  void setError(String error) {
    _errorMessage = error;
    notifyListenersSafely();
  }

  ///clearing any error message and notify listeners for error
  void clearError() {
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      notifyListenersSafely();
    }
  }

  ///notify listeners, checking if this ViewModel has been disposed
  void notifyListenersSafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  ///initialize ViewModel - subclasses should override this
  Future<void> init() async {
    //override in subclasses to perform initialization
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}