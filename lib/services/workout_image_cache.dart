import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Service class for sharing image providers across screens
/// This ensures that the same image instance is used consistently
class WorkoutImageCache {
  // Singleton instance
  static final WorkoutImageCache _instance = WorkoutImageCache._internal();
  factory WorkoutImageCache() => _instance;
  WorkoutImageCache._internal();
  
  // Cache of pre-loaded images keyed by their unique ID
  final Map<String, ImageProvider> _imageCache = {};
  
  /// Get a cached image provider for the given URL and workout
  /// This will reuse the same image provider across the app
  ImageProvider getImageProvider(String baseUrl, Map<String, dynamic> workout) {
    final imageUrl = baseUrl + workout['image'];
    final cacheKey = "workout_${workout['workout']}_${workout['image']}";
    
    // Return existing provider if we already have it
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }
    
    // Create a new provider and cache it
    final provider = CachedNetworkImageProvider(
      imageUrl,
      cacheKey: cacheKey,
    );
    
    _imageCache[cacheKey] = provider;
    return provider;
  }
  
  /// Pre-load an image into the cache to ensure it's ready
  /// This should be called when images are first displayed in a list
  Future<void> preloadImage(BuildContext context, String baseUrl, Map<String, dynamic> workout) async {
    final provider = getImageProvider(baseUrl, workout);
    
    // Force Flutter to precache this image
    precacheImage(provider, context);
  }
  
  /// Clear the entire image cache
  void clearCache() {
    _imageCache.clear();
  }
}