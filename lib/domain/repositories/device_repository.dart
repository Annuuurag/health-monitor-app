import '../models/device_profile.dart';

abstract class DeviceRepository {
  Future<DeviceProfile> getDeviceProfile();

  Future<void> saveDeviceProfile(DeviceProfile profile);
}
