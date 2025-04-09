import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fitmate/models/workout.dart';
import 'package:fitmate/viewmodels/workout_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class WorkoutHistoryWidget extends StatelessWidget {
  final int initialVisibleCount;
  final bool showViewAllButton;

  const WorkoutHistoryWidget({
    Key? key,
    this.initialVisibleCount = 3, // Show only 3 items initially
    this.showViewAllButton = false, // Hide view all button by default now
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WorkoutViewModel>(context);
    // Sort workouts by date, most recent first
    final workoutHistory = viewModel.workoutHistory
      ..sort((a, b) => b.date.compareTo(a.date));

    // Calculate the actual height based on available workouts
    final int itemCount = workoutHistory.length > initialVisibleCount
        ? initialVisibleCount
        : workoutHistory.length;
    final double listHeight = itemCount > 0 ? itemCount * 85.0 : 80.0; // 80px height for empty state

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (workoutHistory.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Text(
                    'Complete your first workout to see it here',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: listHeight,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: workoutHistory.length > initialVisibleCount && !showViewAllButton
                      ? initialVisibleCount
                      : workoutHistory.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[300],
                  ),
                  itemBuilder: (context, index) {
                    final workout = workoutHistory[index];
                    return InkWell(
                      onTap: () {
                        if (workout.hasDetails()) {
                          _showWorkoutDetailsDialog(context, workout);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: _buildWorkoutHistoryItem(context, workout),
                    );
                  },
                ),
              ),
            // View All button has been removed as requested
          ],
        ),
      ),
    );
  }

  void _showWorkoutDetailsDialog(BuildContext context, CompletedWorkout workout) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: WorkoutDetailPopup(workout: workout),
          ),
        ),
      ),
    );
  }

  // Removed _showAllWorkoutsDialog method as it's no longer needed

  Widget _buildWorkoutHistoryItem(BuildContext context, CompletedWorkout workout) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _getCategoryColor(workout.category).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _getCategoryColor(workout.category).withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(workout.category),
                color: _getCategoryColor(workout.category),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  workout.category,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM d, yyyy • HH:mm').format(workout.date),
                  style: GoogleFonts.dmSans(
                    color: Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                workout.duration,
                style: GoogleFonts.albertSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${workout.completedExercises}/${workout.totalExercises}',
                  style: GoogleFonts.dmSans(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (workout.hasDetails())
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right,
                  color: Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'push':
        return Colors.blue;
      case 'pull':
        return Colors.red;
      case 'legs':
        return Colors.green;
      case 'upper body':
        return Colors.purple;
      case 'lower body':
        return Colors.orange;
      case 'cardio':
        return Colors.teal;
      default:
        return Colors.tealAccent;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'push':
        return Icons.fitness_center;
      case 'pull':
        return Icons.settings_input_component;
      case 'legs':
        return Icons.directions_run;
      case 'upper body':
        return Icons.accessibility_new;
      case 'lower body':
        return Icons.airline_seat_legroom_extra;
      case 'cardio':
        return Icons.directions_run;
      default:
        return Icons.sports_gymnastics;
    }
  }
}

class WorkoutDetailPopup extends StatelessWidget {
  final CompletedWorkout workout;

