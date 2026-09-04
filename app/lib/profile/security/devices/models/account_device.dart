class AccountDevice {
  const AccountDevice({
    required this.id,
    required this.userId,
    required this.sessionId,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.appVersion,
    required this.createdAt,
    required this.lastSeenAt,
    required this.revokedAt,
    required this.endedAt,
  });

  final String id;
  final String userId;
  final String sessionId;
  final String deviceId;
  final String deviceName;
  final String platform;
  final String? appVersion;
  final DateTime createdAt;
  final DateTime lastSeenAt;
  final DateTime? revokedAt;
  final DateTime? endedAt;

  bool get isRevoked => revokedAt != null;

  bool get isEnded => endedAt != null;

  bool get isActive =>
      !isRevoked &&
      !isEnded;

  factory AccountDevice.fromMap(
    Map<String, dynamic> map,
  ) {
    String requireString(
      String key,
    ) {
      final value = map[key];

      if (value is String &&
          value.trim().isNotEmpty) {
        return value;
      }

      throw FormatException(
        'Campo inválido em AccountDevice: $key',
      );
    }

    DateTime requireDate(
      String key,
    ) {
      final raw = requireString(
        key,
      );

      final parsed = DateTime.tryParse(
        raw,
      );

      if (parsed == null) {
        throw FormatException(
          'Data inválida em AccountDevice: $key',
        );
      }

      return parsed.toLocal();
    }

    DateTime? optionalDate(
      String key,
    ) {
      final value = map[key];

      if (value == null) {
        return null;
      }

      if (value is! String) {
        throw FormatException(
          'Data inválida em AccountDevice: $key',
        );
      }

      final parsed = DateTime.tryParse(
        value,
      );

      if (parsed == null) {
        throw FormatException(
          'Data inválida em AccountDevice: $key',
        );
      }

      return parsed.toLocal();
    }

    final rawAppVersion = map['app_version'];

    return AccountDevice(
      id: requireString(
        'id',
      ),
      userId: requireString(
        'user_id',
      ),
      sessionId: requireString(
        'session_id',
      ),
      deviceId: requireString(
        'device_id',
      ),
      deviceName: requireString(
        'device_name',
      ),
      platform: requireString(
        'platform',
      ),
      appVersion: rawAppVersion is String &&
              rawAppVersion.trim().isNotEmpty
          ? rawAppVersion
          : null,
      createdAt: requireDate(
        'created_at',
      ),
      lastSeenAt: requireDate(
        'last_seen_at',
      ),
      revokedAt: optionalDate(
        'revoked_at',
      ),
      endedAt: optionalDate(
        'ended_at',
      ),
    );
  }
}
