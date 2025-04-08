import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:fitmate/models/workout.dart';
import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/services/workout_service.dart';
import 'package:fitmate/viewmodels/todays_workout_viewmodel.dart';
import 'package:fitmate/screens/workout_screens/active_workout_screen.dart';
import 'package:fitmate/screens/workout_screens/cardio_active_workout_screen.dart';
import 'package:fitmate/widgets/bottom_nav_bar.dart';
import 'package:fitmate/widgets/workout_skeleton.dart';
import 'package:fitmate/widgets/cardio_workout_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fitmate/services/api_service.dart';

class WorkoutCard extends StatelessWidget {
  final WorkoutExercise workout;
  
  const WorkoutCard({Key? key, required this.workout}) : super(key: key);

  void _showInstructionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title of the exercise
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    workout.workout,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Sets and reps information
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    "${workout.sets} sets × ${workout.reps} reps",
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Image of the exercise
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: CachedNetworkImage(
                    imageUrl: ApiService.baseUrl + '/workout-images/' + 
                      '${workout.workout.replaceAll(' ', '-')}.webp',
                    height: 260,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: Colors.white,
                      height: 260,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFD2EB50),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print("Error loading image for workout: ${workout.workout} - Error: $error");
                      return Container(
                        height: 260,
                        color: Colors.white,
                        child: Icon(Icons.fitness_center, size: 80, color: Colors.grey[400]),
                      );
                    },
                  ),
                ),
                
                // Simple "Got it" button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2EB50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Got it',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showInstructionDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[100],
                  child: CachedNetworkImage(
                    imageUrl: ApiService.baseUrl + workout.image,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFD2EB50),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      print("Error loading image: $error");
                      return Icon(Icons.fitness_center, size: 30, color: Colors.grey[700]);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.workout,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${workout.sets} sets × ${workout.reps} reps',
                      style: GoogleFonts.dmSans(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  color: Color(0xFFD2EB50),
                ),
                onPressed: () => _showInstructionDialog(context),
                tooltip: 'View exercise details',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FreshTodaysWorkoutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => TodaysWorkoutViewModel(
        repository: context.read<WorkoutRepository>(),
        workoutService: context.read<WorkoutService>(),
      )..init(),
      child: const _TodaysWorkoutScreenContent(),
    );
  }
}

class _TodaysWorkoutScreenContent extends StatefulWidget {
  const _TodaysWorkoutScreenContent({Key? key}) : super(key: key);

  @override
  State<_TodaysWorkoutScreenContent> createState() => _TodaysWorkoutScreenContentState();
}

