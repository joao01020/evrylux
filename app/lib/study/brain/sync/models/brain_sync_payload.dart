import 'dart:convert';

import '../../vault/models/brain_vault_object.dart';
import '../../vault/services/brain_vault_serializer.dart';

// ============================================================
// BRAIN SYNC PAYLOAD
// ============================================================
//
// Representa SOMENTE um BrainVaultObject já criptografado.
//
// REGRA:
// este model nunca recebe BrainReviewItem, BrainFile, título,
// pergunta, resposta ou conteúdo em plaintext.
//
// O campo encryptedObject contém a serialização física do .evobj.
//
// FASE 13 — FONTES DO CONHECIMENTO:
//
// - source/reference/author/note nunca entram em plaintext;
// - sources só podem existir dentro do BrainVaultObject criptografado;
// - validate() falha antes de gravar a SyncQueue caso uma chave de
//   domínio de BrainSource apareça fora do ciphertext.
//
// ============================================================

class BrainSyncPayload {
  const BrainSyncPayload({
    required this.vaultId,
    required this.objectId,
    required this.objectVersion,
    required this.cryptoVersion,
    required this.keyVersion,
    required this.isDeleted,
    required this.encryptedObject,
    required this.createdAt,
    required this.updatedAt,
  });

  final String vaultId;
  final String objectId;
  final int objectVersion;
  final int cryptoVersion;
  final int keyVersion;
  final bool isDeleted;

  final Map<String, dynamic> encryptedObject;

  final DateTime createdAt;
  final DateTime updatedAt;

  // ============================================================
  // FROM VAULT OBJECT
  // ============================================================

  factory BrainSyncPayload.fromVaultObject({
    required BrainVaultObject object,
    BrainVaultSerializer serializer = const BrainVaultSerializer(),
  }) {
    object.header.validate();

    final raw = serializer.serializeObject(object);

    final decoded = jsonDecode(raw);

    if (decoded is! Map) {
      throw const FormatException(
        'BrainVaultObject serializado não é um objeto JSON.',
      );
    }

    final payload = BrainSyncPayload(
      vaultId: object.header.vaultId,
      objectId: object.header.objectId,
      objectVersion: object.header.objectVersion.value,
      cryptoVersion: object.header.cryptoVersion.value,
      keyVersion: object.header.keyVersion,
      isDeleted: object.isDeleted,
      encryptedObject: Map<String, dynamic>.from(decoded),
      createdAt: object.header.createdAt.toUtc(),
      updatedAt: object.header.updatedAt.toUtc(),
    );

    payload.validate(serializer: serializer);

    return payload;
  }

  // ============================================================
  // FROM QUEUE
  // ============================================================

  factory BrainSyncPayload.fromQueuePayload(
    Map<String, dynamic> map, {
    BrainVaultSerializer serializer = const BrainVaultSerializer(),
  }) {
    final encryptedObjectRaw = map['encrypted_object'];

    if (encryptedObjectRaw is! Map) {
      throw const FormatException('encrypted_object ausente na fila E2EE.');
    }

    final payload = BrainSyncPayload(
      vaultId: map['vault_id']?.toString().trim() ?? '',
      objectId: map['object_id']?.toString().trim() ?? '',
      objectVersion: _readInt(map['object_version'], 'object_version'),
      cryptoVersion: _readInt(map['crypto_version'], 'crypto_version'),
      keyVersion: _readInt(map['key_version'], 'key_version'),
      isDeleted: _readBool(map['is_deleted'], 'is_deleted'),
      encryptedObject: Map<String, dynamic>.from(encryptedObjectRaw),
      createdAt: _readDate(map['created_at'], 'created_at'),
      updatedAt: _readDate(map['updated_at'], 'updated_at'),
    );

    payload.validate(serializer: serializer);

    return payload;
  }

  // ============================================================
  // FROM SUPABASE ROW
  // ============================================================

  factory BrainSyncPayload.fromRemoteRow(
    Map<String, dynamic> row, {
    BrainVaultSerializer serializer = const BrainVaultSerializer(),
  }) {
    dynamic encrypted = row['encrypted_object'];

    if (encrypted is String) {
      encrypted = jsonDecode(encrypted);
    }

    if (encrypted is! Map) {
      throw const FormatException('encrypted_object remoto inválido.');
    }

    return BrainSyncPayload.fromQueuePayload(<String, dynamic>{
      'vault_id': row['vault_id'],
      'object_id': row['object_id'],
      'object_version': row['object_version'],
      'crypto_version': row['crypto_version'],
      'key_version': row['key_version'],
      'is_deleted': row['is_deleted'],
      'encrypted_object': Map<String, dynamic>.from(encrypted),
      'created_at': row['created_at'],
      'updated_at': row['updated_at'],
    }, serializer: serializer);
  }

  // ============================================================
  // QUEUE PAYLOAD
  // ============================================================
  //
  // Não inclui user_id.
  //
  // A identidade é resolvida pelo Supabase/Auth somente no
  // momento do envio.
  //
  // ============================================================

