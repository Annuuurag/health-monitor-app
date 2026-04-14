enum AlertSeverity { low, medium, high }

class AlertEvent {
  const AlertEvent({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    required this.category,
    required this.isAcknowledged,
  });

  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final String category;
  final bool isAcknowledged;

  AlertEvent copyWith({
    String? id,
    String? title,
    String? message,
    AlertSeverity? severity,
    DateTime? timestamp,
    String? category,
    bool? isAcknowledged,
  }) {
    return AlertEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }
}
