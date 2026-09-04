import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/devices/security/brain_device_crypto_service.dart';

void main() {
  group(
    'BrainDeviceCryptoService',
    () {
      final service = BrainDeviceCryptoService();

      test(
        'gera identidades diferentes',
        () async {
          final a = await service.generateLocalSecrets(
            deviceName: 'A',
          );

          final b = await service.generateLocalSecrets(
            deviceName: 'B',
          );

          expect(
            a.deviceId,
            isNot(
              b.deviceId,
            ),
          );

          expect(
            a.publicKeyBase64,
            isNot(
              b.publicKeyBase64,
            ),
          );

          expect(
            a.keyFingerprint,
            isNotEmpty,
          );

          expect(
            b.keyFingerprint,
            isNotEmpty,
          );
        },
      );

      test(
        'wrap e unwrap preservam Master Key',
        () async {
          final sender = await service.generateLocalSecrets(
            deviceName: 'Sender',
          );

          final target = await service.generateLocalSecrets(
            deviceName: 'Target',
          );

          final masterKey = List<int>.generate(
            32,
            (
              index,
            ) {
              return index;
            },
          );

          final recoveryExpiresAt = DateTime.now()
              .toUtc()
              .add(
                const Duration(
                  minutes: 10,
                ),
              );

          final envelope = await service.wrapMasterKey(
            sender: sender,
            targetDeviceId: target.deviceId,
            targetPublicKeyBase64: target.publicKeyBase64,
            targetKeyFingerprint: target.keyFingerprint,
            recoveryRequestId: 'request_test_001',
            recoveryExpiresAt: recoveryExpiresAt,
            vaultId: 'vault_test',
            keyVersion: 1,
            masterKeyBytes: masterKey,
          );

          final recovered = await service.unwrapMasterKey(
            target: target,
            envelope: envelope,
          );

          expect(
            recovered,
            masterKey,
          );
        },
      );

      test(
        'dispositivo errado não abre envelope',
        () async {
          final sender = await service.generateLocalSecrets(
            deviceName: 'Sender',
          );

          final target = await service.generateLocalSecrets(
            deviceName: 'Target',
          );

          final attacker = await service.generateLocalSecrets(
            deviceName: 'Attacker',
          );

          final recoveryExpiresAt = DateTime.now()
              .toUtc()
              .add(
                const Duration(
                  minutes: 10,
                ),
              );

          final envelope = await service.wrapMasterKey(
            sender: sender,
            targetDeviceId: target.deviceId,
            targetPublicKeyBase64: target.publicKeyBase64,
            targetKeyFingerprint: target.keyFingerprint,
            recoveryRequestId: 'request_test_002',
            recoveryExpiresAt: recoveryExpiresAt,
            vaultId: 'vault_test',
            keyVersion: 1,
            masterKeyBytes: List<int>.filled(
              32,
              7,
            ),
          );

          expect(
            () {
              return service.unwrapMasterKey(
                target: attacker,
                envelope: envelope,
              );
            },
            throwsStateError,
          );
        },
      );

      test(
        'request expirado não permite criar envelope',
        () async {
          final sender = await service.generateLocalSecrets(
            deviceName: 'Sender',
          );

          final target = await service.generateLocalSecrets(
            deviceName: 'Target',
          );

          final recoveryExpiresAt = DateTime.now()
              .toUtc()
              .subtract(
                const Duration(
                  seconds: 1,
                ),
              );

          expect(
            () {
              return service.wrapMasterKey(
                sender: sender,
                targetDeviceId: target.deviceId,
                targetPublicKeyBase64: target.publicKeyBase64,
                targetKeyFingerprint: target.keyFingerprint,
                recoveryRequestId: 'request_expired',
                recoveryExpiresAt: recoveryExpiresAt,
                vaultId: 'vault_test',
                keyVersion: 1,
                masterKeyBytes: List<int>.filled(
                  32,
                  1,
                ),
              );
            },
            throwsStateError,
          );
        },
      );
    },
  );
}
