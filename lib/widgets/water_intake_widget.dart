import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class WaterIntakeGlassWidget extends StatefulWidget {
  const WaterIntakeGlassWidget({super.key});

  @override
  State<WaterIntakeGlassWidget> createState() => _WaterIntakeGlassWidgetState();
}

class _WaterIntakeGlassWidgetState extends State<WaterIntakeGlassWidget>
    with SingleTickerProviderStateMixin {
  int _waterIntake = 0; // in glasses
  int _dailyGoal = 8; // in glasses

  // Clean monochromatic color scheme
  final Color _primaryBlue = const Color(0xFF7EB5F5); // Main blue
  final Color _lightBlue = const Color(0xFFBFDCFF); // Light blue
  final Color _textColor = const Color(0xFF454545); // Dark text
  final Color _subtleGray = const Color(0xFFF5F7FA); // Background gray

  late AnimationController _animationController;
  late Animation<double> _fillAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fillAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _waveAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    )..addListener(() {
      if (_animationController.status == AnimationStatus.completed) {
        _animationController.repeat(min: 0.95, max: 1.0, reverse: true);
      }
    });

    _loadPreferences();
    loadWaterIntake().then((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPreferences() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot prefsDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('waterIntake')
          .get();

      if (prefsDoc.exists) {
        final data = prefsDoc.data() as Map<String, dynamic>;
        setState(() {
          _dailyGoal = data['dailyGoal'] ?? 8;
        });
      }
    }
  }

  Future<void> _savePreferences() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('preferences')
          .doc('waterIntake')
          .set({
        'dailyGoal': _dailyGoal,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> loadWaterIntake() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Get today's date
      DateTime now = DateTime.now();
      String dateKey = DateFormat('yyyy-MM-dd').format(now);

      DocumentSnapshot waterDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('waterIntake')
          .doc(dateKey)
          .get();

      if (waterDoc.exists) {
        setState(() {
          _waterIntake = (waterDoc.data() as Map<String, dynamic>)['glasses'] ?? 0;
        });
      }
    }
  }

  Future<void> updateWaterIntake(int change) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final newIntake = (_waterIntake + change).clamp(0, 20); // Limit to reasonable amount

      if (newIntake != _waterIntake) {
        setState(() {
          _waterIntake = newIntake;
        });

        // Reset and restart the animation
        _animationController.reset();
        _animationController.forward();

        // Save to Firestore
        DateTime now = DateTime.now();
        String dateKey = DateFormat('yyyy-MM-dd').format(now);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('waterIntake')
            .doc(dateKey)
            .set({
          'glasses': _waterIntake,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  void _showCustomizationSheet() {
    final TextEditingController goalController = TextEditingController(text: _dailyGoal.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Set Daily Goal',
                style: GoogleFonts.bebasNeue(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _primaryBlue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: goalController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.bebasNeue(),
                decoration: InputDecoration(
                  hintText: 'Number of glasses',
                  suffixText: 'glasses',
                  suffixStyle: GoogleFonts.bebasNeue(fontWeight: FontWeight.w500),
                  filled: true,
                  fillColor: _subtleGray,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _primaryBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final newGoal = int.tryParse(goalController.text) ?? 8;

                  if (newGoal > 0) {
                    setState(() {
                      _dailyGoal = newGoal;
                    });
                    _savePreferences();
                  }

                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _waterIntake / _dailyGoal;
    final cappedProgress = progress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showCustomizationSheet,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Left side - Small glass
                Container(
                  width: 40,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Glass container
                      Container(
                        height: 50,
                        width: 32,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(10),
                            top: Radius.circular(2),
                          ),
                          color: Colors.transparent,
                          border: Border.all(
                            color: _primaryBlue.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                      ),
                      // Animated water fill
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return ClipPath(
                            clipper: SimpleWaveClipper(
                              progress: cappedProgress * _fillAnimation.value,
                              waveHeight: 2.0,
                              wavePhase: _waveAnimation.value,
                            ),
                            child: Container(
                              height: 50,
                              width: 32,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(8),
                                  top: Radius.circular(1),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _lightBlue,
                                    _primaryBlue,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Middle - Progress info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Glass counter and goal
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _subtleGray,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop_rounded,
                              color: _primaryBlue,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_waterIntake',
                              style:GoogleFonts.bebasNeue(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _primaryBlue,
                              ),
                            ),
                            Text(
                              '/$_dailyGoal glasses',
                              style: GoogleFonts.bebasNeue(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Simple progress bar
                      Container(
                        height: 8,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _subtleGray,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: cappedProgress,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _primaryBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Right side - Add/Remove controls
                Container(
                  width: 72,
                  child: Row(
                    children: [
                      // Minus button
                      Expanded(
                        child: GestureDetector(
                          onTap: _waterIntake > 0 ? () => updateWaterIntake(-1) : null,
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: _waterIntake > 0
                                  ? _primaryBlue.withOpacity(0.1)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 16,
                              color: _waterIntake > 0 ? _primaryBlue : Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Plus button
                      Expanded(
                        child: GestureDetector(
                          onTap: () => updateWaterIntake(1),
                          child: Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: _primaryBlue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Simplified wave clipper
class SimpleWaveClipper extends CustomClipper<Path> {
  final double progress;
  final double waveHeight;
  final double wavePhase;

  SimpleWaveClipper({required this.progress, required this.waveHeight, required this.wavePhase});

  @override
  Path getClip(Size size) {
    final path = Path();
    final height = size.height;
    final width = size.width;

    // Calculate the water level height
    final waterHeight = height * progress;

    if (waterHeight <= 0) {
      return path;
    }

    path.lineTo(0, height - waterHeight);

    // Simple wave effect
    for (int i = 0; i <= width; i++) {
      final x = i.toDouble();
      final y = height - waterHeight + sin((x / width * 3 * pi) + wavePhase) * waveHeight;
      path.lineTo(x, y);
    }

    path.lineTo(width, height - waterHeight);
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}