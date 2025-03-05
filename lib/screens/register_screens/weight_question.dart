import 'package:fitmate/screens/register_screens/height_question.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class WeightQuestionPage extends StatefulWidget {
  final int age;

  const WeightQuestionPage({Key? key, required this.age}) : super(key: key);

  @override
  _WeightQuestionPageState createState() => _WeightQuestionPageState();
}

class _WeightQuestionPageState extends State<WeightQuestionPage> {
  double _weight = 60.0; // Default weight in kg
  bool isKg = true; // Default unit is kg
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: _weight.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  // Save weight and unit preference to SharedPreferences
  void _saveUserPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('weight', _weight);
    await prefs.setBool('isKg', isKg);
  }

  void toggleUnit(bool isKgSelected) {
    if (isKg == isKgSelected) return;

    setState(() {
      isKg = isKgSelected;
      if (isKg) {
        _weight = (_weight / 2.20462).roundToDouble(); // Convert lbs to kg
      } else {
        _weight = (_weight * 2.20462).roundToDouble(); // Convert kg to lbs
      }
      _weightController.text = _weight.toStringAsFixed(0);
      _saveUserPreferences(); // Save the updated weight and unit preference
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0e0f16),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                'Step 2 of 6',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'What is your weight?',
                style: GoogleFonts.bebasNeue(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              // Unit selection buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _unitButton('LBS', !isKg, () => toggleUnit(false)),
                  _unitButton('KG', isKg, () => toggleUnit(true)),
                ],
              ),
              const SizedBox(height: 40),
              // Weight Input
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      onChanged: (value) {
                        double? newWeight = double.tryParse(value);
                        if (newWeight != null) {
                          setState(() => _weight = newWeight);
                          _saveUserPreferences(); // Save the updated weight
                        }
                      },
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HeightQuestionPage(
                          age: widget.age,
                          weight: isKg ? _weight : _weight / 2.20462, // Ensure weight is in kg
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD2EB50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15.0),
                  ),
                  child: Text(
                    'Next',
                    style: GoogleFonts.bebasNeue(
                      color: Colors.black,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _unitButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD2EB50) : Colors.transparent,
          border: Border.all(color: const Color(0xFFD2EB50), width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFFD2EB50),
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}