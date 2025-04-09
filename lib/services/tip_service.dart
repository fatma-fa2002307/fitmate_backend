import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/services/api_service.dart';

class TipService {
  static const String TIPS_CACHE_KEY = 'cached_tip_data';
  static const Duration CACHE_DURATION = Duration(hours: 4); //cache tip for 4 hours
  
  // Get a personalized tip for the user
  static Future<Map<String, dynamic>> getPersonalizedTip({
    bool useCache = true,
  }) async {
    try {
      // Check cache if requested
      if (useCache) {
        final cachedTip = await _getCachedTip();
        if (cachedTip != null) {
          print('Using cached tip: ${cachedTip['tip']}');
          return cachedTip;
        }
      }
      
      // Get current user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }
      
      // Get user data from Firestore
      final userData = await _getUserData(user.uid);
      print('Fetched user data for personalization: ${userData['goal']}');
      
      // Get recent workouts
      final recentWorkouts = await _getRecentWorkouts(user.uid);
      print('Fetched ${recentWorkouts.length} recent workouts for personalization');
      
      // Get today's food logs
      final foodLogs = await _getTodaysFoodLogs(user.uid);
      print('Fetched ${foodLogs.length} food logs for personalization');
      
      // Calculate calorie percentage
      final calorieData = await _getCalorieData(user.uid);
      double caloriePercentage = 0.0;
      if (calorieData['totalCalories'] > 0 && calorieData['dailyCaloriesGoal'] > 0) {
        caloriePercentage = calorieData['totalCalories'] / calorieData['dailyCaloriesGoal'];
      }
      
      // Prepare request data
      final Map<String, dynamic> requestData = {
        'userId': user.uid,
        'goal': userData['goal'] ?? 'Improve Fitness',
        'gender': userData['gender'] ?? 'Unspecified',
        'fitnessLevel': userData['fitnessLevel'] ?? 'Intermediate',
        'workoutDays': userData['workoutDays'] ?? 3,
        'caloriePercentage': caloriePercentage,
      };
      
      // Add sanitized data (convert Firebase types to simple types)
      final sanitizedWorkouts = _sanitizeFirebaseData(recentWorkouts);
      final sanitizedFoodLogs = _sanitizeFirebaseData(foodLogs);
      
      requestData['recentWorkouts'] = sanitizedWorkouts;
      requestData['foodLogs'] = sanitizedFoodLogs;
      
      // Send request to backend
      print('Sending personalized tip request with sanitized data');
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/generate_personalized_tip/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );
      
      if (response.statusCode == 200) {
        final resultData = jsonDecode(response.body);
        print('Received personalized tip: ${resultData['tip']}');
        
        // Cache the result
        await _cacheTip(resultData);
        
        return resultData;
      } else {
        print('Error from tip API: ${response.statusCode} - ${response.body}');
        // Return a fallback tip if request fails
        return _getFallbackTip();
      }
    } catch (e) {
      print('Error getting personalized tip: $e');
      return _getFallbackTip();
    }
  }
  
  // Sanitize Firebase data (convert Timestamps to ISO strings and remove complex objects)
  static List<Map<String, dynamic>> _sanitizeFirebaseData(List<Map<String, dynamic>> data) {
    final sanitizedData = <Map<String, dynamic>>[];
    
    for (var item in data) {
      final sanitizedItem = <String, dynamic>{};
      
      item.forEach((key, value) {
        if (value is Timestamp) {
          // Convert Timestamp to ISO string
          sanitizedItem[key] = value.toDate().toIso8601String();
        } else if (value is DateTime) {
          // Convert DateTime to ISO string
          sanitizedItem[key] = value.toIso8601String();
        } else if (value is num || value is String || value is bool || value == null) {
          // Keep simple types
          sanitizedItem[key] = value;
        } else if (value is Map<String, dynamic>) {
          // Recursively sanitize nested maps
          try {
            sanitizedItem[key] = _sanitizeMap(value);
          } catch (e) {
            // Skip if conversion fails
            print('Error sanitizing nested map: $e');
          }
        } else if (value is List) {
          // Skip complex lists that might contain unsupported types
          try {
            // Try to sanitize list items
            sanitizedItem[key] = _sanitizeList(value);
          } catch (e) {
            // Skip if conversion fails
            print('Error sanitizing list: $e');
          }
        }
        // Skip other complex types
      });
      
      sanitizedData.add(sanitizedItem);
    }
    
    return sanitizedData;
  }
  
  // Helper to sanitize maps
  static Map<String, dynamic> _sanitizeMap(Map<String, dynamic> map) {
    final sanitizedMap = <String, dynamic>{};
    
    map.forEach((key, value) {
      if (value is Timestamp) {
        sanitizedMap[key] = value.toDate().toIso8601String();
      } else if (value is DateTime) {
        sanitizedMap[key] = value.toIso8601String();
      } else if (value is num || value is String || value is bool || value == null) {
        sanitizedMap[key] = value;
      } else if (value is Map<String, dynamic>) {
        sanitizedMap[key] = _sanitizeMap(value);
      } else if (value is List) {
        sanitizedMap[key] = _sanitizeList(value);
      }
    });
    
    return sanitizedMap;
  }
  
  // Helper to sanitize lists
  static List<dynamic> _sanitizeList(List<dynamic> list) {
    final sanitizedList = <dynamic>[];
    
    for (var item in list) {
      if (item is Timestamp) {
        sanitizedList.add(item.toDate().toIso8601String());
      } else if (item is DateTime) {
        sanitizedList.add(item.toIso8601String());
      } else if (item is num || item is String || item is bool || item == null) {
        sanitizedList.add(item);
      } else if (item is Map<String, dynamic>) {
        sanitizedList.add(_sanitizeMap(item));
      } else if (item is List) {
        sanitizedList.add(_sanitizeList(item));
      }
    }
    
    return sanitizedList;
  }
  
  // Get user data from Firestore
  static Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() ?? {};
        
        // Convert any complex objects like Timestamps
        final sanitizedData = <String, dynamic>{};
        userData.forEach((key, value) {
          if (value is Timestamp) {
            sanitizedData[key] = value.toDate().toIso8601String();
          } else {
            sanitizedData[key] = value;
          }
        });
        
        return sanitizedData;
      }
      
      return {};
    } catch (e) {
      print('Error getting user data: $e');
      return {};
    }
  }
  
  // Get recent workouts from Firestore
  static Future<List<Map<String, dynamic>>> _getRecentWorkouts(String userId) async {
    try {
      final lastTwoWeeks = DateTime.now().subtract(const Duration(days: 14));
      
      final workoutDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('workoutLogs')
          .where('date', isGreaterThanOrEqualTo: lastTwoWeeks)
          .orderBy('date', descending: true)
          .limit(10)
          .get();
      
      return workoutDocs.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('Error getting recent workouts: $e');
      return [];
    }
  }
  
  // Get today's food logs from Firestore
  static Future<List<Map<String, dynamic>>> _getTodaysFoodLogs(String userId) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      final foodDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('foodLogs')
          .where('date', isGreaterThanOrEqualTo: today)
          .where('date', isLessThan: tomorrow)
          .get();
      
      return foodDocs.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      print('Error getting food logs: $e');
      return [];
    }
  }
  
  // Get calorie data for the user
  static Future<Map<String, dynamic>> _getCalorieData(String userId) async {
    try {
      // Get user macros
      final macroDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('userMacros')
          .doc('macro')
          .get();
      
      double dailyCaloriesGoal = 2000.0; // Default
      if (macroDoc.exists) {
        dailyCaloriesGoal = (macroDoc.data()?['calories'] ?? 2000).toDouble();
      }
      
      // Get today's food logs to calculate total calories
      final foodLogs = await _getTodaysFoodLogs(userId);
      
      double totalCalories = 0.0;
      for (var food in foodLogs) {
        totalCalories += (food['calories'] ?? 0).toDouble();
      }
      
      return {
        'totalCalories': totalCalories,
        'dailyCaloriesGoal': dailyCaloriesGoal,
      };
    } catch (e) {
      print('Error getting calorie data: $e');
      return {
        'totalCalories': 0.0,
        'dailyCaloriesGoal': 2000.0,
      };
    }
  }
  
  // Save tip to cache
  static Future<void> _cacheTip(Map<String, dynamic> tipData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = {
        'tip': tipData,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(TIPS_CACHE_KEY, jsonEncode(cachedData));
      print('Tip cached successfully');
    } catch (e) {
      print('Error caching tip: $e');
    }
  }
  
  // Get cached tip if it's still valid
  static Future<Map<String, dynamic>?> _getCachedTip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDataString = prefs.getString(TIPS_CACHE_KEY);
      
      if (cachedDataString == null) {
        return null;
      }
      
      final cachedData = jsonDecode(cachedDataString);
      final timestamp = cachedData['timestamp'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      
      // Check if cache is still valid
      if (now.difference(cachedTime) < CACHE_DURATION) {
        return cachedData['tip'];
      }
      
      return null;
    } catch (e) {
      print('Error getting cached tip: $e');
      return null;
    }
  }
  
  // Get a fallback tip if API request fails
  static Map<String, dynamic> _getFallbackTip() {
    final fallbackTips = [
      {
        "tip": "💧 Make water your BFF! Try infusing it with fruits for a flavor party that keeps you hydrated and happy!",
        "category": "hydration",
        "icon": "water_drop"
      },
      {
        "tip": "🥦 Pro tip: Sneak in veggies like a nutrition ninja! Add spinach to your smoothie for a stealth health upgrade!",
        "category": "nutrition",
        "icon": "nutrition_restaurant"
      },
      {
        "tip": "💪 Quality beats quantity! Master your squat form before adding weight—your knees will send you a thank-you card!",
        "category": "workout",
        "icon": "fitness_center"
      },
      {
        "tip": "✨ Remember: Rome wasn't built in a day, and neither are awesome biceps! Keep showing up for yourself!",
        "category": "motivation",
        "icon": "emoji_events"
      },
      {
        "tip": "😴 Rest isn't being lazy—it's when your muscles throw their build-back-better party! Give them time to celebrate!",
        "category": "recovery",
        "icon": "self_improvement"
      }
    ];
    
    // Select a random tip
    final random = fallbackTips[DateTime.now().millisecond % fallbackTips.length];
    
    // Add generated timestamp
    random['generated_at'] = DateTime.now().toIso8601String();
    
    print('Using fallback tip: ${random['tip']}');
    return random;
  }
}