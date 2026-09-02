import 'dart:convert';

import '../../security/models/brain_encrypted_payload.dart';
import 'brain_vault_object_header.dart';
import 'brain_vault_tombstone.dart';

// ============================================================
// BRAIN VAULT OBJECT
// ============================================================
//
// Unidade física/lógica armazenável do Vault.
//
// Um objeto ativo possui:
//
// header
// +
// encrypted_payload
//
// Um objeto excluído possui:
//
// header
// +
// tombstone
//
// Nunca deve existir:
//
// payload + tombstone
//
// simultaneamente.
//
// ============================================================

class BrainVaultObject {
  const BrainVaultObject({
    required this.header,
    this.encryptedPayload,
    this.tombstone,
  });

  // ============================================================
  // HEADER
  // ============================================================

  final BrainVaultObjectHeader header;

  // ============================================================
  // PAYLOAD
  // ============================================================

  final BrainEncryptedPayload? encryptedPayload;

  // ============================================================
  // TOMBSTONE
  // ============================================================

  final BrainVaultTombstone? tombstone;

  // ============================================================
  // STATE
  // ============================================================

  bool get isDeleted {
    return tombstone !=
        null;
  }

  bool get isActive {
    return !isDeleted;
  }

  bool get hasPayload {
    return encryptedPayload !=
        null;
  }

  // ============================================================
  // VALIDATE
  // ============================================================

  void validate() {
    header.validate();

    final hasEncryptedPayload =
        encryptedPayload !=
        null;

    final hasTombstone =
        tombstone !=
        null;

    if (hasEncryptedPayload ==
        hasTombstone) {
      throw const FormatException(
        'BrainVaultObject deve conter exatamente '
        'um encryptedPayload ou um tombstone.',
      );
    }

    if (hasTombstone) {
      final deleted = tombstone!;

      deleted.validate();

      if (deleted.objectId !=
          header.objectId) {
        throw const FormatException(
          'objectId do tombstone não corresponde ao header.',
        );
      }

      if (deleted.vaultId !=
          header.vaultId) {
        throw const FormatException(
          'vaultId do tombstone não corresponde ao header.',
        );
      }

      if (deleted.objectVersion !=
          header.objectVersion) {
        throw const FormatException(
          'objectVersion do tombstone não corresponde ao header.',
        );
      }
    }

    if (hasEncryptedPayload) {
      final payload = encryptedPayload!;

      if (payload.metadata.version !=
          header.cryptoVersion) {
        throw const FormatException(
          'cryptoVersion do payload não corresponde ao header.',
        );
      }
    }
  }

  // ============================================================
  // ACTIVE FACTORY
  // ============================================================

  factory BrainVaultObject.active({
    required BrainVaultObjectHeader header,
    required BrainEncryptedPayload encryptedPayload,
  }) {
    final object = BrainVaultObject(
      header: header,
      encryptedPayload: encryptedPayload,
    );

    object.validate();

    return object;
  }

  // ============================================================
  // DELETED FACTORY
  // ============================================================

  factory BrainVaultObject.deleted({
    required BrainVaultObjectHeader header,
    required BrainVaultTombstone tombstone,
  }) {
    final object = BrainVaultObject(
      header: header,
      tombstone: tombstone,
    );

    object.validate();

    return object;
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
      'header': header.toJson(),

      if (encryptedPayload !=
          null)
        'encrypted_payload': encryptedPayload!.toJson(),

      if (tombstone !=
          null)
        'tombstone': tombstone!.toJson(),
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

  factory BrainVaultObject.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    final rawHeader = json['header'];

    if (rawHeader
        is! Map) {
      throw const FormatException(
        'Header do BrainVaultObject inválido.',
      );
    }

    final rawPayload = json['encrypted_payload'];

    final rawTombstone = json['tombstone'];

    final header = BrainVaultObjectHeader.fromJson(
      Map<
        String,
        dynamic
      >.from(
        rawHeader,
      ),
    );

    BrainEncryptedPayload? payload;

    BrainVaultTombstone? tombstone;

    if (rawPayload !=
        null) {
      if (rawPayload
          is! Map) {
        throw const FormatException(
          'encrypted_payload inválido.',
        );
      }

      payload = BrainEncryptedPayload.fromJson(
        Map<
          String,
          dynamic
        >.from(
          rawPayload,
        ),
      );
    }

    if (rawTombstone !=
        null) {
      if (rawTombstone
          is! Map) {
        throw const FormatException(
          'tombstone inválido.',
        );
      }

      tombstone = BrainVaultTombstone.fromJson(
        Map<
          String,
          dynamic
        >.from(
          rawTombstone,
        ),
      );
    }

    final object = BrainVaultObject(
      header: header,
      encryptedPayload: payload,
      tombstone: tombstone,
    );

    object.validate();

    return object;
  }

  // ============================================================
  // FROM JSON STRING
  // ============================================================

  factory BrainVaultObject.fromJsonString(
    String jsonString,
  ) {
    final decoded = jsonDecode(
      jsonString,
    );

    if (decoded
        is! Map) {
      throw const FormatException(
        'BrainVaultObject JSON inválido.',
      );
    }

    return BrainVaultObject.fromJson(
      Map<
        String,
        dynamic
      >.from(
        decoded,
      ),
    );
  }

  // ============================================================
  // COPY
  // ============================================================

  BrainVaultObject copyWith({
    BrainVaultObjectHeader? header,
    BrainEncryptedPayload? encryptedPayload,
    BrainVaultTombstone? tombstone,
    bool clearEncryptedPayload = false,
    bool clearTombstone = false,
  }) {
    return BrainVaultObject(
      header:
          header ??
          this.header,
      encryptedPayload: clearEncryptedPayload
          ? null
          : encryptedPayload ??
                this.encryptedPayload,
      tombstone: clearTombstone
          ? null
          : tombstone ??
                this.tombstone,
    );
  }

  // ============================================================
  // STRING
  // ============================================================
  //
  // Não imprimir ciphertext.
  //
  // ============================================================

  @override
  String toString() {
    return 'BrainVaultObject('
        'objectId: ${header.objectId}, '
        'vaultId: ${header.vaultId}, '
        'objectVersion: ${header.objectVersion.value}, '
        'deleted: $isDeleted'
        ')';
  }
}
