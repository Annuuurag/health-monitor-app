import '../models/health_snapshot.dart';
import '../models/telemetry_sample.dart';

abstract class TelemetryRepository {
  Future<HealthSnapshot> getLatestSnapshot();

  Future<List<TelemetrySample>> getRecentSamples();
}
