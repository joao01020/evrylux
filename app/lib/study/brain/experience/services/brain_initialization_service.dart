import '../../controllers/brain_controller.dart';
import '../../settings/models/brain_data_mode.dart';
import '../../settings/storage/brain_data_mode_storage.dart';
import '../../../../brain/visualization/services/brain_visual_state_storage.dart';

/// Snapshot imutável dos dados necessários para decidir o fluxo
/// inicial da experiência do Brain.
class BrainInitializationResult {
  const BrainInitializationResult({
    required this.knowledgeCount,
    required this.introSeen,
    required this.storedDataMode,
  });

  final int knowledgeCount;

  final bool introSeen;

  final BrainDataMode? storedDataMode;

  bool get needsBirth => !introSeen;

  bool get needsDataModeChoice => storedDataMode == null;

  BrainInitializationResult copyWith({
    int? knowledgeCount,
    bool? introSeen,
    BrainDataMode? storedDataMode,
    bool clearStoredDataMode = false,
  }) {
    return BrainInitializationResult(
      knowledgeCount: knowledgeCount ?? this.knowledgeCount,
      introSeen: introSeen ?? this.introSeen,
      storedDataMode: clearStoredDataMode
          ? null
          : storedDataMode ?? this.storedDataMode,
    );
  }
}

/// Carrega e persiste somente o estado necessário para a primeira
/// experiência do Brain.
///
/// Não conhece BuildContext, widgets, dialogs ou navegação.
class BrainInitializationService {
  BrainInitializationService({
    required BrainController brainController,
    required BrainVisualStateStorage visualStateStorage,
    required BrainDataModeStorage dataModeStorage,
  }) : _brainController = brainController,
       _visualStateStorage = visualStateStorage,
       _dataModeStorage = dataModeStorage;

  final BrainController _brainController;

  final BrainVisualStateStorage _visualStateStorage;

  final BrainDataModeStorage _dataModeStorage;

  Future<BrainInitializationResult> initialize() async {
    if (!_brainController.isInitialized) {
      await _brainController.initialize();
    }

    var introSeen = await _visualStateStorage.readIntroSeen();

    final storedDataMode = await _dataModeStorage.load();

    // Migração segura para contas que já possuíam Cérebro antes da Web.
    // Se já existe conhecimento persistido, a animação de nascimento não
    // representa uma conta nova e não deve reaparecer neste navegador.
    if (!introSeen && _brainController.notes.isNotEmpty) {
      await _visualStateStorage.writeIntroSeen(true);
      introSeen = true;
    }

    return BrainInitializationResult(
      knowledgeCount: _brainController.notes.length,
      introSeen: introSeen,
      storedDataMode: storedDataMode,
    );
  }

  Future<void> markBirthCompleted() async {
    await _visualStateStorage.writeIntroSeen(true);
  }
}
