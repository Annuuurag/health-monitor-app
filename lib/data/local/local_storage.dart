import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static const _userProfileKey = 'user_profile';
  static const _deviceProfileKey = 'device_profile';
  static const _settingsKey = 'app_settings';
  static const _remindersKey = 'medication_reminders';

  Future<Map<String, dynamic>?> readJson(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(key);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    return jsonDecode(rawValue) as Map<String, dynamic>;
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(value));
  }

  Future<List<Map<String, dynamic>>?> readJsonList(String key) async {
    final preferences = await SharedPreferences.getInstance();
    final rawValue = preferences.getString(key);
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(rawValue) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  Future<void> writeJsonList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, jsonEncode(value));
  }

  String get userProfileKey => _userProfileKey;
  String get deviceProfileKey => _deviceProfileKey;
  String get settingsKey => _settingsKey;
  String get remindersKey => _remindersKey;
}
