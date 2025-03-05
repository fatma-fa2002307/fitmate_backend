// import 'package:fitmate/screens/register_screens/workout-days_question.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class GoalSelectionScreen extends StatefulWidget {
//   final String selectedGoal;

//   GoalSelectionScreen({Key? key, required this.selectedGoal}) : super(key: key);

//   @override
//   _GoalSelectionPageState createState() => _GoalSelectionPageState();
// }

// class _GoalSelectionPageState extends State<GoalSelectionScreen> {
//   String _selectedGoal = '';

//   @override
//   void initState() {
//     super.initState();
//     _selectedGoal = widget.selectedGoal;
//   }

//   void selectGoal(String goal) {
//     setState(() {
//       _selectedGoal = goal;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF0e0f16),
//       body: SingleChildScrollView( // Add SingleChildScrollView here
//         child: Center(
//           child: Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Step 4 of 6',
//                   style: TextStyle(
//                       color: Color(0xFFFFFFFF),
//                       fontFamily: GoogleFonts.montserrat().fontFamily,
//                       fontSize: 16),
//                 ),
//                 SizedBox(height: 10),
//                 Text(
//                   'What is your goal?',
//                   style: GoogleFonts.bebasNeue(
//                     color: Color(0xFFFFFFFF),
//                     fontSize: 36,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 SizedBox(height: 40),
//                 // Goal Options
//                 goalOption('Weight Loss', Icons.monitor_weight_outlined),
//                 SizedBox(height: 20),
//                 goalOption('Gain Muscle', Icons.fitness_center_outlined),
//                 SizedBox(height: 20),
//                 goalOption('Improve Fitness', Icons.health_and_safety_outlined),
//                 SizedBox(height: 40),
//                 // Next Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => WorkoutDaysQuestionScreen(workoutDays: 1),
//                         ),
//                       );
//                     },
//                     child: Text(
//                       'Next',
//                       style: GoogleFonts.bebasNeue(
//                         color: Color(0xFFFFFFFF),
//                         fontSize: 22,
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color(0xFFD2EB50),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(5.0),
//                       ),
//                       padding: EdgeInsets.symmetric(vertical: 15.0),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // A helper method to create goal selection options
//   Widget goalOption(String goal, IconData icon) {
//     return InkWell(
//       onTap: () => selectGoal(goal),
//       child: Container(
//         width: double.infinity,
//         padding: EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: _selectedGoal == goal ? Color(0xFFD2EB50) : Colors.transparent,
//           borderRadius: BorderRadius.zero,
//           border: Border.all(
//             color: Color(0xFFD2EB50),
//             width: 2,
//           ),
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               color: _selectedGoal == goal ? Colors.white : Color(0xFFD2EB50),
//               size: 40,
//             ),
//             SizedBox(width: 10),
//             Text(
//               goal,
//               style: TextStyle(
//                 color: _selectedGoal == goal ? Colors.white : Color(0xFFD2EB50),
//                 fontFamily: GoogleFonts.montserrat().fontFamily,
//                 fontSize: 20,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'workout-days_question.dart'; // Import the WorkoutDaysQuestionScreen

class GoalSelectionScreen extends StatefulWidget {
  final int age;
  final double weight;
  final double height;
  final String gender;
  final String selectedGoal;

  GoalSelectionScreen({
    Key? key,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.selectedGoal,
  }) : super(key: key);

  @override
  _GoalSelectionPageState createState() => _GoalSelectionPageState();
}

class _GoalSelectionPageState extends State<GoalSelectionScreen> {
  String _selectedGoal = 'Weight Loss';

  @override
  void initState() {
    super.initState();
    // This will initialize the _selectedGoal with Weight Loss or the value passed from the previous page
    if (widget.selectedGoal.isNotEmpty) {
      _selectedGoal = widget.selectedGoal;
    }
  }

  void selectGoal(String goal) {
    setState(() {
      _selectedGoal = goal;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0e0f16),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFFFFF)),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Text(
                  'Step 5 of 6',
                  style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                      fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'What is your goal?',
                  style: GoogleFonts.bebasNeue(
                    color: Color(0xFFFFFFFF),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 40),
                // Goal Options
                goalOption('Weight Loss', Icons.monitor_weight_outlined),
                SizedBox(height: 20),
                goalOption('Gain Muscle', Icons.fitness_center_outlined),
                SizedBox(height: 20),
                goalOption('Improve Fitness', Icons.health_and_safety_outlined),
                SizedBox(height: 40),
                // Next Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutDaysQuestionScreen(
                            age: widget.age,
                            weight: widget.weight,
                            height: widget.height,
                            gender: widget.gender,
                            goal: _selectedGoal,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFD2EB50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 15.0),
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
      ),
    );
  }

  Widget goalOption(String goal, IconData icon) {
    return InkWell(
      onTap: () => selectGoal(goal),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _selectedGoal == goal ? Color(0xFFD2EB50) : Colors.transparent,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: Color(0xFFD2EB50),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _selectedGoal == goal ? Colors.black : Color(0xFFD2EB50),
              size: 40,
            ),
            SizedBox(width: 10),
            Text(
              goal,
              style: TextStyle(
                color: _selectedGoal == goal ? Colors.black : Color(0xFFD2EB50),
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}