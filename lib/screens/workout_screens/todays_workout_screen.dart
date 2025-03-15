import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:fitmate/screens/workout_screens/active_workout_screen.dart';
import 'package:fitmate/screens/workout_screens/cardio_active_workout_screen.dart';
import 'package:fitmate/services/api_service.dart';
import 'package:fitmate/services/workout_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitmate/widgets/workout_skeleton.dart';
import 'package:fitmate/widgets/cardio_workout_card.dart';

class WorkoutCard extends StatelessWidget {
  final Map<String, dynamic> workout;
  
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
            width: MediaQuery.of(context).size.width * 0.85,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title of the exercise
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    workout["workout"]!,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Sets and reps information
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    "${workout["sets"]} sets × ${workout["reps"]} reps",
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Image of the exercise
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: CachedNetworkImage(
                    imageUrl: ApiService.baseUrl + '/workout-images/' + 
                      '${workout["workout"]!.replaceAll(' ', '-')}.webp',
                    height: 260,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: Colors.white,
                      height: 260,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD2EB50),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print("Error loading image for workout: ${workout["workout"]} - Error: $error");
                      return Container(
                        height: 260,
                        color: Colors.white,
                        child: Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
                      );
                    },
                  ),
                ),
                
                // Simple "Got it" button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2EB50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Got it',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showInstructionDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[100],
                  child: CachedNetworkImage(
                    imageUrl: ApiService.baseUrl + workout["image"]!,
                    fit: BoxFit.contain, // Use contain to preserve aspect ratio
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
                      return Icon(Icons.fitness_center, size: 30, color: Colors.grey[700]);
                    },
                  ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${workout["sets"]} sets × ${workout["reps"]} reps',
                      style: GoogleFonts.dmSans(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  color: Color(0xFFD2EB50), // Just the icon, no white background
                ),
                onPressed: () => _showInstructionDialog(context),
                tooltip: 'View exercise details',
              ),
            ],
          ),
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

