import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

String? validateFullName(String? value) {
  if (value == null || value.isEmpty) {
    return 'Full name is required';
  }
  return null;
}

String? validateWeight(String? value) {
  if (value == null || value.isEmpty) {
    return 'Weight is required';
  }
  final number = double.tryParse(value);
  if (number == null) {
    return 'Please enter a valid number';
  }
  if (number <= 0) {
    return 'Weight must be greater than 0';
  }
  return null;
}

String? validateHeight(String? value) {
  if (value == null || value.isEmpty) {
    return 'Height is required';
  }
  final number = double.tryParse(value);
  if (number == null) {
    return 'Please enter a valid number';
  }
  if (number <= 0) {
    return 'Height must be greater than 0';
  }
  return null;
}

String? validateAge(String? value) {
  if (value == null || value.isEmpty) {
    return 'Age is required';
  }
  final number = int.tryParse(value);
  if (number == null) {
    return 'Please enter a valid number';
  }
  if (number <= 0) {
    return 'Age must be greater than 0';
  }
  if (number > 120) {
    return 'Please enter a reasonable age';
  }
  return null;
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String _gender = "Female";
  String _goal = "Lose Weight";
  bool isKg = true; // Default to KG
  bool isCm = true; // Default to CM
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (mounted && userData.exists) {
        setState(() {
          _fullNameController.text = userData['fullName'] ?? '';
          _weightController.text = userData['weight']?.toString() ?? '';
          _heightController.text = userData['height']?.toString() ?? '';
          _ageController.text = userData['age']?.toString() ?? '';
          _gender = userData['gender'] ?? 'Female';
          _goal = userData['goal'] ?? 'Lose Weight';
        });
      }
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        double weight = double.parse(_weightController.text);
        double height = double.parse(_heightController.text);
        if (!isKg) {
          weight = weight * 0.453592;
        }
        if (!isCm) {
          height = height * 30.48;
        }
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fullName': _fullNameController.text,
          'weight': weight.toStringAsFixed(2),
          'height': height.toStringAsFixed(2),
          'age': int.tryParse(_ageController.text) ?? 0,
          'gender': _gender,
          'goal': _goal,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile updated successfully!"))
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error updating profile: $e"))
          );
        }
      }
    }
  }

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
          'EDIT PROFILE',
          style: GoogleFonts.bebasNeue(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: const Color(0xFFD2EB50),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Full Name',
                    style: GoogleFonts.montserrat(color: Colors.black),
                  ),
                  TextFormField(
                    controller: _fullNameController,
                    style: GoogleFonts.montserrat(),
                    validator: validateFullName,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0X15696940),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Weight', style: GoogleFonts.montserrat(color: Colors.black),),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          style: GoogleFonts.montserrat(),
                          validator: validateWeight,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0X15696940),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ToggleButtons(
                        isSelected: [!isKg, isKg],
                        onPressed: (int index) {
                          setState(() {
                            isKg = index == 1;
                          });
                        },
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.black12,
                        selectedColor: Colors.black,
                        fillColor: Colors.grey[300],
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('LBS', style: GoogleFonts.montserrat(color: Colors.black),),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text('KG', style: GoogleFonts.montserrat(color: Colors.black),),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Height', style: GoogleFonts.montserrat(color: Colors.black),),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          style: GoogleFonts.montserrat(),
                          validator: validateHeight,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Color(0X15696940),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ToggleButtons(
                        isSelected: [!isCm, isCm],
                        onPressed: (int index) {
                          setState(() {
                            isCm = index == 1;
                          });
                        },
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.black12,
                        selectedColor: Colors.black,
                        fillColor: Colors.grey[300],
                        children:  [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('FEET', style: GoogleFonts.montserrat(color: Colors.black),),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('CM', style: GoogleFonts.montserrat(color: Colors.black),),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Gender', style: GoogleFonts.montserrat(color: Colors.black),),
                  DropdownButtonFormField<String>(
                    value: _gender,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _gender = newValue;
                        });
                      }
                    },
                    items: <String>[
                      'Female',
                      'Male',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              value == 'Female' ? Icons.female : Icons.male,
                              color: Color(0xFF303841),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              value,
                              style: GoogleFonts.montserrat(color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0x15696940),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Goal', style: GoogleFonts.montserrat(color: Colors.black),),
                  DropdownButtonFormField<String>(
                    value: _goal,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _goal = newValue;
                        });
                      }
                    },
                    items: <String>[
                      'Lose Weight',
                      'Gain Muscle',
                      'Improve Fitness'
                    ].map<DropdownMenuItem<String>>((String value) {
                      IconData icon;
                      if (value == 'Lose Weight') {
                        icon = Icons.monitor_weight_outlined;
                      } else if (value == 'Gain Muscle') {
                        icon = Icons.fitness_center_outlined;
                      } else {
                        icon = Icons.health_and_safety_outlined;
                      }

                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              color: Color(0xFF303841),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              value,
                              style: GoogleFonts.montserrat(color: Colors.black),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0X15696940),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Age', style: GoogleFonts.montserrat(color: Colors.black),),
                  TextFormField(
                    controller: _ageController,
                    style: GoogleFonts.montserrat(),
                    validator: validateAge,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Color(0X15696940),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _saveUserData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD2EB50),
                            minimumSize: const Size(150, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child: Text(
                            'SAVE',
                            style: GoogleFonts.bebasNeue(
                                fontSize: 20, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 20),
                        OutlinedButton(
                          onPressed: () {
                            FirebaseAuth.instance.signOut().then((_) {
                              Navigator.pushReplacementNamed(context, '/login');
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: const Color(0xFFD2EB50)),
                            minimumSize: const Size(150, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                          child: Text(
                            'LOGOUT',
                            style: GoogleFonts.bebasNeue(
                                fontSize: 20, color: const Color(0xFFD2EB50)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          _onItemTapped(index);
        },
      ),
    );
  }
}