import '../../domain/models/device_profile.dart';
import '../../domain/repositories/device_repository.dart';
import '../local/local_storage.dart';
import 'mock_seed_data.dart';

class MockDeviceRepository implements DeviceRepository {
  MockDeviceRepository(this._storage);

  final LocalStorage _storage;

  @override
  Future<DeviceProfile> getDeviceProfile() async {
    final stored = await _storage.readJson(_storage.deviceProfileKey);
    if (stored == null) {
      final seeded = MockSeedData.deviceProfile();
      await saveDeviceProfile(seeded);
      return seeded;
    }
    return DeviceProfile.fromJson(stored);
  }

  @override
  Future<void> saveDeviceProfile(DeviceProfile profile) {
    return _storage.writeJson(_storage.deviceProfileKey, profile.toJson());
  }
}
