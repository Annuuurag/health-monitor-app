class ReportSummary {
  const ReportSummary({
    required this.title,
    required this.periodLabel,
    required this.averageHeartRate,
    required this.averageSpo2,
    required this.averageTemperature,
    required this.activeMinutes,
    required this.note,
  });

  final String title;
  final String periodLabel;
  final double averageHeartRate;
  final double averageSpo2;
  final double averageTemperature;
  final int activeMinutes;
  final String note;
}
