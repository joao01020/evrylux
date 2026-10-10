import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../study/brain/security/models/brain_key_bundle.dart';
import 'web_brain_secure_storage.dart';

class WebBrainRecoveryKeyResult {
  const WebBrainRecoveryKeyResult({
    required this.vaultId,
    required this.recoveryKey,
    required this.keyVersion,
    required this.createdAt,
  });

  final String vaultId;
  final String recoveryKey;
  final int keyVersion;
  final DateTime createdAt;

  String toTextFile() {
    return [
      'EVRYLUX - Chave de recuperação do Cérebro',
      '',
      recoveryKey,
      '',
      'Vault: $vaultId',
      'Versão da chave: $keyVersion',
      'Criada em: ${createdAt.toUtc().toIso8601String()}',
      '',
      'IMPORTANTE:',
      '- Guarde este arquivo em um lugar seguro.',
      '- Quem possuir esta chave poderá recuperar o seu Cérebro.',
      '- O EVRYLUX não armazena esta chave em texto puro no servidor.',
      '',
    ].join('\n');
  }
}

class _BrainRecoveryPackage {
  const _BrainRecoveryPackage({
    required this.vaultId,
    required this.recoveryVersion,
    required this.keyVersion,
    required this.salt,
    required this.nonce,
    required this.cipherText,
    required this.mac,
  });

  final String vaultId;
  final int recoveryVersion;
  final int keyVersion;
  final List<int> salt;
  final List<int> nonce;
  final List<int> cipherText;
  final List<int> mac;

  factory _BrainRecoveryPackage.fromMap(Map<String, dynamic> map) {
    final vaultId = map['vault_id']?.toString().trim() ?? '';
    final recoveryVersion =
        int.tryParse(map['recovery_version']?.toString() ?? '') ?? 0;
    final keyVersion =
        int.tryParse(map['key_version']?.toString() ?? '') ?? 0;

    if (vaultId.isEmpty || recoveryVersion <= 0 || keyVersion <= 0) {
      throw const FormatException(
        'Pacote de recuperação possui metadata inválida.',
      );
    }

    List<int> decodeField(String name) {
      final raw = map[name]?.toString().trim() ?? '';
      if (raw.isEmpty) {
        throw FormatException('Campo ausente no pacote: $name');
      }
      return base64Url.decode(base64Url.normalize(raw));
    }

    final salt = decodeField('salt_b64');
    final nonce = decodeField('nonce_b64');
    final cipherText = decodeField('cipher_text_b64');
    final mac = decodeField('mac_b64');

    if (salt.length != WebBrainRecoveryKeyService.saltLengthBytes ||
        nonce.length != WebBrainRecoveryKeyService.nonceLengthBytes ||
        mac.length != 16 ||
        cipherText.isEmpty) {
      throw const FormatException(
        'Pacote de recuperação possui tamanhos criptográficos inválidos.',
      );
    }

    return _BrainRecoveryPackage(
      vaultId: vaultId,
      recoveryVersion: recoveryVersion,
      keyVersion: keyVersion,
      salt: List<int>.unmodifiable(salt),
      nonce: List<int>.unmodifiable(nonce),
      cipherText: List<int>.unmodifiable(cipherText),
      mac: List<int>.unmodifiable(mac),
    );
  }
}

class WebBrainRecoveryKeyService {
  WebBrainRecoveryKeyService({
    required WebBrainSecureStorage storage,
    SupabaseClient? client,
    Cipher? cipher,
    Random? random,
  }) : _storage = storage,
       _client = client ?? Supabase.instance.client,
       _cipher = cipher ?? Xchacha20.poly1305Aead(),
       _random = random ?? Random.secure();

  static const int recoveryKeyLengthBytes = 32;
  static const int saltLengthBytes = 32;
  static const int nonceLengthBytes = 24;
  static const int recoveryVersion = 1;

  final WebBrainSecureStorage _storage;
  final SupabaseClient _client;
  final Cipher _cipher;
  final Random _random;

  Future<bool> hasRecoveryPackage({
    required String vaultId,
  }) async {
    _requireAuth();

    final result = await _client.rpc(
      'brain_recovery_package_exists',
      params: <String, dynamic>{
        'p_vault_id': _requiredVault(vaultId),
      },
    );

    return result == true;
  }

