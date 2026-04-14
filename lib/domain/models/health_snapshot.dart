class HealthSnapshot {
  const HealthSnapshot({
    required this.deviceId,
    required this.timestamp,
    required this.heartRateBpm,
    required this.spo2Percent,
    required this.bodyTempC,
    required this.activityLabel,
    required this.signalQuality,
    required this.overallStatus,
    required this.isAnomaly,
    required this.summary,
  });

  final String deviceId;
  final DateTime timestamp;
  final double heartRateBpm;
  final double spo2Percent;
  final double bodyTempC;
  final String activityLabel;
  final double signalQuality;
  final String overallStatus;
  final bool isAnomaly;
  final String summary;
}
