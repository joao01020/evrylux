import '../models/brain_device_identity.dart';
import '../security/brain_device_crypto_service.dart';
import '../security/brain_device_local_secrets.dart';
import '../security/brain_device_secure_storage.dart';

class BrainDeviceIdentityService {
  BrainDeviceIdentityService({
    required BrainDeviceSecureStorage storage,
    BrainDeviceCryptoService? cryptoService,
  }) : _storage = storage,
       _cryptoService = cryptoService ?? BrainDeviceCryptoService();

  final BrainDeviceSecureStorage _storage;
  final BrainDeviceCryptoService _cryptoService;

  Future<BrainDeviceLocalSecrets> getOrCreateLocalSecrets({
    required String deviceName,
  }) async {
    final existing = await _storage.load();
    if (existing != null) return existing;
    final created = await _cryptoService.generateLocalSecrets(
      deviceName: deviceName,
    );
    await _storage.save(created);
    return created;
  }

  Future<BrainDeviceLocalSecrets?> loadLocalSecrets() => _storage.load();

  Future<BrainDeviceIdentity?> loadPublicIdentity() async {
    final value = await _storage.load();
    if (value == null) return null;
    return BrainDeviceIdentity(
      deviceId: value.deviceId,
      deviceName: value.deviceName,
      publicKeyBase64: value.publicKeyBase64,
      keyFingerprint: value.keyFingerprint,
      createdAt: value.createdAt,
    );
  }

  Future<void> clearLocalIdentity() => _storage.clear();
}
