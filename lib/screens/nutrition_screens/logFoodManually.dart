// import 'dart:io';
// import 'package:fitmate/widgets/bottom_nav_bar.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:path/path.dart' as path;

// class LogFoodManuallyScreen extends StatefulWidget {
//   const LogFoodManuallyScreen({super.key});

//   @override
//   State<LogFoodManuallyScreen> createState() => _LogFoodManuallyScreenState();
// }

// class _LogFoodManuallyScreenState extends State<LogFoodManuallyScreen> {
//   int _selectedIndex = 2;

//   final TextEditingController _caloriesController = TextEditingController();
//   final TextEditingController _fatController = TextEditingController();
//   final TextEditingController _carbsController = TextEditingController();
//   final TextEditingController _proteinController = TextEditingController();
//   final TextEditingController _dishNameController = TextEditingController();
//   File? _image;

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//     });
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final pickedFile = await ImagePicker().pickImage(source: source);
//       if (pickedFile != null) {
//         print("Image picked: ${pickedFile.path}");
//         setState(() {
//           _image = File(pickedFile.path);
//         });
//       } else {
//         print("No image selected.");
//       }
//     } catch (e) {
//       print("Error picking image: $e");
//     }
//   }

//   Future<void> saveFood() async {
//     print("Saving food...");
//     User? user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       print("Error: User not logged in.");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("User not logged in.")),
//         );
//       }
//       return;
//     }

//     if (_caloriesController.text.isEmpty ||
//         _fatController.text.isEmpty ||
//         _carbsController.text.isEmpty ||
//         _proteinController.text.isEmpty ||
//         _dishNameController.text.isEmpty
//     //|| _image == null
//     ) {
//       //print("Error: All fields and image are required.");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("All fields  are required.")),
//         );
//       }
//       return;
//     }

//     try {
//       // String fileName = path.basename(_image!.path);
//       // Reference storageReference = FirebaseStorage.instance
//       //     .ref()
//       //     .child('food_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$fileName');
//       //
//       // print("Uploading image: $fileName");
//       // UploadTask uploadTask = storageReference.putFile(_image!);
//       // TaskSnapshot snapshot = await uploadTask;
//       // String imageUrl = await snapshot.ref.getDownloadURL();
//       // print("Image uploaded: $imageUrl");

//       Map<String, dynamic> foodData = {
//         //'imageUrl': imageUrl,
//         'dishName': _dishNameController.text,
//         'calories': double.tryParse(_caloriesController.text) ?? 0,
//         'fat': double.tryParse(_fatController.text) ?? 0,
//         'carbs': double.tryParse(_carbsController.text) ?? 0,
//         'protein': double.tryParse(_proteinController.text) ?? 0,
//         'date': DateTime.now(),
//       };
//       print("Saving data: $foodData");

