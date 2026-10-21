import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../crypto/brain_secure_random.dart';
import '../exceptions/brain_crypto_exception.dart';
import '../models/brain_key_bundle.dart';
import 'brain_key_storage.dart';

// ============================================================
// BRAIN KEY SERVICE
// ============================================================
//
// Responsável pelo ciclo local da Master Key do Cérebro.
//
// FASE 01:
//
// - gerar Master Key;
// - validar Master Key;
// - criar BrainKeyBundle;
// - salvar através de BrainKeyStorage;
// - carregar através de BrainKeyStorage;
// - criar chave caso ainda não exista.
//
// FASE 07:
//
// - exportar os bytes da Master Key somente para fluxo interno
//   de autorização de dispositivo;
// - importar uma Master Key recebida por envelope E2EE;
// - validar vaultId, keyVersion e tamanho da chave;
// - impedir sobrescrita silenciosa de uma chave diferente;
// - continuar usando BrainKeyStorage como única persistência.
//
// IMPORTANTE:
//
// - este service NÃO conhece Supabase;
// - este service NÃO conhece UI;
// - este service NÃO conhece dispositivos diretamente;
// - este service NÃO faz key wrapping;
// - este service NÃO transmite chave;
// - este service NÃO salva Master Key fora do BrainKeyStorage;
// - a Master Key nunca deve ser serializada em plaintext para rede,
//   arquivo comum, SharedPreferences ou SyncQueue.
//
// A Fase 07 deve acessar este service através de um adapter/port.
//
// ============================================================

class BrainRecoveryKeyPackageData {
  const BrainRecoveryKeyPackageData({
    required this.vaultId,
    required this.keyVersion,
    required this.keyCreatedAt,
    required this.masterKeyBytes,
  });

  final String vaultId;
  final int keyVersion;
  final DateTime keyCreatedAt;
  final List<int> masterKeyBytes;
}

class BrainKeyService {
  BrainKeyService({BrainSecureRandom? secureRandom, BrainKeyStorage? storage})
    : _secureRandom = secureRandom ?? BrainSecureRandom(),
      _storage = storage ?? InMemoryBrainKeyStorage();

  final BrainSecureRandom _secureRandom;

  final BrainKeyStorage _storage;

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const int masterKeyLengthBytes = BrainKeyBundle.masterKeyLengthBytes;

  static const int initialKeyVersion = BrainKeyBundle.initialKeyVersion;

  /// Formato externo da chave de recuperação.
  static const String recoveryFileFormat = 'evrylux-brain-recovery-key';

  /// Versão do envelope de recuperação.
  static const int recoveryFileVersion = 1;

  /// PBKDF2-HMAC-SHA256. Valor deliberadamente alto para tornar
  /// tentativas offline de senha mais caras.
  static const int recoveryKdfIterations = 210000;

  static const int recoverySaltLengthBytes = 16;

  static const int minimumRecoveryPasswordLength = 12;

  int get recoveryMinimumPasswordLength => minimumRecoveryPasswordLength;

  // ============================================================
  // STORAGE ERROR HANDLING
  // ============================================================

  Never _throwStorageError({
    required String operation,
    required Object error,
    StackTrace? stackTrace,
  }) {
    if (error is BrainCryptoException) {
      throw error;
    }

    developer.log(
      '[BRAIN KEY STORAGE] Falha em $operation',
      name: 'EVRYLUX.BrainKeyService',
      error: error,
      stackTrace: stackTrace,
    );

    throw BrainCryptoException.keyStorageFailed(cause: error);
  }

  // ============================================================
  // CREATE
  // ============================================================

  BrainKeyBundle createKeyBundle() {
    final bytes = _secureRandom.generateMasterKey();

    final bundle = BrainKeyBundle(
      masterKeyBytes: List<int>.unmodifiable(bytes),
      keyVersion: initialKeyVersion,
      createdAt: DateTime.now().toUtc(),
    );

    validateKeyBundle(bundle);

    return bundle;
  }

  // ============================================================
  // CREATE FROM IMPORTED BYTES — FASE 07
  // ============================================================

  BrainKeyBundle createImportedKeyBundle({
    required List<int> masterKeyBytes,
    required int keyVersion,
    DateTime? createdAt,
  }) {
    final normalizedBytes = List<int>.unmodifiable(masterKeyBytes);

    final bundle = BrainKeyBundle(
      masterKeyBytes: normalizedBytes,
      keyVersion: keyVersion,
      createdAt: (createdAt ?? DateTime.now()).toUtc(),
    );

    validateKeyBundle(bundle);

    return bundle;
  }

  // ============================================================
  // VALIDATE
  // ============================================================

