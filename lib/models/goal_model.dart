class GoalModel {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? targetDate;  // ISO8601 date string

  GoalModel({
    this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    this.targetDate,
  });

  // Progress percentage (0.0 to 1.0)
  double get progress {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'],
      name: map['name'],
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'],
      targetDate: map['targetDate'],
    );
  }

  GoalModel copyWith({
    int? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    String? targetDate,
  }) {
    return GoalModel(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
    );
  }
}
