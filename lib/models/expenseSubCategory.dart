class ExpenseSubCategory {
  int? id;
  String title;
  int expenseCategoryId;

  ExpenseSubCategory({
    this.id,
    required this.title,
    required this.expenseCategoryId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'expense_category_id': expenseCategoryId,
    };
  }

  factory ExpenseSubCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseSubCategory(
      id: map['id'],
      title: map['title'],
      expenseCategoryId: map['expense_category_id'],
    );
  }
}