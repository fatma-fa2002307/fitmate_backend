import 'dart:io';
import 'dart:async';
import 'package:fitmate/screens/nutrition_screens/nutrition_screen.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:convert';

// Update the LogFoodManuallyScreen constructor
class LogFoodManuallyScreen extends StatefulWidget {
  final Map<String, String>? prefillData;

  const LogFoodManuallyScreen({
    super.key,
    this.prefillData,
  });

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

  final FocusNode _dishNameFocus = FocusNode();
  final FocusNode _portionFocus = FocusNode();
  final FocusNode _caloriesFocus = FocusNode();
  final FocusNode _fatFocus = FocusNode();
  final FocusNode _carbsFocus = FocusNode();
  final FocusNode _proteinFocus = FocusNode();

  File? _image;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;
  double _portionSize = 1.0;
  bool _foodSelected = false;

  // Flag to track if we're loading results from the cache
  bool _isLoadingCachedResults = false;
  // Local SQLite caching could be implemented here

  @override
  void initState() {
    super.initState();
    _portionController.addListener(_onPortionChanged);
    _loadCachedFoods();

    // If prefill data is provided, use it to populate the fields
    if (widget.prefillData != null) {
      _dishNameController.text = widget.prefillData!['dishName'] ?? '';
      _caloriesController.text = widget.prefillData!['calories'] ?? '';
      _proteinController.text = widget.prefillData!['protein'] ?? '';
      _carbsController.text = widget.prefillData!['carbs'] ?? '';
      _fatController.text = widget.prefillData!['fat'] ?? '';

      // Store base nutritional values for portion calculations
      _baseCalories = double.tryParse(_caloriesController.text) ?? 0;
      _baseFat = double.tryParse(_fatController.text) ?? 0;
      _baseCarbs = double.tryParse(_carbsController.text) ?? 0;
      _baseProtein = double.tryParse(_proteinController.text) ?? 0;

      // Mark as food selected to prevent overwriting these values
      _foodSelected = true;
    }
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

    _dishNameFocus.dispose();
    _portionFocus.dispose();
    _caloriesFocus.dispose();
    _fatFocus.dispose();
    _carbsFocus.dispose();
    _proteinFocus.dispose();

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

        // If we have base values (either from selected food or previously calculated),
        // update the nutrition values based on the new portion size
        if (_baseCalories > 0 || _baseCarbs > 0 || _baseProtein > 0 || _baseFat > 0) {
          _updateNutritionValues();
        } else if (!_foodSelected && _caloriesController.text.isNotEmpty) {
          // For manually entered foods without base values yet, calculate and store base values
          // based on the previous portion size, then update
          double prevPortionSize = _portionSize == newPortion ? 1.0 : _portionSize;

          // Store base values (per single portion)
          _baseCalories = (double.tryParse(_caloriesController.text) ?? 0) / prevPortionSize;
          _baseFat = (double.tryParse(_fatController.text) ?? 0) / prevPortionSize;
          _baseCarbs = (double.tryParse(_carbsController.text) ?? 0) / prevPortionSize;
          _baseProtein = (double.tryParse(_proteinController.text) ?? 0) / prevPortionSize;

          // Now update with the new portion size
          _updateNutritionValues();
        }
      }
    } catch (e) {
      // Invalid input, ignore
      print("Error parsing portion size: $e");
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

  // Always update the controller values
  _caloriesController.text = calories;
  _fatController.text = fat;
  _carbsController.text = carbs;
  _proteinController.text = protein;
}

  Future<void> _searchFoods(String query) async {
    setState(() {
      _isSearching = true;
    });

    // 1. Search in user's food history - without limit to show all matches
    final userFoods = await _searchUserFoodHistory(query);

    // 2. Search in food database API - limit to 5 results
    final apiFoods = await _searchFoodDatabase(query);

    setState(() {
      // Combine results with Firebase results first, then API results
      _searchResults = [...userFoods, ...apiFoods];
      _isSearching = false;
    });
  }

  Future<List<Map<String, dynamic>>> _searchUserFoodHistory(String query) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      // Modified to use startsWith pattern without limiting results
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('foodLogs')
          .orderBy('dishName')
          .startAt([query])
          .endAt([query + '\uf8ff'])
      // Remove the limit to get all matching Firebase results
          .get();

      print("Firebase search returned ${snapshot.docs.length} results");

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

      final sanitizedQuery = query.trim();

      final response = await http.get(
        Uri.parse('https://api.nal.usda.gov/fdc/v1/foods/search?query=$sanitizedQuery&pageSize=5&dataType=Foundation,SR%20Legacy,Survey%20(FNDDS)&sortBy=dataType.keyword&api_key=$apiKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final foods = data['foods'] as List;

        // Debug log to check results
        print("API returned ${foods.length} results for query '$sanitizedQuery'");

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

  double safeToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (e) {
      return 0.0;
    }
  }
  return 0.0;
}

