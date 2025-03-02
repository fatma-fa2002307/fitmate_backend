// import 'package:fitmate/screens/register_screens/gender_question.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class HeightQuestionScreen extends StatefulWidget {
//   final double height;

//   HeightQuestionScreen({Key? key, required this.height}) : super(key: key);

//   @override
//   _HeightQuestionScreenState createState() => _HeightQuestionScreenState();
// }

// class _HeightQuestionScreenState extends State<HeightQuestionScreen> {
//   double _currentHeight = 0.0;
//   bool isFeet = true;

//   @override
//   void initState() {
//     super.initState();
//     _currentHeight = widget.height;
//   }

//   void toggleUnit(bool isFeetSelected) {
//     setState(() {
//       isFeet = isFeetSelected;
//       if (isFeet) {
//         _currentHeight = (_currentHeight / 30.48).roundToDouble();
//       } else {
//         _currentHeight = (_currentHeight * 30.48).roundToDouble();
//       }
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
//                 'What is your height?',
//                 style: GoogleFonts.bebasNeue(
//                   color: Color(0xFFFFFFFF),
//                   fontSize: 36,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 40),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   InkWell(
//                     onTap: () => toggleUnit(true),
//                     child: Container(
//                       padding: EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: isFeet ? Color(0xFFD2EB50) : Colors.transparent,
//                         borderRadius: BorderRadius.zero,
//                         border: Border.all(
//                           color: Color(0xFFD2EB50),
//                           width: 2,
//                         ),
//                       ),
//                       child: Text(
//                         'FEET',
//                         style: TextStyle(
//                           color: isFeet ? Colors.white : Color(0xFFD2EB50),
//                           fontSize: 20,
//                         ),
//                       ),
//                     ),
//                   ),
//                   InkWell(
//                     onTap: () => toggleUnit(false),
//                     child: Container(
//                       padding: EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: !isFeet ? Color(0xFFD2EB50) : Colors.transparent,
//                         borderRadius: BorderRadius.zero,
//                         border: Border.all(
//                           color: Color(0xFFD2EB50),
//                           width: 2,
//                         ),
//                       ),
//                       child: Text(
//                         'CM',
//                         style: TextStyle(
//                           color: !isFeet ? Colors.white : Color(0xFFD2EB50),
//                           fontSize: 20,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 40),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: TextEditingController(
//                         text: _currentHeight.toStringAsFixed(0),
//                       ),
//                       onChanged: (value) {
//                         setState(() {
//                           _currentHeight = double.tryParse(value) ?? 0.0;
//                         });
//                       },
//                       style: TextStyle(
//                         color: Color(0xFFFFFFFF),
//                         fontSize: 48,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                       keyboardType: TextInputType.number,
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 40),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => GenderQuestionScreen(gender: 'Male')
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
import 'gender_question.dart'; // Will link to the next page (Gender)

class HeightQuestionPage extends StatefulWidget {
  final int age;
  final double weight;

  const HeightQuestionPage({Key? key, required this.age, required this.weight}) : super(key: key);

  @override
  _HeightQuestionPageState createState() => _HeightQuestionPageState();
}

class _HeightQuestionPageState extends State<HeightQuestionPage> {
  double _height = 170.0; // Default height in cm
  bool isFeet = false; // Track if the unit is feet

  @override
  void initState() {
    super.initState();
  }

  void toggleUnit(bool isFeetSelected) {
    setState(() {
      isFeet = isFeetSelected;
      if (isFeet) {
        // Convert cm to feet
        _height = (_height / 30.48).roundToDouble(); // Convert cm to feet (1 foot = 30.48 cm)
      } else {
        // Convert feet to cm
        _height = (_height * 30.48).roundToDouble(); // Convert feet to cm
      }
    });
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
              IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFFFFF)),
                onPressed: () {
                  Navigator.pop(context); // Navigate back to the previous page
                },
              ),
              Text(
                'Step 3 of 6',
                style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                    fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'What is your height?',
                style: GoogleFonts.bebasNeue(
                  color: Color(0xFFFFFFFF),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              // Unit selection buttons (Feet / CM)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => toggleUnit(true), // Feet selected
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isFeet ? Color(0xFFD2EB50) : Colors.transparent,
                        borderRadius: BorderRadius.zero, // Square shape
                        border: Border.all(
                          color: Color(0xFFD2EB50),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'FEET',
                        style: TextStyle(
                          color: isFeet ? Colors.white : Color(0xFFD2EB50),
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => toggleUnit(false), // CM selected
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: !isFeet ? Color(0xFFD2EB50) : Colors.transparent,
                        borderRadius: BorderRadius.zero, // Square shape
                        border: Border.all(
                          color: Color(0xFFD2EB50),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'CM',
                        style: TextStyle(
                          color: !isFeet ? Colors.white : Color(0xFFD2EB50),
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              // Height Input
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(
                        text: _height.toStringAsFixed(0),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _height = double.tryParse(value) ?? 170.0;
                        });
                      },
                      style: TextStyle(
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
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the next page (Gender question), passing height, age, and weight
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GenderQuestionPage(
                          age: widget.age,
                          weight: widget.weight,
                          height: _height,
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
