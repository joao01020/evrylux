import 'dart:convert';

import '../../security/models/brain_crypto_version.dart';

// ============================================================
// BRAIN VAULT MANIFEST
// ============================================================
//
// Identidade e versão estrutural de um Vault.
//
// Este arquivo NÃO deve conter:
//
// - títulos;
// - temas;
// - conteúdo;
// - perguntas;
// - respostas;
// - tags;
// - caminhos sem necessidade.
//
// Estrutura física futura:
//
// brain/
// └── vault/
//     ├── manifest.json
//     └── objects/
//         ├── <objectId>.evobj
//         └── ...
//
// ============================================================

class BrainVaultManifest {
  const BrainVaultManifest({
    required this.vaultId,
    required this.formatVersion,
    required this.cryptoVersion,
    required this.keyVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // FORMAT
  // ============================================================

  static const String format = 'evrylux-brain-vault';

  static const int currentFormatVersion = 1;

  // ============================================================
  // ID
  // ============================================================

  final String vaultId;

  // ============================================================
  // VERSIONS
  // ============================================================

  final int formatVersion;

  final BrainCryptoVersion cryptoVersion;

  final int keyVersion;

  // ============================================================
  // DATES
  // ============================================================

  final DateTime createdAt;

  final DateTime updatedAt;

  // ============================================================
  // FACTORY NEW
  // ============================================================

  factory BrainVaultManifest.create({
    required String vaultId,
    int keyVersion = 1,
    DateTime? now,
  }) {
    final cleanVaultId = vaultId.trim();

    if (cleanVaultId.isEmpty) {
      throw ArgumentError(
        'vaultId não pode estar vazio.',
      );
    }

    if (keyVersion <=
        0) {
      throw ArgumentError(
        'keyVersion deve ser maior que zero.',
      );
    }

    final timestamp =
        (now ??
                DateTime.now())
            .toUtc();

    return BrainVaultManifest(
      vaultId: cleanVaultId,
      formatVersion: currentFormatVersion,
      cryptoVersion: BrainCryptoVersion.current,
      keyVersion: keyVersion,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  // ============================================================
  // VALIDATE
  // ============================================================

  void validate() {
    if (vaultId.trim().isEmpty) {
      throw const FormatException(
        'vaultId do manifest não pode estar vazio.',
      );
    }

    if (formatVersion <=
        0) {
      throw const FormatException(
        'formatVersion deve ser maior que zero.',
      );
    }

    if (formatVersion >
        currentFormatVersion) {
      throw FormatException(
        'Versão de Vault ainda não suportada: '
        '$formatVersion.',
      );
    }

    if (keyVersion <=
        0) {
      throw const FormatException(
        'keyVersion deve ser maior que zero.',
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
  // TOUCH
  // ============================================================

  BrainVaultManifest touch({
    DateTime? updatedAt,
  }) {
    return copyWith(
      updatedAt:
          (updatedAt ??
                  DateTime.now())
              .toUtc(),
    );
  }

  // ============================================================
  // COPY
  // ============================================================

  BrainVaultManifest copyWith({
    String? vaultId,
    int? formatVersion,
    BrainCryptoVersion? cryptoVersion,
    int? keyVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrainVaultManifest(
      vaultId:
          vaultId ??
          this.vaultId,
      formatVersion:
          formatVersion ??
          this.formatVersion,
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
  // JSON
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    validate();

    return {
      'format': format,
      'format_version': formatVersion,
      'vault_id': vaultId,
      'crypto_version': cryptoVersion.value,
      'key_version': keyVersion,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // JSON STRING
  // ============================================================

  String toJsonString() {
    return jsonEncode(
      toJson(),
    );
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory BrainVaultManifest.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    final rawFormat =
        json['format']?.toString().trim() ??
        '';

    if (rawFormat !=
        format) {
      throw FormatException(
        'Formato de Vault inválido: $rawFormat',
      );
    }

    final formatVersion = _parsePositiveInt(
      json['format_version'],
      fieldName: 'format_version',
    );

    final vaultId =
        json['vault_id']?.toString().trim() ??
        '';

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

    final manifest = BrainVaultManifest(
      vaultId: vaultId,
      formatVersion: formatVersion,
      cryptoVersion: cryptoVersion,
      keyVersion: keyVersion,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );

    manifest.validate();

    return manifest;
  }

  // ============================================================
  // FROM JSON STRING
  // ============================================================

  factory BrainVaultManifest.fromJsonString(
    String jsonString,
  ) {
    final decoded = jsonDecode(
      jsonString,
    );

    if (decoded
        is! Map) {
      throw const FormatException(
        'Manifest JSON inválido.',
      );
    }

    return BrainVaultManifest.fromJson(
      Map<
        String,
        dynamic
      >.from(
        decoded,
      ),
    );
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
            is BrainVaultManifest &&
        other.vaultId ==
            vaultId &&
        other.formatVersion ==
            formatVersion &&
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
      vaultId,
      formatVersion,
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
    return 'BrainVaultManifest('
        'format: $format, '
        'formatVersion: $formatVersion, '
        'vaultId: $vaultId, '
        'cryptoVersion: ${cryptoVersion.value}, '
        'keyVersion: $keyVersion, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
