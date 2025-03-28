import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/screens/login_screens/edit_profile.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _userFullName = "Loading...";
  String _userGoal = "Loading...";
  double _totalCalories = 0;
  double _dailyCaloriesGoal = 2500; // Default goal, can be fetched from user data

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFoodLogs();
  }

  void _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      setState(() {
        _userFullName = userData['fullName'] ?? 'User';
        _userGoal = userData['goal'] ?? 'No goal set';
        _dailyCaloriesGoal = userData['dailyCaloriesGoal']?.toDouble() ?? 2500; // Fetch goal
      });
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
                        "WELCOME, ${_userFullName.toUpperCase()}",
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
                          backgroundColor: Colors.grey, // Loading indicator
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EditProfilePage()),
                            );
                          },
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
                      String? profileImage = (snapshot.data!.data() as Map<String, dynamic>)['profileImage'];

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditProfilePage()),
                          );
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: profileImage != null
                              ? NetworkImage(profileImage)
                              : null, // Use network image if available
                          backgroundColor: profileImage == null ? const Color(0xFFD2EB50) : null,
                          child: profileImage == null
                              ? const Icon(
                            Icons.person_2,
                            color: Colors.white,
                            size: 28,
                          )
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Text(
                        "Current Goal",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userGoal,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      //shrifa
                      //    SizedBox(height: 12),  // Add spacing before the button
                      //     ElevatedButton(
                      //       onPressed: () {
                      //         Navigator.push(
                      //           context,
                      //           MaterialPageRoute(builder: (context) => FoodRecognitionScreen()),
                      //         );
                      //       },
                      //       child: Text("Go to Food Recognition"),
                      //       style: ElevatedButton.styleFrom(
                      //         padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      //         backgroundColor: Color(0xFFD2EB50),
                      //         textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      //       ),


                      // ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          "3 Week Streak!",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        return Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: index == 2 || index == 3
                                  ? Color(0xFFD2EB50)
                                  : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                "${21 + index}",
                                style: TextStyle(
                                  color: index == 2 || index == 3
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                // children: [
                //   const SizedBox(width: 16),
                //   Expanded(
                //     child: Container(
                //       height: 180,
                //       padding: const EdgeInsets.all(16),
                //       decoration: BoxDecoration(
                //         color: Colors.white,
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //       child: Center(
                //         child: Column(
                //           mainAxisAlignment: MainAxisAlignment.center,
                //           crossAxisAlignment: CrossAxisAlignment.center,
                //           children: [
                //             Image.asset(
                //               'assets/data/images/yoga-pose.png',
                //               width: 60,
                //               height: 60,
                //             ),
                //             const SizedBox(height: 8),
                //             const Text(
                //               "Total Workouts",
                //               style: TextStyle(color: Colors.grey, fontSize: 14),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ),
                //   )
                // ],
              ),
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