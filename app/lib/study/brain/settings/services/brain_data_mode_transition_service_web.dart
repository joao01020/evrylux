import '../../devices/models/brain_device_record.dart';
import '../models/brain_data_mode.dart';
import '../storage/brain_data_mode_storage.dart';
import '../../../../web_app/services/web_brain_device_service.dart';
import '../../../../web_app/services/web_brain_secure_storage.dart';

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

  bool get isAuthorized => device?.isAuthorized ?? false;
  bool get isPending => device?.isPending ?? false;
  bool get cloudProtectionReady =>
      isAuthorized && deviceRegistrationError == null;
}

/// Versão Web da transição Local/Cloud.
///
/// Na Web, o Brain usa o Vault E2EE remoto como fonte persistente. O modo
/// "Local" apenas impede novas operações Cloud até o usuário escolher Cloud;
/// não há filesystem nativo para criar um Vault local equivalente ao desktop.
class BrainDataModeTransitionService {
  BrainDataModeTransitionService({
    required BrainDataModeStorage storage,
    required WebBrainDeviceService deviceService,
    required WebBrainSecureStorage secureStorage,
  }) : _storage = storage,
       _deviceService = deviceService,
       _secureStorage = secureStorage;

  final BrainDataModeStorage _storage;
  final WebBrainDeviceService _deviceService;
  final WebBrainSecureStorage _secureStorage;

  Future<void> activateLocal({
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Ativando o modo Local...');
    await _storage.save(BrainDataMode.local);
    onProgress?.call('Modo Local ativado.');
  }

  Future<BrainCloudActivationResult> activateCloud({
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Preparando a proteção do seu Cérebro...');
    await _storage.save(BrainDataMode.cloud);

    BrainDeviceRecord? device;
    Object? registrationError;

    try {
      onProgress?.call('Verificando este dispositivo...');

      final bootstrap = await _deviceService.bootstrapAccess();
      device = bootstrap.state.record;

      if (bootstrap.firstDeviceBootstrap && bootstrap.state.ready) {
        onProgress?.call(
          'Cérebro protegido. Este é o primeiro dispositivo confiável.',
        );
      } else if (device.isPending) {
        onProgress?.call(
          'Cloud ativado. Este dispositivo ainda precisa ser autorizado.',
        );
      } else if (bootstrap.state.ready) {
        onProgress?.call('Cloud ativado. Cérebro protegido e conectado.');
      } else {
        onProgress?.call(
          'Cloud ativado, mas a chave local ainda não está disponível.',
        );
      }
    } catch (error) {
      registrationError = error;

      onProgress?.call(
        'Cloud ativado. A conexão será concluída '
        'quando o acesso estiver disponível.',
      );
    }

    return BrainCloudActivationResult(
      localObjectCount: 0,
      queuedObjectCount: 0,
      device: device,
      remoteSyncAttempted:
          device?.isAuthorized == true && registrationError == null,
      deviceRegistrationError: registrationError,
    );
  }
}
