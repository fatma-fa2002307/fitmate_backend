import 'dart:math';

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
  late AnimationController _levelAnimationController;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFoodLogs();
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
        DocumentSnapshot userData =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        DocumentSnapshot userProgress = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('userProgress')
            .doc('progress')
            .get();

        if (!userProgress.exists) {
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

          userProgress = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('userProgress')
              .doc('progress')
              .get();
        }

        String fullName = userData['fullName'] ?? 'User';
        String goal = userData['goal'] ?? 'No goal set';

        setState(() {
          _userFullName = fullName;
          _userGoal = goal;
        });

        _levelAnimationController.forward();
      } catch (e) {
        print('Error loading user data: $e');
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

      setState(() {
        _dailyCaloriesGoal = macrosSnapshot.data()?['calories']?.toDouble() ?? 2500;
      });
    } catch (e) {
      print('Error loading daily calories: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _refreshTip() async {
    setState(() {});
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
              HeaderWidget(
                userName: _userFullName,
                userGoal: _userGoal,
                onProfileTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfilePage()),
                  );
                },
              ),

              const SizedBox(height: 24),

              PersonalizedTipBox(
                onRefresh: _refreshTip,
                elevation: 2.0,
                showAnimation: true,
              ),

              const SizedBox(height: 16),

              const UserLevelWidget(),

              const SizedBox(height: 16),

              CaloriesSummaryWidget(
                totalCalories: _totalCalories,
                dailyCaloriesGoal: _dailyCaloriesGoal,
              ),

              const SizedBox(height: 16),

              const WorkoutStreakWidget(),

              const SizedBox(height: 16),

              const WaterIntakeGlassWidget(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

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
                  return CircleAvatar(
                    radius: 35,
                    backgroundColor: const Color(0xFFD2EB50).withOpacity(0.7),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                      strokeWidth: 2,
                    ),
                  );
                }

                String? imageLocation;
                if (snapshot.hasData && snapshot.data!.exists) {
                  imageLocation = (snapshot.data!.data() as Map<String, dynamic>)['profileImage'];
                }

                return GestureDetector(
                  onTap: onProfileTap,
                  child: Hero(
                    tag: 'profileImage',
                    child: TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.elasticOut,
                      builder: (context, double value, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulsating outer glow
                            TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.9, end: 1.1),
                              duration: const Duration(milliseconds: 1200),
                              curve: Curves.easeInOut,
                              builder: (context, double pulseValue, _) {
                                return Transform.scale(
                                  scale: pulseValue,
                                  child: Container(
                                    width: 80 * value,
                                    height: 80 * value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          const Color(0xFFD2EB50).withOpacity(0.7),
                                          const Color(0xFFD2EB50).withOpacity(0.0),
                                        ],
                                        stops: const [0.6, 1.0],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Rotating accent circles
                            TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0, end: 2 * 3.14159),
                              duration: const Duration(seconds: 8),
                              curve: Curves.linear,
                              builder: (context, double rotation, _) {
                                return Transform.rotate(
                                  angle: rotation,
                                  child: Container(
                                    width: 70 * value,
                                    height: 70 * value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFD2EB50).withOpacity(0.5),
                                        width: 2,
                                        strokeAlign: BorderSide.strokeAlignOutside,
                                      ),
                                    ),
                                    child: Stack(
                                      children: List.generate(
                                        4,
                                            (index) => Positioned(
                                          left: 35 * value * cos(index * 3.14159 / 2),
                                          top: 35 * value * sin(index * 3.14159 / 2),
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD2EB50),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFFD2EB50).withOpacity(0.6),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Profile image
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              width: 60 * value,
                              height: 60 * value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFD2EB50),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFD2EB50).withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: imageLocation != null && imageLocation.isNotEmpty
                                    ? Image.asset(
                                  imageLocation,
                                  fit: BoxFit.cover,
                                  width: 60 * value,
                                  height: 60 * value,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.person,
                                      color: Colors.black,
                                      size: 40 * value,
                                    );
                                  },
                                )
                                    : Icon(
                                  Icons.person,
                                  color: Colors.black,
                                  size: 40 * value,
                                ),
                              ),
                            ),

                            // Shine effect
                            IgnorePointer(
                              child: TweenAnimationBuilder(
                                tween: Tween<double>(begin: -1.0, end: 1.0),
                                duration: const Duration(seconds: 2),
                                curve: Curves.easeInOut,
                                builder: (context, double shimmerValue, _) {
                                  return Container(
                                    width: 60 * value,
                                    height: 60 * value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        begin: Alignment(shimmerValue - 0.3, shimmerValue - 0.3),
                                        end: Alignment(shimmerValue, shimmerValue),
                                        colors: [
                                          Colors.white.withOpacity(0.0),
                                          Colors.white.withOpacity(0.3),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
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