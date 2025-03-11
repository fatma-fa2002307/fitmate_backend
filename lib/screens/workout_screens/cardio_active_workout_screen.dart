import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/screens/workout_screens/workout_completion_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CardioActiveWorkoutScreen extends StatefulWidget {
  final Map<String, dynamic> workout;
  final String category;

  const CardioActiveWorkoutScreen({
    Key? key,
    required this.workout,
    this.category = 'Cardio',
  }) : super(key: key);

  @override
  _CardioActiveWorkoutScreenState createState() => _CardioActiveWorkoutScreenState();
}

class _CardioActiveWorkoutScreenState extends State<CardioActiveWorkoutScreen> {
  int _elapsedSeconds = 0;
  late Timer _timer;
  bool _isCompleted = false;
  bool _isPaused = false;
  String _targetDuration = "30 min";  // Default
  int _targetSeconds = 1800;  // Default (30 min * 60)
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _parseDuration();
    _startTimer();
  }

  void _parseDuration() {
    // Parse duration from the workout (e.g., "30 min" to seconds)
    String duration = widget.workout['duration'] ?? "30 min";
    duration = duration.replaceAll(' ', '').toLowerCase();
    
    if (duration.contains('min')) {
      String minValue = duration.replaceAll('min', '');
      try {
        if (minValue.contains('-')) {
          // Handle range like "20-30 min"
          minValue = minValue.split('-').last;
        }
        int minutes = int.parse(minValue);
        _targetSeconds = minutes * 60;
        _targetDuration = "$minutes min";
      } catch (e) {
        // Use default if parsing fails
        _targetSeconds = 1800;
        _targetDuration = "30 min";
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedSeconds++;
          _progress = _elapsedSeconds / _targetSeconds;
          
          // Cap progress at 100%
          if (_progress > 1.0) {
            _progress = 1.0;
          }
        });
      }
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formattedTime = formatTime(_elapsedSeconds);
    int remainingSeconds = _targetSeconds - _elapsedSeconds;
    String remainingTime = remainingSeconds > 0 ? formatTime(remainingSeconds) : "00:00";

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and cancel
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.bebasNeue(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Cardio Exercise Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.grey[900],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: widget.workout['image'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[800],
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD2EB50),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      return Center(
                        child: Icon(
                          Icons.directions_run,
                          size: 80,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            
            // Exercise Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                widget.workout['workout'].toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 28,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Timer Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      'ELAPSED',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTime,
                      style: GoogleFonts.albertSans(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  height: 50,
                  width: 1,
                  color: Colors.white24,
                ),
                Column(
                  children: [
                    Text(
                      'REMAINING',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      remainingTime,
                      style: GoogleFonts.albertSans(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: remainingSeconds > 0 ? Colors.white : Color(0xFFD2EB50),
                      ),
                    ),
                  ],
                ),
              ],
            ),
              
            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TARGET: $_targetDuration',
                        style: GoogleFonts.dmSans(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: GoogleFonts.dmSans(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
            ),
            
            // Pause/Resume and Complete buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isPaused = !_isPaused;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.white24,
                  ),
                  child: Icon(
                    _isPaused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isCompleted = true;
                    });
                    
                    _timer.cancel();
                    
                    // Navigate to completion screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutCompletionScreen(
                          completedExercises: 1,
                          totalExercises: 1,
                          duration: formatTime(_elapsedSeconds),
                          category: widget.category,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD2EB50),
                    minimumSize: const Size(120, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'COMPLETE',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Workout details in a horizontal scrollable
            Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildDetailItem(Icons.whatshot, 'Intensity', widget.workout['intensity'] ?? 'Moderate'),
                  const SizedBox(width: 24),
                  _buildDetailItem(Icons.loop, 'Format', widget.workout['format'] ?? 'Steady-state'),
                  const SizedBox(width: 24),
                  _buildDetailItem(Icons.local_fire_department, 'Calories', widget.workout['calories'] ?? '300-350'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFFD2EB50), size: 24),
        const SizedBox(width: 8),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: Colors.white60,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}