import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:fitmate/viewmodels/nutrition_viewmodel.dart';

///list of providers that are used in the app
List<SingleChildWidget> providers = [
  ChangeNotifierProvider<NutritionViewModel>(
    create: (_) => NutritionViewModel(),
  ),
  //add additional view models here
];