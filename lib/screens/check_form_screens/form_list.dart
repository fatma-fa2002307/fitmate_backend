import 'package:fitmate/screens/check_form_screens/form_instructions_page.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FormListPage extends StatefulWidget {
  @override
  _FormListPageState createState() => _FormListPageState();
}

class _FormListPageState extends State<FormListPage> {
  final List<Map<String, String>> workouts = [
    {"title": "Squat", "image": "assets/data/images/workouts/image 2.png"},
    {"title": "Sit Ups", "image": "assets/data/images/workouts/image 4.png"},
    {"title": "Lunge", "image": "assets/data/images/workouts/image 3.png"},
    {"title": "Bicep Curl", "image": "assets/data/images/workouts/image 5.png"},
  ];

  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Form Check',
          style: GoogleFonts.bebasNeue(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select an Exercise to Begin',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize:15, color: Colors.black54),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: workouts.length,
              itemBuilder: (context, index) {
                final workout = workouts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      leading: Image.asset(
                        workout["image"]!,
                        // width: 70,
                        // height: 100,
                        fit: BoxFit.cover,
                      ),
                      title: Text(
                        workout["title"]!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FormInstructionsPage(
                              title: workout["title"]!,
                              image: workout["image"]!,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
