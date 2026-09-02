import 'dart:convert';

import '../models/brain_vault_object.dart';
import '../models/brain_vault_object_header.dart';
import '../models/brain_vault_object_type.dart';

// ============================================================
// BRAIN VAULT DECODED PAYLOAD
// ============================================================
//
// Representa o conteúdo lógico recuperado após descriptografar
// um objeto.
//
// Os campos de identidade também existem dentro do conteúdo
// criptografado.
//
// Isso permite verificar se o header externo foi adulterado.
//
// ============================================================

class BrainVaultDecodedPayload {
  const BrainVaultDecodedPayload({
    required this.schemaVersion,
    required this.type,
    required this.objectId,
    required this.vaultId,
    required this.objectVersion,
    required this.cryptoVersion,
    required this.keyVersion,
    required this.createdAt,
    required this.updatedAt,
    required this.data,
  });

  // ============================================================
  // SCHEMA
  // ============================================================

  final int schemaVersion;

  // ============================================================
  // TYPE
  // ============================================================

  final BrainVaultObjectType type;

  // ============================================================
  // BINDING
  // ============================================================

  final String objectId;

  final String vaultId;

  final int objectVersion;

  final int cryptoVersion;

  final int keyVersion;

  // ============================================================
  // DATES
  // ============================================================

  final DateTime createdAt;

  final DateTime updatedAt;

  // ============================================================
  // DATA
  // ============================================================

  final Map<
    String,
    dynamic
  >
  data;

  // ============================================================
  // STRING
  // ============================================================
  //
  // Não imprime os dados do usuário.
  //
  // ============================================================

  @override
  String toString() {
    return 'BrainVaultDecodedPayload('
        'schemaVersion: $schemaVersion, '
        'type: ${type.value}, '
        'objectId: $objectId, '
        'vaultId: $vaultId, '
        'objectVersion: $objectVersion'
        ')';
  }
}

// ============================================================
// BRAIN VAULT SERIALIZER
// ============================================================
//
// Possui duas funções diferentes:
//
// 1. serializar/deserializar BrainVaultObject
//    para gravação física do .evobj;
//
// 2. serializar/deserializar o conteúdo lógico que será
//    criptografado.
//
// ============================================================

class BrainVaultSerializer {
  const BrainVaultSerializer();

  // ============================================================
  // CONSTANTS
  // ============================================================

  static const int payloadSchemaVersion = 1;

  // ============================================================
  // SERIALIZE OBJECT
  // ============================================================

  String serializeObject(
    BrainVaultObject object,
  ) {
    object.validate();

    return jsonEncode(
      object.toJson(),
    );
  }

  // ============================================================
  // DESERIALIZE OBJECT
  // ============================================================

  BrainVaultObject deserializeObject(
    String serialized,
  ) {
    final decoded = _decodeJsonMap(
      serialized,
      errorMessage: 'Arquivo .evobj inválido.',
    );

    return BrainVaultObject.fromJson(
      decoded,
    );
  }

  // ============================================================
  // SERIALIZE LOGICAL PAYLOAD
  // ============================================================
  //
  // Esse resultado será enviado ao BrainCryptoService.
  //
  // Além dos dados reais, inserimos uma cópia autenticada do
  // header.
  //
  // ============================================================

  String serializeLogicalPayload({
    required BrainVaultObjectType type,
    required BrainVaultObjectHeader header,
    required Map<
      String,
      dynamic
    >
    data,
  }) {
    header.validate();

    final envelope =
        <
          String,
          dynamic
        >{
          'schema_version': payloadSchemaVersion,

          'type': type.value,

          'binding': {
            'object_id': header.objectId,
            'vault_id': header.vaultId,
            'object_version': header.objectVersion.value,
            'crypto_version': header.cryptoVersion.value,
            'key_version': header.keyVersion,
            'created_at': header.createdAt.toUtc().toIso8601String(),
            'updated_at': header.updatedAt.toUtc().toIso8601String(),
          },

          'data':
              Map<
                String,
                dynamic
              >.from(
                data,
              ),
        };

    try {
      return jsonEncode(
        envelope,
      );
    } catch (
      error
    ) {
      throw FormatException(
        'O conteúdo lógico do Vault não pode ser serializado: $error',
      );
    }
  }

  // ============================================================
  // DESERIALIZE LOGICAL PAYLOAD
  // ============================================================

