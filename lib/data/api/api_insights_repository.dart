import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import '../../domain/models/health_snapshot.dart';
import '../../domain/models/insight_result.dart';
import '../../domain/repositories/insights_repository.dart';

class ApiInsightsRepository implements InsightsRepository {
  final String apiUrl = 'https://vfeh40pll0.execute-api.ap-south-1.amazonaws.com/Prod/disease-prediction';

  // Static cache to hold the last disease prediction result
  static InsightResult? lastDiseasePrediction;

  @override
  Future<List<InsightResult>> getInsights(HealthSnapshot snapshot) async {
    final List<InsightResult> list = [];

    // 1. Risk Detection (PPG Outlier Anomaly Model)
    final riskSeverity = snapshot.isAnomaly ? InsightSeverity.high : InsightSeverity.low;
    final riskSummary = snapshot.isAnomaly
        ? snapshot.summary
        : 'PPG vitals are stable. No outlier patterns detected by the ML ensemble.';
    final riskSuggestion = snapshot.isAnomaly
        ? 'The anomaly detection ensemble flagged a high-deviation PPG pattern. Rest is advised.'
        : 'Your cardiovascular signals are within healthy baseline limits.';

    list.add(InsightResult(
      title: 'Risk Detection',
      category: 'Risk',
      severity: riskSeverity,
      confidence: snapshot.isAnomaly ? 0.92 : 0.98,
      summary: riskSummary,
      suggestion: riskSuggestion,
    ));

    // 2. Activity Recognition (CNN-BiLSTM Model)
    final activity = snapshot.activityLabel;
    String actSuggestion = 'Resting state helps in cardiac recovery and vital stabilization.';
    if (activity.toLowerCase() == 'walking') {
      actSuggestion = 'Moderate walking detected. Great for keeping your daily active minutes up!';
    } else if (activity.toLowerCase() == 'jogging') {
      actSuggestion = 'Vigorous activity detected. Monitor heart rate to stay in a safe aerobic zone.';
    }

    list.add(InsightResult(
      title: 'Activity Recognition',
      category: 'Activity',
      severity: InsightSeverity.low,
      confidence: 0.94,
      summary: 'Recent motion pattern matches $activity.',
      suggestion: actSuggestion,
    ));

    // 3. Disease Prediction (Voting Ensemble Model)
    if (lastDiseasePrediction != null) {
      list.add(lastDiseasePrediction!);
    } else {
      list.add(const InsightResult(
        title: 'Disease Prediction',
        category: 'Heart Health',
        severity: InsightSeverity.low,
        confidence: 0.0,
        summary: 'No clinical risk assessment has been performed yet.',
        suggestion: 'Complete the survey above to run the Soft-Voting Stacking Ensemble model.',
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
        
        final result = InsightResult(
          title: 'Disease Prediction',
          category: 'Heart Health',
          severity: severity,
          confidence: prob,
          summary: '$label ($pct% Probability) predicted based on your clinical inputs.',
          suggestion: suggestion,
        );

        lastDiseasePrediction = result;
        return result;
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Error calling disease prediction API: $e');
      rethrow;
    }
  }
}
