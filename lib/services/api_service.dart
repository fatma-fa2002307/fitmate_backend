import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Your permanent Cloudflare Tunnel URL
  static const String baseUrl = 'https://tunnel.fitnessmates.net';
  static final _client = http.Client(); // Reuse HTTP client

  // Cache keys
  static const String WORKOUT_CACHE_KEY = 'cached_workout_data';
  static const String WORKOUT_IMAGES_CACHE_PREFIX = 'workout_image_';

  // Generate workout plan
  static Future<Map<String, dynamic>> generateWorkout({
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String goal,
    required int workoutDays,
    required String fitnessLevel,
    String? lastWorkoutCategory,
    bool useCache = true,
  }) async {
    try {
      // Check cache if requested
      if (useCache) {
        final prefs = await SharedPreferences.getInstance();
        final cachedData = prefs.getString(WORKOUT_CACHE_KEY);
        if (cachedData != null) {
          return jsonDecode(cachedData);
        }
      }
      final response = await http.post(
        Uri.parse('$baseUrl/generate_workout/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'age': age,
          'gender': gender,
          'height': height,
          'weight': weight,
          'goal': goal,
          'workoutDays': workoutDays,
          'fitnessLevel': fitnessLevel,
          'lastWorkoutCategory': lastWorkoutCategory ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final resultData = jsonDecode(response.body);

        // Save to cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(WORKOUT_CACHE_KEY, response.body);

        return resultData;

      } else {
        throw Exception(
            'Failed to generate workout plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // Generate multiple workout options at once
  static Future<Map<String, dynamic>> generateWorkoutOptions({
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String goal,
    required int workoutDays,
    required String fitnessLevel,
    String? lastWorkoutCategory,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate_workout_options/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'age': age,
          'gender': gender,
          'height': height,
          'weight': weight,
          'goal': goal,
          'workoutDays': workoutDays,
          'fitnessLevel': fitnessLevel,
          'lastWorkoutCategory': lastWorkoutCategory ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final resultData = jsonDecode(response.body);
        return resultData;
      } else {
        throw Exception(
            'Failed to generate workout options: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // Helper method to get the full URL for workout images with consistent formatting
  static String getWorkoutImageUrl(String imagePath) {
    // Handle both absolute and relative paths
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // Format the image path properly
    String formattedPath = imagePath;
    
    // Check if the path already contains the workout-images prefix
    bool hasWorkoutImagesPrefix = formattedPath.contains('workout-images');
    bool hasCardioPrefix = formattedPath.contains('cardio');
    
    // Remove any double slashes
    while (formattedPath.contains('//')) {
      formattedPath = formattedPath.replaceAll('//', '/');
    }
    
    // Ensure path starts with a slash
    if (!formattedPath.startsWith('/')) {
      formattedPath = '/$formattedPath';
    }
    
    // Add the proper prefix for workout images if not present
    if (!hasWorkoutImagesPrefix && !hasCardioPrefix && !formattedPath.startsWith('/workout-icons')) {
      formattedPath = '/workout-images$formattedPath';
    }
    
    // Return the full URL
    return '$baseUrl$formattedPath';
  }

  // Helper method specifically for cardio images with consistent formatting
  static String getCardioImageUrl(String filename) {
    // Handle if the filename already has the full path
    if (filename.contains('workout-images/cardio')) {
      // It already has the correct path format, just normalize it
      String normalizedPath = filename;
      
      // Remove any double slashes
      while (normalizedPath.contains('//')) {
        normalizedPath = normalizedPath.replaceAll('//', '/');
      }
      
      // Ensure path starts with a slash
      if (!normalizedPath.startsWith('/')) {
        normalizedPath = '/$normalizedPath';
      }
      
      return '$baseUrl$normalizedPath';
    }

    // Clean the filename and ensure proper formatting
    String cleanFilename = filename.trim();
    
    // If the filename doesn't have an extension, add .webp
    if (!cleanFilename.contains('.')) {
      cleanFilename = '$cleanFilename.webp';
    }
    
    // Ensure we're using the correct path format for cardio images
    return '$baseUrl/workout-images/cardio/$cleanFilename';
  }

  // Helper method to get the full URL for workout icons with consistent formatting
  static String getWorkoutIconUrl(String iconPath) {
    // Handle both absolute and relative paths
    if (iconPath.startsWith('http')) {
      return iconPath;
    }
    
    // Check if the path already has the workout-icons prefix
    bool hasIconsPrefix = iconPath.contains('workout-icons');
    
    // Format the icon path properly
    String formattedPath = iconPath;
    
    // Remove any double slashes
    while (formattedPath.contains('//')) {
      formattedPath = formattedPath.replaceAll('//', '/');
    }
    
    // Ensure path starts with a slash
    if (!formattedPath.startsWith('/')) {
      formattedPath = '/$formattedPath';
    }
    
    // Add the proper prefix for icons if not present
    if (!hasIconsPrefix) {
      formattedPath = '/workout-icons$formattedPath';
    }
    
    return '$baseUrl$formattedPath';
  }
  
  // Check if an image exists on the server and cache the result
  static Future<bool> checkImageExists(String url) async {
    try {
      // First check SharedPreferences for a cached result to avoid network request
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${WORKOUT_IMAGES_CACHE_PREFIX}${url.hashCode}';
      
      // Check if we have a cached result for this URL
      if (prefs.containsKey(cacheKey)) {
        return prefs.getBool(cacheKey) ?? false;
      }
      
      // If not cached, make a HEAD request to check if the image exists
      final response = await http.head(Uri.parse(url));
      final exists = response.statusCode == 200;
      
      // Cache the result for future checks
      await prefs.setBool(cacheKey, exists);
      
      return exists;
    } catch (e) {
      print('Error checking image: $e');
      return false;
    }
  }
  
  // Clear the image existence cache - useful when refreshing data
  static Future<void> clearImageExistenceCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all keys
      final keys = prefs.getKeys();
      
      // Filter for image cache keys
      final imageCacheKeys = keys.where(
        (key) => key.startsWith(WORKOUT_IMAGES_CACHE_PREFIX)
      ).toList();
      
      // Remove each key
      for (final key in imageCacheKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Error clearing image cache: $e');
    }
  }
}