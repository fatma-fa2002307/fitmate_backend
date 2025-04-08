import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fitmate/models/workout.dart';
import 'package:fitmate/services/workout_image_cache.dart';

class WorkoutCard extends StatefulWidget {
  final WorkoutExercise workout;
  
  const WorkoutCard({Key? key, required this.workout}) : super(key: key);

  @override
  State<WorkoutCard> createState() => _WorkoutCardState();
}

class _WorkoutCardState extends State<WorkoutCard> {
  final _imageCache = WorkoutImageCache();
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _imageCache.preloadWorkoutImage(context, widget.workout);
    });
  }

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    widget.workout.workout,
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    "${widget.workout.sets} sets × ${widget.workout.reps} reps",
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // Transparent background image
                Container(
                  color: Colors.transparent, // Ensures container is transparent
                  constraints: BoxConstraints(maxHeight: 260),
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: _imageCache.getWorkoutImageWidget(
                    workout: widget.workout,
                    fit: BoxFit.contain,
                  ),
                ),
                
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
              // Transparent container for the image
              Container(
                width: 60,
                height: 60,
                color: Colors.transparent, // Make container transparent
                child: _imageCache.getWorkoutImageWidget(
                  workout: widget.workout,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.workout.workout,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.workout.sets} sets × ${widget.workout.reps} reps',
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