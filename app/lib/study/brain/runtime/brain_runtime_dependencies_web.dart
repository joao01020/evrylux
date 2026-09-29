import '../controllers/brain_controller.dart';
import '../controllers/review_controller.dart';
import '../repositories/brain_repository_web.dart' as web_brain_repository;
import '../repositories/review_repository_web.dart' as web_review_repository;
import '../settings/services/brain_data_mode_transition_service_web.dart' as web_mode_transition;
import '../settings/storage/brain_data_mode_storage.dart';
import '../settings/storage/brain_data_mode_storage_web.dart';
import '../../../web_app/services/web_brain_device_service.dart';
import '../../../web_app/services/web_brain_secure_storage.dart';

final WebBrainSecureStorage
_webBrainStorage = WebBrainSecureStorage();

final WebBrainDeviceService
_webBrainDeviceService = WebBrainDeviceService(
  storage: _webBrainStorage,
);

/// Repositório Web real do Brain.
///
/// Importamos a implementação Web diretamente neste arquivo para que o
/// analisador Dart do desktop não resolva acidentalmente o export condicional
/// para `brain_repository_native.dart` ao analisar este arquivo isoladamente.
final web_brain_repository.BrainRepository
brainRepository = web_brain_repository.BrainRepository(
  storage: _webBrainStorage,
);

/// O cast para dynamic aqui é intencional apenas para manter o analisador do
/// host (Linux/macOS) compatível. Durante um build Web, o import condicional
/// usado por BrainController resolve BrainRepository para a implementação Web,
/// então o tipo concreto é o esperado em runtime.
final BrainController
brainController = BrainController(
  repository:
      brainRepository
          as dynamic,
);

final web_review_repository.ReviewRepository
reviewRepository = web_review_repository.ReviewRepository(
  storage: _webBrainStorage,
);

final ReviewController
reviewController = ReviewController(
  repository:
      reviewRepository
          as dynamic,
);

final BrainDataModeStorage
brainDataModeStorage = WebBrainDataModeStorage();

final web_mode_transition.BrainDataModeTransitionService
brainDataModeTransitionService = web_mode_transition.BrainDataModeTransitionService(
  storage: brainDataModeStorage,
  deviceService: _webBrainDeviceService,
  secureStorage: _webBrainStorage,
);

/// O storage visual Web ignora filesystem e usa browser storage.
final Object
userStorageScope = Object();