  void validateKeyBundle(BrainKeyBundle bundle) {
    if (bundle.masterKeyBytes.length != masterKeyLengthBytes) {
      throw BrainCryptoException.invalidKey(
        message:
            'Master Key inválida: esperado '
            '$masterKeyLengthBytes bytes.',
      );
    }

    if (bundle.keyVersion <= 0) {
      throw BrainCryptoException.invalidKey(
        message: 'Versão da Master Key inválida.',
      );
    }

    for (final byte in bundle.masterKeyBytes) {
      if (byte < 0 || byte > 255) {
        throw BrainCryptoException.invalidKey(
          message: 'Master Key contém byte inválido.',
        );
      }
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<void> saveKeyBundle({
    required String vaultId,
    required BrainKeyBundle bundle,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw BrainCryptoException.invalidKey(
        message: 'vaultId inválido para armazenamento da chave.',
      );
    }

    validateKeyBundle(bundle);

    try {
      await _storage.saveKeyBundle(vaultId: cleanVaultId, bundle: bundle);
    } catch (error, stackTrace) {
      _throwStorageError(
        operation: 'saveKeyBundle',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<BrainKeyBundle?> loadKeyBundle({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return null;
    }

    try {
      final bundle = await _storage.loadKeyBundle(vaultId: cleanVaultId);

      if (bundle == null) {
        return null;
      }

      validateKeyBundle(bundle);

      return bundle;
    } catch (error, stackTrace) {
      _throwStorageError(
        operation: 'loadKeyBundle',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // REQUIRE
  // ============================================================

  Future<BrainKeyBundle> requireKeyBundle({required String vaultId}) async {
    final bundle = await loadKeyBundle(vaultId: vaultId);

    if (bundle == null) {
      throw BrainCryptoException.keyNotFound();
    }

    return bundle;
  }

  // ============================================================
  // GET OR CREATE
  // ============================================================

  Future<BrainKeyBundle> getOrCreateKeyBundle({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw BrainCryptoException.invalidKey(message: 'vaultId inválido.');
    }

    final existing = await loadKeyBundle(vaultId: cleanVaultId);

    if (existing != null) {
      return existing;
    }

    final created = createKeyBundle();

    await saveKeyBundle(vaultId: cleanVaultId, bundle: created);

    return created;
  }

  // ============================================================
  // EXISTS
  // ============================================================

  Future<bool> hasKeyBundle({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return false;
    }

    try {
      return await _storage.containsKeyBundle(vaultId: cleanVaultId);
    } catch (error, stackTrace) {
      _throwStorageError(
        operation: 'containsKeyBundle',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // EXPORT MASTER KEY — FASE 07
  // ============================================================

  Future<List<int>> exportMasterKeyBytes({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw BrainCryptoException.invalidKey(
        message: 'vaultId inválido para exportação da Master Key.',
      );
    }

    final bundle = await requireKeyBundle(vaultId: cleanVaultId);

    validateKeyBundle(bundle);

    return Uint8List.fromList(List<int>.from(bundle.masterKeyBytes));
  }

  // ============================================================
  // IMPORT MASTER KEY — FASE 07
  // ============================================================

  Future<BrainKeyBundle> importMasterKeyBytes({
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
    DateTime? createdAt,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw BrainCryptoException.invalidKey(
        message: 'vaultId inválido para importação da Master Key.',
      );
    }

    final imported = createImportedKeyBundle(
      masterKeyBytes: masterKeyBytes,
      keyVersion: keyVersion,
      createdAt: createdAt,
    );

    final existing = await loadKeyBundle(vaultId: cleanVaultId);

    if (existing != null) {
      final sameVersion = existing.keyVersion == imported.keyVersion;

      final sameKey = _constantTimeEquals(
        existing.masterKeyBytes,
        imported.masterKeyBytes,
      );

      if (sameVersion && sameKey) {
        return existing;
      }

      throw BrainCryptoException.invalidKey(
        message:
            'Já existe uma Master Key diferente para este Vault. '
            'Importação recusada para evitar sobrescrita insegura.',
      );
    }

    await saveKeyBundle(vaultId: cleanVaultId, bundle: imported);

    return imported;
  }

  // ============================================================
  // MATCHES EXISTING KEY — FASE 07
  // ============================================================

  Future<bool> matchesExistingKey({
    required String vaultId,
    required int keyVersion,
    required List<int> masterKeyBytes,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty ||
        keyVersion <= 0 ||
        masterKeyBytes.length != masterKeyLengthBytes) {
      return false;
    }

    final existing = await loadKeyBundle(vaultId: cleanVaultId);

    if (existing == null) {
      return false;
    }

    if (existing.keyVersion != keyVersion) {
      return false;
    }

    return _constantTimeEquals(existing.masterKeyBytes, masterKeyBytes);
  }

  // ============================================================
  // EXPORT RECOVERY KEY — .evkey
  // ============================================================
  //
  // Este fluxo é explicitamente iniciado pelo usuário em um
  // dispositivo que já possui a Master Key.
  //
  // SEGURANÇA:
  //
  // - a Master Key nunca é gravada em plaintext no arquivo;
  // - a senha não é persistida nem enviada ao servidor;
  // - PBKDF2-HMAC-SHA256 deriva uma chave de proteção;
  // - XChaCha20-Poly1305 protege confidencialidade + integridade;
  // - o pacote externo contém apenas metadados necessários para
  //   futura restauração.
  //
  // A autorização do dispositivo é validada na camada de UI /
  // BrainDeviceAuthorizationService antes de chamar este método.
  // ============================================================

  Future<Uint8List> exportRecoveryKeyPackage({
    required String vaultId,
    required String password,
  }) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw BrainCryptoException.invalidKey(
        message: 'Vault ID inválido para exportação da chave de recuperação.',
      );
    }

    if (password.length < minimumRecoveryPasswordLength) {
      throw BrainCryptoException.invalidKey(
        message:
            'A senha da chave de recuperação precisa ter pelo menos '
            '$minimumRecoveryPasswordLength caracteres.',
      );
    }

    final bundle = await requireKeyBundle(vaultId: cleanVaultId);

    validateKeyBundle(bundle);

    final salt = _secureRandom.generateBytes(recoverySaltLengthBytes);

    final nonce = _secureRandom.generateNonce();

    final kdf = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: recoveryKdfIterations,
      bits: 256,
    );

    final wrappingKey = await kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    final plaintext = utf8.encode(
      jsonEncode(<String, dynamic>{
        'vault_id': cleanVaultId,
        'key_version': bundle.keyVersion,
        'key_created_at': bundle.createdAt.toUtc().toIso8601String(),
        'master_key_b64': base64Encode(bundle.masterKeyBytes),
      }),
    );

    final cipher = Xchacha20.poly1305Aead();

    final secretBox = await cipher.encrypt(
      plaintext,
      secretKey: wrappingKey,
      nonce: nonce,
    );

    final package = <String, dynamic>{
      'format': recoveryFileFormat,
      'version': recoveryFileVersion,
      'vault_id': cleanVaultId,
      'key_version': bundle.keyVersion,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'protection': <String, dynamic>{
        'kdf': 'pbkdf2-hmac-sha256',
        'iterations': recoveryKdfIterations,
        'salt_b64': base64Encode(salt),
        'cipher': 'xchacha20-poly1305',
        'nonce_b64': base64Encode(secretBox.nonce),
        'ciphertext_b64': base64Encode(secretBox.cipherText),
        'mac_b64': base64Encode(secretBox.mac.bytes),
      },
    };

    return Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(package)),
    );
  }

  // ============================================================
  // DECODE RECOVERY KEY PACKAGE — .evkey
  // ============================================================
  //
  // Lê o mesmo formato criado por exportRecoveryKeyPackage().
  //
  // IMPORTANTE:
  // - a senha nunca é persistida;
  // - a Master Key só existe em memória durante a recuperação;
  // - MAC/AEAD é validado antes de qualquer importação;
  // - o método NÃO salva a chave. O caller deve autorizar o
  //   dispositivo primeiro e só então chamar importMasterKeyBytes().
  // ============================================================

  Future<BrainRecoveryKeyPackageData> decodeRecoveryKeyPackage({
    required List<int> packageBytes,
    required String password,
  }) async {
    if (packageBytes.isEmpty) {
      throw BrainCryptoException.invalidPayload(
        message: 'Arquivo de recuperação vazio.',
      );
    }

    if (password.isEmpty) {
      throw BrainCryptoException.invalidKey(
        message: 'Informe a senha do arquivo de recuperação.',
      );
    }

    late final Map<String, dynamic> package;

    try {
      final decoded = jsonDecode(utf8.decode(packageBytes));

      if (decoded is! Map) {
        throw const FormatException();
      }

      package = Map<String, dynamic>.from(decoded);
    } catch (error) {
      throw BrainCryptoException.invalidPayload(
        message: 'Arquivo .evkey inválido.',
        cause: error,
      );
    }

    final format = package['format']?.toString().trim() ?? '';
    final version = int.tryParse(package['version']?.toString() ?? '') ?? 0;
    final vaultId = package['vault_id']?.toString().trim() ?? '';
    final keyVersion =
        int.tryParse(package['key_version']?.toString() ?? '') ?? 0;

    if (format != recoveryFileFormat ||
        version != recoveryFileVersion ||
        vaultId.isEmpty ||
        keyVersion <= 0) {
      throw BrainCryptoException.invalidPayload(
        message:
            'Este arquivo não é uma chave de recuperação EVRYLUX compatível.',
      );
    }

    final protectionRaw = package['protection'];

    if (protectionRaw is! Map) {
      throw BrainCryptoException.invalidPayload(
        message: 'Proteção criptográfica ausente no arquivo .evkey.',
      );
    }

    final protection = Map<String, dynamic>.from(protectionRaw);

    final kdf = protection['kdf']?.toString().trim() ?? '';
    final cipherName = protection['cipher']?.toString().trim() ?? '';
    final iterations =
        int.tryParse(protection['iterations']?.toString() ?? '') ?? 0;

    if (kdf != 'pbkdf2-hmac-sha256' ||
        cipherName != 'xchacha20-poly1305' ||
        iterations < 100000 ||
        iterations > 2000000) {
      throw BrainCryptoException.unsupportedAlgorithm(
        message: 'Proteção do arquivo .evkey não é suportada.',
      );
    }

    List<int> decodeBase64Field(String name) {
      final raw = protection[name]?.toString().trim() ?? '';

      if (raw.isEmpty) {
        throw BrainCryptoException.invalidPayload(
          message: 'Campo criptográfico ausente: $name.',
        );
      }

      try {
        return base64Decode(raw);
      } catch (error) {
        throw BrainCryptoException.invalidPayload(
          message: 'Campo criptográfico inválido: $name.',
          cause: error,
        );
      }
    }

    final salt = decodeBase64Field('salt_b64');
    final nonce = decodeBase64Field('nonce_b64');
    final cipherText = decodeBase64Field('ciphertext_b64');
    final mac = decodeBase64Field('mac_b64');

    if (salt.length != recoverySaltLengthBytes ||
        nonce.length != 24 ||
        mac.length != 16 ||
        cipherText.isEmpty) {
      throw BrainCryptoException.invalidPayload(
        message: 'Arquivo .evkey possui parâmetros criptográficos inválidos.',
      );
    }

    final passwordKey = await Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);

    late final List<int> clear;

    try {
      clear = await Xchacha20.poly1305Aead().decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: passwordKey,
      );
    } on SecretBoxAuthenticationError catch (error) {
      throw BrainCryptoException.authenticationFailed(
        message: 'Senha incorreta ou arquivo de recuperação adulterado.',
        cause: error,
      );
    } catch (error) {
      throw BrainCryptoException.decryptionFailed(
        message: 'Não foi possível abrir o arquivo de recuperação.',
        cause: error,
      );
    }

    late final Map<String, dynamic> payload;

    try {
      final decoded = jsonDecode(utf8.decode(clear));

      if (decoded is! Map) {
        throw const FormatException();
      }

      payload = Map<String, dynamic>.from(decoded);
    } catch (error) {
      throw BrainCryptoException.invalidPayload(
        message: 'Conteúdo interno do arquivo .evkey é inválido.',
        cause: error,
      );
    }

    final payloadVaultId = payload['vault_id']?.toString().trim() ?? '';
    final payloadKeyVersion =
        int.tryParse(payload['key_version']?.toString() ?? '') ?? 0;
    final keyCreatedAt = DateTime.tryParse(
      payload['key_created_at']?.toString() ?? '',
    );
    final masterKeyRaw = payload['master_key_b64']?.toString().trim() ?? '';

    if (payloadVaultId != vaultId ||
        payloadKeyVersion != keyVersion ||
        keyCreatedAt == null ||
        masterKeyRaw.isEmpty) {
      throw BrainCryptoException.invalidPayload(
        message: 'Binding interno do arquivo .evkey não confere.',
      );
    }

    late final List<int> masterKey;

    try {
      masterKey = base64Decode(masterKeyRaw);
    } catch (error) {
      throw BrainCryptoException.invalidPayload(
        message: 'Master Key do arquivo .evkey é inválida.',
        cause: error,
      );
    }

    if (masterKey.length != masterKeyLengthBytes) {
      throw BrainCryptoException.invalidKey(
        message: 'Master Key recuperada possui tamanho inválido.',
      );
    }

    return BrainRecoveryKeyPackageData(
      vaultId: vaultId,
      keyVersion: keyVersion,
      keyCreatedAt: keyCreatedAt.toUtc(),
      masterKeyBytes: List<int>.unmodifiable(masterKey),
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> deleteKeyBundle({required String vaultId}) async {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      return;
    }

    try {
      await _storage.deleteKeyBundle(vaultId: cleanVaultId);
    } catch (error, stackTrace) {
      _throwStorageError(
        operation: 'deleteKeyBundle',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // CONSTANT-TIME BYTE COMPARISON
  // ============================================================

  bool _constantTimeEquals(List<int> first, List<int> second) {
    if (first.length != second.length) {
      return false;
    }

    var difference = 0;

    for (var index = 0; index < first.length; index++) {
      difference |= first[index] ^ second[index];
    }

    return difference == 0;
  }
}
