import '../models/medication_reminder.dart';

abstract class RemindersRepository {
  Future<List<MedicationReminder>> getReminders();

  Future<void> saveReminders(List<MedicationReminder> reminders);
}
