class ExpenseSubCategory {
  int? id;
  String title;
  int expenseCategoryId;
  int orderIndex;
  double budget;

  ExpenseSubCategory({
    this.id,
    required this.title,
    required this.expenseCategoryId,
    this.orderIndex = 0,
    this.budget = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'expense_category_id': expenseCategoryId,
      'order_index': orderIndex,
      'budget': budget,
    };
  }

  factory ExpenseSubCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseSubCategory(
      id: map['id'],
      title: map['title'],
      expenseCategoryId: map['expense_category_id'],
      orderIndex: map['order_index'] as int? ?? 0,
      budget: (map['budget'] as num?)?.toDouble() ?? 0,
    );
  }
}
