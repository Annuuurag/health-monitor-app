import '../../domain/models/medication_reminder.dart';
import '../../domain/repositories/reminders_repository.dart';
import '../local/local_storage.dart';
import 'mock_seed_data.dart';

class MockRemindersRepository implements RemindersRepository {
  MockRemindersRepository(this._storage);

  final LocalStorage _storage;

  @override
  Future<List<MedicationReminder>> getReminders() async {
    final stored = await _storage.readJsonList(_storage.remindersKey);
    if (stored == null) {
      final seeded = MockSeedData.reminders();
      await saveReminders(seeded);
      return seeded;
    }
    return stored
        .map((item) => MedicationReminder.fromJson(item))
        .toList(growable: false);
  }

  @override
  Future<void> saveReminders(List<MedicationReminder> reminders) {
    return _storage.writeJsonList(
      _storage.remindersKey,
      reminders.map((reminder) => reminder.toJson()).toList(growable: false),
    );
  }
}
