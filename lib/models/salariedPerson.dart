class SalariedPerson {
  int? id;
  String title;
  String? description;
  int orderIndex;

  SalariedPerson({
    this.id,
    required this.title,
    this.description,
    this.orderIndex = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'order_index': orderIndex,
    };
  }

  factory SalariedPerson.fromMap(Map<String, dynamic> map) {
    return SalariedPerson(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      orderIndex: map['order_index'] as int? ?? 0,
    );
  }
}
