enum InsightSeverity { low, moderate, high }

class InsightResult {
  const InsightResult({
    required this.title,
    required this.category,
    required this.severity,
    required this.confidence,
    required this.summary,
    required this.suggestion,
  });

  final String title;
  final String category;
  final InsightSeverity severity;
  final double confidence;
  final String summary;
  final String suggestion;
}
