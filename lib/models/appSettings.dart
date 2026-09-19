class AppSettings {
  int? id;
  int hintMonths;
  double monthlySavingsTarget;

  AppSettings({
    this.id,
    this.hintMonths = 3,
    this.monthlySavingsTarget = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hint_months': hintMonths,
      'monthly_savings_target': monthlySavingsTarget,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      id: map['id'],
      hintMonths: map['hint_months'] as int? ?? 3,
      monthlySavingsTarget:
          (map['monthly_savings_target'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
