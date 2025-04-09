import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/viewmodels/onboarding_viewmodel.dart';
import 'package:fitmate/screens/register_screens/height_question.dart';

class WeightQuestionPage extends StatelessWidget {
  final OnboardingViewModel viewModel;

  const WeightQuestionPage({
    Key? key, 
    required this.viewModel
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: _WeightQuestionContent(),
    );
  }
}

class _WeightQuestionContent extends StatefulWidget {
  @override
  _WeightQuestionContentState createState() => _WeightQuestionContentState();
}

class _WeightQuestionContentState extends State<_WeightQuestionContent> {
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<OnboardingViewModel>(context, listen: false);
    _weightController = TextEditingController(text: viewModel.weight.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingViewModel>(
      builder: (context, viewModel, _) {
        return Scaffold(
          backgroundColor: const Color(0xFF0e0f16),
          body: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Step 2 of 6',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What is your weight?',
                    style: GoogleFonts.bebasNeue(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Unit selection buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _unitButton('LBS', !viewModel.isKg, () => _toggleUnit(viewModel, false)),
                      _unitButton('KG', viewModel.isKg, () => _toggleUnit(viewModel, true)),
                    ],
                  ),
                  const SizedBox(height: 40),
                  // Weight Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _weightController,
                          onChanged: (value) {
                            double? newWeight = double.tryParse(value);
                            if (newWeight != null) {
                              viewModel.setWeight(newWeight);
                            }
                          },
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HeightQuestionPage(viewModel: viewModel),
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
        );
      },
    );
  }
  
  void _toggleUnit(OnboardingViewModel viewModel, bool isKg) {
    viewModel.toggleWeightUnit(isKg);
    _weightController.text = viewModel.weight.toStringAsFixed(0);
  }

  Widget _unitButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD2EB50) : Colors.transparent,
          border: Border.all(color: const Color(0xFFD2EB50), width: 2),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : const Color(0xFFD2EB50),
            fontSize: 20,
          ),
        ),
      ),
    );
  }
}