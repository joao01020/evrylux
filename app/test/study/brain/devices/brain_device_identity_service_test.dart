import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/devices/security/brain_device_secure_storage.dart';
import 'package:EVRYLUX/study/brain/devices/services/brain_device_identity_service.dart';

void main() {
  test('identidade local é persistida e reutilizada', () async {
    final storage = InMemoryBrainDeviceSecureStorage();
    final service = BrainDeviceIdentityService(storage: storage);

    final first = await service.getOrCreateLocalSecrets(deviceName: 'Apolo');
    final second = await service.getOrCreateLocalSecrets(deviceName: 'Outro');

    expect(first.deviceId, second.deviceId);
    expect(first.privateKeyBase64, second.privateKeyBase64);
    expect(first.authorizationSecretBase64, second.authorizationSecretBase64);
  });
}
