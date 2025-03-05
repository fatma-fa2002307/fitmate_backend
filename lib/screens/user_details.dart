import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';

class UserDetailsScreen extends StatefulWidget {
  final String fullName;
  final String email;
  final int age;
  final double weight; // Stored in kg
  final double height; // Stored in cm
  final String gender;
  final String selectedGoal;
  final int workoutDays;
  final int currentIndex;
  final Function(int) onTap;

  UserDetailsScreen({
    required this.fullName,
    required this.email,
    required this.age,
    required this.weight, // Weight in kg
    required this.height, // Height in cm
    required this.gender,
    required this.selectedGoal,
    required this.workoutDays,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  _UserDetailsScreenState createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  late bool isKg; // To track kg or lbs unit
  late bool isFeet; // To track cm or feet unit
  late double currentWeight;
  late double currentHeight;

  @override
  void initState() {
    super.initState();
    currentWeight = widget.weight; // Initial weight in kg
    currentHeight = widget.height; // Initial height in cm
    _loadPreferences();
  }

  _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isKg = prefs.getBool('isKg') ?? true; // Default to kg
      isFeet = prefs.getBool('isFeet') ?? false; // Default to cm
    });
  }

  _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isKg', isKg);
    await prefs.setBool('isFeet', isFeet);
  }

  String getConvertedHeight() {
    if (isFeet) {
      double heightInFeet = widget.height / 30.48; // Convert cm to feet
      int feet = heightInFeet.floor();
      double remainingInches = (heightInFeet - feet) * 12;
      int inches = remainingInches.round();
      return "$feet' $inches\"";
    } else {
      return "${widget.height.toInt()} cm"; // Display in cm by default
    }
  }

  String getConvertedWeight() {
    if (isKg) {
      return "${currentWeight.toInt()} kg"; // Display weight in kg
    } else {
      return "${(currentWeight * 2.20462).toInt()} lbs"; // Convert kg to lbs for display
    }
  }

  void toggleWeightUnit(bool toKg) {
    setState(() {
      isKg = toKg;
      if (isKg) {
        currentWeight = widget.weight; // Always store weight in kg
      } else {
        currentWeight = widget.weight * 2.20462; // Convert to lbs for display
      }
    });
    _savePreferences();
  }

  void toggleHeightUnit(bool toCm) {
    setState(() {
      isFeet = !toCm;
    });
    _savePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0e0f16),
      appBar: AppBar(
        backgroundColor: Color(0xFF0D0E11),
        title: Text(
          'User Details',
          style: GoogleFonts.bebasNeue(color: Color(0xFFD2EB50)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Full Name: ${widget.fullName}',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Email: ${widget.email}',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Age: ${widget.age}',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Weight: ${getConvertedWeight()}',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Height: ${getConvertedHeight()}',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Gender: ${widget.gender}',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Goal: ${widget.selectedGoal}',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Text(
              'Workout Days: ${widget.workoutDays}',
              style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
            ),
            Row(
              children: [
                Text(
                  'Unit Settings:',
                  style: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
                ),
                ElevatedButton(
                  onPressed: () => toggleWeightUnit(true), // Show weight in kg
                  child: Text('kg'),
                ),
                ElevatedButton(
                  onPressed: () => toggleWeightUnit(false), // Show weight in lbs
                  child: Text('lbs'),
                ),
                ElevatedButton(
                  onPressed: () => toggleHeightUnit(true), // Show height in cm
                  child: Text('cm'),
                ),
                ElevatedButton(
                  onPressed: () => toggleHeightUnit(false), // Show height in feet
                  child: Text('feet'),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
      ),
    );
  }
}
