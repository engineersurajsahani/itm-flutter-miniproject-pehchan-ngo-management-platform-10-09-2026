class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String type;       // 'Income' or 'Expense'
  final String category;
  final String date;       // stored as ISO8601 string
  final String? note;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
  });

  // Convert model to map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date,
      'note': note,
    };
  }

  // Create model from SQLite map
  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      type: map['type'],
      category: map['category'],
      date: map['date'],
      note: map['note'],
    );
  }

  // Copy with updated fields
  TransactionModel copyWith({
    int? id,
    String? title,
    double? amount,
    String? type,
    String? category,
    String? date,
    String? note,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }
}
