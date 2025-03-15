class FoodHistory {
  final String id;
  final Map<String, List<String>> logsByDate;

  FoodHistory({required this.id, required this.logsByDate});

  /// 🔥 Convert from Firestore
  factory FoodHistory.fromMap(String id, Map<String, dynamic> data) {
    return FoodHistory(
      id: id,
      logsByDate: (data['logsByDate'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, List<String>.from(value ?? [])),
      ) ??
          {},
    );
  }

  /// 🔥 Convert to Firestore
  Map<String, dynamic> toMap() {
    return {'logsByDate': logsByDate};
  }
}
