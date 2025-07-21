class SalariedPerson {
  int? id;
  String title;
  String? description; // Added optional description field

  SalariedPerson({
    this.id,
    required this.title,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
    };
  }

  factory SalariedPerson.fromMap(Map<String, dynamic> map) {
    return SalariedPerson(
      id: map['id'],
      title: map['title'],
      description: map['description'],
    );
  }
}