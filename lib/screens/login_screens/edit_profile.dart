import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/repositories/food_repository.dart';
import 'package:fitmate/screens/login_screens/welcome_screen.dart';
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
  if (number <= 15) {
    return 'Age must be greater than 15';
  }
  if (number > 120) {
    return 'Please enter a reasonable age';
  }
  return null;
}

class _EditProfilePageState extends State<EditProfilePage> {

  final FoodRepository _foodRepository = FoodRepository();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String _gender = "Female";
  String _goal = "Weight Loss";
  String _workoutDays = '3';
  bool isKg = true;
  bool isCm = true;
  int _selectedIndex = 3;
  bool _isLoading = true;
  bool _isSaving = false;

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
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted && userData.exists) {
          final data = userData.data() as Map<String, dynamic>?;

          if (data != null) {
            final storedWeight = (data['weight'] is double)
                ? data['weight']
                : double.tryParse(data['weight']?.toString() ?? '') ?? 0.0;

            final storedHeight = (data['height'] is double)
                ? data['height']
                : double.tryParse(data['height']?.toString() ?? '') ?? 0.0;

            final storedUnit = data['unitPreference'] ?? 'metric';

            setState(() {
              isKg = storedUnit == 'metric';
              isCm = storedUnit == 'metric';

              _fullNameController.text = data['fullName'] ?? '';
              _ageController.text = data['age']?.toString() ?? '';
              _gender = data['gender'] ?? 'Female';
              _goal = data['goal'] ?? 'Weight Loss';
              _workoutDays = data['workoutDays']?.toString() ?? '3';

              if (isKg) {
                _weightController.text = storedWeight.toStringAsFixed(2);
              } else {
                _weightController.text = (storedWeight * 2.20462).toStringAsFixed(2);
              }

              if (isCm) {
                _heightController.text = storedHeight.toStringAsFixed(2);
              } else {
                _heightController.text = (storedHeight / 30.48).toStringAsFixed(2);
              }
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error loading profile: $e"))
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _convertWeight() {
    if (_weightController.text.isNotEmpty) {
      final currentWeight = double.tryParse(_weightController.text) ?? 0.0;
      setState(() {
        if (isKg) {
          _weightController.text = (currentWeight * 0.453592).toStringAsFixed(2);
        } else {
          _weightController.text = (currentWeight * 2.20462).toStringAsFixed(2);
        }
      });
    }
  }

  void _convertHeight() {
    if (_heightController.text.isNotEmpty) {
      final currentHeight = double.tryParse(_heightController.text) ?? 0.0;
      setState(() {
        if (isCm) {
          _heightController.text = (currentHeight * 30.48).toStringAsFixed(2);
        } else {
          _heightController.text = (currentHeight / 30.48).toStringAsFixed(2);
        }
      });
    }
  }

  Future<void> _selectProfileImage() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String? selectedImagePath;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Choose Profile Picture',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 14,
                  itemBuilder: (context, index) {
                    final imagePath = 'assets/data/images/avatar/av${index + 1}.png';
                    final isSelected = imagePath == selectedImagePath;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedImagePath = imagePath;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? const Color(0xFFD2EB50) : Colors.transparent,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: selectedImagePath == null
                    ? null
                    : () async {
                  Navigator.pop(context, selectedImagePath);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD2EB50),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  'CONFIRM',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 20,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((selectedImage) async {
      if (selectedImage != null) {
        try {
          // Show loading indicator
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Updating profile picture..."),
                  duration: Duration(milliseconds: 600),
              )

          );

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'profileImage': selectedImage,
          });

          // Update the UI
          setState(() {
          });

          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Profile picture updated successfully!"),
                // backgroundColor: const Color(0xFFD2EB50),
                duration: Duration(milliseconds: 1000)
              )
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error updating profile picture: $e"),
                backgroundColor: Colors.red,
              )
          );
        }
      }
    });
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Parse inputs as doubles
        double weight = double.parse(_weightController.text);
        double height = double.parse(_heightController.text);
        int age = int.tryParse(_ageController.text) ?? 0;
        int workoutDays = int.parse(_workoutDays);

        // Convert to metric for storage
        if (!isKg) {
          weight = weight * 0.453592;
        }

        if (!isCm) {
          height = height * 30.48;
        }

        // Round to 2 decimal places
        weight = double.parse(weight.toStringAsFixed(2));
        height = double.parse(height.toStringAsFixed(2));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'fullName': _fullNameController.text,
          'weight': weight,
          'height': height,
          'age': age,
          'gender': _gender,
          'goal': _goal,
          'workoutDays': workoutDays,
          'unitPreference': isKg ? 'metric' : 'imperial',
        });

        // Recalculate and save user macros after profile update
        await _foodRepository.calculateAndSaveUserMacros(
            _gender,
            weight,
            height,
            age,
            _goal,
            workoutDays
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Profile updated successfully!"),
                  duration: Duration(milliseconds: 1000)
              )
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Error updating profile: $e"),
                backgroundColor: Colors.red,
              )
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

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
          style: GoogleFonts.bebasNeue(
            color: Colors.black,
            fontSize: 22,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD2EB50),
        ),
      )
          : SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _selectProfileImage,
                      child: Stack(
                        children: [
                          FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .get(),
                            builder: (context, snapshot) {
                              String? profileImage;

                              if (snapshot.hasData && snapshot.data != null) {
                                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                profileImage = userData?['profileImage'];
                              }

                              return GestureDetector(
                                onTap: _selectProfileImage,
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: const Color(0xFFD2EB50),
                                      child: profileImage != null
                                          ? ClipOval(
                                        child: Image.asset(
                                          profileImage,
                                          fit: BoxFit.cover,
                                          width: 100,
                                          height: 100,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person,
                                              color: Colors.black,
                                              size: 40,
                                            );
                                          },
                                        ),
                                      )
                                          : const Icon(
                                        Icons.person,
                                        color: Colors.black,
                                        size: 40,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        height: 34,
                                        width: 34,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(17),
                                          border: Border.all(
                                            color: const Color(0xFFD2EB50),
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          color: Colors.black,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              height: 34,
                              width: 34,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: const Color(0xFFD2EB50),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.black,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Full Name',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _fullNameController,
                    style: GoogleFonts.montserrat(),
                    validator: validateFullName,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0X15696940),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Weight',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _weightController,
                          style: GoogleFonts.montserrat(),
                          validator: validateWeight,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0X15696940),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            suffixText: isKg ? 'kg' : 'lbs',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ToggleButtons(
                        isSelected: [!isKg, isKg],
                        onPressed: (int index) {
                          setState(() {
                            isKg = index == 1;
                            _convertWeight();
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black54,
                        selectedColor: Colors.white,
                        fillColor: const Color(0xFFD2EB50),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'LBS',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'KG',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Height',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _heightController,
                          style: GoogleFonts.montserrat(),
                          validator: validateHeight,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0X15696940),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            suffixText: isCm ? 'cm' : 'ft',
                            helperText: isCm ? null : 'Enter decimal feet, e.g. 5.75',
                            helperStyle: GoogleFonts.montserrat(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ToggleButtons(
                        isSelected: [!isCm, isCm],
                        onPressed: (int index) {
                          setState(() {
                            isCm = index == 1;
                            _convertHeight();
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.black54,
                        selectedColor: Colors.white,
                        fillColor: const Color(0xFFD2EB50),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'FEET',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'CM',
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Age',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ageController,
                    style: GoogleFonts.montserrat(),
                    validator: validateAge,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0X15696940),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixText: 'years',
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Gender',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      IconData icon;
                      if (value == 'Female') {
                        icon = Icons.female;
                      } else {
                        icon = Icons.male;
                      }

                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              color: const Color(0xFF303841),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              value,
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0x15696940),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Goal',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      'Weight Loss',
                      'Gain Muscle',
                      'Improve Fitness',
                    ].map<DropdownMenuItem<String>>((String value) {
                      IconData icon;
                      if (value == 'Weight Loss') {
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
                              color: const Color(0xFF303841),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              value,
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0X15696940),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Workout Days Per Week',
                    style: GoogleFonts.montserrat(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _workoutDays,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _workoutDays = newValue;
                        });
                      }
                    },
                    items: <String>[
                      '1', '2', '3', '4', '5', '6',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF303841),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$value day${value != '1' ? 's' : ''} per week',
                              style: GoogleFonts.montserrat(
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0x15696940),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveUserData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD2EB50),
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              :  Text(
                            'SAVE',
                            style: GoogleFonts.bebasNeue(
                                fontSize: 20, color: Colors.white),

                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(
                                  'Logout',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to logout?',
                                  style: GoogleFonts.montserrat(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async { // Make the onPressed async
                                      try {
                                        // Sign out first
                                        await FirebaseAuth.instance.signOut();

                                        // Then navigate to the WelcomePage
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(builder: (context) => const WelcomePage()),
                                              (route) => false,
                                        );
                                      } catch (e) {
                                        // Handle any potential errors during sign-out
                                        print("Error during sign out: $e");
                                        // Optionally show an error message to the user
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to logout. Please try again.')),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD2EB50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5.0),
                                      ),
                                    ),
                                    child: Text(
                                      'Logout',
                                      style: GoogleFonts.montserrat(
                                        color: Colors.black,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD2EB50)),
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text(
                            'LOGOUT',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 20,
                              color: const Color(0xFFD2EB50),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}