class BrainRemoteDeletionFloor {
  const BrainRemoteDeletionFloor({
    required this.vaultId,
    required this.objectId,
    required this.objectVersion,
    required this.deletedAt,
    required this.compactedAt,
  });

  final String vaultId;
  final String objectId;
  final int objectVersion;
  final DateTime deletedAt;
  final DateTime compactedAt;

  factory BrainRemoteDeletionFloor.fromMap(Map<String, dynamic> map) {
    final vaultId = map['vault_id']?.toString().trim() ?? '';
    final objectId = map['object_id']?.toString().trim() ?? '';
    final objectVersion = int.tryParse(map['object_version']?.toString() ?? '');
    final deletedAt = DateTime.tryParse(map['deleted_at']?.toString() ?? '')?.toUtc();
    final compactedAt =
        DateTime.tryParse(map['compacted_at']?.toString() ?? '')?.toUtc();

    if (vaultId.isEmpty ||
        objectId.isEmpty ||
        objectVersion == null ||
        objectVersion <= 0 ||
        deletedAt == null ||
        compactedAt == null) {
      throw const FormatException('Deletion floor remoto inválido.');
    }

    return BrainRemoteDeletionFloor(
      vaultId: vaultId,
      objectId: objectId,
      objectVersion: objectVersion,
      deletedAt: deletedAt,
      compactedAt: compactedAt,
    );
  }
}

class BrainDeletionObservation {
  const BrainDeletionObservation({
    required this.objectId,
    required this.objectVersion,
  });

  final String objectId;
  final int objectVersion;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'object_id': objectId,
        'object_version': objectVersion,
      };
}
