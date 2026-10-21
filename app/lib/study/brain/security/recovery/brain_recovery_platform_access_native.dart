import '../../devices/security/brain_device_local_secrets.dart';
import '../../devices/security/brain_device_secure_storage.dart';
import '../keys/brain_key_service.dart';
import '../keys/brain_platform_key_storage.dart';

Future<BrainDeviceLocalSecrets?> loadBrainRecoveryLocalDevice() {
  return PlatformBrainDeviceSecureStorage().load();
}

BrainKeyService createBrainRecoveryKeyService() {
  return BrainKeyService(storage: BrainPlatformKeyStorage());
}
