// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'weight_question.dart';

// class AgeQuestionPage extends StatelessWidget {
//   final int age;

//   AgeQuestionPage({Key? key, required this.age}) : super(key: key);

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
//               IconButton(
//                 icon: Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFFFFF)),
//                 onPressed: () {
//                   Navigator.pop(context); // Navigate back to the previous page
//                 },
//               ),
//               Text(
//                 'Step 1 of 6',
//                 style: TextStyle(
//                     color: Color(0xFFFFFFFF),
//                     fontFamily: GoogleFonts.montserrat().fontFamily,
//                     fontSize: 16),
//               ),
//               SizedBox(height: 10),
//               Text(
//                 'How old are you?',
//                 style: GoogleFonts.bebasNeue(
//                   color: Color(0xFFFFFFFF),
//                   fontSize: 36,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 40),
//               // Number Picker
//               SizedBox(
//                 height: 200,
//                 child: ListWheelScrollView.useDelegate(
//                   itemExtent: 50,
//                   physics: FixedExtentScrollPhysics(),
//                   childDelegate: ListWheelChildBuilderDelegate(
//                     childCount: 100, // Allows scrolling from 0 to 99
//                     builder: (context, index) {
//                       return Center(
//                         child: Text(
//                           index.toString(),
//                           style: TextStyle(
//                             color: Color(0xFFFFFFFF),
//                             fontSize: 24,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//               SizedBox(height: 40),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     // Navigate to the next question
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (context) => WeightQuestionPage(weight: 0)),
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
import 'weight_question.dart'; // Will link to the next page (Weight)

class AgeQuestionPage extends StatefulWidget {
  final int age;
  AgeQuestionPage({Key? key, required this.age}) : super(key: key);

  @override
  _AgeQuestionPageState createState() => _AgeQuestionPageState();
}

class _AgeQuestionPageState extends State<AgeQuestionPage> {
  int _selectedAge = 18;  // Default age

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
                'Step 1 of 6',
                style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontFamily: GoogleFonts.montserrat().fontFamily,
                    fontSize: 16),
              ),
              SizedBox(height: 10),
              Text(
                'How old are you?',
                style: GoogleFonts.bebasNeue(
                  color: Color(0xFFFFFFFF),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 40),
              // Age Picker
              SizedBox(
                height: 200,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  physics: FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedAge = index;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 100, // Allows scrolling from 0 to 99
                    builder: (context, index) {
                      return Center(
                        child: Text(
                          index.toString(),
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 24,
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
                    // Navigate to the next page, passing selected age to the next screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WeightQuestionPage(age: _selectedAge),
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
