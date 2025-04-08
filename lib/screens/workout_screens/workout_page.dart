import 'package:fitmate/models/workout.dart';
import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/screens/workout_screens/todays_workout_screen.dart';
import 'package:fitmate/services/workout_service.dart';
import 'package:fitmate/viewmodels/workout_viewmodel.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WorkoutViewModel(
        repository: context.read<WorkoutRepository>(),
        workoutService: context.read<WorkoutService>(),
      )..init(),
      child: const _WorkoutPageContent(),
    );
  }
}

class _WorkoutPageContent extends StatefulWidget {
  const _WorkoutPageContent({Key? key}) : super(key: key);

  @override
  State<_WorkoutPageContent> createState() => _WorkoutPageContentState();
}

class _WorkoutPageContentState extends State<_WorkoutPageContent> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WorkoutViewModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'WORKOUT',
          style: GoogleFonts.bebasNeue(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        automaticallyImplyLeading: false,
        actions: [
          if (viewModel.hasError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => viewModel.init(),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: viewModel.isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
              ),
            )
          : viewModel.hasError
              ? _buildErrorView(viewModel)
              : _buildMainContent(viewModel),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
  
  Widget _buildErrorView(WorkoutViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.refresh_rounded, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              viewModel.errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => viewModel.init(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2EB50),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(WorkoutViewModel viewModel) {
    final completionRatio = viewModel.completionRatio;
    final duration = viewModel.duration;
    final lastWorkout = viewModel.lastWorkout;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Last Workout',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 150,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Completion',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              lastWorkout != null
                                ? '${lastWorkout.completedExercises}/${lastWorkout.totalExercises}'
                                : '0/0',
                              style: GoogleFonts.albertSans(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                if (completionRatio > 0) // Only show if there's progress
                                  FractionallySizedBox(
                                    widthFactor: completionRatio,
                                    child: Container(
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE7FC00),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 150,
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Duration',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              duration,
                              style: GoogleFonts.albertSans(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              Icons.timer,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildWorkoutButton(
              viewModel,
              context,
              icon: Icons.fitness_center,
              text: "View Suggested Workout",
              onTap: () async {
                final readyForWorkout = await viewModel.navigateToTodaysWorkout();
                if (readyForWorkout && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FreshTodaysWorkoutScreen()),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            _buildWorkoutButton(
              viewModel, 
              context,
              icon: Icons.auto_awesome,
              text: "FitMate AI",
              isRichText: true,
              onTap: () {
                // Future implementation
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildWorkoutButton(
    WorkoutViewModel viewModel, 
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool isRichText = false,
  }) {
    return GestureDetector(
      onTap: viewModel.isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(
              icon,
              color: Colors.lightGreen,
              size: 20,
            ),
            if (isRichText)
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: text.split(' ')[0] + ' ',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: text.split(' ')[1],
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.lightGreen,
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                text,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            const Icon(Icons.arrow_forward, color: Colors.black),
          ],
        ),
      ),
    );
  }
}