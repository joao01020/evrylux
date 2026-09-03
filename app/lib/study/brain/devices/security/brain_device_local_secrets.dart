class BrainDeviceLocalSecrets {
  const BrainDeviceLocalSecrets({
    required this.deviceId,
    required this.deviceName,
    required this.privateKeyBase64,
    required this.publicKeyBase64,
    required this.keyFingerprint,
    required this.authorizationSecretBase64,
    required this.createdAt,
  });
  final String deviceId;
  final String deviceName;
  final String privateKeyBase64;
  final String publicKeyBase64;
  final String keyFingerprint;
  final String authorizationSecretBase64;
  final DateTime createdAt;
  Map<String, dynamic> toMap() => {
    'device_id': deviceId,
    'device_name': deviceName,
    'private_key_b64': privateKeyBase64,
    'public_key_b64': publicKeyBase64,
    'key_fingerprint': keyFingerprint,
    'authorization_secret_b64': authorizationSecretBase64,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
  factory BrainDeviceLocalSecrets.fromMap(Map<String, dynamic> map) {
    String s(String k) => map[k]?.toString().trim() ?? '';
    final created = DateTime.tryParse(s('created_at'));
    if (created == null ||
        [
          'device_id',
          'device_name',
          'private_key_b64',
          'public_key_b64',
          'key_fingerprint',
          'authorization_secret_b64',
        ].any((k) => s(k).isEmpty)) {
      throw const FormatException('BrainDeviceLocalSecrets inválido.');
    }
    return BrainDeviceLocalSecrets(
      deviceId: s('device_id'),
      deviceName: s('device_name'),
      privateKeyBase64: s('private_key_b64'),
      publicKeyBase64: s('public_key_b64'),
      keyFingerprint: s('key_fingerprint'),
      authorizationSecretBase64: s('authorization_secret_b64'),
      createdAt: created.toUtc(),
    );
  }
}
