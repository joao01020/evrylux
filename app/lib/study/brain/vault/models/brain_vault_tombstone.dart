import 'brain_vault_object_version.dart';

// ============================================================
// BRAIN VAULT TOMBSTONE
// ============================================================
//
// Representa a exclusão lógica de um objeto.
//
// Em vez de simplesmente esquecer que um objeto existiu:
//
// object
// ↓
// delete
// ↓
// tombstone
//
// Isso permitirá futuramente que outro dispositivo saiba:
//
// "este objectId foi apagado em uma versão mais nova"
//
// evitando ressuscitar registros antigos durante sync.
//
// ============================================================

class BrainVaultTombstone {
  const BrainVaultTombstone({
    required this.objectId,
    required this.vaultId,
    required this.objectVersion,
    required this.deletedAt,
  });

  // ============================================================
  // IDS
  // ============================================================

  final String objectId;

  final String vaultId;

  // ============================================================
  // VERSION
  // ============================================================

  final BrainVaultObjectVersion objectVersion;

  // ============================================================
  // DELETED AT
  // ============================================================

  final DateTime deletedAt;

  // ============================================================
  // VALIDATE
  // ============================================================

  void validate() {
    if (objectId.trim().isEmpty) {
      throw const FormatException(
        'objectId do tombstone não pode estar vazio.',
      );
    }

    if (vaultId.trim().isEmpty) {
      throw const FormatException(
        'vaultId do tombstone não pode estar vazio.',
      );
    }
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
      'deleted_at': deletedAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory BrainVaultTombstone.fromJson(
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

    final deletedAt = DateTime.tryParse(
      json['deleted_at']?.toString().trim() ??
          '',
    );

    if (deletedAt ==
        null) {
      throw const FormatException(
        'deleted_at do tombstone inválido.',
      );
    }

    final tombstone = BrainVaultTombstone(
      objectId: objectId,
      vaultId: vaultId,
      objectVersion: objectVersion,
      deletedAt: deletedAt.toUtc(),
    );

    tombstone.validate();

    return tombstone;
  }

  // ============================================================
  // COPY
  // ============================================================

  BrainVaultTombstone copyWith({
    String? objectId,
    String? vaultId,
    BrainVaultObjectVersion? objectVersion,
    DateTime? deletedAt,
  }) {
    return BrainVaultTombstone(
      objectId:
          objectId ??
          this.objectId,
      vaultId:
          vaultId ??
          this.vaultId,
      objectVersion:
          objectVersion ??
          this.objectVersion,
      deletedAt:
          deletedAt ??
          this.deletedAt,
    );
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return 'BrainVaultTombstone('
        'objectId: $objectId, '
        'vaultId: $vaultId, '
        'objectVersion: ${objectVersion.value}, '
        'deletedAt: $deletedAt'
        ')';
  }
}
