import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/devices/models/brain_device_key_envelope.dart';
import 'package:EVRYLUX/study/brain/devices/models/brain_device_record.dart';
import 'package:EVRYLUX/study/brain/devices/ports/brain_device_master_key_port.dart';
import 'package:EVRYLUX/study/brain/devices/ports/brain_device_remote_port.dart';
import 'package:EVRYLUX/study/brain/devices/security/brain_device_local_secrets.dart';
import 'package:EVRYLUX/study/brain/devices/security/brain_device_secure_storage.dart';
import 'package:EVRYLUX/study/brain/devices/services/brain_device_gate_service.dart';
import 'package:EVRYLUX/study/brain/devices/services/brain_device_identity_service.dart';

void main() {
  test(
    'gate falha fechado sem identidade local',
    () async {
      final identityService = BrainDeviceIdentityService(
        storage: InMemoryBrainDeviceSecureStorage(),
      );

      final gate = BrainDeviceGateService(
        identityService: identityService,
        remote: _FakeRemote(
          authorized: true,
        ),
        masterKeyPort: _FakeMasterKeyPort(
          hasKey: true,
        ),
      );

      final allowed = await gate.canUseCloud(
        vaultId: 'vault_test',
        isAuthenticated: true,
        dataModeAllowsCloud: true,
      );

      expect(
        allowed,
        false,
      );
    },
  );

  test(
    'gate exige Master Key local',
    () async {
      final storage = InMemoryBrainDeviceSecureStorage();

      final identityService = BrainDeviceIdentityService(
        storage: storage,
      );

      await identityService.getOrCreateLocalSecrets(
        deviceName: 'Apolo',
      );

      final gate = BrainDeviceGateService(
        identityService: identityService,
        remote: _FakeRemote(
          authorized: true,
        ),
        masterKeyPort: _FakeMasterKeyPort(
          hasKey: false,
        ),
      );

      expect(
        await gate.canUseCloud(
          vaultId: 'vault_test',
          isAuthenticated: true,
          dataModeAllowsCloud: true,
        ),
        false,
      );
    },
  );

  test(
    'gate exige auth + cloud + device authorized + Master Key',
    () async {
      final storage = InMemoryBrainDeviceSecureStorage();

      final identityService = BrainDeviceIdentityService(
        storage: storage,
      );

      await identityService.getOrCreateLocalSecrets(
        deviceName: 'Apolo',
      );

      final gate = BrainDeviceGateService(
        identityService: identityService,
        remote: _FakeRemote(
          authorized: true,
        ),
        masterKeyPort: _FakeMasterKeyPort(
          hasKey: true,
        ),
      );

      expect(
        await gate.canUseCloud(
          vaultId: 'vault_test',
          isAuthenticated: false,
          dataModeAllowsCloud: true,
        ),
        false,
      );

      expect(
        await gate.canUseCloud(
          vaultId: 'vault_test',
          isAuthenticated: true,
          dataModeAllowsCloud: false,
        ),
        false,
      );

      expect(
        await gate.canUseCloud(
          vaultId: 'vault_test',
          isAuthenticated: true,
          dataModeAllowsCloud: true,
        ),
        true,
      );
    },
  );

  test(
    'device revogado é bloqueado pelo gate',
    () async {
      final storage = InMemoryBrainDeviceSecureStorage();

      final identityService = BrainDeviceIdentityService(
        storage: storage,
      );

      await identityService.getOrCreateLocalSecrets(
        deviceName: 'Apolo',
      );

      final gate = BrainDeviceGateService(
        identityService: identityService,
        remote: _FakeRemote(
          authorized: false,
        ),
        masterKeyPort: _FakeMasterKeyPort(
          hasKey: true,
        ),
      );

      expect(
        await gate.canUseCloud(
          vaultId: 'vault_test',
          isAuthenticated: true,
          dataModeAllowsCloud: true,
        ),
        false,
      );
    },
  );
}

class _FakeMasterKeyPort implements BrainDeviceMasterKeyPort {
  _FakeMasterKeyPort({
    required this.hasKey,
  });

  final bool hasKey;

  @override
  Future<bool> hasMasterKey({
    required String vaultId,
  }) async {
    return hasKey;
  }

  @override
  Future<List<int>> exportMasterKey({
    required String vaultId,
  }) async {
    return List<int>.filled(
      32,
      1,
    );
  }

  @override
  Future<void> importMasterKey({
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
  }) async {}
}

class _FakeRemote implements BrainDeviceRemotePort {
  _FakeRemote({
    required this.authorized,
  });

  final bool authorized;

  @override
  Future<bool> isAuthorized({
    required String vaultId,
    required String deviceId,
    required String authorizationSecretBase64,
  }) async {
    return authorized;
  }

  @override
  Future<void> approveDevice({
    required String vaultId,
    required String approverDeviceId,
    required String approverAuthorizationSecretBase64,
    required String targetDeviceId,
    required BrainDeviceKeyEnvelope envelope,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<BrainDeviceRecord?> getDevice({
    required String vaultId,
    required String requesterDeviceId,
    required String requesterAuthorizationSecretBase64,
    required String targetDeviceId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<BrainDeviceRecord>> listDevices({
    required String vaultId,
    required String requesterDeviceId,
    required String requesterAuthorizationSecretBase64,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<BrainDeviceKeyEnvelope?> claimPendingEnvelope({
    required String vaultId,
    required String targetDeviceId,
    required String targetAuthorizationSecretBase64,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<BrainDeviceRecord> registerDevice({
    required String vaultId,
    required BrainDeviceLocalSecrets localSecrets,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> revokeDevice({
    required String vaultId,
    required String approverDeviceId,
    required String approverAuthorizationSecretBase64,
    required String targetDeviceId,
  }) async {
    throw UnimplementedError();
  }
}