  BrainVaultDecodedPayload deserializeLogicalPayload(
    String serialized,
  ) {
    final json = _decodeJsonMap(
      serialized,
      errorMessage: 'Payload lógico do Vault inválido.',
    );

    final schemaVersion = _parsePositiveInt(
      json['schema_version'],
      fieldName: 'schema_version',
    );

    if (schemaVersion !=
        payloadSchemaVersion) {
      throw FormatException(
        'Versão de payload lógico não suportada: '
        '$schemaVersion.',
      );
    }

    final type = BrainVaultObjectType.fromValue(
      json['type']?.toString().trim() ??
          '',
    );

    final rawBinding = json['binding'];

    if (rawBinding
        is! Map) {
      throw const FormatException(
        'Binding criptográfico do Vault inválido.',
      );
    }

    final binding =
        Map<
          String,
          dynamic
        >.from(
          rawBinding,
        );

    final objectId =
        binding['object_id']?.toString().trim() ??
        '';

    final vaultId =
        binding['vault_id']?.toString().trim() ??
        '';

    if (objectId.isEmpty) {
      throw const FormatException(
        'object_id autenticado ausente.',
      );
    }

    if (vaultId.isEmpty) {
      throw const FormatException(
        'vault_id autenticado ausente.',
      );
    }

    final objectVersion = _parsePositiveInt(
      binding['object_version'],
      fieldName: 'object_version',
    );

    final cryptoVersion = _parsePositiveInt(
      binding['crypto_version'],
      fieldName: 'crypto_version',
    );

    final keyVersion = _parsePositiveInt(
      binding['key_version'],
      fieldName: 'key_version',
    );

    final createdAt = _parseDate(
      binding['created_at'],
      fieldName: 'created_at',
    );

    final updatedAt = _parseDate(
      binding['updated_at'],
      fieldName: 'updated_at',
    );

    final rawData = json['data'];

    if (rawData
        is! Map) {
      throw const FormatException(
        'Dados do payload lógico inválidos.',
      );
    }

    return BrainVaultDecodedPayload(
      schemaVersion: schemaVersion,
      type: type,
      objectId: objectId,
      vaultId: vaultId,
      objectVersion: objectVersion,
      cryptoVersion: cryptoVersion,
      keyVersion: keyVersion,
      createdAt: createdAt,
      updatedAt: updatedAt,
      data:
          Map<
            String,
            dynamic
          >.from(
            rawData,
          ),
    );
  }

  // ============================================================
  // VERIFY BINDING
  // ============================================================
  //
  // Compara o header visível do .evobj com a cópia que estava
  // dentro do conteúdo autenticado pelo AEAD.
  //
  // ============================================================

  void verifyBinding({
    required BrainVaultObjectHeader header,
    required BrainVaultDecodedPayload decoded,
  }) {
    if (decoded.objectId !=
        header.objectId) {
      throw const FormatException(
        'Falha de integridade: objectId não corresponde ao conteúdo autenticado.',
      );
    }

    if (decoded.vaultId !=
        header.vaultId) {
      throw const FormatException(
        'Falha de integridade: vaultId não corresponde ao conteúdo autenticado.',
      );
    }

    if (decoded.objectVersion !=
        header.objectVersion.value) {
      throw const FormatException(
        'Falha de integridade: objectVersion não corresponde ao conteúdo autenticado.',
      );
    }

    if (decoded.cryptoVersion !=
        header.cryptoVersion.value) {
      throw const FormatException(
        'Falha de integridade: cryptoVersion não corresponde ao conteúdo autenticado.',
      );
    }

    if (decoded.keyVersion !=
        header.keyVersion) {
      throw const FormatException(
        'Falha de integridade: keyVersion não corresponde ao conteúdo autenticado.',
      );
    }

    if (decoded.createdAt.toUtc() !=
        header.createdAt.toUtc()) {
      throw const FormatException(
        'Falha de integridade: createdAt não corresponde ao conteúdo autenticado.',
      );
    }

    if (decoded.updatedAt.toUtc() !=
        header.updatedAt.toUtc()) {
      throw const FormatException(
        'Falha de integridade: updatedAt não corresponde ao conteúdo autenticado.',
      );
    }
  }

  // ============================================================
  // DECODE JSON MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  _decodeJsonMap(
    String source, {
    required String errorMessage,
  }) {
    if (source.trim().isEmpty) {
      throw FormatException(
        errorMessage,
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(
        source,
      );
    } catch (
      _
    ) {
      throw FormatException(
        errorMessage,
      );
    }

    if (decoded
        is! Map) {
      throw FormatException(
        errorMessage,
      );
    }

    return Map<
      String,
      dynamic
    >.from(
      decoded,
    );
  }

  // ============================================================
  // PARSE INT
  // ============================================================

  int _parsePositiveInt(
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

  DateTime _parseDate(
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
}
