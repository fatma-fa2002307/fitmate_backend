class Food {
  final String name;
  final double calories; // in kcal (calories)
  final double protein;  // in grams
  final double carbs;    // in grams
  final double fat;      // in grams
  final double servingSize; // in grams

  Food({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
  });

  // Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'servingSize': servingSize,
    };
  }

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      name: map['name'],
      calories: map['calories'],
      protein: map['protein'],
      carbs: map['carbs'],
      fat: map['fat'],
      servingSize: map['servingSize'],
    );
  }
}
