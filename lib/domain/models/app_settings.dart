class AppSettings {
  const AppSettings({
    required this.notificationsEnabled,
    required this.darkMode,
    required this.privacyMode,
    required this.hasCompletedOnboarding,
    required this.isSignedIn,
    required this.hasCompletedPairing,
  });

  final bool notificationsEnabled;
  final bool darkMode;
  final bool privacyMode;
  final bool hasCompletedOnboarding;
  final bool isSignedIn;
  final bool hasCompletedPairing;

  factory AppSettings.defaults() {
    return const AppSettings(
      notificationsEnabled: true,
      darkMode: false,
      privacyMode: false,
      hasCompletedOnboarding: false,
      isSignedIn: false,
      hasCompletedPairing: false,
    );
  }

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? darkMode,
    bool? privacyMode,
    bool? hasCompletedOnboarding,
    bool? isSignedIn,
    bool? hasCompletedPairing,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      privacyMode: privacyMode ?? this.privacyMode,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isSignedIn: isSignedIn ?? this.isSignedIn,
      hasCompletedPairing: hasCompletedPairing ?? this.hasCompletedPairing,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'darkMode': darkMode,
      'privacyMode': privacyMode,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'isSignedIn': isSignedIn,
      'hasCompletedPairing': hasCompletedPairing,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      darkMode: json['darkMode'] as bool? ?? false,
      privacyMode: json['privacyMode'] as bool? ?? false,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      isSignedIn: json['isSignedIn'] as bool? ?? false,
      hasCompletedPairing: json['hasCompletedPairing'] as bool? ?? false,
    );
  }
}
