import '../controllers/brain_data_mode_controller.dart';

import '../../devices/models/brain_device_record.dart';
import '../../devices/services/brain_device_authorization_service.dart';
import '../../sync/services/brain_e2ee_sync_coordinator.dart';
import '../../vault/services/brain_vault_service.dart';

// ============================================================
// BRAIN DATA MODE TRANSITION SERVICE
// ============================================================
//
// Centraliza a transição operacional entre:
//
// LOCAL
//   -> permanece local-first;
//   -> não transmite novos objetos para a nuvem;
//   -> NÃO apaga automaticamente a cópia remota existente.
//
// CLOUD
//   -> permanece local-first;
//   -> registra/valida o dispositivo;
//   -> faz pull seguro quando autorizado;
//   -> prepara TODOS os objetos locais existentes para sync E2EE;
//   -> solicita processamento da fila global.
//
// A interface pode usar onProgress para explicar cada etapa.
//
// ============================================================

class BrainCloudActivationResult {
  const BrainCloudActivationResult({
    required this.localObjectCount,
    required this.queuedObjectCount,
    required this.device,
    required this.remoteSyncAttempted,
    this.deviceRegistrationError,
  });

  final int localObjectCount;
  final int queuedObjectCount;
  final BrainDeviceRecord? device;
  final bool remoteSyncAttempted;
  final Object? deviceRegistrationError;

  bool get isAuthorized {
    return device?.isAuthorized ?? false;
  }

  bool get isPending {
    return device?.isPending ?? false;
  }

  bool get cloudProtectionReady {
    return isAuthorized && deviceRegistrationError == null;
  }
}

class BrainDataModeTransitionService {
  BrainDataModeTransitionService({
    required BrainDataModeController modeController,
    required BrainVaultService vaultService,
    required BrainDeviceAuthorizationService deviceAuthorizationService,
    required BrainE2eeSyncCoordinator syncCoordinator,
    required bool Function() isAuthenticated,
    required String Function() deviceNameProvider,
    required Future<void> Function() forceSync,
  }) : _modeController = modeController,
       _vaultService = vaultService,
       _deviceAuthorizationService = deviceAuthorizationService,
       _syncCoordinator = syncCoordinator,
       _isAuthenticated = isAuthenticated,
       _deviceNameProvider = deviceNameProvider,
       _forceSync = forceSync;

  final BrainDataModeController _modeController;
  final BrainVaultService _vaultService;
  final BrainDeviceAuthorizationService _deviceAuthorizationService;
  final BrainE2eeSyncCoordinator _syncCoordinator;
  final bool Function() _isAuthenticated;
  final String Function() _deviceNameProvider;
  final Future<void> Function() _forceSync;

  // ============================================================
  // ACTIVATE LOCAL
  // ============================================================

  Future<void> activateLocal({
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Ativando o modo Local...');

    await _modeController.initialize();

    final saved = await _modeController.useLocalMode();

    if (!saved) {
      throw StateError(
        _modeController.errorMessage ?? 'Não foi possível ativar o modo Local.',
      );
    }

    onProgress?.call('Modo Local ativado.');
  }

  // ============================================================
  // ACTIVATE CLOUD
  // ============================================================

  Future<BrainCloudActivationResult> activateCloud({
    void Function(String message)? onProgress,
  }) async {
    if (!_isAuthenticated()) {
      throw StateError('Entre na sua conta antes de ativar o Cloud.');
    }

    onProgress?.call('Preparando a proteção do seu Cérebro...');

    await _modeController.initialize();

    // O Vault precisa existir antes de qualquer transição Cloud.
    final manifest = await _vaultService.openVault();

    final localObjects = await _vaultService.loadAllEncryptedObjects();

    onProgress?.call(
      localObjects.isEmpty
          ? 'Nenhum item local precisa ser enviado.'
          : 'Encontrados ${localObjects.length} itens locais para proteger.',
    );

    final saved = await _modeController.useCloudMode();

    if (!saved) {
      throw StateError(
        _modeController.errorMessage ?? 'Não foi possível ativar o modo Cloud.',
      );
    }

    // ----------------------------------------------------------
    // DEVICE
    // ----------------------------------------------------------
    //
    // Falha de rede aqui NÃO volta o usuário para Local.
    // A escolha Cloud permanece persistida e o bootstrap global
    // tentará novamente quando houver conectividade.
    //
    // ----------------------------------------------------------

    BrainDeviceRecord? device;
    Object? deviceRegistrationError;

    try {
      onProgress?.call('Verificando este dispositivo...');

      device = await _deviceAuthorizationService.registerCurrentDevice(
        vaultId: manifest.vaultId,
        deviceName: _deviceNameProvider(),
      );
    } catch (error) {
      deviceRegistrationError = error;
    }

    // ----------------------------------------------------------
    // SAFE PULL
    // ----------------------------------------------------------

    if (device?.isAuthorized ?? false) {
      onProgress?.call('Verificando sua cópia protegida na nuvem...');

      await _syncCoordinator.pullNow();
    }

    // ----------------------------------------------------------
    // BACKFILL LOCAL
    // ----------------------------------------------------------
    //
    // Este é o passo que garante Local -> Cloud completo:
    // conhecimento criado ANTES da ativação também entra na fila.
    //
    // ----------------------------------------------------------

    onProgress?.call(
      localObjects.isEmpty
          ? 'Preparando sincronização...'
          : 'Protegendo ${localObjects.length} itens...',
    );

    final queued = await _syncCoordinator.queueAllLocal(
      onProgress: (completed, total) {
        if (total <= 0) {
          onProgress?.call('Preparando sincronização...');

          return;
        }

        onProgress?.call('Protegendo $completed de $total itens...');
      },
    );

    var remoteSyncAttempted = false;

    if (device?.isAuthorized ?? false) {
      onProgress?.call('Enviando a cópia criptografada para a nuvem...');

      remoteSyncAttempted = true;

      await _forceSync();
    }

    if (device?.isPending ?? false) {
      onProgress?.call(
        'Cloud ativado. Este dispositivo ainda precisa ser autorizado.',
      );
    } else if (deviceRegistrationError != null) {
      onProgress?.call(
        'Cloud ativado. A proteção será concluída quando houver conexão.',
      );
    } else {
      onProgress?.call(
        'Cloud ativado. Seus dados estão protegidos automaticamente.',
      );
    }

    return BrainCloudActivationResult(
      localObjectCount: localObjects.length,
      queuedObjectCount: queued,
      device: device,
      remoteSyncAttempted: remoteSyncAttempted,
      deviceRegistrationError: deviceRegistrationError,
    );
  }
}
