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
import 'package:shared_preferences/shared_preferences.dart';
import 'gender_question.dart';

class HeightQuestionPage extends StatefulWidget {
  final int age;
  final double weight;

  const HeightQuestionPage({Key? key, required this.age, required this.weight}) : super(key: key);

  @override
  _HeightQuestionPageState createState() => _HeightQuestionPageState();
}

class _HeightQuestionPageState extends State<HeightQuestionPage> {
  double _height = 170.0; // Default height in cm
  bool isFeet = false;
  TextEditingController _heightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateControllerText();
  }


  void toggleUnit(bool isFeetSelected) async {
    if (isFeetSelected != isFeet) {
      setState(() {
        isFeet = isFeetSelected;
        _updateControllerText();
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setBool('isFeet', isFeet);
    }
  }

  void updateHeight(String value) {
    setState(() {
      if (isFeet) {
        List<String> parts = value.split("'");
        if (parts.length == 2) {
          int? feet = int.tryParse(parts[0]);
          int? inches = int.tryParse(parts[1]);
          if (feet != null && inches != null) {
            _height = (feet * 12 + inches) * 2.54;
          }
        }
      } else {
        _height = double.tryParse(value) ?? 170.0;
      }
    });
  }

  void _updateControllerText() {
    if (isFeet) {
      int feet = (_height / 2.54 / 12).floor();
      int inches = ((_height / 2.54) - (feet * 12)).round();
      _heightController.text = '$feet\'$inches';
    } else {
      _heightController.text = _height.toStringAsFixed(0);
    }
  }

  bool _validateInput() {
    if (isFeet) {
      List<String> parts = _heightController.text.split("'");
      if (parts.length != 2) return false;
      int? feet = int.tryParse(parts[0]);
      int? inches = int.tryParse(parts[1]);
      return feet != null && inches != null;
    } else {
      return double.tryParse(_heightController.text) != null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0e0f16),
      body: SingleChildScrollView(
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
                'Step 3 of 6',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontSize: 16,
                ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => toggleUnit(true),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isFeet ? Color(0xFFD2EB50) : Colors.transparent,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: Color(0xFFD2EB50),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'FEET',
                        style: TextStyle(
                          color: isFeet ? Colors.black : Color(0xFFD2EB50),
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => toggleUnit(false),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: !isFeet ? Color(0xFFD2EB50) : Colors.transparent,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(
                          color: Color(0xFFD2EB50),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        'CM',
                        style: TextStyle(
                          color: !isFeet ? Colors.black : Color(0xFFD2EB50),
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      onChanged: updateHeight,
                      style: TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_validateInput()) {
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
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a valid height.')),
                      );
                    }
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
}