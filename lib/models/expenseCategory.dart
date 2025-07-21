class ExpenseCategory {
  int? id;
  String title;

  ExpenseCategory({
    this.id,
    required this.title,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
    };
  }

  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'],
      title: map['title'],
    );
  }
}