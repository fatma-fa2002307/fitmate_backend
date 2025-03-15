import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitmate/models/users.dart';
import 'package:fitmate/repositories/users_repository.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) => UserRepository());

class UserNotifier extends AsyncNotifier<Users?> {
  @override
  Future<Users?> build() async {
    return null;
  }

  String? validateFullName(String? value) {
    return ref.read(userRepositoryProvider).validateFullName(value);
  }

  String? validateEmail(String? value) {
    return ref.read(userRepositoryProvider).validateEmail(value);
  }

  String? validatePassword(String? value) {
    return ref.read(userRepositoryProvider).validatePassword(value);
  }

  Future<void> registerUser(
      String email,
      String password,
      String fullName,
      int age,
      double weight,
      double height,
      String gender,
      String selectedGoal,
      int workoutDays,
      ) async {
    state = const AsyncLoading();
    try {
      final newUser = await ref.read(userRepositoryProvider).createUserWithEmailAndPassword(
        email, password, fullName, age, weight, height, gender, selectedGoal, workoutDays,
      );
      state = AsyncData(newUser);
    } on FirebaseAuthException catch (e) {
      state = AsyncError(e, StackTrace.current);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }
}

final userProvider = AsyncNotifierProvider<UserNotifier, Users?>(
      () => UserNotifier(),
);