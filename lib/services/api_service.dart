import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Your permanent Cloudflare Tunnel URL
  static const String baseUrl = 'https://tunnel.fitnessmates.net';
  static final _client = http.Client(); // Reuse HTTP client

  // Cache keys
  static const String WORKOUT_CACHE_KEY = 'cached_workout_data';

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

  // Helper method to get the full URL for workout images
  static String getWorkoutImageUrl(String imagePath) {
    // Handle both absolute and relative paths
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    // Ensure path starts with a slash
    if (!imagePath.startsWith('/')) {
      imagePath = '/$imagePath';
    }
    return '$baseUrl$imagePath';
  }

  // Helper method specifically for cardio images
  static String getCardioImageUrl(String filename) {
    // Ensure we're using the correct path format for cardio images
    return '$baseUrl/workout-images/cardio/$filename';
  }

  // Helper method to get the full URL for workout icons
  static String getWorkoutIconUrl(String iconPath) {
    // Handle both absolute and relative paths
    if (iconPath.startsWith('http')) {
      return iconPath;
    }
    // Ensure path starts with a slash
    if (!iconPath.startsWith('/')) {
      iconPath = '/$iconPath';
    }
    return '$baseUrl$iconPath';
  }
  
  // Check if an image exists on the server
  static Future<bool> checkImageExists(String url) async {
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print('Error checking image: $e');
      return false;
    }
  }
}