import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../widgets/bottom_nav_bar.dart';
import '../widgets/food_suggestion_card.dart';
import '../repositories/food_repository.dart';
import '../models/food_suggestion.dart';
import '../services/food_suggestion_service.dart';
import 'logFoodManually.dart';
import 'camera_page.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({Key? key}) : super(key: key);

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  // App navigation
  int _selectedIndex = 2;
  
  // User's nutrition data
  double _totalCalories = 0;
  double _totalCarbs = 0;
  double _totalProtein = 0;
  double _totalFat = 0;
  Map<String, double> _dailyMacros = {};
  
  // User profile data
  String _gender = '';
  double _weight = 0;
  double _height = 0;
  int _age = 0;
  String _goal = '';
  int _workoutDays = 0;
  
  // UI state
  bool _isLoading = true;
  List<Map<String, dynamic>> _todaysFoodLogs = [];
  DateTime _selectedDate = DateTime.now();
  
  // Food suggestions state
  final FoodSuggestionService _foodSuggestionService = FoodSuggestionService();
  List<FoodSuggestion> _suggestions = [];
  bool _suggestionsLoading = true;
  String _suggestionsError = '';
  int _currentSuggestionIndex = 0;
  SuggestionMilestone _currentMilestone = SuggestionMilestone.START;

  // Initialize repository
  final FoodRepository _foodRepository = FoodRepository();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Load all necessary data
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    await _loadUserData();
    await _loadFoodLogs();
    _loadFoodSuggestions();
    
    setState(() {
      _isLoading = false;
    });
  }

  // Load user profile and nutrition targets
  Future<void> _loadUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load user profile data
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userData.exists) {
        setState(() {
          _gender = userData['gender'] as String;

          // Handle weight field - could be double or String
          if (userData['weight'] is double) {
            _weight = userData['weight'];
          } else {
            _weight = double.tryParse(userData['weight']?.toString() ?? '0') ?? 0;
          }

          // Handle height field - could be double or String
          if (userData['height'] is double) {
            _height = userData['height'];
          } else {
            _height = double.tryParse(userData['height']?.toString() ?? '0') ?? 0;
          }

          _age = userData['age'] as int;
          _goal = userData['goal'] as String;
          _workoutDays = userData['workoutDays'] as int;
        });

        // Check if macros exist in Firebase, if not, calculate and save them
        bool macrosExist = await _foodRepository.userMacrosExist();

        if (macrosExist) {
          // Load macros from Firebase
          _dailyMacros = await _foodRepository.getUserMacros();
        } else {
          // Calculate macros and save them to Firebase
          _dailyMacros = await _foodRepository.calculateAndSaveUserMacros(
              _gender,
              _weight,
              _height,
              _age,
              _goal,
              _workoutDays
          );
        }
      }
    }
  }

  // Load food logs for the selected date
  Future<void> _loadFoodLogs() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Create date range for selected date
      DateTime startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      DateTime endDate = startDate.add(const Duration(days: 1));

      QuerySnapshot foodLogs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('foodLogs')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThan: endDate)
          .orderBy('date', descending: true)
          .get();

      setState(() {
        _todaysFoodLogs = foodLogs.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'id': doc.id,
                })
            .toList();
            
        // Reset totals
        _totalCalories = 0;
        _totalCarbs = 0;
        _totalProtein = 0;
        _totalFat = 0;
        
        // Calculate totals
        for (var food in _todaysFoodLogs) {
          _totalCalories += food['calories'] ?? 0;
          _totalCarbs += food['carbs'] ?? 0;
          _totalProtein += food['protein'] ?? 0;
          _totalFat += food['fat'] ?? 0;
        }
      });
    }
  }

  // Load food suggestions based on current milestone
  Future<void> _loadFoodSuggestions() async {
    setState(() {
      _suggestionsLoading = true;
      _suggestionsError = '';
    });
    
    try {
      // Get current milestone
      final percentage = _totalCalories / (_dailyMacros['calories'] ?? 2000);
      _currentMilestone = SuggestionMilestoneExtension.fromPercentage(percentage);
      
      // Get suggestions
      final suggestions = await _foodSuggestionService.getSuggestionsForCurrentMilestone(
        totalCalories: _dailyMacros['calories'] ?? 2000,
        consumedCalories: _totalCalories,
        goal: _goal,
      );
      
      setState(() {
        _suggestions = suggestions;
        _suggestionsLoading = false;
        _currentSuggestionIndex = 0; // Reset to first suggestion
      });
    } catch (e) {
      setState(() {
        _suggestionsError = 'Unable to load suggestions';
        _suggestionsLoading = false;
      });
      print('Error loading suggestions: $e');
    }
  }
  
  // Select a different date
  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadFoodLogs();
  }
  
  // Navigate to previous day
  void _previousDay() {
    _selectDate(_selectedDate.subtract(const Duration(days: 1)));
  }
  
  // Navigate to next day
  void _nextDay() {
    _selectDate(_selectedDate.add(const Duration(days: 1)));
  }
  
  // Delete a food log entry
  Future<void> _deleteFood(String foodId) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('foodLogs')
            .doc(foodId)
            .delete();
            
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Food entry deleted')),
        );
        
        _loadFoodLogs();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting food: $e')),
      );
    }
  }
  
  // Handle when a suggestion is liked or disliked
  void _handleSuggestionPreferenceChange() {
    // Move to next suggestion when preference changes
    if (_suggestions.length > 1) {
      setState(() {
        _currentSuggestionIndex = (_currentSuggestionIndex + 1) % _suggestions.length;
      });
    }
  }
  
  // Generate a personalized reason for the current suggestion
  String _getPersonalizedReason(FoodSuggestion suggestion) {
    // Calculate remaining calories
    final remainingCalories = (_dailyMacros['calories'] ?? 2000) - _totalCalories;
    
    // Generate reason based on milestone and nutrition needs
    switch (_currentMilestone) {
      case SuggestionMilestone.START:
        return "Great breakfast option to start your day with energy";
      
      case SuggestionMilestone.QUARTER:
        if ((_totalProtein / (_dailyMacros['protein'] ?? 150)) < 0.25) {
          return "Good protein source for your mid-morning snack";
        } else {
          return "Perfect mid-morning snack that fits your calorie budget";
        }
      
      case SuggestionMilestone.HALF:
        if (suggestion.calories < remainingCalories * 0.4) {
          return "Balanced lunch option that leaves plenty of calories for later";
        } else if ((_totalProtein / (_dailyMacros['protein'] ?? 150)) < 0.3) {
          return "Protein-rich lunch to help you reach your daily goals";
        } else {
          return "Nutritious lunch option to keep you going through the day";
        }
      
      case SuggestionMilestone.THREE_QUARTERS:
        if (remainingCalories < 500) {
          return "Light dinner option that fits within your remaining calories";
        } else {
          return "Dinner option with balanced nutrients for your evening meal";
        }
      
      case SuggestionMilestone.ALMOST_COMPLETE:
        return "Light snack to complete your day without exceeding your calorie goal";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentages for macro circles
    final caloriePercentage = (_dailyMacros['calories'] ?? 2000) > 0 
        ? (_totalCalories / (_dailyMacros['calories'] ?? 2000)).clamp(0.0, 1.0) 
        : 0.0;
    final proteinPercentage = (_dailyMacros['protein'] ?? 150) > 0 
        ? (_totalProtein / (_dailyMacros['protein'] ?? 150)).clamp(0.0, 1.0) 
        : 0.0;
    final carbsPercentage = (_dailyMacros['carbs'] ?? 225) > 0 
        ? (_totalCarbs / (_dailyMacros['carbs'] ?? 225)).clamp(0.0, 1.0) 
        : 0.0;
    final fatPercentage = (_dailyMacros['fat'] ?? 65) > 0 
        ? (_totalFat / (_dailyMacros['fat'] ?? 65)).clamp(0.0, 1.0) 
        : 0.0;
    
    // Format date for display
    final bool isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;
    final dateText = isToday 
        ? 'Today' 
        : DateFormat('EEEE, MMMM d').format(_selectedDate);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'NUTRITION',
          style: GoogleFonts.bebasNeue(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD2EB50)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFFD2EB50),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date selector
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      color: Colors.white,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: _previousDay,
                          ),
                          Column(
                            children: [
                              Text(
                                dateText,
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_totalCalories.toInt()} / ${_dailyMacros['calories']?.toInt() ?? 2000} calories',
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: isToday ? null : _nextDay,
                            color: isToday ? Colors.grey[400] : null,
                          ),
                        ],
                      ),
                    ),
                    
                    // Main macros summary
                    Container(
                      color: Colors.white,
                      margin: const EdgeInsets.only(top: 1),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Calories
                              Expanded(
                                flex: 2,
                                child: Column(
                                  children: [
                                    CircularPercentIndicator(
                                      radius: 60.0,
                                      lineWidth: 10.0,
                                      percent: caloriePercentage,
                                      center: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _totalCalories.toInt().toString(),
                                            style: GoogleFonts.montserrat(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'kcal',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                      progressColor: const Color(0xFFD2EB50),
                                      backgroundColor: Colors.grey[200]!,
                                      circularStrokeCap: CircularStrokeCap.round,
                                      animation: true,
                                      animationDuration: 1200,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Calories',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Other macros grid
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildMacroProgress(
                                          'Protein', 
                                          _totalProtein.toInt(), 
                                          _dailyMacros['protein']?.toInt() ?? 150,
                                          proteinPercentage,
                                          Colors.red[400]!,
                                        ),
                                        _buildMacroProgress(
                                          'Carbs', 
                                          _totalCarbs.toInt(), 
                                          _dailyMacros['carbs']?.toInt() ?? 225,
                                          carbsPercentage,
                                          Colors.blue[400]!,
                                        ),
                                        _buildMacroProgress(
                                          'Fat', 
                                          _totalFat.toInt(), 
                                          _dailyMacros['fat']?.toInt() ?? 65,
                                          fatPercentage,
                                          Colors.amber[700]!,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Meal suggestion section
                    if (isToday) // Only show suggestions for today
                      Container(
                        margin: const EdgeInsets.only(top: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.restaurant_menu, color: Color(0xFFD2EB50)),
                                const SizedBox(width: 8),
                                Text(
                                  'Food Suggestion',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (_suggestions.isNotEmpty && !_suggestionsLoading)
                                  TextButton(
                                    onPressed: _loadFoodSuggestions,
                                    style: TextButton.styleFrom(
                                      minimumSize: Size.zero,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Refresh',
                                      style: TextStyle(color: Color(0xFFD2EB50)),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Suggestion content
                            if (_suggestionsLoading)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24.0),
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                                  ),
                                ),
                              )
                            else if (_suggestionsError.isNotEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        _suggestionsError,
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                      TextButton(
                                        onPressed: _loadFoodSuggestions,
                                        child: const Text('Try Again'),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_suggestions.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text(
                                    'No suggestions available',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: [
                                  // Current suggestion
                                  FoodSuggestionCard(
                                    suggestion: _suggestions[_currentSuggestionIndex],
                                    customReason: _getPersonalizedReason(_suggestions[_currentSuggestionIndex]),
                                    onLike: _handleSuggestionPreferenceChange,
                                    onDislike: _handleSuggestionPreferenceChange,
                                  ),
                                  
                                  // Navigation dots
                                  if (_suggestions.length > 1)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          for (int i = 0; i < _suggestions.length; i++)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.symmetric(horizontal: 4),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: i == _currentSuggestionIndex
                                                    ? const Color(0xFFD2EB50)
                                                    : Colors.grey[300],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    
                    // Today's Food header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TODAY\'S FOOD',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          if (isToday)
                            TextButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LogFoodManuallyScreen(),
                                  ),
                                ).then((_) => _loadData());
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('ADD FOOD'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFD2EB50),
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Food logs list
                    if (_todaysFoodLogs.isEmpty)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.no_food,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No food logged for this day',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              if (isToday)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => LogFoodManuallyScreen(),
                                        ),
                                      ).then((_) => _loadData());
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD2EB50),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('ADD FOOD'),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _todaysFoodLogs.length,
                        itemBuilder: (context, index) {
                          final food = _todaysFoodLogs[index];
                          final foodTime = (food['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                          
                          return Container(
                            margin: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 8,
                              top: index == 0 ? 8 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                food['dishName'] ?? 'Unknown Food',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(DateFormat('h:mm a').format(foodTime)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _buildNutrientBadge('${food['calories']?.toInt() ?? 0} cal', Colors.orange[100]!),
                                      const SizedBox(width: 8),
                                      _buildNutrientBadge('P: ${food['protein']?.toInt() ?? 0}g', Colors.red[100]!),
                                      const SizedBox(width: 8),
                                      _buildNutrientBadge('C: ${food['carbs']?.toInt() ?? 0}g', Colors.blue[100]!),
                                      const SizedBox(width: 8),
                                      _buildNutrientBadge('F: ${food['fat']?.toInt() ?? 0}g', Colors.amber[100]!),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: isToday ? IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.grey[600],
                                onPressed: () => _deleteFood(food['id']),
                              ) : null,
                            ),
                          );
                        },
                      ),
                      
                    // Add space at the bottom
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      
      // Add floating action button only for today's view
      floatingActionButton: isToday ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LogFoodManuallyScreen(),
            ),
          ).then((_) => _loadData());
        },
        backgroundColor: const Color(0xFFD2EB50),
        child: const Icon(Icons.add),
      ) : null,
      
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
  
  // Helper to build a macro progress indicator
  Widget _buildMacroProgress(String label, int current, int target, double percentage, Color color) {
    return Column(
      children: [
        SizedBox(
          height: 70,
          width: 70,
          child: Stack(
            children: [
              Center(
                child: CircularPercentIndicator(
                  radius: 28.0,
                  lineWidth: 6.0,
                  percent: percentage,
                  progressColor: color,
                  backgroundColor: Colors.grey[200]!,
                  circularStrokeCap: CircularStrokeCap.round,
                  animation: true,
                  animationDuration: 1200,
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      current.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'g',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$current/$target',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  // Helper to build a nutrient badge
  Widget _buildNutrientBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey[800],
        ),
      ),
    );
  }
}