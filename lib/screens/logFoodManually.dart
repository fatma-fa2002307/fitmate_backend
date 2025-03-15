import 'dart:io';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class LogFoodManuallyScreen extends StatefulWidget {
  const LogFoodManuallyScreen({super.key});

  @override
  State<LogFoodManuallyScreen> createState() => _LogFoodManuallyScreenState();
}

class _LogFoodManuallyScreenState extends State<LogFoodManuallyScreen> {
  int _selectedIndex = 2;

  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _dishNameController = TextEditingController();
  File? _image;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (pickedFile != null) {
        print("Image picked: ${pickedFile.path}");
        setState(() {
          _image = File(pickedFile.path);
        });
      } else {
        print("No image selected.");
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> saveFood() async {
    print("Saving food...");
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User not logged in.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
      }
      return;
    }

    if (_caloriesController.text.isEmpty ||
        _fatController.text.isEmpty ||
        _carbsController.text.isEmpty ||
        _proteinController.text.isEmpty ||
        _dishNameController.text.isEmpty
        //|| _image == null
        ) {
      //print("Error: All fields and image are required.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields  are required.")),
        );
      }
      return;
    }

    try {
      // String fileName = path.basename(_image!.path);
      // Reference storageReference = FirebaseStorage.instance
      //     .ref()
      //     .child('food_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName');
      //
      // print("Uploading image: $fileName");
      // UploadTask uploadTask = storageReference.putFile(_image!);
      // TaskSnapshot snapshot = await uploadTask;
      // String imageUrl = await snapshot.ref.getDownloadURL();
      // print("Image uploaded: $imageUrl");

      Map<String, dynamic> foodData = {
        //'imageUrl': imageUrl,
        'dishName': _dishNameController.text,
        'calories': double.tryParse(_caloriesController.text) ?? 0,
        'fat': double.tryParse(_fatController.text) ?? 0,
        'carbs': double.tryParse(_carbsController.text) ?? 0,
        'protein': double.tryParse(_proteinController.text) ?? 0,
        'date': DateTime.now(),
      };
      print("Saving data: $foodData");

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('foodLogs')
          .add(foodData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Food logged successfully!")),
        );
        Navigator.pop(context);
      }
      _caloriesController.clear();
      _fatController.clear();
      _carbsController.clear();
      _proteinController.clear();
      _dishNameController.clear();
      // setState(() {
      //   _image = null;
      // });
    } catch (e) {
      print("Error saving food: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error logging food: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'NUTRITION',
          style: GoogleFonts.bebasNeue(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return SafeArea(
                          child: Wrap(
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Photo Library'),
                                onTap: ()
                                {
                                  _pickImage(ImageSource.gallery);
                                  Navigator.of(context).pop();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Camera'),
                                onTap: () {
                                   _pickImage(ImageSource.camera);
                                   Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _image == null
                         ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                         : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _dishNameController,
                  decoration: const InputDecoration(
                    labelText: 'Dish Name (Required)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _caloriesController,
                  decoration: const InputDecoration(
                    labelText: 'Calories (Required)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _fatController,
                  decoration: const InputDecoration(
                    labelText: 'Fat (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _carbsController,
                  decoration: const InputDecoration(
                    labelText: 'Carbohydrates (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _proteinController,
                  decoration: const InputDecoration(
                    labelText: 'Protein (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: saveFood,
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
              ],
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
