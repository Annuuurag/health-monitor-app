class MedicationReminder {
  const MedicationReminder({
    required this.id,
    required this.title,
    required this.dosage,
    required this.hour,
    required this.minute,
    required this.enabled,
  });

  final String id;
  final String title;
  final String dosage;
  final int hour;
  final int minute;
  final bool enabled;

  MedicationReminder copyWith({
    String? id,
    String? title,
    String? dosage,
    int? hour,
    int? minute,
    bool? enabled,
  }) {
    return MedicationReminder(
      id: id ?? this.id,
      title: title ?? this.title,
      dosage: dosage ?? this.dosage,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'dosage': dosage,
      'hour': hour,
      'minute': minute,
      'enabled': enabled,
    };
  }

  factory MedicationReminder.fromJson(Map<String, dynamic> json) {
    return MedicationReminder(
      id: json['id'] as String,
      title: json['title'] as String,
      dosage: json['dosage'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
