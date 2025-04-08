// Updated ActiveWorkoutScreen
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/models/workout.dart';
import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/viewmodels/active_workout_viewmodel.dart';
import 'package:fitmate/screens/workout_screens/workout_completion_screen.dart';
import 'package:fitmate/services/workout_image_cache.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  final List<Map<String, dynamic>> workouts;
  final String category;

  const ActiveWorkoutScreen({
    Key? key, 
    required this.workouts,
    this.category = 'Workout',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert maps to WorkoutExercise objects
    final workoutExercises = workouts.map((workoutMap) => 
      WorkoutExercise(
        workout: workoutMap['workout'] ?? '',
        image: workoutMap['image'] ?? '',
        sets: workoutMap['sets'] ?? '3',
        reps: workoutMap['reps'] ?? '10',
        instruction: workoutMap['instruction'],
      )
    ).toList();
    
    return ChangeNotifierProvider(
      create: (context) => ActiveWorkoutViewModel(
        repository: context.read<WorkoutRepository>(),
        workouts: workoutExercises,
        category: category,
      )..startTimer(),
      child: _ActiveWorkoutScreenContent(),
    );
  }
}

class _ActiveWorkoutScreenContent extends StatefulWidget {
  @override
  _ActiveWorkoutScreenContentState createState() => _ActiveWorkoutScreenContentState();
}

class _ActiveWorkoutScreenContentState extends State<_ActiveWorkoutScreenContent> {
  // Get the image cache instance
  final _imageCache = WorkoutImageCache();
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Preload all workout images when screen is created
    final viewModel = Provider.of<ActiveWorkoutViewModel>(context, listen: false);
    _preloadWorkoutImages(viewModel.workouts);
  }
  
  Future<void> _preloadWorkoutImages(List<WorkoutExercise> workouts) async {
    // Preload all images in the background
    for (final workout in workouts) {
      await _imageCache.preloadWorkoutImage(context, workout);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveWorkoutViewModel>(
      builder: (context, viewModel, child) {
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
                viewModel.formatTime(viewModel.elapsedSeconds),
                style: GoogleFonts.bebasNeue(
                  fontSize: 48,
                  color: Colors.white,
                ),
              ),
              Text(
                viewModel.category.toUpperCase(),
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
                      value: viewModel.progress,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    Text(
                      '${(viewModel.progress * 100).toInt()}%',
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
                  itemCount: viewModel.workouts.length,
                  itemBuilder: (context, index) {
                    final workout = viewModel.workouts[index];
                    return _buildWorkoutListItem(context, viewModel, workout, index);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await viewModel.completeWorkout();
                    if (success && context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutCompletionScreen(
                            completedExercises: viewModel.completedCount,
                            totalExercises: viewModel.workouts.length,
                            duration: viewModel.formatTime(viewModel.elapsedSeconds),
                            category: viewModel.category,
                          ),
                        ),
                      );
                    }
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
      },
    );
  }

  Widget _buildWorkoutListItem(
    BuildContext context, 
    ActiveWorkoutViewModel viewModel, 
    WorkoutExercise workout, 
    int index
  ) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 40,
          height: 40,
          child: _imageCache.getWorkoutImageWidget(
            workout: workout,
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        workout.workout,
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        '${workout.sets} sets × ${workout.reps} reps',
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
            onPressed: () => _showExerciseInfoDialog(context, workout),
          ),
          InkWell(
            onTap: () => viewModel.toggleExerciseCompletion(index),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                border: Border.all(
                  color: viewModel.completedExercises[index]
                      ? const Color(0xFFD2EB50)
                      : Colors.white,
                  width: 2,
                ),
                color: viewModel.completedExercises[index]
                    ? const Color(0xFFD2EB50)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: viewModel.completedExercises[index]
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
  }

  void _showExerciseInfoDialog(BuildContext context, WorkoutExercise workout) {
    final viewModel = Provider.of<ActiveWorkoutViewModel>(context, listen: false);
    
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
                  workout.workout,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _imageCache.getWorkoutImageWidget(
                    workout: workout,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, size: 16, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      '${workout.sets} sets × ${workout.reps} reps',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (workout.instruction != null && workout.instruction!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      workout.instruction!,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white30),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(
                        'CLOSE',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}