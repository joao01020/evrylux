class BrainCloudPullResult {
  const BrainCloudPullResult({
    required this.vaultId,
    required this.remoteCount,
    required this.applied,
    required this.skippedSameVersion,
    required this.skippedNewerLocal,
    this.remoteDeletionFloorCount = 0,
    this.appliedRemoteFloors = 0,
    this.purgedByRemoteFloor = 0,
    this.skippedCompactedFloor = 0,
    this.rejectedResurrection = 0,
  });

  final String vaultId;
  final int remoteCount;
  final int remoteDeletionFloorCount;
  final int applied;
  final int appliedRemoteFloors;
  final int purgedByRemoteFloor;
  final int skippedSameVersion;
  final int skippedNewerLocal;
  final int skippedCompactedFloor;
  final int rejectedResurrection;

  bool get changed =>
      applied > 0 || appliedRemoteFloors > 0 || purgedByRemoteFloor > 0;

  bool get hasRemoteState => remoteCount > 0 || remoteDeletionFloorCount > 0;

  @override
  String toString() {
    return 'BrainCloudPullResult('
        'vaultId: $vaultId, '
        'remoteCount: $remoteCount, '
        'remoteDeletionFloorCount: $remoteDeletionFloorCount, '
        'applied: $applied, '
        'appliedRemoteFloors: $appliedRemoteFloors, '
        'purgedByRemoteFloor: $purgedByRemoteFloor, '
        'skippedSameVersion: $skippedSameVersion, '
        'skippedNewerLocal: $skippedNewerLocal, '
        'skippedCompactedFloor: $skippedCompactedFloor, '
        'rejectedResurrection: $rejectedResurrection'
        ')';
  }
}
