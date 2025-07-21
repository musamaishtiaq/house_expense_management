class Income {
  int? id;
  int salariedPersonId;
  double amount;
  DateTime dateTime;
  String? description; // Added optional description field

  Income({
    this.id,
    required this.salariedPersonId,
    required this.amount,
    required this.dateTime,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'salaried_person_id': salariedPersonId,
      'amount': amount,
      'date_time': dateTime.toIso8601String(),
      'description': description,
    };
  }

  factory Income.fromMap(Map<String, dynamic> map) {
    return Income(
      id: map['id'],
      salariedPersonId: map['salaried_person_id'],
      amount: map['amount'],
      dateTime: DateTime.parse(map['date_time']),
      description: map['description'],
    );
  }
}