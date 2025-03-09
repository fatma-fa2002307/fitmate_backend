import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogFoodManuallyScreen extends StatefulWidget {
  const LogFoodManuallyScreen({super.key});

  @override
  State<LogFoodManuallyScreen> createState() => _LogFoodManuallyScreenState();
}

class _LogFoodManuallyScreenState extends State<LogFoodManuallyScreen> {
  int _selectedIndex = 2; // Assuming NutritionPage is index 2

  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> saveFood() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        if (user.uid != null && user.uid.isNotEmpty) {
          if (_caloriesController.text.isEmpty ||
              _fatController.text.isEmpty ||
              _carbsController.text.isEmpty ||
              _proteinController.text.isEmpty) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("All fields are required.")),
              );
            }
            return; // Stop the function if any field is empty
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('foodLogs')
              .add({
            'calories': double.tryParse(_caloriesController.text) ?? 0,
            'fat': double.tryParse(_fatController.text) ?? 0,
            'carbs': double.tryParse(_carbsController.text) ?? 0,
            'protein': double.tryParse(_proteinController.text) ?? 0,
            'date': DateTime.now(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Food logged successfully!")),
            );
          }

          _caloriesController.clear();
          _fatController.clear();
          _carbsController.clear();
          _proteinController.clear();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("User not properly authenticated.")),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error logging food: $e")),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
      }
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
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dish Name',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Calories (Required)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fatController,
                  decoration: const InputDecoration(
                    labelText: 'Fat (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _carbsController,
                  decoration: const InputDecoration(
                    labelText: 'Carbohydrates (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _proteinController,
                  decoration: const InputDecoration(
                    labelText: 'Protein (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    saveFood();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD2EB50),
                    minimumSize: const Size(150, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  child: Text(
                    'SAVE',
                    style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white),
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
}