import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/models/workout.dart';
import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/viewmodels/cardio_workout_viewmodel.dart';
import 'package:fitmate/screens/workout_screens/workout_completion_screen.dart';
import 'package:fitmate/services/workout_image_cache.dart';

class CardioActiveWorkoutScreen extends StatelessWidget {
  final Map<String, dynamic> workout;
  final String category;

  const CardioActiveWorkoutScreen({
    Key? key,
    required this.workout,
    this.category = 'Cardio',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //conv map to WorkoutExercise
    final workoutExercise = WorkoutExercise(
      workout: workout['workout'] ?? '',
      image: workout['image'] ?? '',
      sets: '1',
      reps: '1',
      isCardio: true,
      duration: workout['duration'] ?? '30 min',
      intensity: workout['intensity'] ?? 'Moderate',
      format: workout['format'] ?? 'Steady-state',
      calories: workout['calories'] ?? '300-350',
      description: workout['description'] ?? 'Perform at a comfortable pace.',
    );
    
    //create  ViewModel with dependency inje
    return ChangeNotifierProvider(
      create: (context) => CardioWorkoutViewModel(
        repository: context.read<WorkoutRepository>(),
        workout: workoutExercise,
        category: category,
      )..init(),
      child: _CardioActiveWorkoutScreenContent(
        originalWorkout: workout,
      ),
    );
  }
}

class _CardioActiveWorkoutScreenContent extends StatefulWidget {
  final Map<String, dynamic> originalWorkout;
  
  const _CardioActiveWorkoutScreenContent({
    Key? key,
    required this.originalWorkout,
  }) : super(key: key);
  
  @override
  _CardioActiveWorkoutScreenContentState createState() => _CardioActiveWorkoutScreenContentState();
}

class _CardioActiveWorkoutScreenContentState extends State<_CardioActiveWorkoutScreenContent> {
  //get image cache instance
  final _imageCache = WorkoutImageCache();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    //preload image
    final viewModel = Provider.of<CardioWorkoutViewModel>(context, listen: false);
    _imageCache.preloadCardioImage(context, widget.originalWorkout);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CardioWorkoutViewModel>(
      builder: (context, viewModel, child) {
        final String formattedTime = viewModel.formatTime(viewModel.elapsedSeconds);
        final String remainingTime = viewModel.formatTime(viewModel.remainingSeconds);

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                //header w back button and cancel
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
                
                //using shared image cache
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
                      child: _imageCache.getCardioImageWidget(
                        workout: widget.originalWorkout,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                
                //title fo exercise
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    viewModel.workout.workout.toUpperCase(),
                    style: GoogleFonts.bebasNeue(
                      fontSize: 28,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                //timer
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
                            color: viewModel.remainingSeconds > 0 
                                ? Colors.white 
                                : const Color(0xFFD2EB50),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                  
                //prog bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TARGET: ${viewModel.targetDuration}',
                            style: GoogleFonts.dmSans(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${(viewModel.progress * 100).toInt()}%',
                            style: GoogleFonts.dmSans(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: viewModel.progress,
                        backgroundColor: Colors.white10,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ],
                  ),
                ),
                
                //buttons (pause/resume/complete)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        viewModel.togglePause();
                      },
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: Colors.white24,
                      ),
                      child: Icon(
                        viewModel.isPaused ? Icons.play_arrow : Icons.pause,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final success = await viewModel.completeWorkout();
                        if (success && context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WorkoutCompletionScreen(
                                completedExercises: 1,
                                totalExercises: 1,
                                duration: formattedTime,
                                category: viewModel.category,
                              ),
                            ),
                          );
                        }
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
                
                //workout details in horiz
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildDetailItem(Icons.whatshot, 'Intensity', viewModel.workout.intensity ?? 'Moderate'),
                      const SizedBox(width: 24),
                      _buildDetailItem(Icons.loop, 'Format', viewModel.workout.format ?? 'Steady-state'),
                      const SizedBox(width: 24),
                      _buildDetailItem(
                        Icons.local_fire_department, 
                        'Calories', 
                        viewModel.workout.calories ?? '300-350'
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD2EB50), size: 24),
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