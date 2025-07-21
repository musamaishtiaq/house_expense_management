class Expense {
  int? id;
  int expenseSubCategoryId;
  double amount;
  DateTime dateTime;
  String? description; // Added optional description field

  Expense({
    this.id,
    required this.expenseSubCategoryId,
    required this.amount,
    required this.dateTime,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expense_subcategory_id': expenseSubCategoryId,
      'amount': amount,
      'date_time': dateTime.toIso8601String(),
      'description': description,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      expenseSubCategoryId: map['expense_subcategory_id'],
      amount: map['amount'],
      dateTime: DateTime.parse(map['date_time']),
      description: map['description'],
    );
  }
}