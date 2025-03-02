import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/screens/workout_screens/workout_completion_screen.dart';

class ActiveWorkoutScreen extends StatefulWidget {
  final List<Map<String, String>> workouts;
  final String category;

  const ActiveWorkoutScreen({
    Key? key, 
    required this.workouts,
    this.category = 'Workout',
  }) : super(key: key);

  @override
  _ActiveWorkoutScreenState createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  int _elapsedSeconds = 0;
  late Timer _timer;
  List<bool> _completedExercises = [];
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _completedExercises = List.generate(widget.workouts.length, (_) => false);
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void updateProgress() {
    int completedCount = _completedExercises.where((done) => done).length;
    setState(() {
      _progress = completedCount / widget.workouts.length;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            formatTime(_elapsedSeconds),
            style: GoogleFonts.bebasNeue(
              fontSize: 48,
              color: Colors.white,
            ),
          ),
          Text(
            widget.category.toUpperCase(),
            style: GoogleFonts.bebasNeue(
              fontSize: 16,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your progress',
                  style: GoogleFonts.dmSans(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                Text(
                  '${(_progress * 100).toInt()}%',
                  style: GoogleFonts.dmSans(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: widget.workouts.length,
              itemBuilder: (context, index) {
                final workout = widget.workouts[index];
                return ListTile(
                  leading: Image.network(
                    'http://192.168.0.186:8000${workout["image"]}',
                    width: 40,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.fitness_center, color: Colors.white),
                  ),
                  title: Text(
                    workout["workout"]!,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    '${workout["sets"]} sets × ${workout["reps"]} reps',
                    style: GoogleFonts.dmSans(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.white70),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Dialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        workout["workout"]!,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      Image.network(
                                        'http://192.168.0.186:8000/workout-images/${workout["workout"]!.replaceAll(' ', '-')}.webp',
                                        height: 200,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          print("Error loading image for workout: ${workout["workout"]} - Error: $error");
                                          return const Icon(Icons.fitness_center, size: 100);
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFD2EB50),
                                        ),
                                        child: const Text('Got it'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _completedExercises[index] = !_completedExercises[index];
                            updateProgress();
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _completedExercises[index]
                                  ? const Color(0xFFD2EB50)
                                  : Colors.white,
                              width: 2,
                            ),
                            color: _completedExercises[index]
                                ? const Color(0xFFD2EB50)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _completedExercises[index]
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.black,
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                _timer.cancel();
                int completedCount = _completedExercises.where((done) => done).length;
                String duration = formatTime(_elapsedSeconds);
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutCompletionScreen(
                      completedExercises: completedCount,
                      totalExercises: widget.workouts.length,
                      duration: duration,
                      category: widget.category,
                    ),
                  ),
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
          ),
        ],
      ),
    );
  }
}