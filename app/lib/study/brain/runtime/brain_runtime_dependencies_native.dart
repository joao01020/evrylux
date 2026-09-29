import '../../../../app/dependencies/app_dependencies.dart' as app;

final brainController = app.brainController;
final brainRepository = app.brainRepository;
final reviewController = app.reviewController;
final brainDataModeStorage = app.brainDataModeStorage;
final brainDataModeTransitionService = app.brainDataModeTransitionService;
final userStorageScope = app.userStorageScope;

/// Faz o pull E2EE seguro antes de o Brain nativo ler o Vault local.
///
/// O coordinator já aplica gate de dispositivo, merge por object_version,
/// tombstones e deletion floors. Em falha de rede, o app continua offline-first.
Future<void> syncBrainBeforeLoad() async {
  try {
    await app.brainE2eeSyncCoordinator.pullNow();
  } catch (_) {
    // Falha de rede não deve impedir a abertura do Brain.
  }
}
