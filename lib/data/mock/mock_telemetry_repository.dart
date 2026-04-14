import '../../domain/models/health_snapshot.dart';
import '../../domain/models/telemetry_sample.dart';
import '../../domain/repositories/telemetry_repository.dart';
import 'mock_seed_data.dart';

class MockTelemetryRepository implements TelemetryRepository {
  @override
  Future<HealthSnapshot> getLatestSnapshot() async {
    return MockSeedData.latestSnapshot();
  }

  @override
  Future<List<TelemetrySample>> getRecentSamples() async {
    return MockSeedData.telemetrySamples();
  }
}
