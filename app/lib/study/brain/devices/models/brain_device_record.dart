import 'brain_device_status.dart';

class BrainDeviceRecord {
  const BrainDeviceRecord({
    required this.deviceId,
    required this.vaultId,
    required this.deviceName,
    required this.publicKeyBase64,
    required this.keyFingerprint,
    required this.status,
    required this.createdAt,
    this.authorizedAt,
    this.revokedAt,
    this.lastSeenAt,
    this.recoveryRequestId,
    this.recoveryExpiresAt,
  });

  final String deviceId;
  final String vaultId;
  final String deviceName;
  final String publicKeyBase64;
  final String keyFingerprint;
  final BrainDeviceStatus status;
  final DateTime createdAt;
  final DateTime? authorizedAt;
  final DateTime? revokedAt;
  final DateTime? lastSeenAt;

  /// Server-generated nonce that binds one recovery attempt end-to-end.
  final String? recoveryRequestId;

  /// Recovery requests are short lived. Approval must happen before this time.
  final DateTime? recoveryExpiresAt;

  bool get isAuthorized => status == BrainDeviceStatus.authorized;
  bool get isPending => status == BrainDeviceStatus.pending;
  bool get isRevoked => status == BrainDeviceStatus.revoked;

  bool get isRecoveryExpired {
    final expiresAt = recoveryExpiresAt;

    if (expiresAt == null) {
      return false;
    }

    return !expiresAt.isAfter(DateTime.now().toUtc());
  }

  factory BrainDeviceRecord.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString())?.toUtc();

    final createdAt = parseDate(map['created_at']);
    final deviceId = map['device_id']?.toString().trim() ?? '';
    final vaultId = map['vault_id']?.toString().trim() ?? '';
    final name = map['device_name']?.toString().trim() ?? '';
    final pub = map['public_key_b64']?.toString().trim() ?? '';
    final fp = map['key_fingerprint']?.toString().trim() ?? '';
    final requestId = map['recovery_request_id']?.toString().trim();

    if (createdAt == null ||
        deviceId.isEmpty ||
        vaultId.isEmpty ||
        name.isEmpty ||
        pub.isEmpty ||
        fp.isEmpty) {
      throw const FormatException('BrainDeviceRecord inválido.');
    }

    return BrainDeviceRecord(
      deviceId: deviceId,
      vaultId: vaultId,
      deviceName: name,
      publicKeyBase64: pub,
      keyFingerprint: fp,
      status: BrainDeviceStatus.fromString(map['status']?.toString() ?? ''),
      createdAt: createdAt,
      authorizedAt: parseDate(map['authorized_at']),
      revokedAt: parseDate(map['revoked_at']),
      lastSeenAt: parseDate(map['last_seen_at']),
      recoveryRequestId:
          requestId == null || requestId.isEmpty ? null : requestId,
      recoveryExpiresAt: parseDate(map['recovery_expires_at']),
    );
  }
}
