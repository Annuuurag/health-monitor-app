class AppSettings {
  const AppSettings({
    required this.notificationsEnabled,
    required this.darkMode,
    required this.privacyMode,
  });

  final bool notificationsEnabled;
  final bool darkMode;
  final bool privacyMode;

  factory AppSettings.defaults() {
    return const AppSettings(
      notificationsEnabled: true,
      darkMode: false,
      privacyMode: false,
    );
  }

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? darkMode,
    bool? privacyMode,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      privacyMode: privacyMode ?? this.privacyMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'darkMode': darkMode,
      'privacyMode': privacyMode,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? false,
      privacyMode: json['privacyMode'] as bool? ?? false,
    );
  }
}
