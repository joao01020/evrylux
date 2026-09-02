import '../../security/models/brain_crypto_version.dart';
import 'brain_vault_object_version.dart';

// ============================================================
// BRAIN VAULT OBJECT HEADER
// ============================================================
//
// Cabeçalho NÃO sensível de um objeto do Vault.
//
// Pode permanecer visível porque contém somente informações
// necessárias para:
//
// - localizar o objeto;
// - identificar o Vault;
// - versionar;
// - saber qual chave/crypto version utilizar;
// - sincronizar futuramente.
//
// NÃO adicionar aqui:
//
// - título;
// - conteúdo;
// - tema;
// - pergunta;
// - resposta;
// - tags;
// - conceitos;
// - tipo sem necessidade;
// - qualquer conhecimento do usuário.
//
// ============================================================

class BrainVaultObjectHeader {
  const BrainVaultObjectHeader({
    required this.objectId,
    required this.vaultId,
    required this.objectVersion,
    required this.cryptoVersion,
    required this.keyVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // IDS
  // ============================================================

  final String objectId;

  final String vaultId;

  // ============================================================
  // VERSIONS
  // ============================================================

  final BrainVaultObjectVersion objectVersion;

  final BrainCryptoVersion cryptoVersion;

  final int keyVersion;

  // ============================================================
  // DATES
  // ============================================================

  final DateTime createdAt;

  final DateTime updatedAt;

  // ============================================================
  // VALIDATE
  // ============================================================

  void validate() {
    if (objectId.trim().isEmpty) {
      throw const FormatException(
        'objectId do Vault não pode estar vazio.',
      );
    }

    if (vaultId.trim().isEmpty) {
      throw const FormatException(
        'vaultId do Vault não pode estar vazio.',
      );
    }

    if (keyVersion <=
        0) {
      throw const FormatException(
        'keyVersion do Vault deve ser maior que zero.',
      );
    }

    if (updatedAt.isBefore(
      createdAt,
    )) {
      throw const FormatException(
        'updatedAt não pode ser anterior a createdAt.',
      );
    }
  }

  // ============================================================
  // COPY
  // ============================================================

  BrainVaultObjectHeader copyWith({
    String? objectId,
    String? vaultId,
    BrainVaultObjectVersion? objectVersion,
    BrainCryptoVersion? cryptoVersion,
    int? keyVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrainVaultObjectHeader(
      objectId:
          objectId ??
          this.objectId,
      vaultId:
          vaultId ??
          this.vaultId,
      objectVersion:
          objectVersion ??
          this.objectVersion,
      cryptoVersion:
          cryptoVersion ??
          this.cryptoVersion,
      keyVersion:
          keyVersion ??
          this.keyVersion,
      createdAt:
          createdAt ??
          this.createdAt,
      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  // ============================================================
  // NEXT VERSION
  // ============================================================

  BrainVaultObjectHeader nextVersion({
    DateTime? updatedAt,
  }) {
    return copyWith(
      objectVersion: objectVersion.next(),
      updatedAt:
          updatedAt?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return {
      'object_id': objectId,
      'vault_id': vaultId,
      'object_version': objectVersion.value,
      'crypto_version': cryptoVersion.value,
      'key_version': keyVersion,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory BrainVaultObjectHeader.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    final objectId =
        json['object_id']?.toString().trim() ??
        '';

    final vaultId =
        json['vault_id']?.toString().trim() ??
        '';

    final objectVersion = BrainVaultObjectVersion.fromDynamic(
      json['object_version'],
    );

    final cryptoVersion = BrainCryptoVersion.fromValue(
      _parsePositiveInt(
        json['crypto_version'],
        fieldName: 'crypto_version',
      ),
    );

    final keyVersion = _parsePositiveInt(
      json['key_version'],
      fieldName: 'key_version',
    );

    final createdAt = _parseDate(
      json['created_at'],
      fieldName: 'created_at',
    );

    final updatedAt = _parseDate(
      json['updated_at'],
      fieldName: 'updated_at',
    );

    final header = BrainVaultObjectHeader(
      objectId: objectId,
      vaultId: vaultId,
      objectVersion: objectVersion,
      cryptoVersion: cryptoVersion,
      keyVersion: keyVersion,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    header.validate();

    return header;
  }

  // ============================================================
  // PARSE INT
  // ============================================================

  static int _parsePositiveInt(
    dynamic value, {
    required String fieldName,
  }) {
    final parsed =
        value
            is int
        ? value
        : int.tryParse(
            value?.toString().trim() ??
                '',
          );

    if (parsed ==
            null ||
        parsed <=
            0) {
      throw FormatException(
        '$fieldName inválido.',
      );
    }

    return parsed;
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  static DateTime _parseDate(
    dynamic value, {
    required String fieldName,
  }) {
    final parsed = DateTime.tryParse(
      value?.toString().trim() ??
          '',
    );

    if (parsed ==
        null) {
      throw FormatException(
        '$fieldName inválido.',
      );
    }

    return parsed.toUtc();
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is BrainVaultObjectHeader &&
        other.objectId ==
            objectId &&
        other.vaultId ==
            vaultId &&
        other.objectVersion ==
            objectVersion &&
        other.cryptoVersion ==
            cryptoVersion &&
        other.keyVersion ==
            keyVersion &&
        other.createdAt ==
            createdAt &&
        other.updatedAt ==
            updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      objectId,
      vaultId,
      objectVersion,
      cryptoVersion,
      keyVersion,
      createdAt,
      updatedAt,
    );
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return 'BrainVaultObjectHeader('
        'objectId: $objectId, '
        'vaultId: $vaultId, '
        'objectVersion: ${objectVersion.value}, '
        'cryptoVersion: ${cryptoVersion.value}, '
        'keyVersion: $keyVersion, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
