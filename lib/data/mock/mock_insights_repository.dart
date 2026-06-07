import '../../domain/models/health_snapshot.dart';
import '../../domain/models/insight_result.dart';
import '../../domain/repositories/insights_repository.dart';
import 'mock_seed_data.dart';

class MockInsightsRepository implements InsightsRepository {
  @override
  Future<List<InsightResult>> getInsights(HealthSnapshot snapshot) async {
    return MockSeedData.insights();
  }

  @override
  Future<InsightResult> predictHeartDisease(Map<String, dynamic> clinicalData) async {
    await Future.delayed(const Duration(seconds: 1));
    return const InsightResult(
      title: 'AI Heart Disease Assessment',
      category: 'Heart Health',
      severity: InsightSeverity.moderate,
      confidence: 0.45,
      summary: 'Moderate Risk (45.0% Probability) predicted based on your clinical inputs.',
      suggestion: 'Biometrics fall in a moderate risk zone. Consider updating diet, monitoring blood pressure daily, and discussing these vitals with your practitioner.',
    );
  }
}
