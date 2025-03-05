import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'weight_question.dart';

class AgeQuestionPage extends StatefulWidget {
  final int age;

  AgeQuestionPage({Key? key, required this.age}) : super(key: key);

  @override
  _AgeQuestionPageState createState() => _AgeQuestionPageState();
}

class _AgeQuestionPageState extends State<AgeQuestionPage> {
  int _selectedAge = 16;

  @override
  void initState() {
    super.initState();
    // No longer setting _selectedAge to widget.age here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0e0f16),
      body: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              Text(
                'Step 1 of 6',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: GoogleFonts.montserrat().fontFamily,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'How old are you?',
                style: GoogleFonts.bebasNeue(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                height: 200,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 50,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedAge = 16 + index;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: 65, // 16 to 80
                    builder: (context, index) {
                      int ageValue = 16 + index;
                      bool isSelected = _selectedAge == ageValue;

                      return Center(
                        child: Container(
                          width: 80,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF303841) : Colors.transparent,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          child: Text(
                            ageValue.toString(),
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
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WeightQuestionPage(age: _selectedAge),
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
}