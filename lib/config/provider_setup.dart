import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/services/workout_service.dart';
import 'package:fitmate/viewmodels/nutrition_viewmodel.dart';
import 'package:fitmate/viewmodels/workout_viewmodel.dart';

/// List of providers that are used in the app
List<SingleChildWidget> providers = [
  // Repositories
  Provider<WorkoutRepository>(
    create: (_) => WorkoutRepository(),
  ),
  
  // Services
  Provider<WorkoutService>(
    create: (_) => WorkoutService(),
  ),
  
  // ViewModels
  ChangeNotifierProvider<NutritionViewModel>(
    create: (_) => NutritionViewModel(),
  ),
  ChangeNotifierProvider<WorkoutViewModel>(
    create: (context) => WorkoutViewModel(
      repository: context.read<WorkoutRepository>(),
      workoutService: context.read<WorkoutService>(),
    ),
  ),
  
  // Add additional view models here
];