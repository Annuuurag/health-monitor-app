import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

import '../../domain/models/health_snapshot.dart';
import '../../domain/models/telemetry_sample.dart';
import '../../domain/repositories/telemetry_repository.dart';
import '../mock/mock_seed_data.dart';

class ApiTelemetryRepository implements TelemetryRepository {
  final String apiUrl =
      'https://vfeh40pll0.execute-api.ap-south-1.amazonaws.com/Prod/telemetry';

  // ── Response cache: reuse the same API response for both
  // getLatestSnapshot() and getRecentSamples() within the same poll cycle.
  // This eliminates the double Lambda cold-start on every 4-second tick.
  Map<String, dynamic>? _cachedResponse;
  DateTime? _cacheTime;
  static const _cacheDuration = Duration(seconds: 3);

  Future<Map<String, dynamic>?> _fetchRaw() async {
    final now = DateTime.now();
    if (_cachedResponse != null &&
        _cacheTime != null &&
        now.difference(_cacheTime!) < _cacheDuration) {
      return _cachedResponse;
    }

    try {
      final uri = Uri.parse(
          '$apiUrl?deviceId=esp32-user-1&_t=${now.millisecondsSinceEpoch}');
      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        _cachedResponse = data;
        _cacheTime = now;
        return data;
      }
    } catch (e) {
      developer.log('ApiTelemetryRepository._fetchRaw error: $e');
    }
    return null;
  }

  @override
  Future<HealthSnapshot> getLatestSnapshot() async {
    if (apiUrl.isEmpty) return MockSeedData.latestSnapshot();

    final data = await _fetchRaw();
    if (data != null) {
      final s = data['snapshot'] as Map<String, dynamic>?;
      if (s != null) {
        try {
          return HealthSnapshot(
            deviceId: s['deviceId'] as String,
            timestamp: DateTime.parse(s['timestamp'] as String),
            heartRateBpm: (s['heartRateBpm'] as num).toDouble(),
            spo2Percent: (s['spo2Percent'] as num).toDouble(),
            bodyTempC: (s['bodyTempC'] as num).toDouble(),
            activityLabel: s['activityLabel'] as String? ?? 'Resting',
            stepCount: (s['stepCount'] as num?)?.toInt() ?? 0,
            signalQuality: (s['signalQuality'] as num? ?? 0.95).toDouble(),
            overallStatus: s['overallStatus'] as String? ?? 'Normal',
            isAnomaly: s['isAnomaly'] as bool? ?? false,
            summary: s['summary'] as String? ?? 'Vitals look good.',
          );
        } catch (e) {
          developer.log('HealthSnapshot parse error: $e');
        }
      }
    }
    return MockSeedData.latestSnapshot();
  }

  @override
  Future<List<TelemetrySample>> getRecentSamples() async {
    if (apiUrl.isEmpty) return MockSeedData.telemetrySamples();

    final data = await _fetchRaw();
    if (data != null) {
      final samplesData = data['samples'] as List<dynamic>?;
      if (samplesData != null) {
        try {
          return samplesData.map((s) {
            final m = s as Map<String, dynamic>;
            return TelemetrySample(
              deviceId: m['deviceId'] as String,
              timestamp: DateTime.parse(m['timestamp'] as String),
              heartRateBpm: (m['heartRateBpm'] as num).toDouble(),
              spo2Percent: (m['spo2Percent'] as num).toDouble(),
              bodyTempC: (m['bodyTempC'] as num).toDouble(),
              activityLabel: m['activityLabel'] as String? ?? 'Resting',
              stepCount: (m['stepCount'] as num?)?.toInt() ?? 0,
              signalQuality:
                  (m['signalQuality'] as num? ?? 0.95).toDouble(),
              source: m['source'] as String? ?? 'AWS Backend',
            );
          }).toList();
        } catch (e) {
          developer.log('TelemetrySample parse error: $e');
        }
      }
    }
    return MockSeedData.telemetrySamples();
  }
}
