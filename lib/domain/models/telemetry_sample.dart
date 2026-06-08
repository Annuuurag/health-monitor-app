class TelemetrySample {
  const TelemetrySample({
    required this.deviceId,
    required this.timestamp,
    required this.heartRateBpm,
    required this.spo2Percent,
    required this.bodyTempC,
    required this.activityLabel,
    required this.stepCount,
    required this.signalQuality,
    required this.source,
  });

  final String deviceId;
  final DateTime timestamp;
  final double heartRateBpm;
  final double spo2Percent;
  final double bodyTempC;
  final String activityLabel;
  final int stepCount;
  final double signalQuality;
  final String source;

  TelemetrySample copyWith({
    String? deviceId,
    DateTime? timestamp,
    double? heartRateBpm,
    double? spo2Percent,
    double? bodyTempC,
    String? activityLabel,
    int? stepCount,
    double? signalQuality,
    String? source,
  }) {
    return TelemetrySample(
      deviceId: deviceId ?? this.deviceId,
      timestamp: timestamp ?? this.timestamp,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      spo2Percent: spo2Percent ?? this.spo2Percent,
      bodyTempC: bodyTempC ?? this.bodyTempC,
      activityLabel: activityLabel ?? this.activityLabel,
      stepCount: stepCount ?? this.stepCount,
      signalQuality: signalQuality ?? this.signalQuality,
      source: source ?? this.source,
    );
  }
}
