import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:fitmate/screens/workout_screens/active_workout_screen.dart';
import 'package:fitmate/services/api_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitmate/widgets/workout_skeleton.dart';

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

// Main Screen
class TodaysWorkoutScreen extends StatefulWidget {
  @override
  _TodaysWorkoutScreenState createState() => _TodaysWorkoutScreenState();
}

class _TodaysWorkoutScreenState extends State<TodaysWorkoutScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Map<String, List<Map<String, String>>> _workoutOptions = {};
  bool isLoading = true;
  String workoutCategory = '';
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    // Start with a clean slate - always
    _workoutOptions = {};
    workoutCategory = '';
    _loadWorkoutOptions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadWorkoutOptions() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      // Get the currently logged-in user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("No user is logged in.");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      // Fetch workout options from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        print("User document not found.");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }

      // Extract user details
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      // Get stored workout options
      Map<String, dynamic>? workoutOptionsMap = userData['workoutOptions'] as Map<String, dynamic>?;
      String? nextCategory = userData['nextWorkoutCategory'] as String?;
      
      if (workoutOptionsMap != null && workoutOptionsMap.isNotEmpty && nextCategory != null) {
        // Convert Firebase map to our expected format
        Map<String, List<Map<String, String>>> typedWorkoutOptions = {};
        
        workoutOptionsMap.forEach((key, workoutList) {
          List<Map<String, String>> typedWorkoutList = [];
          
          for (var workout in workoutList) {
            typedWorkoutList.add({
              "workout": workout["workout"] as String,
              "image": workout["image"] as String,
              "sets": workout["sets"] as String,
              "reps": workout["reps"] as String,
              "instruction": workout["instruction"] as String,
            });
          }
          
          typedWorkoutOptions[key] = typedWorkoutList;
        });
        
        if (mounted) {
          setState(() {
            _workoutOptions = typedWorkoutOptions;
            workoutCategory = nextCategory;
            isLoading = false;
          });
        }
      } else {
        print("No workout options found. Generating new workouts.");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print("Error loading workout options: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Convert map to list for pagination
    List<List<Map<String, String>>> workoutOptionsList = [];
    if (_workoutOptions.isNotEmpty) {
      _workoutOptions.forEach((key, value) {
        workoutOptionsList.add(value);
      });
    }
    
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
      body: isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                ),
                SizedBox(height: 20),
                Text(
                  "Please stand by...\nLoading your workout options",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          )
        : workoutOptionsList.isEmpty 
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
                  const Text("No workouts available."),
                  const SizedBox(height: 20),
                  const Text(
                    "Please check back later",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Workout Option ${_currentPage + 1} / ${workoutOptionsList.length}',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Workout Pagination Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(workoutOptionsList.length, (index) {
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? const Color(0xFFD2EB50)
                            : Colors.grey.shade300,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Page View for workout options
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemCount: workoutOptionsList.length,
                    itemBuilder: (context, pageIndex) {
                      final workouts = workoutOptionsList[pageIndex];
                      return ListView.builder(
                        itemCount: workouts.length,
                        itemBuilder: (context, index) {
                          return WorkoutCard(workout: workouts[index]);
                        },
                      );
                    },
                  ),
                ),
                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous button
                      ElevatedButton(
                        onPressed: _currentPage > 0
                            ? () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          disabledBackgroundColor: Colors.grey[200],
                        ),
                        child: const Text('Previous'),
                      ),
                      // Next button
                      ElevatedButton(
                        onPressed: _currentPage < workoutOptionsList.length - 1
                            ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          disabledBackgroundColor: Colors.grey[200],
                        ),
                        child: const Text('Next'),
                      ),
                    ],
                  ),
                ),
                // Start workout button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: workoutOptionsList.isNotEmpty
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ActiveWorkoutScreen(
                                  workouts: workoutOptionsList[_currentPage],
                                  category: workoutCategory,
                                ),
                              ),
                            );
                          }
                        : null,
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
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

// Fresh wrapper class
class FreshTodaysWorkoutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TodaysWorkoutScreen();
  }
}