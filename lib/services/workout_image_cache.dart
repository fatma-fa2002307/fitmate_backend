import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitmate/services/api_service.dart';
import 'package:fitmate/models/workout.dart';

///service class for sharing image providers across screens
///ensures that the same image instance is used consistently and images are cached
class WorkoutImageCache {
  static final WorkoutImageCache _instance = WorkoutImageCache._internal();
  factory WorkoutImageCache() => _instance;
  WorkoutImageCache._internal();
  
  //cache of pre-loaded images keyed by their unique ID
  final Map<String, ImageProvider> _imageCache = {};
  
  /// Get a cached image provider for a workout using a consistent URL generation
  ImageProvider getWorkoutImageProvider(WorkoutExercise workout) {
    final imageUrl = _getWorkoutImageUrl(workout);
    final cacheKey = "workout_${workout.workout}_${workout.image}";
    
    // Return existing provider if we already have it
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }
    
    //create provider and cache it
    final provider = CachedNetworkImageProvider(
      imageUrl,
      cacheKey: cacheKey,
    );
    
    _imageCache[cacheKey] = provider;
    return provider;
  }
  
  ///Get cached image provider for cardio workout using a consistent URL generation
  ImageProvider getCardioImageProvider(Map<String, dynamic> workout) {
    final imageUrl = _getCardioWorkoutImageUrl(workout);
    final cacheKey = "cardio_${workout['workout']}_${workout['image']}";
    
    // Return existing provider if we already have it
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }
    
    //create provider and cache it
    final provider = CachedNetworkImageProvider(
      imageUrl,
      cacheKey: cacheKey,
    );
    
    _imageCache[cacheKey] = provider;
    return provider;
  }
  
  ///get cached image provider using a direct URL
  ImageProvider getImageProviderByUrl(String url, {String? cacheKey}) {
    final key = cacheKey ?? "image_$url";
    
    // Return existing provider if we already have it
    if (_imageCache.containsKey(key)) {
      return _imageCache[key]!;
    }
    
    // Create a new provider and cache it
    final provider = CachedNetworkImageProvider(
      url,
      cacheKey: key,
    );
    
    _imageCache[key] = provider;
    return provider;
  }
  
  /// Pre-load a workout image into the cache to ensure it's ready
  Future<void> preloadWorkoutImage(BuildContext context, WorkoutExercise workout) async {
    final provider = getWorkoutImageProvider(workout);
    
    // Force Flutter to precache this image
    precacheImage(provider, context);
  }
  
  /// Pre-load a cardio workout image into the cache
  Future<void> preloadCardioImage(BuildContext context, Map<String, dynamic> workout) async {
    final provider = getCardioImageProvider(workout);
    
    // Force Flutter to precache this image
    precacheImage(provider, context);
  }
  
  /// Pre-load a batch of workout images in the background
  Future<void> preloadWorkoutBatch(BuildContext context, List<WorkoutExercise> workouts) async {
    for (final workout in workouts) {
      await preloadWorkoutImage(context, workout);
    }
  }
  
  ///clear entire image cache
  void clearCache() {
    _imageCache.clear();
  }
  
  ///get full image URL for a workout exercise with consistent formatting
  String _getWorkoutImageUrl(WorkoutExercise workout) {
    if (workout.isCardio) {
      return ApiService.getCardioImageUrl(
        workout.image.replaceAll(' ', '-').toLowerCase()
      );
    } else {
      return ApiService.getWorkoutImageUrl(workout.image);
    }
  }
  
  /// Get the full image URL for a cardio workout with consistent formatting
  String _getCardioWorkoutImageUrl(Map<String, dynamic> workout) {
    final image = workout['image'] ?? '';
    return ApiService.getCardioImageUrl(image.replaceAll(' ', '-').toLowerCase());
  }
  
  /// Get a widget for displaying a workout image consistently throughout the app
  Widget getWorkoutImageWidget({
    required WorkoutExercise workout, 
    double? width, 
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final imageProvider = getWorkoutImageProvider(workout);
    final placeholder = _buildWorkoutPlaceholder(
      height: height, 
      width: width, 
      isCardio: workout.isCardio
    );
    
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      );
    }
    
    return Image(
      image: imageProvider,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
  
  /// Get a widget for displaying a cardio workout image consistently
  Widget getCardioImageWidget({
    required Map<String, dynamic> workout, 
    double? width, 
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final imageProvider = getCardioImageProvider(workout);
    final placeholder = _buildWorkoutPlaceholder(
      height: height, 
      width: width, 
      isCardio: true
    );
    
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image(
          image: imageProvider,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      );
    }
    
    return Image(
      image: imageProvider,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
  
  /// Build a consistent placeholder for workout images
  Widget _buildWorkoutPlaceholder({double? height, double? width, bool isCardio = false}) {
    return Container(
      height: height,
      width: width,
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCardio ? Icons.directions_run : Icons.fitness_center, 
              size: 40, 
              color: Colors.grey[700]
            ),
            if (height != null && height > 100)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Image not available', 
                  style: TextStyle(color: Colors.grey[700])
                ),
              ),
          ],
        ),
      ),
    );
  }
}