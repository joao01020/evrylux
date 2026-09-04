import '../models/brain_device_key_envelope.dart';
import '../models/brain_device_record.dart';
import '../security/brain_device_local_secrets.dart';

abstract class BrainDeviceRemotePort {
  Future<BrainDeviceRecord> registerDevice({
    required String vaultId,
    required BrainDeviceLocalSecrets localSecrets,
  });

  Future<List<BrainDeviceRecord>> listDevices({
    required String vaultId,
    required String requesterDeviceId,
    required String requesterAuthorizationSecretBase64,
  });

  Future<BrainDeviceRecord?> getDevice({
    required String vaultId,
    required String requesterDeviceId,
    required String requesterAuthorizationSecretBase64,
    required String targetDeviceId,
  });

  Future<bool> isAuthorized({
    required String vaultId,
    required String deviceId,
    required String authorizationSecretBase64,
  });

  Future<void> approveDevice({
    required String vaultId,
    required String approverDeviceId,
    required String approverAuthorizationSecretBase64,
    required String targetDeviceId,
    required BrainDeviceKeyEnvelope envelope,
  });

  Future<void> revokeDevice({
    required String vaultId,
    required String approverDeviceId,
    required String approverAuthorizationSecretBase64,
    required String targetDeviceId,
  });

  /// Atomic one-time operation:
  /// the backend marks the envelope consumed in the same transaction
  /// that returns its payload. Replay returns null.
  Future<BrainDeviceKeyEnvelope?> claimPendingEnvelope({
    required String vaultId,
    required String targetDeviceId,
    required String targetAuthorizationSecretBase64,
  });
}
