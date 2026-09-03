class BrainDeviceIdentity {
  const BrainDeviceIdentity({
    required this.deviceId,
    required this.deviceName,
    required this.publicKeyBase64,
    required this.keyFingerprint,
    required this.createdAt,
  });

  final String deviceId;
  final String deviceName;
  final String publicKeyBase64;
  final String keyFingerprint;
  final DateTime createdAt;
}
