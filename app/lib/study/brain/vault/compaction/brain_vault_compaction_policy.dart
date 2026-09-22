class BrainVaultCompactionPolicy {
  const BrainVaultCompactionPolicy({
    this.tombstoneRetention = const Duration(days: 30),
    this.requireRemoteDeletionConfirmation = true,
    this.requireAuthorizedDeviceCoverage = true,
  });

  final Duration tombstoneRetention;
  final bool requireRemoteDeletionConfirmation;
  final bool requireAuthorizedDeviceCoverage;

  void validate() {
    if (tombstoneRetention.isNegative) {
      throw ArgumentError.value(
        tombstoneRetention,
        'tombstoneRetention',
        'A retenção não pode ser negativa.',
      );
    }
  }
}
