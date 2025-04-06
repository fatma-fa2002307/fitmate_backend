import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class UserLevelWidget extends StatefulWidget {
  const UserLevelWidget({Key? key}) : super(key: key);

  @override
  State<UserLevelWidget> createState() => _UserLevelWidgetState();
}

class _UserLevelWidgetState extends State<UserLevelWidget> with SingleTickerProviderStateMixin {
  // User fitness data
  String _fitnessLevel = 'Beginner';
  int _fitnessSubLevel = 1;
  int _workoutsCompleted = 0;
  int _workoutsUntilNextLevel = 20;
  DateTime? _lastUpdated;
  bool _isLoading = true;
  bool _showAnimation = false;

  // Animation controller
  late AnimationController _levelAnimationController;

  @override
  void initState() {
    super.initState();
    _levelAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _loadUserData();
  }

  @override
  void dispose() {
    _levelAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load user progress document
        DocumentSnapshot userProgress = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('userProgress')
            .doc('progress')
            .get();

        if (!userProgress.exists) {
          // Create progress document if it doesn't exist
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('userProgress')
              .doc('progress')
              .set({
            'fitnessLevel': 'Beginner',
            'fitnessSubLevel': 1,
            'workoutsCompleted': 0,
            'workoutsUntilNextLevel': 20,
            'lastUpdated': FieldValue.serverTimestamp(),
          });

          // Reload after creating
          userProgress = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('userProgress')
              .doc('progress')
              .get();
        }

        if (mounted) {
          setState(() {
            final progressData = userProgress.data() as Map<String, dynamic>;
            _fitnessLevel = progressData['fitnessLevel'] ?? 'Beginner';
            _fitnessSubLevel = progressData['fitnessSubLevel'] ?? 1;
            _workoutsCompleted = progressData['workoutsCompleted'] ?? 0;
            _workoutsUntilNextLevel = progressData['workoutsUntilNextLevel'] ?? 20;
            _lastUpdated = progressData['lastUpdated']?.toDate();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  String _getMotivationalMessage() {
    double progress = _workoutsCompleted / _workoutsUntilNextLevel;

    if (progress < 0.25) {
      return "Keep going! Every workout counts.";
    } else if (progress < 0.5) {
      return "You're making progress! Stay consistent.";
    } else if (progress < 0.75) {
      return "You're over halfway there!";
    } else if (progress < 1) {
      return "Almost to the next level! Push through!";
    } else {
      return "Congratulations on reaching your next level!";
    }
  }

  void _playLevelUpAnimation() {
    setState(() {
      _showAnimation = true;
    });
    _levelAnimationController.forward().then((_) {
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showAnimation = false;
          });
        }
      });
    });
  }

  Widget _buildCelebrationAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: 1),
          duration: Duration(milliseconds: 800),
          builder: (context, double value, child) {
            return Transform.scale(
              scale: 1 + (value * 0.3),
              child: Opacity(
                opacity: 1 - (value * 0.5),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getLevelPrimaryColor().withOpacity(0.5),
                  ),
                ),
              ),
            );
          },
        ),
        Icon(
          Icons.emoji_events,
          size: 42,
          color: Colors.amber,
        ),
      ],
    );
  }

  // Get primary color based on fitness level
  // Get primary color based on fitness level
  Color _getLevelPrimaryColor() {
    switch (_fitnessLevel.toLowerCase()) {
      case 'beginner':
        return Color(0xFFD2EB50); // Vibrant Lime Green
      case 'intermediate':
        return Color(0xFF83CFDF); // Bright Teal
      case 'advanced':
        return Color(0xFFF0938C); // Coral Pink
      case 'elite':
        return Color(0xFFFFBE3D); // Golden Yellow
      default:
        return Color(0xFFD2EB50); // Default Lime Green
    }
  }

// Get secondary color based on fitness level
  Color _getLevelSecondaryColor() {
    switch (_fitnessLevel.toLowerCase()) {
      case 'beginner':
        return Color(0xFFB8D143); // Deeper Lime Green
      case 'intermediate':
        return Color(0xFF69B5C3); // Deeper Teal
      case 'advanced':
        return Color(0xFFD87974); // Deeper Coral
      case 'elite':
        return Color(0xFFE5AA36); // Deeper Gold
      default:
        return Color(0xFFB8D143); // Default Deeper Lime
    }
  }

  // Get icon based on fitness level
  IconData _getLevelIcon() {
    switch (_fitnessLevel.toLowerCase()) {
      case 'beginner':
        return Icons.fitness_center;
      case 'intermediate':
        return Icons.self_improvement;
      case 'advanced':
        return Icons.whatshot;
      case 'elite':
        return Icons.emoji_events;
      default:
        return Icons.fitness_center;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate level progress for progress bar
    double levelProgress = _workoutsCompleted / _workoutsUntilNextLevel;
    levelProgress = levelProgress.clamp(0.0, 1.0);

    // Define the lighter background colors
    final Color lightBackground = Color(0xFFF5F7FA);
    final Color cardBackground = Color(0xFFFFFFFF);

    // Get level colors
    final Color primaryColor = _getLevelPrimaryColor();
    final Color secondaryColor = _getLevelSecondaryColor();

    if (_isLoading) {
      return Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor.withOpacity(0.8),
                          primaryColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _showAnimation
                          ? _buildCelebrationAnimation()
                          : Icon(
                        _getLevelIcon(),
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _fitnessLevel,
                        style: GoogleFonts.bebasNeue(
                          color: Color(0xFF2D3748),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              primaryColor.withOpacity(0.9),
                              primaryColor,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          "Level $_fitnessSubLevel",
                          style: GoogleFonts.bebasNeue(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (_lastUpdated != null && DateTime.now().difference(_lastUpdated!).inDays < 3)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFD2DC5C),
                        Color(0xFF388B5C),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF4CAF50).withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.bolt,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ACTIVE',
                        style: GoogleFonts.bebasNeue(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Progress to Next Level",
                style: GoogleFonts.bebasNeue(
                  color: Color(0xFF4A5568),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0xFFF7FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  "$_workoutsCompleted/$_workoutsUntilNextLevel",
                  style: GoogleFonts.bebasNeue(
                    color: secondaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          Stack(
            children: [
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Color(0xFFEDF2F7),
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 1000),
                    height: 14,
                    width: constraints.maxWidth * levelProgress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          secondaryColor.withOpacity(0.8),
                          primaryColor,
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (levelProgress > 0.05)
                Positioned(
                  left: (levelProgress * MediaQuery.of(context).size.width * 0.8) - 18,
                  top: -20,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "${(levelProgress * 100).toInt()}%",
                      style: GoogleFonts.bebasNeue(
                        color: primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: secondaryColor,
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _getMotivationalMessage(),
                    style: GoogleFonts.bebasNeue(
                      color: Color(0xFF4A5568),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}