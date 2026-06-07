import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import '../../domain/models/health_snapshot.dart';
import '../../domain/models/insight_result.dart';
import '../../domain/repositories/insights_repository.dart';
import '../mock/mock_seed_data.dart';

class ApiInsightsRepository implements InsightsRepository {
  final String apiUrl = 'https://vfeh40pll0.execute-api.ap-south-1.amazonaws.com/Prod/disease-prediction';

  @override
  Future<List<InsightResult>> getInsights(HealthSnapshot snapshot) async {
    final list = List<InsightResult>.from(MockSeedData.insights());
    if (snapshot.isAnomaly) {
      list.insert(0, InsightResult(
        title: 'PPG Anomaly Alert',
        category: 'Vitals',
        severity: InsightSeverity.high,
        confidence: 0.95,
        summary: 'Recent telemetry ingestion flagged an anomaly pattern in your PPG/vitals.',
        suggestion: snapshot.summary,
      ));
    }
    return list;
  }

  @override
  Future<InsightResult> predictHeartDisease(Map<String, dynamic> clinicalData) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(clinicalData),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prob = (data['riskProbability'] as num).toDouble();
        final pct = (data['riskPercentage'] as num).toDouble();
        final label = data['riskLabel'] as String;
        final suggestion = data['suggestion'] as String;
        
        final severity = switch (label.toLowerCase()) {
          'high risk' => InsightSeverity.high,
          'moderate risk' => InsightSeverity.moderate,
          _ => InsightSeverity.low,
        };
        
        return InsightResult(
          title: 'AI Heart Disease Assessment',
          category: 'Heart Health',
          severity: severity,
          confidence: prob,
          summary: '$label ($pct% Probability) predicted based on your clinical inputs.',
          suggestion: suggestion,
        );
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error calling disease prediction API: $e');
      rethrow;
    }
  }
}
