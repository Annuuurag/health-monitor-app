import '../models/app_settings.dart';
import '../models/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile> getUserProfile();

  Future<void> saveUserProfile(UserProfile profile);

  Future<AppSettings> getSettings();

  Future<void> saveSettings(AppSettings settings);
}
