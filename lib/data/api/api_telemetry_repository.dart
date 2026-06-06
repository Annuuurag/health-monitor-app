import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import '../../domain/models/health_snapshot.dart';
import '../../domain/models/telemetry_sample.dart';
import '../../domain/repositories/telemetry_repository.dart';
import '../mock/mock_seed_data.dart';

class ApiTelemetryRepository implements TelemetryRepository {
  final String apiUrl = 'https://vfeh40pll0.execute-api.ap-south-1.amazonaws.com/Prod/telemetry'; 

  @override
  Future<HealthSnapshot> getLatestSnapshot() async {
    if (apiUrl.isEmpty) {
      // Fallback to mock data if URL is not configured
      return MockSeedData.latestSnapshot();
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final snapshotData = data['snapshot'];
        if (snapshotData != null) {
          return HealthSnapshot(
            deviceId: snapshotData['deviceId'],
            timestamp: DateTime.parse(snapshotData['timestamp']),
            heartRateBpm: (snapshotData['heartRateBpm'] as num).toDouble(),
            spo2Percent: (snapshotData['spo2Percent'] as num).toDouble(),
            bodyTempC: (snapshotData['bodyTempC'] as num).toDouble(),
            activityLabel: snapshotData['activityLabel'],
            signalQuality: (snapshotData['signalQuality'] as num).toDouble(),
            overallStatus: snapshotData['overallStatus'],
            isAnomaly: snapshotData['isAnomaly'],
            summary: snapshotData['summary'],
          );
        }
      }
    } catch (e) {
      developer.log('Error fetching latest snapshot from API: $e');
    }
    
    // Fallback to mock data on error
    return MockSeedData.latestSnapshot();
  }

  @override
  Future<List<TelemetrySample>> getRecentSamples() async {
    if (apiUrl.isEmpty) {
      // Fallback to mock data if URL is not configured
      return MockSeedData.telemetrySamples();
    }

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final samplesData = data['samples'] as List<dynamic>?;
        
        if (samplesData != null) {
          return samplesData.map((s) => TelemetrySample(
            deviceId: s['deviceId'],
            timestamp: DateTime.parse(s['timestamp']),
            heartRateBpm: (s['heartRateBpm'] as num).toDouble(),
            spo2Percent: (s['spo2Percent'] as num).toDouble(),
            bodyTempC: (s['bodyTempC'] as num).toDouble(),
            activityLabel: s['activityLabel'],
            signalQuality: (s['signalQuality'] as num).toDouble(),
            source: s['source'],
          )).toList();
        }
      }
    } catch (e) {
      developer.log('Error fetching recent samples from API: $e');
    }
    
    // Fallback to mock data on error
    return MockSeedData.telemetrySamples();
  }
}
