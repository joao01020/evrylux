class BrainDeviceKeyEnvelope {
  const BrainDeviceKeyEnvelope({
    required this.envelopeId,
    required this.vaultId,
    required this.senderDeviceId,
    required this.targetDeviceId,
    required this.senderPublicKeyBase64,
    required this.nonceBase64,
    required this.cipherTextBase64,
    required this.macBase64,
    required this.keyVersion,
    required this.createdAt,
  });

  final String envelopeId;
  final String vaultId;
  final String senderDeviceId;
  final String targetDeviceId;
  final String senderPublicKeyBase64;
  final String nonceBase64;
  final String cipherTextBase64;
  final String macBase64;
  final int keyVersion;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'envelope_id': envelopeId,
    'vault_id': vaultId,
    'sender_device_id': senderDeviceId,
    'target_device_id': targetDeviceId,
    'sender_public_key_b64': senderPublicKeyBase64,
    'nonce_b64': nonceBase64,
    'ciphertext_b64': cipherTextBase64,
    'mac_b64': macBase64,
    'key_version': keyVersion,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  factory BrainDeviceKeyEnvelope.fromMap(Map<String, dynamic> map) {
    final created = DateTime.tryParse(map['created_at']?.toString() ?? '');
    final version = int.tryParse(map['key_version']?.toString() ?? '') ?? 0;
    String s(String k) => map[k]?.toString().trim() ?? '';
    if (created == null ||
        version <= 0 ||
        [
          'envelope_id',
          'vault_id',
          'sender_device_id',
          'target_device_id',
          'sender_public_key_b64',
          'nonce_b64',
          'ciphertext_b64',
          'mac_b64',
        ].any((k) => s(k).isEmpty)) {
      throw const FormatException('BrainDeviceKeyEnvelope inválido.');
    }
    return BrainDeviceKeyEnvelope(
      envelopeId: s('envelope_id'),
      vaultId: s('vault_id'),
      senderDeviceId: s('sender_device_id'),
      targetDeviceId: s('target_device_id'),
      senderPublicKeyBase64: s('sender_public_key_b64'),
      nonceBase64: s('nonce_b64'),
      cipherTextBase64: s('ciphertext_b64'),
      macBase64: s('mac_b64'),
      keyVersion: version,
      createdAt: created.toUtc(),
    );
  }
}
