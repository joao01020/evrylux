class BrainBackupRestoreResult {
  const BrainBackupRestoreResult({
    required this.vaultId,
    required this.totalInBackup,
    required this.restored,
    required this.skippedNewerLocal,
  });

  final String vaultId;
  final int totalInBackup;
  final int restored;
  final int skippedNewerLocal;

  bool get changed {
    return restored > 0;
  }

  @override
  String toString() {
    return 'BrainBackupRestoreResult('
        'vaultId: $vaultId, '
        'totalInBackup: $totalInBackup, '
        'restored: $restored, '
        'skippedNewerLocal: $skippedNewerLocal'
        ')';
  }
}
