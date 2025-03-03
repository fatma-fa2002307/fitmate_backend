// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Your permanent Cloudflare Tunnel URL
  static const String baseUrl = 'https://pleasure-elimination-link-recreation.trycloudflare.com';


  
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
  }) async {
    try {
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
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate workout plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to server: $e');
    }
  }

  // Helper method to get the full URL for workout images
  static String getWorkoutImageUrl(String imagePath) {
    return '$baseUrl/workout-images/$imagePath';
  }

  // Helper method to get the full URL for workout icons
  static String getWorkoutIconUrl(String iconPath) {
    return '$baseUrl/workout-images/icons/$iconPath';
  }
}