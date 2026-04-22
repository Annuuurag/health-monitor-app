import 'package:flutter/material.dart';

import '../../domain/models/alert_event.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/device_profile.dart';
import '../../domain/models/health_snapshot.dart';
import '../../domain/models/insight_result.dart';
import '../../domain/models/medication_reminder.dart';
import '../../domain/models/report_summary.dart';
import '../../domain/models/telemetry_sample.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/repositories/insights_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/repositories/reminders_repository.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../domain/repositories/telemetry_repository.dart';
import '../../services/notification_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this.telemetryRepository,
    required this.reportsRepository,
    required this.insightsRepository,
    required this.alertsRepository,
    required this.remindersRepository,
    required this.profileRepository,
    required this.deviceRepository,
    required this.notificationService,
  });

  final TelemetryRepository telemetryRepository;
  final ReportsRepository reportsRepository;
  final InsightsRepository insightsRepository;
  final AlertsRepository alertsRepository;
  final RemindersRepository remindersRepository;
  final ProfileRepository profileRepository;
  final DeviceRepository deviceRepository;
  final NotificationService notificationService;

  bool _isLoading = true;
  bool _initialized = false;
  String? _errorMessage;
  int _selectedTab = 0;

  HealthSnapshot? _snapshot;
  List<TelemetrySample> _samples = const [];
  List<ReportSummary> _reports = const [];
  List<InsightResult> _insights = const [];
  List<AlertEvent> _alerts = const [];
  List<MedicationReminder> _reminders = const [];
  UserProfile _userProfile = UserProfile.defaults();
  DeviceProfile _deviceProfile = DeviceProfile.defaults();
  AppSettings _settings = AppSettings.defaults();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedTab => _selectedTab;
  HealthSnapshot? get snapshot => _snapshot;
  List<TelemetrySample> get samples => _samples;
  List<ReportSummary> get reports => _reports;
  List<InsightResult> get insights => _insights;
  List<AlertEvent> get alerts => _alerts;
  List<MedicationReminder> get reminders => _reminders;
  UserProfile get userProfile => _userProfile;
  DeviceProfile get deviceProfile => _deviceProfile;
  AppSettings get settings => _settings;

  int get activeAlertCount =>
      _alerts.where((alert) => !alert.isAcknowledged).length;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    _setLoading(true);

    try {
      await notificationService.initialize();
      await _loadAll();
      await _syncReminderNotifications();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Failed to initialize the health monitor app.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    _setLoading(true);
    try {
      await _loadAll();
      _errorMessage = null;
    } catch (_) {
      _errorMessage = 'Could not refresh health data right now.';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadAll() async {
    final snapshot = await telemetryRepository.getLatestSnapshot();
    final samples = await telemetryRepository.getRecentSamples();
    final reports = await reportsRepository.getSummaries();
    final alerts = await alertsRepository.getAlerts();
    final reminders = await remindersRepository.getReminders();
    final userProfile = await profileRepository.getUserProfile();
    final deviceProfile = await deviceRepository.getDeviceProfile();
    final settings = await profileRepository.getSettings();
    final insights = await insightsRepository.getInsights(snapshot);

    _snapshot = snapshot;
    _samples = samples;
    _reports = reports;
    _alerts = alerts;
    _reminders = reminders;
    _userProfile = userProfile;
    _deviceProfile = deviceProfile;
    _settings = settings;
    _insights = insights;
    notifyListeners();
  }

  void selectTab(int index) {
    if (_selectedTab == index) {
      return;
    }
    _selectedTab = index;
    notifyListeners();
  }

  Future<void> acknowledgeAlert(String alertId) async {
    await alertsRepository.acknowledgeAlert(alertId);
    _alerts = await alertsRepository.getAlerts();
    notifyListeners();
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    _userProfile = profile;
    await profileRepository.saveUserProfile(profile);
    notifyListeners();
  }

  Future<void> updateDeviceProfile(DeviceProfile profile) async {
    _deviceProfile = profile;
    await deviceRepository.saveDeviceProfile(profile);
    notifyListeners();
  }

  Future<void> updateTheme(bool enabled) async {
    _settings = _settings.copyWith(darkMode: enabled);
    await profileRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> updateNotifications(bool enabled) async {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    await profileRepository.saveSettings(_settings);
    await _syncReminderNotifications();
    notifyListeners();
  }

  Future<void> updatePrivacyMode(bool enabled) async {
    _settings = _settings.copyWith(privacyMode: enabled);
    await profileRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _settings = _settings.copyWith(hasCompletedOnboarding: true);
    await profileRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> signIn() async {
    _settings = _settings.copyWith(isSignedIn: true);
    await profileRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> signOut() async {
    _settings = _settings.copyWith(isSignedIn: false);
    await profileRepository.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> completePairing(String connectionMode) async {
    _settings = _settings.copyWith(hasCompletedPairing: true);
    _deviceProfile = _deviceProfile.copyWith(
      connectionMode: connectionMode,
      lastSyncedAt: DateTime.now(),
    );
    await profileRepository.saveSettings(_settings);
    await deviceRepository.saveDeviceProfile(_deviceProfile);
    notifyListeners();
  }

  Future<void> toggleReminder(String reminderId, bool enabled) async {
    _reminders = _reminders
        .map(
          (reminder) => reminder.id == reminderId
              ? reminder.copyWith(enabled: enabled)
              : reminder,
        )
        .toList(growable: false);
    await remindersRepository.saveReminders(_reminders);
    await _syncReminderNotifications();
    notifyListeners();
  }

  Future<void> updateReminderTime(String reminderId, TimeOfDay time) async {
    _reminders = _reminders
        .map(
          (reminder) => reminder.id == reminderId
              ? reminder.copyWith(hour: time.hour, minute: time.minute)
              : reminder,
        )
        .toList(growable: false);
    await remindersRepository.saveReminders(_reminders);
    await _syncReminderNotifications();
    notifyListeners();
  }

  Future<void> _syncReminderNotifications() async {
    await notificationService.cancelAllReminderNotifications();
    if (!_settings.notificationsEnabled) {
      return;
    }

    for (final reminder in _reminders.where((item) => item.enabled)) {
      await notificationService.scheduleReminder(reminder);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