  Future<WebBrainRecoveryKeyResult> createOrRotateRecoveryKey({
    required String vaultId,
  }) async {
    _requireAuth();

    final cleanVaultId = _requiredVault(vaultId);
    final local = await _storage.loadDevice();

    if (local == null) {
      throw StateError(
        'Identidade local do dispositivo não está disponível.',
      );
    }

    final authorized = await _client.rpc(
      'brain_device_is_authorized',
      params: <String, dynamic>{
        'p_vault_id': cleanVaultId,
        'p_device_id': local.deviceId,
        'p_auth_secret': local.authorizationSecretBase64,
      },
    );

    if (authorized != true) {
      throw StateError(
        'Somente um dispositivo autorizado pode criar uma chave de recuperação.',
      );
    }

    final bundle = await _storage.loadKeyBundle(vaultId: cleanVaultId);

    if (bundle == null) {
      throw StateError(
        'A Master Key do Cérebro não está disponível neste dispositivo.',
      );
    }

    bundle.validate();

    final recoveryKeyBytes = _randomBytes(recoveryKeyLengthBytes);
    final salt = _randomBytes(saltLengthBytes);
    final nonce = _randomBytes(nonceLengthBytes);

    final wrappingKey = await _deriveWrappingKey(
      recoveryKeyBytes: recoveryKeyBytes,
      salt: salt,
      vaultId: cleanVaultId,
      keyVersion: bundle.keyVersion,
    );

    final clear = utf8.encode(
      jsonEncode(<String, dynamic>{
        'recovery_version': recoveryVersion,
        'vault_id': cleanVaultId,
        'key_version': bundle.keyVersion,
        'master_key_b64': base64UrlEncode(bundle.masterKeyBytes),
      }),
    );

    final box = await _cipher.encrypt(
      clear,
      secretKey: wrappingKey,
      nonce: nonce,
      aad: utf8.encode(
        _aad(
          vaultId: cleanVaultId,
          keyVersion: bundle.keyVersion,
        ),
      ),
    );

    final proofHex = await _recoveryProofHex(
      vaultId: cleanVaultId,
      recoveryKeyBytes: recoveryKeyBytes,
    );

    await _client.rpc(
      'save_brain_recovery_package',
      params: <String, dynamic>{
        'p_vault_id': cleanVaultId,
        'p_device_id': local.deviceId,
        'p_auth_secret': local.authorizationSecretBase64,
        'p_recovery_version': recoveryVersion,
        'p_key_version': bundle.keyVersion,
        'p_salt_b64': base64UrlEncode(salt),
        'p_nonce_b64': base64UrlEncode(nonce),
        'p_cipher_text_b64': base64UrlEncode(box.cipherText),
        'p_mac_b64': base64UrlEncode(box.mac.bytes),
        'p_recovery_proof_hex': proofHex,
      },
    );

    final encodedRecoveryKey =
        base64UrlEncode(recoveryKeyBytes).replaceAll('=', '');

    await _storage.saveRecoveryKey(
      vaultId: cleanVaultId,
      recoveryKey: encodedRecoveryKey,
    );

    return WebBrainRecoveryKeyResult(
      vaultId: cleanVaultId,
      recoveryKey: encodedRecoveryKey,
      keyVersion: bundle.keyVersion,
      createdAt: DateTime.now().toUtc(),
    );
  }

  Future<String?> loadLocalRecoveryKey({
    required String vaultId,
  }) {
    return _storage.loadRecoveryKey(
      vaultId: _requiredVault(vaultId),
    );
  }

