import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/services/workout_service.dart';
import 'package:fitmate/viewmodels/workout_completion_viewmodel.dart';
import 'package:fitmate/screens/login_screens/home_page.dart';

class WorkoutCompletionScreen extends StatelessWidget {
  final int completedExercises;
  final int totalExercises;
  final String duration;
  final String category;

  const WorkoutCompletionScreen({
    Key? key,
    required this.completedExercises,
    required this.totalExercises,
    required this.duration,
    required this.category,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WorkoutCompletionViewModel(
        repository: context.read<WorkoutRepository>(),
        workoutService: context.read<WorkoutService>(),
        completedExercises: completedExercises,
        totalExercises: totalExercises,
        duration: duration,
        category: category,
      )..init(),
      child: _WorkoutCompletionScreenContent(),
    );
  }
}

class _WorkoutCompletionScreenContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WorkoutCompletionViewModel>(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Workout Stats',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completion',
                          style: GoogleFonts.dmSans(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${viewModel.completedExercises}/${viewModel.totalExercises}',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1.5),
                            color: Colors.grey[800],
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: viewModel.completionRatio,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1.5),
                                color: const Color(0xFFD2EB50),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duration',
                          style: GoogleFonts.dmSans(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              viewModel.duration,
                              style: GoogleFonts.dmSans(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (viewModel.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Note: ${viewModel.errorMessage}',
                    style: GoogleFonts.dmSans(
                      color: Colors.red[300],
                      fontSize: 14,
                    ),
                  ),
                ),
              const Spacer(),
              if (viewModel.isLoading)
                Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                  ),
                )
              else
                ElevatedButton(
                  onPressed: () {
                    // Use pushAndRemoveUntil to ensure complete navigation stack reset
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => HomePage()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD2EB50),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                  child: Text(
                    'DONE',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}