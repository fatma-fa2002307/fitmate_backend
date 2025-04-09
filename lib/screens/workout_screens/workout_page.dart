import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/screens/workout_screens/todays_workout_screen.dart';
import 'package:fitmate/services/workout_service.dart';
import 'package:fitmate/viewmodels/workout_viewmodel.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:fitmate/widgets/workout_history_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Color scheme
const Color primaryColor = Color(0xFFD2EB50);
const Color accentColor = Color(0xFFE7FC00);
const Color backgroundColor = Color(0xFFFAFAFA);
const Color cardBgColor = Color(0xFFFFFFFF);
const Color textPrimaryColor = Color(0xFF2D3142);
const Color textSecondaryColor = Color(0xFF559125);


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
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'WORKOUT',
          style: GoogleFonts.bebasNeue(
            color: textPrimaryColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: cardBgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimaryColor),
        automaticallyImplyLeading: false,
        actions: [
          if (viewModel.hasError)
            IconButton(
              icon: const Icon(Icons.refresh, size: 24),
              onPressed: () => viewModel.init(),
              tooltip: 'Refresh',
            ),
        ],
      ),
      body: viewModel.isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          strokeWidth: 3,
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(Icons.refresh_rounded, size: 50, color: textSecondaryColor),
            ),
            const SizedBox(height: 32),
            Text(
              viewModel.errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunitoSans(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: textPrimaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () => viewModel.init(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.nunitoSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last Workout',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Completion',
                    value: lastWorkout != null
                        ? '${lastWorkout.completedExercises}/${lastWorkout.totalExercises}'
                        : '0/0',
                    icon: Icons.task_alt,
                    progress: completionRatio,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Duration',
                    value: duration,
                    icon: Icons.timer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Your Workout',
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildWorkoutButton(
              viewModel,
              context,
              icon: Icons.fitness_center,
              text: "Today's Workout",
              description: "View your personalized workout plan",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FreshTodaysWorkoutScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildWorkoutButton(
              viewModel,
              context,
              icon: Icons.auto_awesome,
              text: "FitMate AI",
              description: "Get AI-powered workout recommendations",
              isRichText: true,
              onTap: () {
                // Future implementation
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Workout History',
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: textPrimaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7FC00).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total: ${viewModel.workoutHistory.length}',
                    style: GoogleFonts.albertSans(
                      fontSize: 14,
                      color: textSecondaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const WorkoutHistoryWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    double? progress,
  }) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunitoSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textSecondaryColor,
                  ),
                ),
                Icon(
                  icon,
                  color: primaryColor,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: textPrimaryColor,
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  if (progress > 0)
                    FractionallySizedBox(
                      widthFactor: progress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accentColor, primaryColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                ],
              ),
            ],
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
        required String description,
        required VoidCallback onTap,
        bool isRichText = false,
      }) {
    return GestureDetector(
      onTap: viewModel.isLoading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isRichText)
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: text.split(' ')[0] + ' ',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: textPrimaryColor,
                            ),
                          ),
                          TextSpan(
                            text: text.split(' ')[1],
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      text,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textPrimaryColor,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.nunitoSans(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}