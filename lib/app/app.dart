import 'package:flutter/material.dart';

import '../data/local/local_storage.dart';
import '../data/mock/mock_alerts_repository.dart';
import '../data/mock/mock_device_repository.dart';
import '../data/mock/mock_insights_repository.dart';
import '../data/mock/mock_profile_repository.dart';
import '../data/mock/mock_reminders_repository.dart';
import '../data/mock/mock_reports_repository.dart';
import '../data/api/api_telemetry_repository.dart';
import '../presentation/screens/alerts_screen.dart';
import '../presentation/screens/entry_gate_screen.dart';
import '../services/notification_service.dart';
import 'state/app_controller.dart';
import 'theme/app_theme.dart';

AppController createAppController({NotificationService? notificationService}) {
  final localStorage = LocalStorage();
  return AppController(
    telemetryRepository: ApiTelemetryRepository(),
    reportsRepository: MockReportsRepository(),
    insightsRepository: MockInsightsRepository(),
    alertsRepository: MockAlertsRepository(),
    remindersRepository: MockRemindersRepository(localStorage),
    profileRepository: MockProfileRepository(localStorage),
    deviceRepository: MockDeviceRepository(localStorage),
    notificationService: notificationService ?? LocalNotificationService(),
  );
}

class HealthMonitorApp extends StatefulWidget {
  const HealthMonitorApp({super.key, required this.controller});

  final AppController controller;

  @override
  State<HealthMonitorApp> createState() => _HealthMonitorAppState();
}

class _HealthMonitorAppState extends State<HealthMonitorApp> {
  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'Health Monitor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: !widget.controller.settings.isSignedIn
              ? ThemeMode.light
              : (widget.controller.settings.darkMode
                  ? ThemeMode.dark
                  : ThemeMode.light),
          routes: {
            AlertsScreen.routeName: (context) =>
                AlertsScreen(controller: widget.controller),
          },
          home: EntryGateScreen(controller: widget.controller),
        );
      },
    );
  }
}
