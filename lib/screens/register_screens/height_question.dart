import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/viewmodels/onboarding_viewmodel.dart';
import 'package:fitmate/screens/register_screens/gender_question.dart';

class HeightQuestionPage extends StatelessWidget {
  final OnboardingViewModel viewModel;

  const HeightQuestionPage({
    Key? key, 
    required this.viewModel
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: viewModel,
      child: _HeightQuestionContent(),
    );
  }
}

class _HeightQuestionContent extends StatefulWidget {
  @override
  _HeightQuestionContentState createState() => _HeightQuestionContentState();
}

class _HeightQuestionContentState extends State<_HeightQuestionContent> {
  late TextEditingController _heightController;

  @override
  void initState() {
    super.initState();
    _updateControllerFromViewModel();
  }

  void _updateControllerFromViewModel() {
    final viewModel = Provider.of<OnboardingViewModel>(context, listen: false);
    if (viewModel.isCm) {
      _heightController = TextEditingController(text: viewModel.height.toStringAsFixed(0));
    } else {
      // Convert to feet'inches format
      int feet = (viewModel.height).floor();
      int inches = ((viewModel.height - feet) * 12).round();
      _heightController = TextEditingController(text: '$feet\'$inches');
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
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
                    icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFFFFF)),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  Text(
                    'Step 3 of 6',
                    style: TextStyle(
                      color: const Color(0xFFFFFFFF),
                      fontFamily: GoogleFonts.montserrat().fontFamily,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What is your height?',
                    style: GoogleFonts.bebasNeue(
                      color: const Color(0xFFFFFFFF),
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _unitButton('FEET', !viewModel.isCm, () => _toggleUnit(viewModel, false)),
                      _unitButton('CM', viewModel.isCm, () => _toggleUnit(viewModel, true)),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightController,
                          onChanged: _updateHeight,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          keyboardType: viewModel.isCm ? TextInputType.number : TextInputType.text,
                          decoration: InputDecoration(
                            helperText: viewModel.isCm ? null : 'Enter as feet\'inches (e.g. 5\'10)',
                            helperStyle: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Validate input
                        if (_validateInput(viewModel)) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GenderQuestionPage(viewModel: viewModel),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid height.'))
                          );
                        }
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
  
  void _toggleUnit(OnboardingViewModel viewModel, bool isCm) {
    viewModel.toggleHeightUnit(isCm);
    
    // Update controller with new value
    if (isCm) {
      _heightController.text = viewModel.height.toStringAsFixed(0);
    } else {
      int feet = (viewModel.height).floor();
      int inches = ((viewModel.height - feet) * 12).round();
      _heightController.text = '$feet\'$inches';
    }
  }
  
  void _updateHeight(String value) {
    final viewModel = Provider.of<OnboardingViewModel>(context, listen: false);
    
    if (viewModel.isCm) {
      double? height = double.tryParse(value);
      if (height != null) {
        viewModel.setHeight(height);
      }
    } else {
      // Parse feet'inches format
      List<String> parts = value.split("'");
      if (parts.length == 2) {
        int? feet = int.tryParse(parts[0]);
        int? inches = int.tryParse(parts[1]);
        if (feet != null && inches != null) {
          // Convert to decimal feet
          double height = feet + (inches / 12);
          viewModel.setHeight(height);
        }
      }
    }
  }
  
  bool _validateInput(OnboardingViewModel viewModel) {
    if (viewModel.isCm) {
      // Simple validation for cm
      return double.tryParse(_heightController.text) != null;
    } else {
      // Validate feet and inches format
      List<String> parts = _heightController.text.split("'");
      if (parts.length != 2) return false;
      int? feet = int.tryParse(parts[0]);
      int? inches = int.tryParse(parts[1]);
      return feet != null && inches != null;
    }
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