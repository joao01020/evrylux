import '../../../../web_app/services/web_brain_secure_storage.dart';
import '../../devices/security/brain_device_local_secrets.dart';
import '../keys/brain_key_service.dart';

Future<BrainDeviceLocalSecrets?> loadBrainRecoveryLocalDevice() {
  return WebBrainSecureStorage().loadDevice();
}

BrainKeyService createBrainRecoveryKeyService() {
  return BrainKeyService(storage: WebBrainSecureStorage());
}
