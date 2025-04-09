import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:fitmate/repositories/workout_repository.dart';
import 'package:fitmate/repositories/home_repository.dart';
import 'package:fitmate/services/workout_service.dart';
import 'package:fitmate/viewmodels/nutrition_viewmodel.dart';
import 'package:fitmate/viewmodels/workout_viewmodel.dart';
import 'package:fitmate/viewmodels/edit_profile_viewmodel.dart';
import 'package:fitmate/viewmodels/welcome_viewmodel.dart';
import 'package:fitmate/viewmodels/home_page_viewmodel.dart';

/// providers that are used in the app
List<SingleChildWidget> providers = [
  //repos
  Provider<WorkoutRepository>(
    create: (_) => WorkoutRepository(),
  ),
  Provider<HomeRepository>(
    create: (_) => HomeRepository(),
  ),
  
  //services
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
  ChangeNotifierProvider<EditProfileViewModel>(
    create: (_) => EditProfileViewModel(),
  ),
  ChangeNotifierProvider<WelcomeViewModel>(
    create: (_) => WelcomeViewModel(),
  ),
  ChangeNotifierProvider<HomePageViewModel>(
    create: (context) => HomePageViewModel(
      repository: context.read<HomeRepository>(),
    ),
  ),
  
  //add additional view models here
];