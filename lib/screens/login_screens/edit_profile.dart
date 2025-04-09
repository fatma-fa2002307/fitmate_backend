import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/screens/login_screens/welcome_screen.dart';
import 'package:fitmate/viewmodels/edit_profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Focus nodes for form fields
  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();
  final FocusNode _ageFocusNode = FocusNode();

  late EditProfileViewModel _viewModel;
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    // Initialize the ViewModel
    _viewModel = Provider.of<EditProfileViewModel>(context, listen: false);
    _loadUserData();
  }

  @override
  void dispose() {
    // Dispose controllers
    _fullNameController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();

    // Dispose focus nodes
    _fullNameFocusNode.dispose();
    _weightFocusNode.dispose();
    _heightFocusNode.dispose();
    _ageFocusNode.dispose();

    super.dispose();
  }

  void _loadUserData() async {
    await _viewModel.loadUserData();

    // Update text controllers with data from ViewModel
    _fullNameController.text = _viewModel.fullName;
    _ageController.text = _viewModel.age.toString();

    if (_viewModel.isKg) {
      _weightController.text = _viewModel.weight.toStringAsFixed(2);
    } else {
      _weightController.text = _viewModel.weight.toStringAsFixed(2);
    }

    if (_viewModel.isCm) {
      _heightController.text = _viewModel.height.toStringAsFixed(2);
    } else {
      _heightController.text = _viewModel.height.toStringAsFixed(2);
    }
  }

  // Function to move focus to the next field
  void _fieldFocusChange(BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  Future<void> _selectProfileImage() async {
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

          bool success = await _viewModel.updateProfileImage(selectedImage);

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Profile picture updated successfully!"),
                    duration: Duration(milliseconds: 1000)
                )
            );
          }
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
    // Unfocus any active focus node to dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Update ViewModel with form data
    _viewModel.setFullName(_fullNameController.text);
    _viewModel.setWeight(_weightController.text);
    _viewModel.setHeight(_heightController.text);
    _viewModel.setAge(_ageController.text);

    bool success = await _viewModel.saveUserData();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Profile updated successfully!"),
              duration: Duration(milliseconds: 1000)
          )
      );
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
    return Consumer<EditProfileViewModel>(
      builder: (context, viewModel, child) {
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
          body: viewModel.isLoading
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
                      // Profile image
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
                                  String? profileImage = viewModel.profileImage;

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

                      // Full Name
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
                        focusNode: _fullNameFocusNode,
                        style: GoogleFonts.montserrat(),
                        validator: viewModel.validateFullName,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) {
                          _fieldFocusChange(context, _fullNameFocusNode, _weightFocusNode);
                        },
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

                      // Weight
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
                              focusNode: _weightFocusNode,
                              style: GoogleFonts.montserrat(),
                              validator: viewModel.validateWeight,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                _fieldFocusChange(context, _weightFocusNode, _heightFocusNode);
                              },
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
                                suffixText: viewModel.isKg ? 'kg' : 'lbs',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ToggleButtons(
                            isSelected: [!viewModel.isKg, viewModel.isKg],
                            onPressed: (int index) {
                              viewModel.toggleWeightUnit(index == 1);
                              // Update controller with new weight value
                              _weightController.text = viewModel.weight.toStringAsFixed(2);
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

                      // Height
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
                              focusNode: _heightFocusNode,
                              style: GoogleFonts.montserrat(),
                              validator: viewModel.validateHeight,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) {
                                _fieldFocusChange(context, _heightFocusNode, _ageFocusNode);
                              },
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
                                suffixText: viewModel.isCm ? 'cm' : 'ft',
                                helperText: viewModel.isCm ? null : 'Enter decimal feet, e.g. 5.75',
                                helperStyle: GoogleFonts.montserrat(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ToggleButtons(
                            isSelected: [!viewModel.isCm, viewModel.isCm],
                            onPressed: (int index) {
                              viewModel.toggleHeightUnit(index == 1);
                              // Update controller with new height value
                              _heightController.text = viewModel.height.toStringAsFixed(2);
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

                      // Age
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
                        focusNode: _ageFocusNode,
                        style: GoogleFonts.montserrat(),
                        validator: viewModel.validateAge,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          // Dismiss keyboard after the last field
                          _ageFocusNode.unfocus();
                        },
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

                      // Gender
                      Text(
                        'Gender',
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: viewModel.gender,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            viewModel.setGender(newValue);
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

                      // Goal
                      Text(
                        'Goal',
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: viewModel.goal,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            viewModel.setGoal(newValue);
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

                      // Workout Days Per Week
                      Text(
                        'Workout Days Per Week',
                        style: GoogleFonts.montserrat(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: viewModel.workoutDays,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            viewModel.setWorkoutDays(newValue);
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

                      // Save and Logout buttons
                      Center(
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: viewModel.isLoading ? null : _saveUserData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD2EB50),
                                minimumSize: const Size(double.infinity, 54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                elevation: 0,
                              ),
                              child: viewModel.isLoading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
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
                                        onPressed: () async {
                                          try {
                                            // Use ViewModel to sign out
                                            bool success = await viewModel.signOut();

                                            if (success && mounted) {
                                              // Navigate to the WelcomePage
                                              Navigator.of(context).pushAndRemoveUntil(
                                                MaterialPageRoute(builder: (context) => const WelcomePage()),
                                                    (route) => false,
                                              );
                                            }
                                          } catch (e) {
                                            // Handle any potential errors during sign-out
                                            print("Error during sign out: $e");
                                            if (mounted) {
                                              // Optionally show an error message to the user
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Failed to logout. Please try again.')),
                                              );
                                            }
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
      },
    );
  }
}