//       await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('foodLogs')
//           .add(foodData);

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("Food logged successfully!")),
//         );
//         Navigator.pop(context);
//       }
//       _caloriesController.clear();
//       _fatController.clear();
//       _carbsController.clear();
//       _proteinController.clear();
//       _dishNameController.clear();
//       // setState(() {
//       //   _image = null;
//       // });
//     } catch (e) {
//       print("Error saving food: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Error logging food: $e")),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'NUTRITION',
//           style: GoogleFonts.bebasNeue(color: Colors.black),
//         ),
//         centerTitle: true,
//         backgroundColor: Colors.white,
//         elevation: 0,
//         iconTheme: const IconThemeData(color: Colors.black),
//       ),
//       body: SingleChildScrollView(
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 // GestureDetector(
//                 //   onTap: () {
//                 //     showModalBottomSheet(
//                 //       context: context,
//                 //       builder: (BuildContext context) {
//                 //         return SafeArea(
//                 //           child: Wrap(
//                 //             //children:
//                 //             // <Widget>[
//                 //             //   ListTile(
//                 //             //     leading: const Icon(Icons.photo_library),
//                 //             //     title: const Text('Photo Library'),
//                 //             //     onTap: ()
//                 //             //     {
//                 //             //       _pickImage(ImageSource.gallery);
//                 //             //       Navigator.of(context).pop();
//                 //             //     },
//                 //             //   ),
//                 //             //   ListTile(
//                 //             //     leading: const Icon(Icons.camera_alt),
//                 //             //     title: const Text('Camera'),
//                 //             //     onTap: () {
//                 //             //        _pickImage(ImageSource.camera);
//                 //             //        Navigator.of(context).pop();
//                 //             //     },
//                 //             //   ),
//                 //             // ]
//                 //             //,
//                 //           ),
//                 //         );
//                 //       },
//                 //     );
//                 //   },
//                 //   child:
//                 //   Container(
//                 //     height: 150,
//                 //     width: double.infinity,
//                 //     decoration: BoxDecoration(
//                 //       color: Colors.grey[200],
//                 //       borderRadius: BorderRadius.circular(10),
//                 //     ),
//                 // //     child: _image == null
//                 // //          ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
//                 // //          : ClipRRect(
//                 // //       borderRadius: BorderRadius.circular(10),
//                 // //       child: Image.file(_image!, fit: BoxFit.cover),
//                 // //     ),
//                 //    ),
//                 //  ),
//                 const SizedBox(height: 20),
//                 TextField(
//                   controller: _dishNameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Dish Name (Required)',
//                     border: OutlineInputBorder(),
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//                 TextField(
//                   controller: _caloriesController,
//                   decoration: const InputDecoration(
//                     labelText: 'Calories (Required)',
//                     border: OutlineInputBorder(),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: _fatController,
//                   decoration: const InputDecoration(
//                     labelText: 'Fat (g)',
//                     border: OutlineInputBorder(),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: _carbsController,
//                   decoration: const InputDecoration(
//                     labelText: 'Carbohydrates (g)',
//                     border: OutlineInputBorder(),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 10),
//                 TextField(
//                   controller: _proteinController,
//                   decoration: const InputDecoration(
//                     labelText: 'Protein (g)',
//                     border: OutlineInputBorder(),
//                   ),
//                   keyboardType: TextInputType.number,
//                 ),
//                 const SizedBox(height: 20),
//                 ElevatedButton(
//                   onPressed: saveFood,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFFD2EB50),
//                     minimumSize: const Size(150, 50),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(5.0),
//                     ),
//                   ),
//                   child: Text(
//                     'SAVE',
//                     style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       bottomNavigationBar: BottomNavBar(
//         currentIndex: _selectedIndex,
//         onTap: _onItemTapped,
//       ),
//     );
//   }
// }


