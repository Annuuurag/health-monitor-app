class DeviceProfile {
  const DeviceProfile({
    required this.deviceName,
    required this.deviceId,
    required this.firmwareVersion,
    required this.batteryLevel,
    required this.connectionMode,
    required this.lastSyncedAt,
  });

  final String deviceName;
  final String deviceId;
  final String firmwareVersion;
  final int batteryLevel;
  final String connectionMode;
  final DateTime lastSyncedAt;

  factory DeviceProfile.defaults() {
    return DeviceProfile(
      deviceName: 'PulseBand Prototype',
      deviceId: 'ESP32-HMS-01',
      firmwareVersion: '0.9.4-beta',
      batteryLevel: 78,
      connectionMode: 'Cloud Sync',
      lastSyncedAt: DateTime.now(),
    );
  }

  DeviceProfile copyWith({
    String? deviceName,
    String? deviceId,
    String? firmwareVersion,
    int? batteryLevel,
    String? connectionMode,
    DateTime? lastSyncedAt,
  }) {
    return DeviceProfile(
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      connectionMode: connectionMode ?? this.connectionMode,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceName': deviceName,
      'deviceId': deviceId,
      'firmwareVersion': firmwareVersion,
      'batteryLevel': batteryLevel,
      'connectionMode': connectionMode,
      'lastSyncedAt': lastSyncedAt.toIso8601String(),
    };
  }

  factory DeviceProfile.fromJson(Map<String, dynamic> json) {
    return DeviceProfile(
      deviceName: json['deviceName'] as String? ?? 'PulseBand Prototype',
      deviceId: json['deviceId'] as String? ?? 'ESP32-HMS-01',
      firmwareVersion: json['firmwareVersion'] as String? ?? '0.9.4-beta',
      batteryLevel: json['batteryLevel'] as int? ?? 78,
      connectionMode: json['connectionMode'] as String? ?? 'Cloud Sync',
      lastSyncedAt:
          DateTime.tryParse(json['lastSyncedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
