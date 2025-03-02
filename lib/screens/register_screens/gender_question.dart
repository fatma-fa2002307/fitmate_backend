// import 'package:fitmate/screens/register_screens/goal_question.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class GenderQuestionScreen extends StatefulWidget {
//   final String gender;

//   GenderQuestionScreen({Key? key, required this.gender}) : super(key: key);

//   @override
//   _GenderQuestionScreenState createState() => _GenderQuestionScreenState();
// }

// class _GenderQuestionScreenState extends State<GenderQuestionScreen> {
//   String _selectedGender = '';

//   @override
//   void initState() {
//     super.initState();
//     _selectedGender = widget.gender;
//   }

//   void selectGender(String gender) {
//     setState(() {
//       _selectedGender = gender;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF0e0f16),
//       body: Center(
//         child: Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Step 3 of 6',
//                 style: TextStyle(
//                     color: Color(0xFFFFFFFF),
//                     fontFamily: GoogleFonts.montserrat().fontFamily,
//                     fontSize: 16),
//               ),
//               SizedBox(height: 10),
//               Text(
//                 'What is your gender?',
//                 style: GoogleFonts.bebasNeue(
//                   color: Color(0xFFFFFFFF),
//                   fontSize: 36,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 40),
//               InkWell(
//                 onTap: () => selectGender('Male'),
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: _selectedGender == 'Male' ? Color(0xFFD2EB50) : Colors.transparent,
//                     borderRadius: BorderRadius.zero,
//                     border: Border.all(
//                       color: Color(0xFFD2EB50),
//                       width: 2,
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.male,
//                         color: _selectedGender == 'Male' ? Colors.white : Color(0xFFD2EB50),
//                         size: 40,
//                       ),
//                       SizedBox(width: 10),
//                       Text(
//                         'Male',
//                         style: TextStyle(
//                           color: _selectedGender == 'Male' ? Colors.white : Color(0xFFD2EB50),
//                           fontFamily: GoogleFonts.montserrat().fontFamily,
//                           fontSize: 20,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: 20),
//               InkWell(
//                 onTap: () => selectGender('Female'),
//                 child: Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: _selectedGender == 'Female' ? Color(0xFFD2EB50) : Colors.transparent,
//                     borderRadius: BorderRadius.zero,
//                     border: Border.all(
//                       color: Color(0xFFD2EB50),
//                       width: 2,
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(
//                         Icons.female,
//                         color: _selectedGender == 'Female' ? Colors.white : Color(0xFFD2EB50),
//                         size: 40,
//                       ),
//                       SizedBox(width: 10),
//                       Text(
//                         'Female',
//                         style: TextStyle(
//                           color: _selectedGender == 'Female' ? Colors.white : Color(0xFFD2EB50),
//                           fontFamily: GoogleFonts.montserrat().fontFamily,
//                           fontSize: 20,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               SizedBox(height: 40),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => GoalSelectionScreen(selectedGoal:'Weight Loss'),
//                       ),
//                     );
//                   },
//                   child: Text(
//                     'Next',
//                     style: GoogleFonts.bebasNeue(
//                       color: Color(0xFFFFFFFF),
//                       fontSize: 22,
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Color(0xFFD2EB50),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(5.0),
//                     ),
//                     padding: EdgeInsets.symmetric(vertical: 15.0),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'goal_question.dart'; // Will link to the next page (Goal)

class GenderQuestionPage extends StatefulWidget {
  final int age;
  final double weight;
  final double height;

  const GenderQuestionPage({
    Key? key,
    required this.age,
    required this.weight,
    required this.height,
  }) : super(key: key);

  @override
  _GenderQuestionPageState createState() => _GenderQuestionPageState();
}

class _GenderQuestionPageState extends State<GenderQuestionPage> {
  String _selectedGender = 'Male'; // Default gender

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0e0f16),
      body: SingleChildScrollView(  // Makes the content scrollable
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
                    Navigator.pop(context); // Navigate back to the previous page
                  },
                ),
                Text(
                  'Step 4 of 6',
                  style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                      fontSize: 16),
                ),
                SizedBox(height: 10),
                Text(
                  'What is your gender?',
                  style: GoogleFonts.bebasNeue(
                    color: Color(0xFFFFFFFF),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 40),
                // Gender Selection (Without "Other")
                GenderOption(
                  label: 'Male',
                  icon: Icons.male,
                  isSelected: _selectedGender == 'Male',
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Male';
                    });
                  },
                ),
                SizedBox(height: 20),
                GenderOption(
                  label: 'Female',
                  icon: Icons.female,
                  isSelected: _selectedGender == 'Female',
                  onTap: () {
                    setState(() {
                      _selectedGender = 'Female';
                    });
                  },
                ),
                SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Pass selected gender along with other info to GoalSelectionScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GoalSelectionScreen(
                            age: widget.age,
                            weight: widget.weight,
                            height: widget.height,
                            gender: _selectedGender,
                            selectedGoal: '', // Set the default value for selectedGoal
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
      ),
    );
  }
}

// A custom widget for the gender options with icons
class GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Function() onTap;

  const GenderOption({
    Key? key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFD2EB50) : Colors.transparent,
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
              color: isSelected ? Colors.white : Color(0xFFD2EB50),
              size: 40,
            ),
            SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Color(0xFFD2EB50),
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