class _TodaysWorkoutScreenContentState extends State<_TodaysWorkoutScreenContent> {
  final PageController _pageController = PageController();
  int _selectedIndex = 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
    Widget build(BuildContext context) {
      return Consumer<TodaysWorkoutViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                viewModel.workoutCategory.isNotEmpty 
                    ? viewModel.workoutCategory.toUpperCase() 
                    : 'TODAY\'S WORKOUT',
                style: GoogleFonts.bebasNeue(color: Colors.black),
              ),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                if (viewModel.hasError && !viewModel.isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.black54),
                    onPressed: viewModel.reload,
                    tooltip: 'Refresh',
                  ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: viewModel.isLoading 
                    ? _buildLoadingView(viewModel)
                    : viewModel.hasError
                      ? _buildErrorView(viewModel)
                      : viewModel.workoutOptionsList.isEmpty 
                        ? _buildEmptyView()
                        : _buildWorkoutView(viewModel),
                ),
                // Fixed bottom button
                if (!viewModel.isLoading && !viewModel.hasError && viewModel.workoutOptionsList.isNotEmpty)
                  _buildBottomStartButton(viewModel),
              ],
            ),
            bottomNavigationBar: BottomNavBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          );
        },
      );
    }

  Widget _buildLoadingView(TodaysWorkoutViewModel viewModel) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFD2EB50).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Color(0xFFD2EB50).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFFD2EB50),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
            Text(
              viewModel.statusMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            if (viewModel.isRetrying) ...[
              SizedBox(height: 20),
              Container(
                width: 200,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2EB50)),
                ),
              ),
            ],
          ],
        ),
      );
    }

  Widget _buildErrorView(TodaysWorkoutViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.refresh_rounded, size: 40, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              viewModel.errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 18,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: viewModel.reload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2EB50),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Try Again',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.fitness_center, size: 50, color: Color(0xFFD2EB50)),
            ),
            const SizedBox(height: 24),
            Text(
              "Ready to start your fitness journey?",
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Let's create a personalized workout plan for you",
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 30),
            Consumer<TodaysWorkoutViewModel>(
              builder: (context, viewModel, child) {
                return ElevatedButton(
                  onPressed: viewModel.reload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD2EB50),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Create Workout Plan',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutView(TodaysWorkoutViewModel viewModel) {
    final options = viewModel.workoutOptionsList;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                offset: Offset(0, 2),
                blurRadius: 6,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Workout Option ${viewModel.currentPage + 1} of ${options.length}',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              //Workout Pagination Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(options.length, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    width: viewModel.currentPage == index ? 20 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: viewModel.currentPage == index
                          ? const Color(0xFFD2EB50)
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        //page for workout options
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (int page) {
              viewModel.setCurrentPage(page);
            },
            itemCount: options.length,
            itemBuilder: (context, pageIndex) {
              final workouts = options[pageIndex];
              
              //check if cardio workout
              if (viewModel.isCardioWorkout && workouts.isNotEmpty && workouts[0].isCardio) {
                // Use CardioWorkoutCard for cardio workouts
                return ListView.builder(
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    return CardioWorkoutCard(workout: _convertToMapForCardio(workouts[index]));
                  },
                );
              } else {
                // Use regular WorkoutCard for strength training
                return ListView.builder(
                  padding: EdgeInsets.only(top: 16, bottom: 16),
                  itemCount: workouts.length,
                  itemBuilder: (context, index) {
                    return WorkoutCard(workout: workouts[index]);
                  },
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _convertToMapForCardio(WorkoutExercise workout) {
    // Convert WorkoutExercise to Map for CardioWorkoutCard
    return {
      'workout': workout.workout,
      'image': workout.image,
      'duration': workout.duration ?? '30 min',
      'intensity': workout.intensity ?? 'Moderate',
      'format': workout.format ?? 'Steady-state',
      'calories': workout.calories ?? '300-350',
      'description': workout.description ?? 'Perform at a comfortable pace.',
      'is_cardio': true,
    };
  }

  Widget _buildBottomStartButton(TodaysWorkoutViewModel viewModel) {
    if (viewModel.workoutOptionsList.isEmpty) return SizedBox.shrink();
    
    final currentWorkouts = viewModel.workoutOptionsList[viewModel.currentPage];
    final isCardio = viewModel.isCardioWorkout && 
                     currentWorkouts.isNotEmpty && 
                     currentWorkouts[0].isCardio;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (isCardio) {
            //nav to cardio-specific workout screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardioActiveWorkoutScreen(
                  workout: _convertToMapForCardio(currentWorkouts[0]),
                  category: viewModel.workoutCategory,
                ),
              ),
            );
          } else {
            //nav to regular workout screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActiveWorkoutScreen(
                  workouts: currentWorkouts.map((e) => _convertToMap(e)).toList(),
                  category: viewModel.workoutCategory,
                ),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD2EB50),
          padding: EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'START',
          style: GoogleFonts.bebasNeue(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _convertToMap(WorkoutExercise workout) {
    // Convert WorkoutExercise to Map for ActiveWorkoutScreen
    return {
      'workout': workout.workout,
      'image': workout.image,
      'sets': workout.sets,
      'reps': workout.reps,
      'instruction': workout.instruction,
    };
  }
}