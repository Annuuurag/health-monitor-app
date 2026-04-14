import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../domain/models/medication_reminder.dart';

abstract class NotificationService {
  Future<void> initialize();

  Future<void> scheduleReminder(MedicationReminder reminder);

  Future<void> cancelAllReminderNotifications();
}

class LocalNotificationService implements NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  @override
  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  @override
  Future<void> cancelAllReminderNotifications() async {
    await _plugin.cancelAll();
  }

  @override
  Future<void> scheduleReminder(MedicationReminder reminder) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _notificationId(reminder.id),
      reminder.title,
      reminder.dosage,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication-reminders',
          'Medication Reminders',
          channelDescription: 'Scheduled reminders for medications and care.',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  int _notificationId(String reminderId) {
    return reminderId.codeUnits.fold<int>(0, (sum, code) => sum + code);
  }
}

class NoopNotificationService implements NotificationService {
  @override
  Future<void> cancelAllReminderNotifications() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleReminder(MedicationReminder reminder) async {}
}
