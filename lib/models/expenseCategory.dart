class ExpenseCategory {
  int? id;
  String title;
  int orderIndex;

  ExpenseCategory({
    this.id,
    required this.title,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'order_index': orderIndex,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'],
      title: map['title'],
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }
}