class _TodaysWorkoutScreenState extends State<TodaysWorkoutScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _loadingAnimation;
  
  int _currentPage = 0;
  Map<String, List<Map<String, dynamic>>> _workoutOptions = {};
  bool _isLoading = true;
  bool _hasError = false;
  String _statusMessage = '';
  String? _workoutCategory;
  int _selectedIndex = 1;
  bool _isRetrying = false;
  int _retryCount = 0;
  final int _maxRetries = 5;
  bool _isCardioWorkout = false;

  final List<String> _loadingMessages = [
    'Getting your workout ready...',
    'Creating your personalized plan...',
    'Almost there...',
    'Putting together your exercises...',
    'Final touches on your workout...',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    _loadingAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    
    // Start with a clean slate
    _workoutOptions = {};
    _workoutCategory = null;
    _loadWorkoutOptions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Improved retry mechanism with user-friendly messages
  Future<void> _loadWorkoutOptions() async {
    _retryCount = 0;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _statusMessage = 'Getting your workout ready...';
    });
    
    try {
      // Get the currently logged-in user
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _statusMessage = 'Please sign in to view your workouts';
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
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _statusMessage = 'Unable to find your profile. Please try again';
          });
        }
        return;
      }

      // Extract user details
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      
      // Check for workout options
      await _checkAndLoadWorkouts(userData, user.uid);
      
    } catch (e) {
      print("Error loading workout options: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _statusMessage = 'Unable to load your workout. Please try again';
        });
      }
    }
  }

  Future<void> _checkAndLoadWorkouts(Map<String, dynamic> userData, String userId) async {
    // Get stored workout options
    Map<String, dynamic>? workoutOptionsMap = userData['workoutOptions'] as Map<String, dynamic>?;
    String? nextCategory = userData['nextWorkoutCategory'] as String?;
    
    // Check if workout generation is already in progress
    Timestamp? lastGenerated = userData['workoutsLastGenerated'] as Timestamp?;
    bool recentlyGenerated = false;
    
    if (lastGenerated != null) {
      DateTime lastGeneratedTime = lastGenerated.toDate();
      DateTime now = DateTime.now();
      Duration difference = now.difference(lastGeneratedTime);
      
      // If workout was generated less than 20 seconds ago, consider it "in progress"
      if (difference.inSeconds < 20) {
        recentlyGenerated = true;
        await _retryLoadingWorkout(userId);
        return;
      }
    }
    
    // If we have valid workout data
    if (workoutOptionsMap != null && workoutOptionsMap.isNotEmpty && nextCategory != null) {
      _processWorkoutData(workoutOptionsMap, nextCategory);
    } else if (recentlyGenerated) {
      // If we've exhausted all retries and still no workout data
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _statusMessage = 'Your workout is still being created. Please try again in a moment';
        });
      }
    } else {
      // No workout options found, generate new ones
      await _generateWorkouts(userData);
    }
  }
  
  Future<void> _retryLoadingWorkout(String userId) async {
    _isRetrying = true;
    
    for (_retryCount = 0; _retryCount < _maxRetries; _retryCount++) {
      if (!mounted) return;
      
      // Update loading message
      setState(() {
        _statusMessage = _loadingMessages[_retryCount % _loadingMessages.length];
      });
      
      // Wait with increasing delay between attempts
      await Future.delayed(Duration(seconds: _retryCount + 1));
      
      if (!mounted) return;
      
      // Fetch the updated data
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          Map<String, dynamic>? workoutOptionsMap = userData['workoutOptions'] as Map<String, dynamic>?;
          String? nextCategory = userData['nextWorkoutCategory'] as String?;
          
          // If we have valid workout data now, process it and exit
          if (workoutOptionsMap != null && workoutOptionsMap.isNotEmpty && nextCategory != null) {
            _processWorkoutData(workoutOptionsMap, nextCategory);
            _isRetrying = false;
            return;
          }
        }
      } catch (e) {
        print("Error in retry attempt $_retryCount: $e");
        // Continue to next attempt
      }
    }
    
    // If we get here, all retries failed
    _isRetrying = false;
    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _statusMessage = 'We\'re having trouble creating your workout. Please try again';
      });
    }
  }
  
  void _processWorkoutData(Map<String, dynamic> workoutOptionsMap, String nextCategory) {
    // Convert Firebase map to our expected format
    Map<String, List<Map<String, dynamic>>> typedWorkoutOptions = {};
    
    workoutOptionsMap.forEach((key, workoutList) {
      List<Map<String, dynamic>> typedWorkoutList = [];
      
      for (var workout in workoutList) {
        // Check if this is a cardio workout by looking for cardio-specific fields
        bool isCardio = false;
        Map<String, dynamic> typedWorkout = {};
        
        if (workout.containsKey('duration') || workout.containsKey('intensity') || 
            workout.containsKey('format') || workout.containsKey('calories') || 
            workout.containsKey('is_cardio')) {
          isCardio = true;
          typedWorkout = {
            "workout": workout["workout"] as String,
            "image": workout["image"] as String,
            "duration": workout["duration"] as String? ?? "30 min",
            "intensity": workout["intensity"] as String? ?? "Moderate",
            "format": workout["format"] as String? ?? "Steady-state",
            "calories": workout["calories"] as String? ?? "300-350",
            "description": workout["description"] as String? ?? "Perform at a comfortable pace.",
            "is_cardio": true
          };
        } else {
          // Regular strength workout
          typedWorkout = {
            "workout": workout["workout"] as String,
            "image": workout["image"] as String,
            "sets": workout["sets"] as String,
            "reps": workout["reps"] as String,
            "instruction": workout["instruction"] as String? ?? "",
          };
        }
        
        typedWorkoutList.add(typedWorkout);
      }
      
      typedWorkoutOptions[key] = typedWorkoutList;
    });
    
    if (mounted) {
      setState(() {
        _workoutOptions = typedWorkoutOptions;
        _workoutCategory = nextCategory;
        _isCardioWorkout = nextCategory.toLowerCase() == 'cardio';
        _isLoading = false;
        _hasError = false;
      });
    }
  }

  Future<void> _generateWorkouts(Map<String, dynamic> userData) async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Creating a new workout just for you...';
      });
      
      await WorkoutService.generateAndSaveWorkoutOptions(
        age: userData['age'] ?? 30,
        gender: userData['gender'] ?? 'Male',
        height: (userData['height'] ?? 170).toDouble(),
        weight: (userData['weight'] ?? 70).toDouble(),
        goal: userData['goal'] ?? 'Improve Fitness',
        workoutDays: userData['workoutDays'] ?? 3,
        fitnessLevel: userData['fitnessLevel'] ?? 'Beginner',
        lastWorkoutCategory: userData['lastWorkoutCategory'],
      );
      
      // After generating workouts, retry loading with the new data
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _retryLoadingWorkout(user.uid);
      }
    } catch (e) {
      print("Error generating workouts: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _statusMessage = 'Unable to create your workout. Please try again';
        });
      }
    }
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingAnimation, 
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Color(0xFFD2EB50).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(0xFFD2EB50).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(0xFFD2EB50),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.fitness_center,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          ),
          SizedBox(height: 30),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          if (_isRetrying) ...[
            SizedBox(height: 20),
            Container(
              width: 200,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (_retryCount + 1) / (_maxRetries + 1),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFD2EB50),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.refresh_rounded, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _loadWorkoutOptions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2EB50),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fitness_center, size: 50, color: Color(0xFFD2EB50)),
            ),
            const SizedBox(height: 24),
            Text(
              "Ready to start your fitness journey?",
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Let's create a personalized workout plan for you",
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                // Try to fetch user data and generate workouts
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  final userData = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .get();
                      
                  if (userData.exists) {
                    _generateWorkouts(userData.data() as Map<String, dynamic>);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2EB50),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Create Workout Plan',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutView(List<List<Map<String, dynamic>>> workoutOptionsList) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Workout Option ${_currentPage + 1} of ${workoutOptionsList.length}',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              // Workout Pagination Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(workoutOptionsList.length, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: _currentPage == index ? 20 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: _currentPage == index
                          ? const Color(0xFFD2EB50)
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
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
              
              // Check if this is a cardio workout
              if (_isCardioWorkout && workouts.isNotEmpty && workouts[0].containsKey('is_cardio')) {
                // Use CardioWorkoutCard for cardio workouts
                return ListView.builder(
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    return CardioWorkoutCard(workout: workouts[index]);
                  },
                );
              } else {
                // Use regular WorkoutCard for strength training
                return ListView.builder(
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    return WorkoutCard(workout: workouts[index]);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStartButton(List<List<Map<String, dynamic>>> workoutOptionsList) {
    if (workoutOptionsList.isEmpty) return SizedBox.shrink();
    
    final currentWorkouts = workoutOptionsList[_currentPage];
    final isCardio = _isCardioWorkout && currentWorkouts.isNotEmpty && currentWorkouts[0].containsKey('is_cardio');
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (isCardio) {
            // Navigate to cardio-specific workout screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardioActiveWorkoutScreen(
                  workout: currentWorkouts[0],
                  category: _workoutCategory ?? 'Cardio',
                ),
              ),
            );
          } else {
            // Navigate to regular workout screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActiveWorkoutScreen(
                  workouts: currentWorkouts,
                  category: _workoutCategory ?? 'Workout',
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD2EB50),
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // Convert map to list for pagination
    List<List<Map<String, dynamic>>> workoutOptionsList = [];
    if (_workoutOptions.isNotEmpty) {
      _workoutOptions.forEach((key, value) {
        workoutOptionsList.add(value);
      });
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _workoutCategory?.isNotEmpty == true ? _workoutCategory!.toUpperCase() : 'TODAY\'S WORKOUT',
          style: GoogleFonts.bebasNeue(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasError)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black54),
              onPressed: _loadWorkoutOptions,
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? _buildLoadingView()
              : _hasError
                ? _buildErrorView()
                : workoutOptionsList.isEmpty 
                  ? _buildEmptyView()
                  : _buildWorkoutView(workoutOptionsList),
          ),
          // Fixed bottom button
          if (!_isLoading && !_hasError && workoutOptionsList.isNotEmpty)
            _buildBottomStartButton(workoutOptionsList),
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