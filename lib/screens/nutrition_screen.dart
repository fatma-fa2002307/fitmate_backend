import 'package:fitmate/screens/logFoodManually.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/bottom_nav_bar.dart';
import 'camera_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({Key? key}) : super(key: key);

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  int _selectedIndex = 2;
  double _totalCalories = 0;
  double _totalCarbs = 0;
  double _totalProtein = 0;
  double _totalFat = 0;
  Map<String, double> _dailyMacros = {};
  String _gender = '';
  double _weight = 0;
  double _height = 0;
  int _age = 0;
  String _goal = '';
  int _workoutDays = 0;
  bool _isLoading = true;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    await _loadUserData();
    await _loadFoodLogs();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        setState(() {
          _gender = userData['gender'];
          _weight = userData['weight'];
          _height = userData['height'];
          _age = userData['age'];
          _goal = userData['goal'];
          _workoutDays = userData['workoutDays'];
          _dailyMacros = _calculateMacronutrients(_goal, _calculateBMR(), _workoutDays);
        });
      }
    }
  }

  double _calculateBMR() {
    if (_gender.toLowerCase() == 'male') {
      return (10 * _weight) + (6.25 * _height) - (5 * _age) + 5;
    } else {
      return (10 * _weight) + (6.25 * _height) - (5 * _age) - 161;
    }
  }

  double _calculateTDEE(double bmr, int workoutDays, String goal) {
    double multiplier;
    double cal = 0;
    if (workoutDays == 1) {
      multiplier = 1.2;
    } else if (workoutDays >= 2 && workoutDays <= 3) {
      multiplier = 1.3;
    } else if (workoutDays >= 4 && workoutDays <= 5) {
      multiplier = 1.5;
    } else {
      multiplier = 1.9;
    }
    if (goal == 'Weight Loss') {
      cal = (bmr * multiplier) - 300;
    } else {
      cal = bmr * multiplier;
    }
    return cal;
  }

  Map<String, double> _calculateMacronutrients(String goal, double bmr, int workoutDays) {
    double tdee = _calculateTDEE(bmr, workoutDays, goal);
    Map<String, double> macros = {};

    switch (goal) {
      case 'Weight Loss':
        macros = {
          'calories': tdee,
          'carbs': (tdee * 0.45) / 4,
          'protein': (tdee * 0.30) / 4,
          'fat': (tdee * 0.25) / 9,
        };
        break;
      case 'Gain Muscle':
        macros = {
          'calories': tdee,
          'carbs': (tdee * 0.45) / 4,
          'protein': (tdee * 0.35) / 4,
          'fat': (tdee * 0.20) / 9,
        };
        break;
      case 'Improve Fitness':
        macros = {
          'calories': tdee,
          'carbs': (tdee * 0.60) / 4,
          'protein': (tdee * 0.15) / 4,
          'fat': (tdee * 0.25) / 9,
        };
        break;
    }
    return macros;
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
        _totalCarbs = 0;
        _totalProtein = 0;
        _totalFat = 0;
        for (var doc in foodLogs.docs) {
          _totalCalories += doc['calories'] ?? 0;
          _totalCarbs += doc['carbs'] ?? 0;
          _totalProtein += doc['protein'] ?? 0;
          _totalFat += doc['fat'] ?? 0;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NUTRITION',
          style: GoogleFonts.bebasNeue(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          child: SafeArea(
          child: Padding(
          padding: const EdgeInsets.all(16.0),
      child: Column(
          children: [
          GridView.count(
          physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
      _buildMacroCircle(
      'Carbs',
      _totalCarbs.toStringAsFixed(0),
      'g',
      Colors.orange,
      _dailyMacros.containsKey('carbs')
          ? (_totalCarbs / _dailyMacros['carbs']!).clamp(0, 1)
          : 0,
      _dailyMacros['carbs']?.toStringAsFixed(0) ?? '0',
    ),
    _buildMacroCircle(
    'Protein',
    _totalProtein.toStringAsFixed(0),
    'g',
    Colors.teal,
    _dailyMacros.containsKey('protein')
    ? (_totalProtein / _dailyMacros['protein']!).clamp(0, 1)
        : 0,
    _dailyMacros['protein']?.toStringAsFixed(0) ?? '0',
    ),
    _buildMacroCircle(
    'Fat',
    _totalFat.toStringAsFixed(0),
    'g',
    Colors.pink,
    _dailyMacros.containsKey('fat')
    ? (_totalFat / _dailyMacros['fat']!).clamp(0, 1)
        : 0,
    _dailyMacros['fat']?.toStringAsFixed(0) ?? '0',
    ),
    _buildMacroCircle(
    'Calories',
    _totalCalories.toStringAsFixed(0),
    'Kcal',
    Colors.lime,
    _dailyMacros.containsKey('calories')
    ? (_totalCalories / _dailyMacros['calories']!).clamp(0, 1)
        : 0,
    _dailyMacros['calories']?.toStringAsFixed(0) ?? '0',
    ),
      ],
          ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CameraPage(),
                        ),
                      ).then((_) {
                        _loadData();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2EB50),
                      minimumSize: const Size(150, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    child: Text(
                      'LOG FOOD',
                      style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LogFoodManuallyScreen(),
                        ),
                      ).then((_) {
                        _loadData();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2EB50),
                      minimumSize: const Size(150, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    child: Text(
                      'ADD FOOD',
                      style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Food Suggestion',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Strawberries are low in calories and will fit nicely in your current plan!',
                            style: GoogleFonts.dmSans(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/data/images/strawberry.png',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(Icons.restaurant, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
      ),
          ),
          ),
      ),
    bottomNavigationBar: BottomNavBar(
    currentIndex: _selectedIndex,
    onTap: _onItemTapped,
    ),
    );
  }

  Widget _buildMacroCircle(String label, String value, String unit, Color color, double progress, String max) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 8,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.montserrat(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    unit,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '(max: $max)',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}