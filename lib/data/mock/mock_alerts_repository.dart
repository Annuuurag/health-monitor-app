import '../../domain/models/alert_event.dart';
import '../../domain/repositories/alerts_repository.dart';
import 'mock_seed_data.dart';

class MockAlertsRepository implements AlertsRepository {
  final List<AlertEvent> _alerts = List<AlertEvent>.from(MockSeedData.alerts());

  @override
  Future<void> acknowledgeAlert(String alertId) async {
    final index = _alerts.indexWhere((alert) => alert.id == alertId);
    if (index == -1) {
      return;
    }
    _alerts[index] = _alerts[index].copyWith(isAcknowledged: true);
  }

  @override
  Future<List<AlertEvent>> getAlerts() async {
    return List<AlertEvent>.unmodifiable(_alerts);
  }
}
