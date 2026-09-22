class BrainRemoteGcCandidate {
  const BrainRemoteGcCandidate({
    required this.objectId,
    required this.objectVersion,
    required this.deletedUpdatedAt,
    required this.serverUpdatedAt,
    required this.authorizedDeviceCount,
    required this.acknowledgedDeviceCount,
    required this.eligible,
  });

  final String objectId;
  final int objectVersion;
  final DateTime deletedUpdatedAt;
  final DateTime serverUpdatedAt;
  final int authorizedDeviceCount;
  final int acknowledgedDeviceCount;
  final bool eligible;

  int get missingAcknowledgements =>
      authorizedDeviceCount - acknowledgedDeviceCount;

  factory BrainRemoteGcCandidate.fromMap(Map<String, dynamic> map) {
    final objectId = map['object_id']?.toString().trim() ?? '';
    final version = int.tryParse(map['object_version']?.toString() ?? '');
    final deletedAt = DateTime.tryParse(
      map['deleted_updated_at']?.toString() ?? '',
    )?.toUtc();
    final serverAt = DateTime.tryParse(
      map['server_updated_at']?.toString() ?? '',
    )?.toUtc();
    final authorized =
        int.tryParse(map['authorized_device_count']?.toString() ?? '') ?? -1;
    final acknowledged =
        int.tryParse(map['acknowledged_device_count']?.toString() ?? '') ?? -1;
    final eligible = map['eligible'] == true;

    if (objectId.isEmpty ||
        version == null ||
        version <= 0 ||
        deletedAt == null ||
        serverAt == null ||
        authorized < 0 ||
        acknowledged < 0 ||
        acknowledged > authorized) {
      throw const FormatException('Candidato de GC remoto inválido.');
    }

    return BrainRemoteGcCandidate(
      objectId: objectId,
      objectVersion: version,
      deletedUpdatedAt: deletedAt,
      serverUpdatedAt: serverAt,
      authorizedDeviceCount: authorized,
      acknowledgedDeviceCount: acknowledged,
      eligible: eligible,
    );
  }
}

class BrainRemoteGcReport {
  const BrainRemoteGcReport({
    required this.scanned,
    required this.eligible,
    required this.purged,
    required this.blockedByDevices,
    required this.candidates,
  });

  final int scanned;
  final int eligible;
  final int purged;
  final int blockedByDevices;
  final List<BrainRemoteGcCandidate> candidates;

  @override
  String toString() =>
      'BrainRemoteGcReport(scanned: $scanned, eligible: $eligible, '
      'purged: $purged, blockedByDevices: $blockedByDevices)';
}
