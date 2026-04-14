import '../../domain/models/alert_event.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/device_profile.dart';
import '../../domain/models/health_snapshot.dart';
import '../../domain/models/insight_result.dart';
import '../../domain/models/medication_reminder.dart';
import '../../domain/models/report_summary.dart';
import '../../domain/models/telemetry_sample.dart';
import '../../domain/models/user_profile.dart';

class MockSeedData {
  static List<TelemetrySample> telemetrySamples() {
    final now = DateTime.now();
    final generated = List<TelemetrySample>.generate(24, (index) {
      final point = 23 - index;
      final timestamp = now.subtract(Duration(hours: point));
      final heartRate = 72 + (index % 5) * 2 - (index.isEven ? 1 : 0);
      final spo2 = 97 - (index % 3 == 0 ? 1 : 0);
      final temperature = 36.5 + (index % 4) * 0.1;
      final activities = ['Resting', 'Walking', 'Working', 'Sleeping'];
      return TelemetrySample(
        deviceId: 'ESP32-HMS-01',
        timestamp: timestamp,
        heartRateBpm: heartRate.toDouble(),
        spo2Percent: spo2.toDouble(),
        bodyTempC: temperature,
        activityLabel: activities[index % activities.length],
        signalQuality: 0.89 + (index % 3) * 0.02,
        source: 'mock-cloud',
      );
    });

    generated[21] = generated[21].copyWith(
      spo2Percent: 93,
      activityLabel: 'Walking',
    );
    generated[22] = generated[22].copyWith(
      heartRateBpm: 102,
      bodyTempC: 37.4,
      activityLabel: 'Climbing stairs',
    );
    generated[23] = generated[23].copyWith(
      heartRateBpm: 96,
      spo2Percent: 92,
      bodyTempC: 37.2,
      activityLabel: 'Walking',
    );
    return generated;
  }

  static HealthSnapshot latestSnapshot() {
    final latest = telemetrySamples().last;
    return HealthSnapshot(
      deviceId: latest.deviceId,
      timestamp: latest.timestamp,
      heartRateBpm: latest.heartRateBpm,
      spo2Percent: latest.spo2Percent,
      bodyTempC: latest.bodyTempC,
      activityLabel: latest.activityLabel,
      signalQuality: latest.signalQuality,
      overallStatus: 'Warning',
      isAnomaly: true,
      summary: 'Heart rate elevated, SpO2 low. Rest recommended.',
    );
  }

  static List<ReportSummary> summaries() {
    return const [
      ReportSummary(
        title: 'Daily Summary',
        periodLabel: 'Today',
        averageHeartRate: 78.4,
        averageSpo2: 96.7,
        averageTemperature: 36.8,
        activeMinutes: 86,
        note: 'Vitals remained stable with one oxygen dip after exertion.',
      ),
      ReportSummary(
        title: 'Weekly Summary',
        periodLabel: 'Last 7 Days',
        averageHeartRate: 76.9,
        averageSpo2: 97.2,
        averageTemperature: 36.7,
        activeMinutes: 512,
        note:
            'Activity trend improved and recovery periods remained consistent.',
      ),
    ];
  }

  static List<InsightResult> insights() {
    return const [
      InsightResult(
        title: 'Risk Detection',
        category: 'Risk',
        severity: InsightSeverity.moderate,
        confidence: 0.82,
        summary:
            'Temperature and heart rate increased together during movement.',
        suggestion: 'Hydrate and repeat the reading after a short rest window.',
      ),
      InsightResult(
        title: 'Activity Recognition',
        category: 'Activity',
        severity: InsightSeverity.low,
        confidence: 0.91,
        summary:
            'Recent motion pattern matches light walking and stair climbing.',
        suggestion: 'Keep your pacing steady to maintain safe oxygen levels.',
      ),
      InsightResult(
        title: 'Disease Prediction',
        category: 'Prediction',
        severity: InsightSeverity.low,
        confidence: 0.68,
        summary:
            'Phase-1 placeholder model sees no strong short-term risk pattern.',
        suggestion:
            'Continue collecting data for more personalized predictions.',
      ),
    ];
  }

  static List<AlertEvent> alerts() {
    final now = DateTime.now();
    return [
      AlertEvent(
        id: 'alert-spo2',
        title: 'SpO2 below normal detected',
        message: 'Check breathing and rest.',
        severity: AlertSeverity.high,
        timestamp: now.subtract(const Duration(minutes: 25)),
        category: 'Vitals',
        isAcknowledged: false,
      ),
      AlertEvent(
        id: 'alert-step',
        title: 'Step goal completed',
        message: 'You have crossed today\'s walking target.',
        severity: AlertSeverity.low,
        timestamp: now.subtract(const Duration(minutes: 10)),
        category: 'Activity',
        isAcknowledged: true,
      ),
      AlertEvent(
        id: 'alert-reminder',
        title: 'Medication reminder active',
        message: 'Evening vitamin reminder is scheduled for 8:30 PM.',
        severity: AlertSeverity.medium,
        timestamp: now.subtract(const Duration(hours: 2)),
        category: 'Reminder',
        isAcknowledged: false,
      ),
    ];
  }

  static List<MedicationReminder> reminders() {
    return const [
      MedicationReminder(
        id: 'reminder-morning',
        title: 'Morning medicine',
        dosage: '1 tablet after breakfast',
        hour: 9,
        minute: 0,
        enabled: true,
      ),
      MedicationReminder(
        id: 'reminder-evening',
        title: 'Evening vitamin',
        dosage: '1 capsule after dinner',
        hour: 20,
        minute: 30,
        enabled: true,
      ),
    ];
  }

  static UserProfile userProfile() {
    return const UserProfile(
      name: 'John Doe',
      age: 25,
      gender: 'Male',
      heightCm: 175,
      weightKg: 70,
      emergencyContact: '0987654321',
    );
  }

  static DeviceProfile deviceProfile() {
    return DeviceProfile(
      deviceName: 'Health Monitor',
      deviceId: 'ESP32-HMS-01',
      firmwareVersion: '0.9.4-beta',
      batteryLevel: 100,
      connectionMode: 'Connected',
      lastSyncedAt: DateTime.now().subtract(const Duration(minutes: 4)),
    );
  }

  static AppSettings settings() => AppSettings.defaults();
}
