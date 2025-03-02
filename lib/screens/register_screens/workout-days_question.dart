import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'credentials.dart'; 
class WorkoutDaysQuestionScreen extends StatefulWidget {
  final int age;
  final double weight;
  final double height;
  final String gender;
  final String goal;
  final int workoutDays; // Add workoutDays parameter

  WorkoutDaysQuestionScreen({
    Key? key,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.goal,
    required this.workoutDays, // Include workoutDays in the constructor
  }) : super(key: key);

  @override
  _WorkoutDaysQuestionScreenState createState() =>
      _WorkoutDaysQuestionScreenState();
}

class _WorkoutDaysQuestionScreenState extends State<WorkoutDaysQuestionScreen> {
  int _currentWorkoutDays = 1;

  @override
  void initState() {
    super.initState();
    _currentWorkoutDays = widget.workoutDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0e0f16),
      body: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step 6 of 6',
                style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                    fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'How many days a week would you like to work out?',
                style: GoogleFonts.bebasNeue(
                  color: Color(0xFFFFFFFF),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              SizedBox(
                height: 200,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  physics: FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _currentWorkoutDays = index + 1;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 7,
                    builder: (context, index) {
                      bool isSelected = _currentWorkoutDays == index + 1;
                      return Center(
                        child: Container(
                          width: 80,
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(0xFF303841) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            (index + 1).toString(),
                            style: GoogleFonts.bebasNeue(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // After selecting workout days, pass the data to the CredentialsPage
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CredentialsPage(
                          age: widget.age,
                          weight: widget.weight,
                          height: widget.height,
                          gender: widget.gender,
                          selectedGoal: widget.goal,
                          workoutDays: _currentWorkoutDays,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Next',
                    style: GoogleFonts.bebasNeue(
                      color: Color(0xFFFFFFFF),
                      fontSize: 22,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFD2EB50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
