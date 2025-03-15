class Users {
  final String id;
  final String email;
  final String gender;
  final String fullName;
  final int age;
  final double weight;
  final double height;
  final int workoutDays;
  final String goal;
  final String fitnessLevel;
  final int totalWorkouts;
  final int workoutsUntilNextLevel;

  Users({
    required this.id,
    required this.email,
    required this.gender,
    required this.fullName,
    required this.age,
    required this.weight,
    required this.height,
    required this.workoutDays,
    required this.goal,
    required this.fitnessLevel,
    required this.totalWorkouts,
    required this.workoutsUntilNextLevel,
  });

  factory Users.fromMap(String id, Map<String, dynamic> data) {
    return Users(
      id: id,
      email: data['email'] ?? '',
      gender: data['gender'] ?? '',
      fullName: data['fullName'] ?? '',
      age: data['age'] ?? 0,
      weight: (data['weight'] ?? 0).toDouble(),
      height: (data['height'] ?? 0).toDouble(),
      workoutDays: data['workoutDays'] ?? 0,
      goal: data['goal'] ?? '',
      fitnessLevel: data['fitnessLevel'] ?? '',
      totalWorkouts: data['totalWorkouts'] ?? 0,
      workoutsUntilNextLevel: data['workoutsUntilNextLevel'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'gender': gender,
      'fullName': fullName,
      'age': age,
      'weight': weight,
      'height': height,
      'workoutDays': workoutDays,
      'goal': goal,
      'fitnessLevel': fitnessLevel,
      'totalWorkouts': totalWorkouts,
      'workoutsUntilNextLevel': workoutsUntilNextLevel,
    };
  }
}