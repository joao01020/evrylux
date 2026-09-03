import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../models/brain_device_key_envelope.dart';
import 'brain_device_local_secrets.dart';

class BrainDeviceCryptoService {
  BrainDeviceCryptoService({X25519? keyAgreement, Cipher? cipher})
    : _keyAgreement = keyAgreement ?? X25519(),
      _cipher = cipher ?? Xchacha20.poly1305Aead();

  final X25519 _keyAgreement;
  final Cipher _cipher;
  final Random _random = Random.secure();

  Future<BrainDeviceLocalSecrets> generateLocalSecrets({
    required String deviceName,
  }) async {
    final cleanName = deviceName.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('deviceName não pode ser vazio.');
    }

    final keyPair = await _keyAgreement.newKeyPair();
    final privateKey = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();
    final authSecret = _randomBytes(32);

    return BrainDeviceLocalSecrets(
      deviceId: 'dev_${_token(18)}',
      deviceName: cleanName,
      privateKeyBase64: base64UrlEncode(privateKey),
      publicKeyBase64: base64UrlEncode(publicKey.bytes),
      keyFingerprint: await fingerprintPublicKey(publicKey.bytes),
      authorizationSecretBase64: base64UrlEncode(authSecret),
      createdAt: DateTime.now().toUtc(),
    );
  }

  Future<String> fingerprintPublicKey(List<int> bytes) async {
    final hash = await Sha256().hash(bytes);
    return hash.bytes
        .take(10)
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join(':')
        .toUpperCase();
  }

  Future<BrainDeviceKeyEnvelope> wrapMasterKey({
    required BrainDeviceLocalSecrets sender,
    required String targetDeviceId,
    required String targetPublicKeyBase64,
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
  }) async {
    if (masterKeyBytes.length != 32 || keyVersion <= 0) {
      throw ArgumentError('Master Key/keyVersion inválidos.');
    }

    final nonce = _randomBytes(24);
    final shared = await _keyAgreement.sharedSecretKey(
      keyPair: _restoreKeyPair(sender),
      remotePublicKey: SimplePublicKey(
        base64Url.decode(targetPublicKeyBase64),
        type: KeyPairType.x25519,
      ),
    );

    final wrappingKey = await Hkdf(hmac: Hmac.sha256(), outputLength: 32)
        .deriveKey(
          secretKey: shared,
          nonce: nonce,
          info: utf8.encode(
            _kdfInfo(
              vaultId: vaultId,
              senderDeviceId: sender.deviceId,
              targetDeviceId: targetDeviceId,
              keyVersion: keyVersion,
            ),
          ),
        );

    final clear = utf8.encode(
      jsonEncode({
        'vault_id': vaultId,
        'key_version': keyVersion,
        'master_key_b64': base64UrlEncode(masterKeyBytes),
      }),
    );

    final box = await _cipher.encrypt(
      clear,
      secretKey: wrappingKey,
      nonce: nonce,
      aad: utf8.encode(
        _aad(
          vaultId: vaultId,
          senderDeviceId: sender.deviceId,
          targetDeviceId: targetDeviceId,
          keyVersion: keyVersion,
        ),
      ),
    );

    return BrainDeviceKeyEnvelope(
      envelopeId: 'env_${_token(18)}',
      vaultId: vaultId,
      senderDeviceId: sender.deviceId,
      targetDeviceId: targetDeviceId,
      senderPublicKeyBase64: sender.publicKeyBase64,
      nonceBase64: base64UrlEncode(nonce),
      cipherTextBase64: base64UrlEncode(box.cipherText),
      macBase64: base64UrlEncode(box.mac.bytes),
      keyVersion: keyVersion,
      createdAt: DateTime.now().toUtc(),
    );
  }

  Future<List<int>> unwrapMasterKey({
    required BrainDeviceLocalSecrets target,
    required BrainDeviceKeyEnvelope envelope,
  }) async {
    if (target.deviceId != envelope.targetDeviceId) {
      throw StateError('Envelope não pertence a este dispositivo.');
    }

    final nonce = base64Url.decode(envelope.nonceBase64);
    final shared = await _keyAgreement.sharedSecretKey(
      keyPair: _restoreKeyPair(target),
      remotePublicKey: SimplePublicKey(
        base64Url.decode(envelope.senderPublicKeyBase64),
        type: KeyPairType.x25519,
      ),
    );

    final wrappingKey = await Hkdf(hmac: Hmac.sha256(), outputLength: 32)
        .deriveKey(
          secretKey: shared,
          nonce: nonce,
          info: utf8.encode(
            _kdfInfo(
              vaultId: envelope.vaultId,
              senderDeviceId: envelope.senderDeviceId,
              targetDeviceId: envelope.targetDeviceId,
              keyVersion: envelope.keyVersion,
            ),
          ),
        );

    final clear = await _cipher.decrypt(
      SecretBox(
        base64Url.decode(envelope.cipherTextBase64),
        nonce: nonce,
        mac: Mac(base64Url.decode(envelope.macBase64)),
      ),
      secretKey: wrappingKey,
      aad: utf8.encode(
        _aad(
          vaultId: envelope.vaultId,
          senderDeviceId: envelope.senderDeviceId,
          targetDeviceId: envelope.targetDeviceId,
          keyVersion: envelope.keyVersion,
        ),
      ),
    );

    final decoded = jsonDecode(utf8.decode(clear));
    if (decoded is! Map) {
      throw const FormatException('Envelope inválido.');
    }
    final map = Map<String, dynamic>.from(decoded);
    if (map['vault_id']?.toString() != envelope.vaultId ||
        int.tryParse(map['key_version']?.toString() ?? '') !=
            envelope.keyVersion) {
      throw const FormatException('Binding do envelope inválido.');
    }

    final key = base64Url.decode(map['master_key_b64']?.toString() ?? '');
    if (key.length != 32) {
      throw const FormatException('Master Key importada inválida.');
    }
    return List<int>.unmodifiable(key);
  }

  SimpleKeyPairData _restoreKeyPair(BrainDeviceLocalSecrets secrets) {
    return SimpleKeyPairData(
      base64Url.decode(secrets.privateKeyBase64),
      publicKey: SimplePublicKey(
        base64Url.decode(secrets.publicKeyBase64),
        type: KeyPairType.x25519,
      ),
      type: KeyPairType.x25519,
    );
  }

  String _kdfInfo({
    required String vaultId,
    required String senderDeviceId,
    required String targetDeviceId,
    required int keyVersion,
  }) =>
      'EVRYLUX_BRAIN_DEVICE_WRAP_V1|$vaultId|$senderDeviceId|$targetDeviceId|$keyVersion';

  String _aad({
    required String vaultId,
    required String senderDeviceId,
    required String targetDeviceId,
    required int keyVersion,
  }) =>
      'EVRYLUX_BRAIN_DEVICE_ENVELOPE_V1|$vaultId|$senderDeviceId|$targetDeviceId|$keyVersion';

  Uint8List _randomBytes(int length) => Uint8List.fromList(
    List<int>.generate(length, (_) => _random.nextInt(256), growable: false),
  );

  String _token(int byteLength) =>
      base64UrlEncode(_randomBytes(byteLength)).replaceAll('=', '');
}
