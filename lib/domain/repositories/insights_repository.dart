import '../models/health_snapshot.dart';
import '../models/insight_result.dart';

abstract class InsightsRepository {
  Future<List<InsightResult>> getInsights(HealthSnapshot snapshot);
  Future<InsightResult> predictHeartDisease(Map<String, dynamic> clinicalData);
}
