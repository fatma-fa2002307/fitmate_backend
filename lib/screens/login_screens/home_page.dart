import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/screens/login_screens/edit_profile.dart';
import 'package:fitmate/widgets/caloriesWidget.dart';
import 'package:fitmate/widgets/personalized_tip_box.dart';
import 'package:fitmate/widgets/userLevelWidget.dart';
import 'package:fitmate/widgets/water_intake_widget.dart';
import 'package:fitmate/widgets/workoutWidget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';

// Main HomePage widget with significantly reduced code
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String _userFullName = "Loading...";
  String _userGoal = "Loading...";
  double _totalCalories = 0;
  double _dailyCaloriesGoal = 2500;
  String _fitnessLevel = "Beginner";
  int _fitnessSubLevel = 1;
  int _workoutsCompleted = 0;
  int _workoutsUntilNextLevel = 20;
  List<bool> _workoutDays = List.generate(8, (index) => false);
  int _currentStreak = 0;
  late AnimationController _levelAnimationController;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFoodLogs();
    _loadWorkoutStreak();
    _loadUserDailyCalories();
    _levelAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _levelAnimationController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Load user data
        DocumentSnapshot userData =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        // Load user progress document
        DocumentSnapshot userProgress = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('userProgress')
            .doc('progress')
            .get();

        if (!userProgress.exists) {
          // Create progress document if it doesn't exist
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('userProgress')
              .doc('progress')
              .set({
            'fitnessLevel': 'Beginner',
            'fitnessSubLevel': 1,
            'workoutsCompleted': 0,
            'workoutsUntilNextLevel': 20,
          });

          // Fetch the newly created document
          userProgress = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('userProgress')
              .doc('progress')
              .get();
        }

        // Process data outside of setState
        String fullName = userData['fullName'] ?? 'User';
        String goal = userData['goal'] ?? 'No goal set';

        String fitnessLevel = 'Beginner';
        int fitnessSubLevel = 1;
        int workoutsCompleted = 0;
        int workoutsUntilNextLevel = 20;

        if (userProgress.exists) {
          final progressData = userProgress.data() as Map<String, dynamic>?;
          fitnessLevel = progressData?['fitnessLevel'] ?? 'Beginner';
          fitnessSubLevel = progressData?['fitnessSubLevel'] ?? 1;
          workoutsCompleted = progressData?['workoutsCompleted'] ?? 0;
          workoutsUntilNextLevel = progressData?['workoutsUntilNextLevel'] ?? 20;
        }

        // Update state after all async operations are complete
        setState(() {
          _userFullName = fullName;
          _userGoal = goal;
          _fitnessLevel = fitnessLevel;
          _fitnessSubLevel = fitnessSubLevel;
          _workoutsCompleted = workoutsCompleted;
          _workoutsUntilNextLevel = workoutsUntilNextLevel;
        });

        // Trigger animation after data loads
        _levelAnimationController.forward();
      } catch (e) {
        print('Error loading user data: $e');
        // Set default values in case of error
        setState(() {
          _userFullName = 'User';
          _userGoal = 'No goal set';
        });
      }
    }
  }

  Future<void> _loadFoodLogs() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime tomorrow = today.add(const Duration(days: 1));

      QuerySnapshot foodLogs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('foodLogs')
          .where('date', isGreaterThanOrEqualTo: today)
          .where('date', isLessThan: tomorrow)
          .get();

      setState(() {
        _totalCalories = 0;
        for (var doc in foodLogs.docs) {
          _totalCalories += doc['calories'] ?? 0;
        }
      });
    }
  }

  Future<void> _loadUserDailyCalories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final macrosSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('userMacros')
          .doc('macro')
          .get();

      _dailyCaloriesGoal = macrosSnapshot.data()?['calories']?.toDouble() ?? 2500;
    } catch (e) {
      print('Error loading daily calories: $e');
      // Keep default value if there's an error
    }
  }

  Future<void> _loadWorkoutStreak() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Get user document with workoutHistory array
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        // Check if workoutHistory exists
        if (userData.exists && userData.data() is Map<String, dynamic>) {
          Map<String, dynamic> data = userData.data() as Map<String, dynamic>;

          if (data.containsKey('workoutHistory') && data['workoutHistory'] is List) {
            List<dynamic> workoutHistory = data['workoutHistory'];

            // Get current date
            DateTime now = DateTime.now();
            DateTime thirtyDaysAgo = now.subtract(const Duration(days: 30));

            // Reset workout days array
            List<bool> workoutDays = List.generate(30, (index) => false);

            // Process each workout entry
            for (var workoutEntry in workoutHistory) {
              if (workoutEntry is Map<String, dynamic> && workoutEntry.containsKey('date')) {
                DateTime workoutDate = (workoutEntry['date'] as Timestamp).toDate();

                // Only consider workouts in last 30 days
                if (workoutDate.isAfter(thirtyDaysAgo)) {
                  int daysAgo = now.difference(workoutDate).inDays;
                  if (daysAgo < 30) {
                    // Mark this day as having a workout
                    workoutDays[29 - daysAgo] = true;
                  }
                }
              }
            }

            // Calculate current streak
            int streak = 0;

            // First check if today has a workout
            if (workoutDays[29]) {
              streak = 1;
              // Then count consecutive days going backwards
              for (int i = 28; i >= 0; i--) {
                if (workoutDays[i]) {
                  streak++;
                } else {
                  break; // Break on first day without workout
                }
              }
            } else {
              // If no workout today, check for streak from yesterday and back
              for (int i = 28; i >= 0; i--) {
                if (workoutDays[i]) {
                  streak++;
                } else {
                  break; // Break on first day without workout
                }
              }
            }

            setState(() {
              _workoutDays = workoutDays;
              _currentStreak = streak;
            });
          }
        }
      } catch (e) {
        print('Error loading workout streak: $e');
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshTip() async {
    setState(() {
      // Trigger UI refresh - tip box handles refresh internally
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with welcome text and profile avatar
              HeaderWidget(
                userName: _userFullName,
                userGoal: _userGoal,
                onProfileTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EditProfilePage()),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Personalized tip box - already a widget
              PersonalizedTipBox(
                onRefresh: _refreshTip,
                elevation: 2.0,
                showAnimation: true,
              ),

              const SizedBox(height: 16),

              // User level widget - now imported
              UserLevelWidget(),
              const SizedBox(height: 16),
              CaloriesSummaryWidget(
                totalCalories: _totalCalories,
                dailyCaloriesGoal: _dailyCaloriesGoal,
              ),

              const SizedBox(height: 16),

              // Workout streak widget - now imported
              WorkoutStreakWidget(),
              // Water intake tracker - already a widget
              const SizedBox(height: 16),
              const WaterIntakeGlassWidget(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          _onItemTapped(index);
        },
      ),
    );
  }
}