import 'dart:io';
import 'dart:async';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';

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
  final TextEditingController _portionController = TextEditingController(text: "1");
  
  File? _image;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  double _portionSize = 1.0;

  // Flag to track if we're loading results from the cache
  bool _isLoadingCachedResults = false;
  // Local SQLite caching could be implemented here
    
  @override
  void initState() {
    super.initState();
    _portionController.addListener(_onPortionChanged);
    _loadCachedFoods();
  }
  
  // Load the most recent or common foods from cache
  Future<void> _loadCachedFoods() async {
    setState(() {
      _isLoadingCachedResults = true;
    });
    
    try {
      // This would be a good place to load recently used foods
      // from a local SQLite database to show as suggestions
      
      // For now, we'll just fetch from Firebase history
      final recentFoods = await _fetchRecentFoods();
      
      setState(() {
        _searchResults = recentFoods;
        _isLoadingCachedResults = false;
      });
    } catch (e) {
      print("Error loading cached foods: $e");
      setState(() {
        _isLoadingCachedResults = false;
      });
    }
  }
  
  // Fetch recent foods from Firebase
  Future<List<Map<String, dynamic>>> _fetchRecentFoods() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('foodLogs')
          .orderBy('date', descending: true)
          .limit(5)
          .get();
          
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['source'] = 'history';
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching recent foods: $e");
      return [];
    }
  }

  @override
  void dispose() {
    _portionController.removeListener(_onPortionChanged);
    _debounce?.cancel();
    _caloriesController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _proteinController.dispose();
    _dishNameController.dispose();
    _portionController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // No longer needed - moved logic to the TextField onChanged
  void _onSearchTextChanged() {}

  void _onPortionChanged() {
    try {
      final newPortion = double.parse(_portionController.text);
      if (newPortion > 0) {
        setState(() {
          _portionSize = newPortion;
        });
        _updateNutritionValues();
      }
    } catch (e) {
      // Invalid input, ignore
    }
  }

  // Store original nutrition values and metadata when a food is selected
  double _baseCalories = 0;
  double _baseFat = 0;
  double _baseCarbs = 0;
  double _baseProtein = 0;
  String? _selectedFoodSource;
  String? _selectedFoodId;

  void _updateNutritionValues() {
    // Calculate values based on portion size
    final calories = (_baseCalories * _portionSize).toStringAsFixed(1);
    final fat = (_baseFat * _portionSize).toStringAsFixed(1);
    final carbs = (_baseCarbs * _portionSize).toStringAsFixed(1);
    final protein = (_baseProtein * _portionSize).toStringAsFixed(1);
    
    // Only update if values are different to avoid cursor jumping
    if (_caloriesController.text != calories) _caloriesController.text = calories;
    if (_fatController.text != fat) _fatController.text = fat;
    if (_carbsController.text != carbs) _carbsController.text = carbs;
    if (_proteinController.text != protein) _proteinController.text = protein;
  }

  Future<void> _searchFoods(String query) async {
    // 1. Search in user's food history
    final userFoods = await _searchUserFoodHistory(query);
    
    // 2. Search in food database API
    final apiFoods = await _searchFoodDatabase(query);
    
    setState(() {
      _searchResults = [...userFoods, ...apiFoods];
      _isSearching = false;
    });
  }

  Future<List<Map<String, dynamic>>> _searchUserFoodHistory(String query) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('foodLogs')
          .where('dishName', isGreaterThanOrEqualTo: query)
          .where('dishName', isLessThanOrEqualTo: query + '\uf8ff')
          .limit(5)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['source'] = 'history';
        return data;
      }).toList();
    } catch (e) {
      print("Error searching food history: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _searchFoodDatabase(String query) async {
    // Implementation for USDA FoodData Central API
    try {
      final apiKey = 'Rmow9U6Hr52D2t8TbroUazjKTDpASuLMkLGngFhL'; // Replace with your actual API key
      final response = await http.get(
        Uri.parse('https://api.nal.usda.gov/fdc/v1/foods/search?query=$query&pageSize=5&dataType=Foundation,SR%20Legacy,Survey%20(FNDDS)&sortBy=dataType.keyword&api_key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foods = data['foods'] as List;
        
        return foods.map<Map<String, dynamic>>((food) {
          // Extract relevant nutritional info from the food data
          final nutrients = food['foodNutrients'] as List;
          
          double calories = 0, fat = 0, carbs = 0, protein = 0;
          
          // USDA FoodData Central uses specific nutrientIds for each nutrient
          for (var nutrient in nutrients) {
            // Nutrient data structure changed in recent API versions
            final nutrientId = nutrient['nutrientId'] ?? 
                              (nutrient['nutrient']?['id'] ?? 0);
            
            final value = nutrient['value'] ?? 
                         nutrient['amount'] ?? 0;
            
            // Map nutrient IDs to your categories
            // Energy (kcal)
            if (nutrientId == 1008 || nutrientId == 2047 || nutrientId == 2048) {
              calories = value.toDouble();
            }
            // Total lipid (fat)
            if (nutrientId == 1004 || nutrientId == 2002) {
              fat = value.toDouble();
            }
            // Carbohydrate, by difference
            if (nutrientId == 1005 || nutrientId == 2000) {
              carbs = value.toDouble();
            }
            // Protein
            if (nutrientId == 1003 || nutrientId == 2001) {
              protein = value.toDouble();
            }
          }
          
          // Get portion size info if available
          String portionInfo = "";
          if (food['servingSize'] != null && food['servingSizeUnit'] != null) {
            portionInfo = "${food['servingSize']} ${food['servingSizeUnit']}";
          }
          
          // Get the food category
          String category = food['foodCategory'] ?? '';
          if (food['foodCategory'] == null && food['foodCategoryLabel'] != null) {
            category = food['foodCategoryLabel'];
          }
          
          return {
            'dishName': food['description'],
            'calories': calories,
            'fat': fat,
            'carbs': carbs,
            'protein': protein,
            'portionInfo': portionInfo,
            'category': category,
            'fdcId': food['fdcId'],
            'source': 'USDA',
          };
        }).toList();
      }
      
      print("API response status: ${response.statusCode}");
      if (response.statusCode != 200) {
        print("API error: ${response.body}");
      }
      
      return [];
    } catch (e) {
      print("Error searching food database: $e");
      return [];
    }
  }

  void _selectFood(Map<String, dynamic> food) {
    _dishNameController.text = food['dishName'];
    
    // Store base values (use base values if already stored in history)
    _baseCalories = food['baseCalories'] != null ? food['baseCalories'].toDouble() : food['calories'].toDouble();
    _baseFat = food['baseFat'] != null ? food['baseFat'].toDouble() : food['fat'].toDouble();
    _baseCarbs = food['baseCarbs'] != null ? food['baseCarbs'].toDouble() : food['carbs'].toDouble();
    _baseProtein = food['baseProtein'] != null ? food['baseProtein'].toDouble() : food['protein'].toDouble();
    
    // Store source for later use when saving
    _selectedFoodSource = food['source'];
    _selectedFoodId = food['fdcId'];
    
    // Reset portion size to 1 when selecting a new food
    if (_portionController.text != "1") {
      _portionController.text = "1";
      _portionSize = 1.0;
    }
    
    // Apply portion size
    _updateNutritionValues();
    
    setState(() {
      _searchResults = [];
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
        _dishNameController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All fields are required.")),
        );
      }
      return;
    }

    try {
      // Check if this food already exists in user's history
      bool isUpdating = false;
      String? existingDocId;
      
      // Only check for existing food if it came from history
      if (_selectedFoodSource == 'history') {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('foodLogs')
            .where('dishName', isEqualTo: _dishNameController.text)
            .limit(1)
            .get();
            
        if (querySnapshot.docs.isNotEmpty) {
          isUpdating = true;
          existingDocId = querySnapshot.docs.first.id;
        }
      }

      // Basic food data
      Map<String, dynamic> foodData = {
        'dishName': _dishNameController.text,
        'calories': double.tryParse(_caloriesController.text) ?? 0,
        'fat': double.tryParse(_fatController.text) ?? 0,
        'carbs': double.tryParse(_carbsController.text) ?? 0,
        'protein': double.tryParse(_proteinController.text) ?? 0,
        'baseCalories': _baseCalories,
        'baseFat': _baseFat, 
        'baseCarbs': _baseCarbs,
        'baseProtein': _baseProtein,
        'portionSize': _portionSize,
        'date': DateTime.now(),
      };
      
      if (_selectedFoodId != null) {
        foodData['fdcId'] = _selectedFoodId;
      }
      
      print("Saving data: $foodData");

      if (isUpdating && existingDocId != null) {
        // Update existing record if it came from history
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('foodLogs')
            .doc(existingDocId)
            .update(foodData);
            
        print("Updated existing food entry");
      } else {
        // Add new food log
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('foodLogs')
            .add(foodData);
            
        print("Added new food entry");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isUpdating ? "Food updated successfully!" : "Food logged successfully!"),
            backgroundColor: const Color(0xFFD2EB50),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
      
      // Clear form
      _caloriesController.clear();
      _fatController.clear();
      _carbsController.clear();
      _proteinController.clear();
      _dishNameController.clear();
      _portionController.text = "1";
      setState(() {
        _image = null;
        _portionSize = 1.0;
        _baseCalories = 0;
        _baseFat = 0;
        _baseCarbs = 0;
        _baseProtein = 0;
        _selectedFoodSource = null;
        _selectedFoodId = null;
      });
    } catch (e) {
      print("Error saving food: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error logging food: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LOG FOOD',
          style: GoogleFonts.bebasNeue(
            color: Colors.black,
            fontSize: 26,
            letterSpacing: 1.2,
          ),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                // Header instruction text
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD2EB50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFD2EB50),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Search for a food or enter your own custom meal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // Dish name with integrated search
                TextField(
                  controller: _dishNameController,
                  decoration: InputDecoration(
                    labelText: 'Dish Name (Required)',
                    border: OutlineInputBorder(),
                    hintText: 'Start typing to search or enter custom name...',
                    prefixIcon: Icon(Icons.restaurant_menu),
                    suffixIcon: _dishNameController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _dishNameController.clear();
                              _loadCachedFoods();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    if (_debounce?.isActive ?? false) _debounce!.cancel();
                    _debounce = Timer(const Duration(milliseconds: 500), () {
                      if (value.length > 2) {
                        setState(() {
                          _isSearching = true;
                        });
                        _searchFoods(value);
                      } else if (value.isEmpty) {
                        _loadCachedFoods();
                      } else {
                        setState(() {
                          _searchResults = [];
                          _isSearching = false;
                        });
                      }
                    });
                  },
                ),
                // Show search results
                if (_isSearching || _isLoadingCachedResults)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!_isSearching && !_isLoadingCachedResults && _searchResults.isEmpty && _dishNameController.text.length > 2)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Center(child: Text("No foods found. Try a different search term.")),
                  ),
                if (_searchResults.isNotEmpty)
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final food = _searchResults[index];
                          return Card(
                            elevation: 1,
                            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                food['dishName'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                                      SizedBox(width: 4),
                                      Text(
                                        '${food['calories'].toStringAsFixed(0)} cal',
                                        style: TextStyle(fontWeight: FontWeight.w500),
                                      ),
                                      SizedBox(width: 12),
                                      Icon(Icons.fitness_center, size: 14, color: Colors.red[300]),
                                      SizedBox(width: 4),
                                      Text(
                                        '${food['protein'].toStringAsFixed(1)}g protein',
                                      ),
                                    ],
                                  ),
                                  if (food['portionInfo'] != null && food['portionInfo'].toString().isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Portion: ${food['portionInfo']}',
                                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: food['source'] == 'history'
                                  ? Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD2EB50).withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'History',
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                              isThreeLine: food['portionInfo'] != null && food['portionInfo'].toString().isNotEmpty,
                              onTap: () => _selectFood(food),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                // Portion size with better styling
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'PORTION SIZE',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 18,
                            letterSpacing: 1,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.restaurant, color: const Color(0xFFD2EB50)),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _portionController,
                              decoration: InputDecoration(
                                labelText: 'Number of portions',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                hintText: '1',
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () {
                                    if (_portionSize > 0.25) {
                                      _portionController.text = (_portionSize - 0.25).toStringAsFixed(2);
                                    }
                                  },
                                  color: const Color(0xFFD2EB50),
                                ),
                                Container(
                                  color: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                                    _portionSize.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    _portionController.text = (_portionSize + 0.25).toStringAsFixed(2);
                                  },
                                  color: const Color(0xFFD2EB50),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Nutrition information section with icons
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'NUTRITION INFO',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 18,
                            letterSpacing: 1,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _caloriesController,
                              decoration: InputDecoration(
                                labelText: 'Calories (Required)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.egg_outlined, color: Colors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _fatController,
                              decoration: InputDecoration(
                                labelText: 'Fat (g)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.grain, color: Colors.brown[300]),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _carbsController,
                              decoration: InputDecoration(
                                labelText: 'Carbohydrates (g)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.fitness_center, color: Colors.red[300]),
                          SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _proteinController,
                              decoration: InputDecoration(
                                labelText: 'Protein (g)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Save button
                Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: saveFood,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2EB50),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      elevation: 3,
                    ),
                    child: Text(
                      'SAVE',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24, 
                        color: Colors.white,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
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