// Replace your _selectFood method with this improved version
  void _selectFood(Map<String, dynamic> food) {
    // Use our helper method to safely convert all values to double
    _baseCalories = safeToDouble(food['baseCalories'] ?? food['calories']);
    _baseFat = safeToDouble(food['baseFat'] ?? food['fat']);
    _baseCarbs = safeToDouble(food['baseCarbs'] ?? food['carbs']);
    _baseProtein = safeToDouble(food['baseProtein'] ?? food['protein']);

    // Store source for later use when saving
    _selectedFoodSource = food['source']?.toString();
    _selectedFoodId = food['fdcId']?.toString();

    // Set the dish name
    _dishNameController.text = food['dishName']?.toString() ?? '';

    // Reset portion size to 1 when selecting a new food
    _portionController.text = "1";
    _portionSize = 1.0;

    // Directly set the text controller values as strings
    // Use setState to ensure immediate UI update
    setState(() {
      _caloriesController.text = _baseCalories.toStringAsFixed(1);
      _fatController.text = _baseFat.toStringAsFixed(1);
      _carbsController.text = _baseCarbs.toStringAsFixed(1);
      _proteinController.text = _baseProtein.toStringAsFixed(1);
      _searchResults = [];
      _foodSelected = true;
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

  Future<bool> saveFood() async {
    print("Saving food...");
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("Error: User not logged in.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in.")),
        );
      }
      return false;
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
      return false;
    }

    try {
      if (!_foodSelected) {
        double currentPortionSize = double.tryParse(_portionController.text) ?? 1.0;
        _baseCalories = (double.tryParse(_caloriesController.text) ?? 0) / currentPortionSize;
        _baseFat = (double.tryParse(_fatController.text) ?? 0) / currentPortionSize;
        _baseCarbs = (double.tryParse(_carbsController.text) ?? 0) / currentPortionSize;
        _baseProtein = (double.tryParse(_proteinController.text) ?? 0) / currentPortionSize;
      }

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

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('foodLogs')
          .add(foodData);

      print("Added new food entry");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Food saved successfully!")),
        );
      }

      return true;
    } catch (e) {
      print("Error saving food: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save food: $e")),
        );
      }
      return false;
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
                  focusNode: _dishNameFocus,
                  textInputAction: TextInputAction.next,
                  onEditingComplete: () => FocusScope.of(context).requestFocus(_portionFocus),
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
                    _debounce = Timer(const Duration(milliseconds: 300), () { // Reduced delay
                      if (value.length >= 1) { // Changed from >2 to >=1 to search after just one character
                        setState(() {
                          _isSearching = true;
                          _foodSelected = false;
                        });
                        _searchFoods(value);
                      } else if (value.isEmpty) {
                        _loadCachedFoods();
                        setState(() {
                          _foodSelected = false;
                        });
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
                if (!_isSearching && !_isLoadingCachedResults && _searchResults.isEmpty &&
                    _dishNameController.text.length > 2 && !_foodSelected)
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
                              focusNode: _portionFocus,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => FocusScope.of(context).requestFocus(_caloriesFocus),
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
                              focusNode: _caloriesFocus,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => FocusScope.of(context).requestFocus(_fatFocus),
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
                              focusNode: _fatFocus,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => FocusScope.of(context).requestFocus(_carbsFocus),
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
                              focusNode: _carbsFocus,
                              textInputAction: TextInputAction.next,
                              onEditingComplete: () => FocusScope.of(context).requestFocus(_proteinFocus),
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
                              focusNode: _proteinFocus,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) {
                                // close keyboard after the last field
                                FocusScope.of(context).unfocus();
                              },
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
                    onPressed: () async {
                      bool success = await saveFood();
                      if (success && mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const NutritionPage()),
                              (Route<dynamic> route) => false, // remove all previous routes
                        );
                      }
                    },


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
