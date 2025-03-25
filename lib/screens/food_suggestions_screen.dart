import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/models/food_suggestion.dart';
import 'package:fitmate/services/food_suggestion_service.dart';
import 'package:fitmate/widgets/food_suggestion_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitmate/repositories/food_repository.dart';

class FoodSuggestionsScreen extends StatefulWidget {
  const FoodSuggestionsScreen({Key? key}) : super(key: key);

  @override
  State<FoodSuggestionsScreen> createState() => _FoodSuggestionsScreenState();
}

class _FoodSuggestionsScreenState extends State<FoodSuggestionsScreen> with SingleTickerProviderStateMixin {
  final FoodSuggestionService _foodSuggestionService = FoodSuggestionService();
  final FoodRepository _foodRepository = FoodRepository();
  late TabController _tabController;
  
  Map<SuggestionMilestone, List<FoodSuggestion>> _suggestionsByMilestone = {};
  bool _isLoading = true;
  double _totalCalories = 2000; // Default value
  double _consumedCalories = 0;
  String _userGoal = '';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: SuggestionMilestone.values.length, vsync: this);
    _loadUserData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  /// Load user data and nutrition information
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Load user daily macros
      final macros = await _foodRepository.getUserMacros();
      
      // Load user goal
      final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      // Load today's food logs to calculate consumed calories
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      
      final foodLogs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('foodLogs')
          .where('date', isGreaterThanOrEqualTo: today)
          .where('date', isLessThan: tomorrow)
          .get();
      
      double totalCaloriesConsumed = 0;
      for (var doc in foodLogs.docs) {
        totalCaloriesConsumed += doc['calories'] ?? 0;
      }
      
      if (mounted) {
        setState(() {
          _totalCalories = macros['calories'] ?? 2000;
          _consumedCalories = totalCaloriesConsumed;
          _userGoal = userData.data()?['goal'] ?? '';
        });
      }
      
      // Load suggestions for all milestones
      await _loadAllSuggestions();
      
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }
  
  /// Load food suggestions for all milestones
  Future<void> _loadAllSuggestions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Calculate current milestone based on consumed calories
      final percentage = _consumedCalories / _totalCalories;
      final currentMilestone = SuggestionMilestoneExtension.fromPercentage(percentage);
      
      // Temporary map to store suggestions
      final suggestionMap = <SuggestionMilestone, List<FoodSuggestion>>{};
      
      // First load current milestone suggestions
      final currentSuggestions = await _foodSuggestionService.getSuggestionsForCurrentMilestone(
        totalCalories: _totalCalories,
        consumedCalories: _consumedCalories,
        goal: _userGoal,
      );
      
      suggestionMap[currentMilestone] = currentSuggestions;
      
      // Then try to load cached suggestions for other milestones
      for (final milestone in SuggestionMilestone.values) {
        if (milestone == currentMilestone) continue; // Skip current milestone
        
        try {
          // Simulate different calorie consumption for each milestone
          final simulatedPercentage = switch (milestone) {
            SuggestionMilestone.START => 0.05,
            SuggestionMilestone.QUARTER => 0.3,
            SuggestionMilestone.HALF => 0.55,
            SuggestionMilestone.THREE_QUARTERS => 0.8,
            SuggestionMilestone.ALMOST_COMPLETE => 0.95,
          };
          
          final simulatedCalories = _totalCalories * simulatedPercentage;
          
          // Try to get cached suggestions or generate new ones
          final suggestions = await _foodSuggestionService.getSuggestionsForCurrentMilestone(
            totalCalories: _totalCalories,
            consumedCalories: simulatedCalories,
            goal: _userGoal,
          );
          
          suggestionMap[milestone] = suggestions;
        } catch (e) {
          // If loading fails for a milestone, just skip it
          print('Error loading suggestions for milestone ${milestone.name}: $e');
          suggestionMap[milestone] = [];
        }
      }
      
      if (mounted) {
        setState(() {
          _suggestionsByMilestone = suggestionMap;
          _isLoading = false;
          
          // Move tab to current milestone
          _tabController.animateTo(currentMilestone.index);
        });
      }
    } catch (e) {
      print('Error loading all suggestions: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading suggestions: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FOOD SUGGESTIONS',
          style: GoogleFonts.bebasNeue(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFD2EB50),
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: const Color(0xFFD2EB50),
          tabs: SuggestionMilestone.values.map((milestone) {
            return Tab(
              text: milestone.displayName,
            );
          }).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: SuggestionMilestone.values.map((milestone) {
                final suggestions = _suggestionsByMilestone[milestone] ?? [];
                
                if (suggestions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No suggestions available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadAllSuggestions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD2EB50),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: _loadAllSuggestions,
                  color: const Color(0xFFD2EB50),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with milestone description
                        Text(
                          'Suggestions for ${milestone.displayName}',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        // Milestone description
                        _buildMilestoneDescription(milestone),
                        
                        const SizedBox(height: 16),
                        
                        // Suggestions list
                        Expanded(
                          child: ListView.builder(
                            itemCount: suggestions.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: FoodSuggestionCard(
                                  suggestion: suggestions[index],
                                  // removed an invalid parameter (isDetailed) from here
                                  //
                                  onLike: () {
                                    setState(() {
                                      // Remove from list if disliked to give visual feedback
                                      suggestions.removeAt(index);
                                    });
                                  },
                                  onDislike: () {
                                    setState(() {
                                      // Remove from list if disliked to give visual feedback
                                      suggestions.removeAt(index);
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadAllSuggestions,
        backgroundColor: const Color(0xFFD2EB50),
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  /// Build milestone description with calorie guideline
  Widget _buildMilestoneDescription(SuggestionMilestone milestone) {
    // Calorie percentage for each milestone
    final caloriePercentage = switch (milestone) {
      SuggestionMilestone.START => 0.3, // 30% of daily calories
      SuggestionMilestone.QUARTER => 0.25, // 25% of daily calories
      SuggestionMilestone.HALF => 0.35, // 35% of daily calories
      SuggestionMilestone.THREE_QUARTERS => 0.2, // 20% of daily calories
      SuggestionMilestone.ALMOST_COMPLETE => 0.1, // 10% of daily calories
    };
    
    // Description for each milestone
    final description = switch (milestone) {
      SuggestionMilestone.START => 'Breakfast options to start your day',
      SuggestionMilestone.QUARTER => 'Mid-morning snack to keep you going',
      SuggestionMilestone.HALF => 'Lunch options for a nutritious mid-day meal',
      SuggestionMilestone.THREE_QUARTERS => 'Dinner ideas for the evening',
      SuggestionMilestone.ALMOST_COMPLETE => 'Light evening snacks to complete your day',
    };
    
    // Calculate calorie target for this milestone
    final calorieTarget = (_totalCalories * caloriePercentage).round();
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Target: ~$calorieTarget calories',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}