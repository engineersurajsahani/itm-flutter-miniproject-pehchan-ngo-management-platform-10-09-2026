class BudgetModel {
  final int? id;
  final String category;
  final double amount;   // Budget limit for the month
  final String month;   // Format: 'yyyy-MM'

  BudgetModel({
    this.id,
    required this.category,
    required this.amount,
    required this.month,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'month': month,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'],
      category: map['category'],
      amount: map['amount'],
      month: map['month'],
    );
  }

  BudgetModel copyWith({
    int? id,
    String? category,
    double? amount,
    String? month,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      month: month ?? this.month,
    );
  }
}
