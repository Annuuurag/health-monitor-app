import '../../domain/models/app_settings.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../local/local_storage.dart';
import 'mock_seed_data.dart';

class MockProfileRepository implements ProfileRepository {
  MockProfileRepository(this._storage);

  final LocalStorage _storage;

  @override
  Future<AppSettings> getSettings() async {
    final stored = await _storage.readJson(_storage.settingsKey);
    if (stored == null) {
      final seeded = MockSeedData.settings();
      await saveSettings(seeded);
      return seeded;
    }
    return AppSettings.fromJson(stored);
  }

  @override
  Future<UserProfile> getUserProfile() async {
    final stored = await _storage.readJson(_storage.userProfileKey);
    if (stored == null) {
      final seeded = MockSeedData.userProfile();
      await saveUserProfile(seeded);
      return seeded;
    }
    return UserProfile.fromJson(stored);
  }

  @override
  Future<void> saveSettings(AppSettings settings) {
    return _storage.writeJson(_storage.settingsKey, settings.toJson());
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) {
    return _storage.writeJson(_storage.userProfileKey, profile.toJson());
  }
}