  const WorkoutDetailPopup({Key? key, required this.workout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCardio = workout.isCardioWorkout();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          workout.category,
          style: GoogleFonts.montserrat(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.black54, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(workout.category).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getCategoryIcon(workout.category),
                            color: _getCategoryColor(workout.category),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Workout Summary',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                DateFormat('EEEE, MMMM d, yyyy').format(workout.date),
                                style: GoogleFonts.dmSans(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        _buildStatCard(
                          context,
                          icon: Icons.schedule,
                          title: 'Duration',
                          value: workout.duration,
                          color: Colors.blue[700]!,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          context,
                          icon: Icons.fitness_center,
                          title: 'Exercises',
                          value: '${workout.completedExercises}/${workout.totalExercises}',
                          color: Colors.green!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Completion',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              '${(workout.completion * 100).toInt()}%',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 12,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Stack(
                              children: [
                                Container(
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                ),
                                FractionallySizedBox(
                                  widthFactor: workout.completion,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFE7FC00),
                                          const Color(0xFFD2EB50),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            if (workout.performedExercises != null && workout.performedExercises!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completed Exercises',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...workout.performedExercises!.map((exercise) => _buildExerciseCard(context, exercise, isCardio, true)),
                ],
              ),

            if (workout.performedExercises != null && workout.performedExercises!.isNotEmpty)
              const SizedBox(height: 24),

            if (workout.notPerformedExercises != null && workout.notPerformedExercises!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Skipped Exercises',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...workout.notPerformedExercises!.map((exercise) => _buildExerciseCard(context, exercise, isCardio, false)),
                ],
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.albertSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, Map<String, dynamic> exercise, bool isCardio, bool completed) {
    final name = workout.getExerciseValue(exercise, 'name', '');

    if (isCardio) {
      final duration = workout.getExerciseValue(exercise, 'duration', '');
      final actualDuration = workout.getExerciseValue(exercise, 'actualDuration', '');
      final progressPercentage = workout.getExerciseValue(exercise, 'progressPercentage', '');

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: completed ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.directions_run, size: 20, color: Colors.teal),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (completed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Done',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (duration.isNotEmpty)
                _buildInfoRow('Planned Duration', duration, Icons.timer_outlined),
              if (actualDuration.isNotEmpty)
                _buildInfoRow('Actual Duration', actualDuration, Icons.timer),
              if (progressPercentage.isNotEmpty)
                _buildInfoRow('Progress', progressPercentage, Icons.trending_up),
            ],
          ),
        ),
      );
    } else {
      final sets = workout.getExerciseValue(exercise, 'sets', '');
      final reps = workout.getExerciseValue(exercise, 'reps', '');

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: completed ? const Color(0xFFD2EB50).withOpacity(0.3) : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fitness_center, size: 20, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (completed)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Done',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoRow('Sets', sets, Icons.repeat),
                  ),
                  Expanded(
                    child: _buildInfoRow('Reps', reps, Icons.fitness_center),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            '$label:',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: GoogleFonts.albertSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'push': return Colors.blue;
      case 'pull': return Colors.red;
      case 'legs': return Colors.green;
      case 'upper body': return Colors.purple;
      case 'lower body': return Colors.orange;
      case 'cardio': return Colors.teal;
      default: return Colors.teal;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'push': return Icons.fitness_center;
      case 'pull': return Icons.settings_input_component;
      case 'legs': return Icons.directions_run;
      case 'upper body': return Icons.accessibility_new;
      case 'lower body': return Icons.airline_seat_legroom_extra;
      case 'cardio': return Icons.directions_run;
      default: return Icons.sports_gymnastics;
    }
  }
}

class AllWorkoutsPopup extends StatelessWidget {
  const AllWorkoutsPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<WorkoutViewModel>(context);
    final workoutHistory = viewModel.workoutHistory
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'ALL WORKOUTS',
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.black54, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: workoutHistory.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No workout history yet',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first workout to see it here',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: workoutHistory.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Colors.grey[300],
        ),
        itemBuilder: (context, index) {
          final workout = workoutHistory[index];
          return InkWell(
            onTap: workout.hasDetails()
                ? () {
              Navigator.of(context).pop();
              // Show workout details
              showDialog(
                context: context,
                builder: (context) => Dialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: WorkoutDetailPopup(workout: workout),
                    ),
                  ),
                ),
              );
            }
                : null,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(workout.category).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        _getCategoryIcon(workout.category),
                        color: _getCategoryColor(workout.category),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.category,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMM d, yyyy • HH:mm').format(workout.date),
                          style: GoogleFonts.dmSans(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        workout.duration,
                        style: GoogleFonts.albertSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${workout.completedExercises}/${workout.totalExercises}',
                          style: GoogleFonts.dmSans(
                            color: Colors.black54,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (workout.hasDetails())
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'push': return Colors.blue;
      case 'pull': return Colors.red;
      case 'legs': return Colors.green;
      case 'upper body': return Colors.purple;
      case 'lower body': return Colors.orange;
      case 'cardio': return Colors.teal;
      default: return Colors.teal;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'push': return Icons.fitness_center;
      case 'pull': return Icons.settings_input_component;
      case 'legs': return Icons.directions_run;
      case 'upper body': return Icons.accessibility_new;
      case 'lower body': return Icons.airline_seat_legroom_extra;
      case 'cardio': return Icons.directions_run;
      default: return Icons.sports_gymnastics;
    }
  }
}