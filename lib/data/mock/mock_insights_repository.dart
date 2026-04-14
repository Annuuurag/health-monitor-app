import '../../domain/models/health_snapshot.dart';
import '../../domain/models/insight_result.dart';
import '../../domain/repositories/insights_repository.dart';
import 'mock_seed_data.dart';

class MockInsightsRepository implements InsightsRepository {
  @override
  Future<List<InsightResult>> getInsights(HealthSnapshot snapshot) async {
    return MockSeedData.insights();
  }
}
