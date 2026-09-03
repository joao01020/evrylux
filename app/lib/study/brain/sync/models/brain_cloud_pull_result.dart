class BrainCloudPullResult {
  const BrainCloudPullResult({
    required this.vaultId,
    required this.remoteCount,
    required this.applied,
    required this.skippedSameVersion,
    required this.skippedNewerLocal,
  });

  final String vaultId;
  final int remoteCount;
  final int applied;
  final int skippedSameVersion;
  final int skippedNewerLocal;

  bool get changed {
    return applied > 0;
  }

  @override
  String toString() {
    return 'BrainCloudPullResult('
        'vaultId: $vaultId, '
        'remoteCount: $remoteCount, '
        'applied: $applied, '
        'skippedSameVersion: $skippedSameVersion, '
        'skippedNewerLocal: $skippedNewerLocal'
        ')';
  }
}
