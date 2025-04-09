import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/viewmodels/onboarding_viewmodel.dart';
import 'package:fitmate/screens/register_screens/workout-days_question.dart';

class GoalSelectionScreen extends StatelessWidget {
  final OnboardingViewModel viewModel;

  const GoalSelectionScreen({
    Key? key, 
    required this.viewModel
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: _GoalSelectionContent(),
    );
  }
}

class _GoalSelectionContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0e0f16),
          body: SingleChildScrollView(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFFFFF)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Step 5 of 6',
                      style: TextStyle(
                          color: const Color(0xFFFFFFFF),
                          fontFamily: GoogleFonts.montserrat().fontFamily,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'What is your goal?',
                      style: GoogleFonts.bebasNeue(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Goal Options
                    _goalOption(context, 'Weight Loss', Icons.monitor_weight_outlined, viewModel),
                    const SizedBox(height: 20),
                    _goalOption(context, 'Gain Muscle', Icons.fitness_center_outlined, viewModel),
                    const SizedBox(height: 20),
                    _goalOption(context, 'Improve Fitness', Icons.health_and_safety_outlined, viewModel),
                    const SizedBox(height: 40),
                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkoutDaysQuestionScreen(viewModel: viewModel),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD2EB50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15.0),
                        ),
                        child: Text(
                          'Next',
                          style: GoogleFonts.bebasNeue(
                            color: Colors.black,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _goalOption(BuildContext context, String goal, IconData icon, OnboardingViewModel viewModel) {
    bool isSelected = viewModel.goal == goal;

    return InkWell(
      onTap: () => viewModel.setGoal(goal),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD2EB50) : Colors.transparent,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: const Color(0xFFD2EB50),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : const Color(0xFFD2EB50),
              size: 40,
            ),
            const SizedBox(width: 10),
            Text(
              goal,
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFFD2EB50),
                fontFamily: GoogleFonts.montserrat().fontFamily,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}