  Map<String, dynamic> toQueuePayload() {
    validate();

    return <String, dynamic>{
      'vault_id': vaultId,
      'object_id': objectId,
      'object_version': objectVersion,
      'crypto_version': cryptoVersion,
      'key_version': keyVersion,
      'is_deleted': isDeleted,
      'encrypted_object': Map<String, dynamic>.from(encryptedObject),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // REMOTE ROW
  // ============================================================

  Map<String, dynamic> toRemoteRow({required String userId}) {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError('userId não pode ser vazio.');
    }

    return <String, dynamic>{'user_id': normalizedUserId, ...toQueuePayload()};
  }

  // ============================================================
  // RESTORE OBJECT
  // ============================================================

  BrainVaultObject toVaultObject({
    BrainVaultSerializer serializer = const BrainVaultSerializer(),
  }) {
    validate(serializer: serializer);

    return serializer.deserializeObject(jsonEncode(encryptedObject));
  }

  // ============================================================
  // VALIDATE
  // ============================================================

  void validate({
    BrainVaultSerializer serializer = const BrainVaultSerializer(),
  }) {
    if (vaultId.trim().isEmpty) {
      throw const FormatException('vault_id vazio no BrainSyncPayload.');
    }

    if (objectId.trim().isEmpty) {
      throw const FormatException('object_id vazio no BrainSyncPayload.');
    }

    if (objectVersion <= 0) {
      throw const FormatException('object_version inválida.');
    }

    if (cryptoVersion <= 0) {
      throw const FormatException('crypto_version inválida.');
    }

    if (keyVersion <= 0) {
      throw const FormatException('key_version inválida.');
    }

    _assertNoPlaintextDomainKeys(encryptedObject);

    final object = serializer.deserializeObject(jsonEncode(encryptedObject));

    object.header.validate();

    if (object.header.vaultId != vaultId) {
      throw const FormatException(
        'vault_id do payload não corresponde ao .evobj.',
      );
    }

    if (object.header.objectId != objectId) {
      throw const FormatException(
        'object_id do payload não corresponde ao .evobj.',
      );
    }

    if (object.header.objectVersion.value != objectVersion) {
      throw const FormatException('object_version não corresponde ao .evobj.');
    }

    if (object.header.cryptoVersion.value != cryptoVersion) {
      throw const FormatException('crypto_version não corresponde ao .evobj.');
    }

    if (object.header.keyVersion != keyVersion) {
      throw const FormatException('key_version não corresponde ao .evobj.');
    }

    if (object.isDeleted != isDeleted) {
      throw const FormatException('is_deleted não corresponde ao .evobj.');
    }
  }

  // ============================================================
  // PLAINTEXT GUARD
  // ============================================================
  //
  // Se no futuro alguém tentar colocar acidentalmente um model
  // lógico dentro do envelope de sync, falhamos antes de gravar
  // a SyncQueue.
  //
  // ============================================================

  static void _assertNoPlaintextDomainKeys(dynamic value) {
    const forbiddenKeys = <String>{
      // ========================================================
      // CONTEÚDO PRINCIPAL
      // ========================================================

      'question',
      'answer',
      'content',
      'title',
      'description',
      'topic',

      // ========================================================
      // VÍNCULOS / MODELOS DE DOMÍNIO
      // ========================================================

      'source_note_path',
      'source_note_title',
      'concept_id',
      'model',
      'data',

      // ========================================================
      // FASE 13 — FONTES DO CONHECIMENTO
      // ========================================================
      //
      // Nenhum dado lógico de BrainSource pode aparecer em
      // plaintext dentro do envelope enviado à SyncQueue.
      //
      // Esses campos só podem existir dentro do ciphertext do
      // BrainVaultObject.
      //
      // ========================================================

      'source',
      'sources',
      'reference',
      'author',
      'note',
      'published_at',
    };

    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString().trim().toLowerCase();

        if (forbiddenKeys.contains(key)) {
          throw FormatException(
            'Campo de domínio em plaintext detectado '
            'no payload E2EE: $key',
          );
        }

        _assertNoPlaintextDomainKeys(entry.value);
      }

      return;
    }

    if (value is Iterable) {
      for (final item in value) {
        _assertNoPlaintextDomainKeys(item);
      }
    }
  }

  // ============================================================
  // PARSERS
  // ============================================================

  static int _readInt(dynamic value, String field) {
    if (value is int) {
      return value;
    }

    final parsed = int.tryParse(value?.toString().trim() ?? '');

    if (parsed == null) {
      throw FormatException('$field inválido.');
    }

    return parsed;
  }

  static bool _readBool(dynamic value, String field) {
    if (value is bool) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase();

    if (normalized == 'true' || normalized == '1') {
      return true;
    }

    if (normalized == 'false' || normalized == '0') {
      return false;
    }

    throw FormatException('$field inválido.');
  }

  static DateTime _readDate(dynamic value, String field) {
    final parsed = DateTime.tryParse(value?.toString().trim() ?? '');

    if (parsed == null) {
      throw FormatException('$field inválido.');
    }

    return parsed.toUtc();
  }
}
