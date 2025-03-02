// import 'package:fitmate/screens/register_screens/height_question.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';

// class WeightQuestionPage extends StatefulWidget {
//   final double weight;

//   WeightQuestionPage({Key? key, required this.weight}) : super(key: key);

//   @override
//   _WeightQuestionPageState createState() => _WeightQuestionPageState();
// }

// class _WeightQuestionPageState extends State<WeightQuestionPage> {
//   double _currentWeight = 0.0;
//   bool isKg = false; // Track if the unit is kg

//   @override
//   void initState() {
//     super.initState();
//     _currentWeight = widget.weight;
//   }

//   void toggleUnit(bool isKgSelected) {
//     setState(() {
//       isKg = isKgSelected;
//       if (isKg) {
//         // Convert lbs to kg
//         _currentWeight = (_currentWeight / 2.20462).roundToDouble();
//       } else {
//         // Convert kg to lbs
//         _currentWeight = (_currentWeight * 2.20462).roundToDouble();
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
//                 'Step 2 of 6',
//                 style: TextStyle(
//                     color: Color(0xFFFFFFFF),
//                     fontFamily: GoogleFonts.montserrat().fontFamily,
//                     fontSize: 16),
//               ),
//               SizedBox(height: 10),
//               Text(
//                 'How much do you weigh?',
//                 style: GoogleFonts.bebasNeue(
//                   color: Color(0xFFFFFFFF),
//                   fontSize: 36,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 40),
//               // Unit selection buttons (LBS / KG)
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   InkWell(
//                     onTap: () => toggleUnit(false), // LBS selected
//                     child: Container(
//                       padding: EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: !isKg ? Color(0xFFD2EB50) : Colors.transparent,
//                         borderRadius: BorderRadius.zero, // Square shape
//                         border: Border.all(
//                           color: Color(0xFFD2EB50),
//                           width: 2,
//                         ),
//                       ),
//                       child: Text(
//                         'LBS',
//                         style: TextStyle(
//                           color: !isKg ? Colors.white : Color(0xFFD2EB50),
//                           fontSize: 20,
//                         ),
//                       ),
//                     ),
//                   ),
//                   InkWell(
//                     onTap: () => toggleUnit(true), // KG selected
//                     child: Container(
//                       padding: EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: isKg ? Color(0xFFD2EB50) : Colors.transparent,
//                         borderRadius: BorderRadius.zero, // Square shape
//                         border: Border.all(
//                           color: Color(0xFFD2EB50),
//                           width: 2,
//                         ),
//                       ),
//                       child: Text(
//                         'KG',
//                         style: TextStyle(
//                           color: isKg ? Colors.white : Color(0xFFD2EB50),
//                           fontSize: 20,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               SizedBox(height: 40),
//               // Weight Input
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Expanded(
//                     child: TextField(
//                       controller: TextEditingController(
//                         text: _currentWeight.toStringAsFixed(0),
//                       ),
//                       onChanged: (value) {
//                         setState(() {
//                           _currentWeight = double.tryParse(value) ?? 0.0;
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
//                     // Navigate to the next question
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => HeightQuestionScreen(height: 0)),
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
import 'height_question.dart'; // Will link to the next page (Height)

class WeightQuestionPage extends StatefulWidget {
  final int age;

  const WeightQuestionPage({Key? key, required this.age}) : super(key: key);

  @override
  _WeightQuestionPageState createState() => _WeightQuestionPageState();
}

class _WeightQuestionPageState extends State<WeightQuestionPage> {
  double _weight = 60.0; // Default weight in kg
  bool isKg = true; // Track if the unit is kg (default)

  // Toggle between KG and LBS units
  void toggleUnit(bool isKgSelected) {
    setState(() {
      isKg = isKgSelected;
      if (isKg) {
        // Convert lbs to kg (if necessary)
        _weight = (_weight * 2.20462).roundToDouble();
      } else {
        // Convert kg to lbs (if necessary)
        _weight = (_weight / 2.20462).roundToDouble();
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
                'Step 2 of 6',
                style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                    fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'What is your weight?',
                style: GoogleFonts.bebasNeue(
                  color: Color(0xFFFFFFFF),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              // Unit selection buttons (LBS / KG)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => toggleUnit(false), // LBS selected
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: !isKg ? Color(0xFFD2EB50) : Colors.transparent,
                        borderRadius: BorderRadius.zero, // Square shape
                        border: Border.all(
                          color: Color(0xFFD2EB50),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'LBS',
                        style: TextStyle(
                          color: !isKg ? Colors.white : Color(0xFFD2EB50),
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => toggleUnit(true), // KG selected
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isKg ? Color(0xFFD2EB50) : Colors.transparent,
                        borderRadius: BorderRadius.zero, // Square shape
                        border: Border.all(
                          color: Color(0xFFD2EB50),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'KG',
                        style: TextStyle(
                          color: isKg ? Colors.white : Color(0xFFD2EB50),
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              // Weight Input
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: TextEditingController(
                        text: _weight.toStringAsFixed(0),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _weight = double.tryParse(value) ?? 0.0;
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
                    // Navigate to the next page (Height question), passing weight and age
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HeightQuestionPage(
                          age: widget.age,
                          weight: _weight,
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