// Header widget with welcome message, goal, and profile avatar
class HeaderWidget extends StatelessWidget {
  final String userName;
  final String userGoal;
  final VoidCallback onProfileTap;

  const HeaderWidget({
    Key? key,
    required this.userName,
    required this.userGoal,
    required this.onProfileTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEEE, dd MMM').format(DateTime.now()),
                  style: GoogleFonts.raleway(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "WELCOME, ${userName.toUpperCase()}",
                  style: GoogleFonts.bebasNeue(
                    color: Colors.black,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey,
                  );
                }
                if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                  return GestureDetector(
                    onTap: onProfileTap,
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFD2EB50),
                      child: Icon(
                        Icons.person_2,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                }
                String? imageLocation =
                (snapshot.data!.data() as Map<String, dynamic>)['profileImage'];

                if (imageLocation != null && imageLocation.isNotEmpty) {
                  return GestureDetector(
                    onTap: onProfileTap,
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(imageLocation),
                    ),
                  );
                } else {
                  return GestureDetector(
                    onTap: onProfileTap,
                    child: const CircleAvatar(
                      radius: 24,
                      backgroundColor: Color(0xFFD2EB50),
                      child: Icon(
                        Icons.person_2,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Goal text added directly under header
        Row(
          children: [
            const Icon(Icons.flag_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            const Text(
              "Goal: ",
              style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: Text(
                userGoal,
                style: const TextStyle(color: Colors.black87, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
