class BrainDeviceKeyEnvelope {
  const BrainDeviceKeyEnvelope({
    required this.envelopeId,
    required this.vaultId,
    required this.senderDeviceId,
    required this.targetDeviceId,
    required this.senderPublicKeyBase64,
    required this.targetKeyFingerprint,
    required this.recoveryRequestId,
    required this.nonceBase64,
    required this.cipherTextBase64,
    required this.macBase64,
    required this.keyVersion,
    required this.createdAt,
    required this.expiresAt,
  });

  final String envelopeId;
  final String vaultId;
  final String senderDeviceId;
  final String targetDeviceId;
  final String senderPublicKeyBase64;
  final String targetKeyFingerprint;
  final String recoveryRequestId;
  final String nonceBase64;
  final String cipherTextBase64;
  final String macBase64;
  final int keyVersion;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isExpired => !expiresAt.isAfter(DateTime.now().toUtc());

  Map<String, dynamic> toMap() => {
    'envelope_id': envelopeId,
    'vault_id': vaultId,
    'sender_device_id': senderDeviceId,
    'target_device_id': targetDeviceId,
    'sender_public_key_b64': senderPublicKeyBase64,
    'target_key_fingerprint': targetKeyFingerprint,
    'recovery_request_id': recoveryRequestId,
    'nonce_b64': nonceBase64,
    'ciphertext_b64': cipherTextBase64,
    'mac_b64': macBase64,
    'key_version': keyVersion,
    'created_at': createdAt.toUtc().toIso8601String(),
    'expires_at': expiresAt.toUtc().toIso8601String(),
  };

  factory BrainDeviceKeyEnvelope.fromMap(Map<String, dynamic> map) {
    String s(String key) => map[key]?.toString().trim() ?? '';

    final created = DateTime.tryParse(s('created_at'));
    final expires = DateTime.tryParse(s('expires_at'));
    final version = int.tryParse(s('key_version')) ?? 0;

    const requiredStrings = <String>[
      'envelope_id',
      'vault_id',
      'sender_device_id',
      'target_device_id',
      'sender_public_key_b64',
      'target_key_fingerprint',
      'recovery_request_id',
      'nonce_b64',
      'ciphertext_b64',
      'mac_b64',
    ];

    if (created == null ||
        expires == null ||
        version <= 0 ||
        requiredStrings.any((key) => s(key).isEmpty)) {
      throw const FormatException('BrainDeviceKeyEnvelope inválido.');
    }

    return BrainDeviceKeyEnvelope(
      envelopeId: s('envelope_id'),
      vaultId: s('vault_id'),
      senderDeviceId: s('sender_device_id'),
      targetDeviceId: s('target_device_id'),
      senderPublicKeyBase64: s('sender_public_key_b64'),
      targetKeyFingerprint: s('target_key_fingerprint'),
      recoveryRequestId: s('recovery_request_id'),
      nonceBase64: s('nonce_b64'),
      cipherTextBase64: s('ciphertext_b64'),
      macBase64: s('mac_b64'),
      keyVersion: version,
      createdAt: created.toUtc(),
      expiresAt: expires.toUtc(),
    );
  }
}
