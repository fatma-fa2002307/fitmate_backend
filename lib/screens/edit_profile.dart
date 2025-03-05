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
  bool isKg = true;
  bool isCm = true;
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
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fullName': _fullNameController.text,
          'weight': double.tryParse(_weightController.text) ?? 0,
          'height': double.tryParse(_heightController.text) ?? 0,
          'age': int.tryParse(_ageController.text) ?? 0,
          'gender': _gender,
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
                  const Text('Full Name', style: TextStyle(color: Colors.black)),
                  TextFormField(
                    controller: _fullNameController,
                    validator: validateFullName,
                  ),
                  const SizedBox(height: 20),
                  const Text('Weight', style: TextStyle(color: Colors.black)),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          validator: validateWeight,
                          keyboardType: TextInputType.number,
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
                        children: const [Text('LBS'), Text('KG')],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Height', style: TextStyle(color: Colors.black)),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          validator: validateHeight,
                          keyboardType: TextInputType.number,
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
                        children: const [Text('FEET'), Text('CM')],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Gender', style: TextStyle(color: Colors.black)),
                  DropdownButton<String>(
                    value: _gender,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _gender = newValue;
                        });
                      }
                    },
                    items: <String>['Female', 'Male']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const Text('Age', style: TextStyle(color: Colors.black)),
                  TextFormField(
                    controller: _ageController,
                    validator: validateAge,
                    keyboardType: TextInputType.number,
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
                            style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white),
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
                            style: GoogleFonts.bebasNeue(fontSize: 20, color: const Color(0xFFD2EB50)),
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