  /// FASE 3
  ///
  /// Recupera a Master Key usando a Recovery Key e autoriza ESTE device.
  ///
  /// Ordem:
  /// 1. busca pacote cifrado usando identidade pending atual;
  /// 2. deriva wrapping key localmente;
  /// 3. autentica/descriptografa XChaCha20-Poly1305;
  /// 4. valida bindings do payload;
  /// 5. prova posse da Recovery Key ao backend;
  /// 6. backend autoriza o device;
  /// 7. salva a Master Key no secure storage local.
  Future<void> recoverCurrentDevice({
    required String vaultId,
    required String recoveryKey,
  }) async {
    _requireAuth();

    final cleanVaultId = _requiredVault(vaultId);
    final local = await _storage.loadDevice();

    if (local == null) {
      throw StateError(
        'Este navegador ainda não possui uma identidade de dispositivo.',
      );
    }

    final recoveryKeyBytes = _decodeRecoveryKey(recoveryKey);

    final rawPackage = await _client.rpc(
      'get_brain_recovery_package',
      params: <String, dynamic>{
        'p_vault_id': cleanVaultId,
        'p_device_id': local.deviceId,
        'p_auth_secret': local.authorizationSecretBase64,
      },
    );

    if (rawPackage == null) {
      throw StateError(
        'Este Cérebro ainda não possui uma chave de recuperação configurada.',
      );
    }

    if (rawPackage is! Map) {
      throw const FormatException(
        'Resposta inválida do pacote de recuperação.',
      );
    }

    final package = _BrainRecoveryPackage.fromMap(
      Map<String, dynamic>.from(rawPackage),
    );

    if (package.vaultId != cleanVaultId ||
        package.recoveryVersion != recoveryVersion) {
      throw StateError(
        'O pacote de recuperação não corresponde a este Cérebro.',
      );
    }

    final wrappingKey = await _deriveWrappingKey(
      recoveryKeyBytes: recoveryKeyBytes,
      salt: package.salt,
      vaultId: cleanVaultId,
      keyVersion: package.keyVersion,
    );

    late final List<int> clear;

    try {
      clear = await _cipher.decrypt(
        SecretBox(
          package.cipherText,
          nonce: package.nonce,
          mac: Mac(package.mac),
        ),
        secretKey: wrappingKey,
        aad: utf8.encode(
          _aad(
            vaultId: cleanVaultId,
            keyVersion: package.keyVersion,
          ),
        ),
      );
    } on SecretBoxAuthenticationError {
      throw StateError(
        'A chave de recuperação informada é inválida.',
      );
    }

    final decoded = jsonDecode(utf8.decode(clear));

    if (decoded is! Map) {
      throw const FormatException(
        'Conteúdo do pacote de recuperação inválido.',
      );
    }

    final map = Map<String, dynamic>.from(decoded);

    final payloadRecoveryVersion =
        int.tryParse(map['recovery_version']?.toString() ?? '') ?? 0;
    final payloadKeyVersion =
        int.tryParse(map['key_version']?.toString() ?? '') ?? 0;

    if (map['vault_id']?.toString() != cleanVaultId ||
        payloadRecoveryVersion != package.recoveryVersion ||
        payloadKeyVersion != package.keyVersion) {
      throw StateError(
        'O binding criptográfico do pacote de recuperação é inválido.',
      );
    }

    final masterKeyRaw = map['master_key_b64']?.toString().trim() ?? '';

    if (masterKeyRaw.isEmpty) {
      throw const FormatException(
        'Master Key ausente no pacote de recuperação.',
      );
    }

    final masterKey = base64Url.decode(
      base64Url.normalize(masterKeyRaw),
    );

    if (masterKey.length != BrainKeyBundle.masterKeyLengthBytes) {
      throw const FormatException(
        'Master Key recuperada possui tamanho inválido.',
      );
    }

    final proofHex = await _recoveryProofHex(
      vaultId: cleanVaultId,
      recoveryKeyBytes: recoveryKeyBytes,
    );

    final authorized = await _client.rpc(
      'authorize_brain_device_with_recovery_key',
      params: <String, dynamic>{
        'p_vault_id': cleanVaultId,
        'p_device_id': local.deviceId,
        'p_auth_secret': local.authorizationSecretBase64,
        'p_recovery_proof_hex': proofHex,
      },
    );

    if (authorized != true) {
      throw StateError(
        'O backend não autorizou este dispositivo.',
      );
    }

    final bundle = BrainKeyBundle(
      masterKeyBytes: List<int>.unmodifiable(masterKey),
      keyVersion: package.keyVersion,
      createdAt: DateTime.now().toUtc(),
    );

    bundle.validate();

    await _storage.saveKeyBundle(
      vaultId: cleanVaultId,
      bundle: bundle,
    );

    await _storage.saveRecoveryKey(
      vaultId: cleanVaultId,
      recoveryKey:
          base64UrlEncode(recoveryKeyBytes).replaceAll('=', ''),
    );
  }

  Future<SecretKey> _deriveWrappingKey({
    required List<int> recoveryKeyBytes,
    required List<int> salt,
    required String vaultId,
    required int keyVersion,
  }) {
    return Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    ).deriveKey(
      secretKey: SecretKey(recoveryKeyBytes),
      nonce: salt,
      info: utf8.encode(
        _kdfInfo(
          vaultId: vaultId,
          keyVersion: keyVersion,
        ),
      ),
    );
  }

  Future<String> _recoveryProofHex({
    required String vaultId,
    required List<int> recoveryKeyBytes,
  }) async {
    final proof = await Hmac.sha256().calculateMac(
      utf8.encode(
        'EVRYLUX_BRAIN_RECOVERY_PROOF_V1|$vaultId',
      ),
      secretKey: SecretKey(recoveryKeyBytes),
    );

    return proof.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  List<int> _decodeRecoveryKey(String value) {
    final clean = value.trim().replaceAll(RegExp(r'\s+'), '');

    if (clean.isEmpty) {
      throw ArgumentError('Informe a chave de recuperação.');
    }

    late final List<int> bytes;

    try {
      bytes = base64Url.decode(
        base64Url.normalize(clean),
      );
    } on FormatException {
      throw StateError(
        'O formato da chave de recuperação é inválido.',
      );
    }

    if (bytes.length != recoveryKeyLengthBytes) {
      throw StateError(
        'A chave de recuperação possui tamanho inválido.',
      );
    }

    return List<int>.unmodifiable(bytes);
  }

  String _requiredVault(String value) {
    final clean = value.trim();

    if (clean.isEmpty) {
      throw ArgumentError('vaultId não pode ser vazio.');
    }

    return clean;
  }

  void _requireAuth() {
    if (_client.auth.currentUser == null) {
      throw StateError('Usuário não autenticado.');
    }
  }

  Uint8List _randomBytes(int length) {
    return Uint8List.fromList(
      List<int>.generate(
        length,
        (_) => _random.nextInt(256),
        growable: false,
      ),
    );
  }

  String _kdfInfo({
    required String vaultId,
    required int keyVersion,
  }) {
    return [
      'EVRYLUX_BRAIN_RECOVERY_WRAP_V1',
      vaultId,
      recoveryVersion.toString(),
      keyVersion.toString(),
    ].join('|');
  }

  String _aad({
    required String vaultId,
    required int keyVersion,
  }) {
    return [
      'EVRYLUX_BRAIN_RECOVERY_PACKAGE_V1',
      vaultId,
      recoveryVersion.toString(),
      keyVersion.toString(),
    ].join('|');
  }
}
