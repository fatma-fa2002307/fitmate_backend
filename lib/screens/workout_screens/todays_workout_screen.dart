// lib/screens/workout_screens/todays_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:fitmate/screens/workout_screens/active_workout_screen.dart';
import 'package:fitmate/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutCard extends StatelessWidget {
  final Map<String, String> workout;
  
  const WorkoutCard({Key? key, required this.workout}) : super(key: key);

  void _showInstructionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  workout["workout"]!,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                CachedNetworkImage(
                  imageUrl: ApiService.getWorkoutImageUrl(
                    '${workout["workout"]!.replaceAll(' ', '-')}.webp'
                  ),
                  height: 200,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD2EB50),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    print("Error loading image for workout: ${workout["workout"]} - Error: $error");
                    return const Icon(Icons.fitness_center, size: 100);
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD2EB50),
                  ),
                  child: const Text('Got it'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  child: CachedNetworkImage(
                    imageUrl: ApiService.baseUrl + workout["image"]!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD2EB50),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print("Error loading image: $error");
                      return const Icon(Icons.fitness_center);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout["workout"]!,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${workout["sets"]} sets × ${workout["reps"]} reps',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () => _showInstructionDialog(context),
                  color: const Color(0xFFD2EB50),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Skeleton widget for loading state
class WorkoutSkeleton extends StatelessWidget {
  const WorkoutSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 20,
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 16,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Main Screen
class TodaysWorkoutScreen extends StatefulWidget {
  @override
  _TodaysWorkoutScreenState createState() => _TodaysWorkoutScreenState();
}

class _TodaysWorkoutScreenState extends State<TodaysWorkoutScreen> {
  List<Map<String, String>> workouts = [];
  bool isLoading = true;
  bool isRefreshing = false;
  String workoutCategory = '';
  int _selectedIndex = 1;
  static const String WORKOUT_CACHE_KEY = 'cached_workout_data';

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Try to load from cache first
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(WORKOUT_CACHE_KEY);
      
      if (cachedData != null) {
        final data = jsonDecode(cachedData);
        setState(() {
          workouts = (data["workouts"] as List<dynamic>)
            .map<Map<String, String>>((item) => {
                "workout": item["workout"].toString(),
                "image": item["image"].toString(),
                "sets": item["sets"].toString(),
                "reps": item["reps"].toString(),
                "instruction": item["instruction"].toString(),
              })
            .toList();
          workoutCategory = data["category"] ?? '';
          isLoading = false;
        });
        return; // Exit early if cache was loaded successfully
      }
      
      // If no cache, fetch workout data
      await fetchWorkoutData();
    } catch (e) {
      print("Error loading workout data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Update your existing fetchWorkoutData to handle refreshing
  Future<void> fetchWorkoutData({bool forceRefresh = false}) async {
    if (forceRefresh) {
      setState(() {
        isRefreshing = true;
      });
    } else if (isLoading == false) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      // Get the currently logged-in user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user is logged in.");
        return;
      }

      // Fetch user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        print("User document not found.");
        return;
      }

      // Extract user details
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      // Get the last workout category to determine next workout
      String lastCategory = userData['lastWorkoutCategory'] ?? '';
      int workoutDays = userData['workoutDays'] ?? 3;

      setState(() {
        workoutCategory = lastCategory;
      });

      try {
        // Use the API service
        final responseData = await ApiService.generateWorkout(
          age: userData["age"] ?? 30,
          gender: userData["gender"] ?? "Male",
          height: (userData["height"] ?? 170).toDouble(),
          weight: (userData["weight"] ?? 70).toDouble(),
          goal: userData["goal"] ?? "Improve Fitness",
          workoutDays: userData["workoutDays"] ?? 3,
          fitnessLevel: userData["fitnessLevel"] ?? "Beginner",
          lastWorkoutCategory: lastCategory,
          useCache: !forceRefresh, 
        );

        // Clear the old cache if forcing refresh
        if (forceRefresh) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove(WORKOUT_CACHE_KEY);
        }
        
        // Save to cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(WORKOUT_CACHE_KEY, jsonEncode(responseData));

        setState(() {
          workouts = (responseData["workouts"] as List<dynamic>)
              .map<Map<String, String>>((item) => {
                    "workout": item["workout"].toString(),
                    "image": item["image"].toString(),
                    "sets": item["sets"].toString(),
                    "reps": item["reps"].toString(),
                    "instruction": item["instruction"].toString(),
                  })
              .toList();
          isLoading = false;
          isRefreshing = false;
          workoutCategory = responseData["category"] ?? '';
        });
      } catch (e) {
        print("API Error: $e");
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
        // Show error dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Error Loading Workouts'),
              content: Text('Failed to load workouts from server: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print("Error fetching workout data: $e");
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          workoutCategory.isEmpty ? 'TODAY\'S WORKOUT' : workoutCategory.toUpperCase(),
          style: GoogleFonts.bebasNeue(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Do not like the workout?',
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () {
                    fetchWorkoutData(forceRefresh: true);
                  },
                  icon: isRefreshing 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Color(0xFFD2EB50),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: Color(0xFFD2EB50),
                      ),
                  tooltip: 'Get new workout',
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
              ? WorkoutSkeleton()  // Show skeleton while loading
              : workouts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                        const Text("No workouts available."),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => fetchWorkoutData(forceRefresh: true),
                          child: const Text("Try Again"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD2EB50),
                          ),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: workouts.length,
                    itemBuilder: (context, index) {
                      return WorkoutCard(workout: workouts[index]);
                    },
                  ),
          ),
          if (!isLoading && workouts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ActiveWorkoutScreen(
                        workouts: workouts,
                        category: workoutCategory,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD2EB50),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: Text(
                  'START',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}