import '../../../../app/dependencies/app_dependencies.dart' as app;

final brainController = app.brainController;
final brainRepository = app.brainRepository;
final reviewController = app.reviewController;
final brainDataModeStorage = app.brainDataModeStorage;
final brainDataModeTransitionService = app.brainDataModeTransitionService;
final userStorageScope = app.userStorageScope;

/// Faz o pull E2EE seguro antes de o Cérebro nativo ler o Vault local.
///
/// O coordinator já aplica:
/// - gate de dispositivo;
/// - merge por object_version;
/// - tombstones;
/// - deletion floors.
///
/// Quando o pull realmente altera o Vault, os stores precisam invalidar
/// seus caches em memória antes de o BrainController reler as notas.
/// Caso contrário, o objeto novo existe no disco, mas loadNotes() pode
/// continuar devolvendo o índice/cache anterior.
Future<
  void
>
syncBrainBeforeLoad() async {
  try {
    final result = await app.brainE2eeSyncCoordinator.pullNow();

    if (result ==
        null) {
      return;
    }

    final vaultChanged =
        result.applied >
            0 ||
        result.appliedRemoteFloors >
            0 ||
        result.purgedByRemoteFloor >
            0;

    if (!vaultChanged) {
      return;
    }

    app.brainNoteVaultStore.invalidateCache();
    app.brainConceptVaultStore.invalidateCache();
    app.brainReviewVaultStore.invalidateCache();
  } catch (
    _
  ) {
    // Falha de rede/sync não deve impedir a abertura do Cérebro.
  }
}
