import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:fitmate/screens/workout_screens/active_workout_screen.dart';

// Workout Card Widget
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
                Image.network(
                  'http://192.168.0.186:8000/workout-images/${workout["workout"]!.replaceAll(' ', '-')}.webp',
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
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
                  child: Image.network(
                    'http://192.168.0.186:8000${workout["image"]}',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
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

// Main Screen
class TodaysWorkoutScreen extends StatefulWidget {
  @override
  _TodaysWorkoutScreenState createState() => _TodaysWorkoutScreenState();
}

class _TodaysWorkoutScreenState extends State<TodaysWorkoutScreen> {
  List<Map<String, String>> workouts = [];
  bool isLoading = true;
  String workoutCategory = '';
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    fetchWorkoutData();
  }

  Future<void> fetchWorkoutData() async {
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

      // Define workout sequence based on workout days
      Map<int, List<String>> workoutSequence = {
        3: ['Legs', 'Push', 'Pull'],
        4: ['Legs', 'Push', 'Pull', 'Core'],
        5: ['Legs', 'Push', 'Pull', 'Legs', 'Core'],
        6: ['Legs', 'Push', 'Pull', 'Legs', 'Push', 'Core']
      };

      List<String> sequence = workoutSequence[workoutDays] ?? workoutSequence[3]!;

      // Determine next workout category
      String nextCategory;
      if (lastCategory.isEmpty) {
        nextCategory = sequence[0];
      } else {
        int currentIndex = sequence.indexOf(lastCategory);
        nextCategory = sequence[(currentIndex + 1) % sequence.length];
      }

      setState(() {
        workoutCategory = nextCategory;
      });

      // Send request to your backend API
      final response = await http.post(
        Uri.parse("http://192.168.0.186:8000/generate_workout/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "age": userData["age"],
          "gender": userData["gender"],
          "height": userData["height"],
          "weight": userData["weight"],
          "goal": userData["goal"],
          "workoutDays": workoutDays,
          "fitnessLevel": userData["fitnessLevel"] ?? "Beginner",
          "lastWorkoutCategory": lastCategory
        }),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
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
        });
      } else {
        throw Exception("Failed to fetch workouts.");
      }
    } catch (e) {
      print("Error fetching workout data: $e");
      setState(() {
        isLoading = false;
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
          workoutCategory.toUpperCase(),
          style: GoogleFonts.bebasNeue(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : workouts.isEmpty
              ? const Center(child: Text("No workouts available."))
              : Column(
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
                              setState(() {
                                isLoading = true;
                              });
                              fetchWorkoutData();
                            },
                            icon: const Icon(
                              Icons.refresh,
                              color: Color(0xFFD2EB50),
                            ),
                            tooltip: 'Get new workout',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: workouts.length,
                        itemBuilder: (context, index) {
                          return WorkoutCard(workout: workouts[index]);
                        },
                      ),
                    ),
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