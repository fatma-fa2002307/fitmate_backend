import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/viewmodels/onboarding_viewmodel.dart';
import 'package:fitmate/screens/register_screens/goal_question.dart';

class GenderQuestionPage extends StatelessWidget {
  final OnboardingViewModel viewModel;

  const GenderQuestionPage({
    Key? key, 
    required this.viewModel
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: _GenderQuestionContent(),
    );
  }
}

class _GenderQuestionContent extends StatelessWidget {
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
                      onPressed: () {
                        Navigator.pop(context); // Navigate back to the previous page
                      },
                    ),
                    Text(
                      'Step 4 of 6',
                      style: TextStyle(
                          color: const Color(0xFFFFFFFF),
                          fontFamily: GoogleFonts.montserrat().fontFamily,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'What is your gender?',
                      style: GoogleFonts.bebasNeue(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Gender Selection
                    GenderOption(
                      label: 'Male',
                      icon: Icons.male,
                      isSelected: viewModel.gender == 'Male',
                      onTap: () => viewModel.setGender('Male'),
                    ),
                    const SizedBox(height: 20),
                    GenderOption(
                      label: 'Female',
                      icon: Icons.female,
                      isSelected: viewModel.gender == 'Female',
                      onTap: () => viewModel.setGender('Female'),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GoalSelectionScreen(viewModel: viewModel),
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
}

// A custom widget for the gender options with icons
class GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Function() onTap;

  const GenderOption({
    Key? key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              label,
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