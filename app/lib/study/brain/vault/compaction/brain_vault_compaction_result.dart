enum BrainVaultCompactionBlockReason {
  retentionNotElapsed,
  pendingSync,
  remoteDeletionNotConfirmed,
  authorizedDeviceCoverageUnknown,
  stateChangedDuringCompaction,
}

class BrainVaultCompactionEntry {
  const BrainVaultCompactionEntry({
    required this.objectId,
    required this.objectVersion,
    required this.deletedAt,
    required this.age,
    required this.eligible,
    required this.blockReasons,
    this.purged = false,
  });

  final String objectId;
  final int objectVersion;
  final DateTime deletedAt;
  final Duration age;
  final bool eligible;
  final bool purged;
  final List<BrainVaultCompactionBlockReason> blockReasons;
}

class BrainVaultCompactionResult {
  const BrainVaultCompactionResult({
    required this.totalObjects,
    required this.activeObjects,
    required this.tombstones,
    required this.retained,
    required this.eligible,
    required this.purged,
    required this.entries,
  });

  final int totalObjects;
  final int activeObjects;
  final int tombstones;
  final int retained;
  final int eligible;
  final int purged;
  final List<BrainVaultCompactionEntry> entries;

  @override
  String toString() {
    return 'BrainVaultCompactionResult('
        'totalObjects: $totalObjects, '
        'activeObjects: $activeObjects, '
        'tombstones: $tombstones, '
        'retained: $retained, '
        'eligible: $eligible, '
        'purged: $purged)';
  }
}
