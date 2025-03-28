import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fitmate/viewmodels/nutrition_viewmodel.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:fitmate/widgets/food_suggestion_card.dart';
import 'package:fitmate/screens/logFoodManually.dart';
import 'advanced_circular_indicator.dart';
import 'animated_macro_wheel.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({Key? key}) : super(key: key);

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;
  late NutritionViewModel _viewModel;
  bool _isAnimating = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Initialize ViewModel
    _viewModel = NutritionViewModel();
    // Add listener to trigger animations when data changes
    _viewModel.addListener(_onViewModelChanged);
    _initializeData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    // This method will be called whenever the viewModel notifies its listeners
    // If we're not already animating, start a new animation
    if (!_animationController.isAnimating) {
      _animationController.reset();
      setState(() => _isAnimating = true);
      _animationController.forward();
    }
  }

  Future<void> _initializeData() async {
    setState(() => _isAnimating = false);
    await _viewModel.init();

    // Reset and start animation after data is loaded
    _animationController.reset();
    setState(() => _isAnimating = true);
    _animationController.forward();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<NutritionViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'NUTRITION',
                style: GoogleFonts.bebasNeue(color: Colors.black),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: viewModel.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _initializeData,
                    color: const Color(0xFFD2EB50),
                    child: _buildMainContent(viewModel),
                  ),
            floatingActionButton:
                viewModel.isToday ? _buildFloatingActionButton(context) : null,
            bottomNavigationBar: BottomNavBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(NutritionViewModel viewModel) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date selector
          _buildDateSelector(viewModel),
          // Main macros summary
          _buildMacrosSummary(viewModel),
          // Food Suggestion section
          if (viewModel.isToday) _buildFoodSuggestions(viewModel),
          // Today's Food header
          _buildFoodHeader(),
          // Food logs list
          _buildFoodLogs(viewModel),
          // Add space at the bottom
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDateSelector(NutritionViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: viewModel.previousDay,
          ),
          Column(
            children: [
              Text(
                viewModel.formattedDate,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${viewModel.totalCalories.toInt()} / ${viewModel.dailyMacros['calories']?.toInt() ?? 2000} calories',
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: viewModel.isToday ? null : viewModel.nextDay,
            color: viewModel.isToday ? Colors.grey[400] : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMacrosSummary(NutritionViewModel viewModel) {
    return Container(
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
                    SizedBox(
                      height: 120,
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isAnimating ? 1.0 + (_animationController.value * 0.1 * (1 - _animationController.value) * 2) : 1.0,
                              child: AdvancedCircularProgressIndicator(
                                progress: viewModel.caloriePercentage,
                                radius: 60.0,
                                lineWidth: 12.0,
                                progressColor: const Color(0xFFD2EB50),
                                backgroundColor: Colors.grey[200]!,
                                animate: _isAnimating,
                                animationDuration: const Duration(milliseconds: 1500),
                                allowOverflow: true,
                                center: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      viewModel.totalCalories.toInt().toString(),
                                      style: GoogleFonts.montserrat(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: _isAnimating ? Color.lerp(Colors.black, const Color(0xFFD2EB50), _animationController.value * (1 - _animationController.value) * 4) : Colors.black,
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
                              ),
                            );
                          },
                        ),
                      ),
                    ),
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
                        AnimatedMacroWheel(
                          label: 'Protein',
                          current: viewModel.totalProtein.toInt(),
                          target:
                              viewModel.dailyMacros['protein']?.toInt() ?? 150,
                          percentage: viewModel.proteinPercentage,
                          color: Colors.red[400]!,
                          animate: _isAnimating,
                        ),
                        AnimatedMacroWheel(
                          label: 'Carbs',
                          current: viewModel.totalCarbs.toInt(),
                          target:
                              viewModel.dailyMacros['carbs']?.toInt() ?? 225,
                          percentage: viewModel.carbsPercentage,
                          color: Colors.blue[400]!,
                          animate: _isAnimating,
                        ),
                        AnimatedMacroWheel(
                          label: 'Fat',
                          current: viewModel.totalFat.toInt(),
                          target: viewModel.dailyMacros['fat']?.toInt() ?? 65,
                          percentage: viewModel.fatPercentage,
                          color: Colors.amber[700]!,
                          animate: _isAnimating,
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
    );
  }

  Widget _buildFoodSuggestions(NutritionViewModel viewModel) {
    return Container(
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
            ],
          ),
          const SizedBox(height: 8),

          // Suggestion content
          if (viewModel.suggestionsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                ),
              ),
            )
          else if (viewModel.suggestionsError.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      viewModel.suggestionsError,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: viewModel.isRetrying 
                        ? null 
                        : () => viewModel.retryLoadFoodSuggestions(),
                      icon: viewModel.isRetrying 
                        ? Container(
                            width: 20,
                            height: 20,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.refresh),
                      label: Text(viewModel.isRetrying ? 'Retrying...' : 'Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD2EB50),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (viewModel.suggestions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No suggestions available',
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: FoodSuggestionCard(
                suggestions: viewModel.suggestions,
                onLike: () => viewModel.handleFoodPreference(true),
                onDislike: () => viewModel.handleFoodPreference(false),
                initialIndex: viewModel.currentSuggestionIndex,
                milestone: viewModel.currentMilestone,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodHeader() {
    return Padding(
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
        ],
      ),
    );
  }

  Widget _buildFoodLogs(NutritionViewModel viewModel) {
    if (viewModel.todaysFoodLogs.isEmpty) {
      return _buildEmptyFoodLog(viewModel);
    } else {
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: viewModel.todaysFoodLogs.length,
        itemBuilder: (context, index) {
          return _buildFoodLogItem(viewModel, index);
        },
      );
    }
  }

  Widget _buildEmptyFoodLog(NutritionViewModel viewModel) {
    return Container(
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
            if (viewModel.isToday)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: () => _navigateToAddFood(context),
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
    );
  }

  Widget _buildFoodLogItem(NutritionViewModel viewModel, int index) {
    final food = viewModel.todaysFoodLogs[index];
    final DateTime foodTime = (food['date'] as Timestamp).toDate();

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
                _buildNutrientBadge('${food['calories']?.toInt() ?? 0} cal',
                    Colors.orange[100]!),
                const SizedBox(width: 8),
                _buildNutrientBadge(
                    'P: ${food['protein']?.toInt() ?? 0}g', Colors.red[100]!),
                const SizedBox(width: 8),
                _buildNutrientBadge(
                    'C: ${food['carbs']?.toInt() ?? 0}g', Colors.blue[100]!),
                const SizedBox(width: 8),
                _buildNutrientBadge(
                    'F: ${food['fat']?.toInt() ?? 0}g', Colors.amber[100]!),
              ],
            ),
          ],
        ),
        trailing: viewModel.isToday
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.grey[600],
                onPressed: () => viewModel.deleteFood(food['id']),
              )
            : null,
      ),
    );
  }

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

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _navigateToAddFood(context),
      backgroundColor: const Color(0xFFD2EB50),
      child: const Icon(Icons.add),
    );
  }

  void _navigateToAddFood(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LogFoodManuallyScreen(),
      ),
    ).then((_) => _initializeData());
  }
}