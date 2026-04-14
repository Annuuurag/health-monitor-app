import '../models/alert_event.dart';

abstract class AlertsRepository {
  Future<List<AlertEvent>> getAlerts();

  Future<void> acknowledgeAlert(String alertId);
}
