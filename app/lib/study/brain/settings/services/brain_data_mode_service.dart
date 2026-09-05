import '../models/brain_data_mode.dart';
import '../storage/brain_data_mode_storage.dart';

// ============================================================
// BRAIN DATA MODE SERVICE
// ============================================================
//
// Fonte de verdade operacional da decisão LOCAL / CLOUD.
//
// A preferência persistida pode ser isolada por conta. Por isso
// este serviço também conhece um identificador de scope e invalida
// seu cache quando o usuário autenticado muda.
//
// ============================================================

class BrainDataModeService {
  BrainDataModeService({
    required BrainDataModeStorage storage,
    BrainDataMode defaultMode = BrainDataMode.local,
    String? Function()? scopeProvider,
  }) : _storage = storage,
       _defaultMode = defaultMode,
       _scopeProvider = scopeProvider;

  final BrainDataModeStorage _storage;

  final BrainDataMode _defaultMode;

  final String? Function()? _scopeProvider;

  BrainDataMode? _currentMode;

  bool _initialized = false;

  String? _initializedScope;

  // ============================================================
  // SCOPE
  // ============================================================

  String? get _currentScope {
    final raw = _scopeProvider?.call()?.trim();

    if (raw ==
            null ||
        raw.isEmpty) {
      return null;
    }

    return raw;
  }

  bool get isInitializedForCurrentScope {
    return _initialized &&
        _currentMode !=
            null &&
        _initializedScope ==
            _currentScope;
  }

  // ============================================================
  // STATE
  // ============================================================

  bool get isInitialized {
    return isInitializedForCurrentScope;
  }

  BrainDataMode get currentMode {
    if (!isInitializedForCurrentScope ||
        _currentMode ==
            null) {
      throw StateError(
        'BrainDataModeService ainda não foi inicializado para a conta atual.',
      );
    }

    return _currentMode!;
  }

  bool get isLocalOnly {
    return currentMode.isLocalOnly;
  }

  bool get allowsCloudSync {
    return currentMode.allowsCloudSync;
  }

  bool get requiresAuthentication {
    return currentMode.requiresAuthentication;
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    BrainDataMode
  >
  initialize() async {
    final scope = _currentScope;

    if (isInitializedForCurrentScope &&
        _currentMode !=
            null) {
      return _currentMode!;
    }

    final stored = await _storage.load();

    // O default Local é apenas fail-safe operacional.
    // Ele NÃO é salvo automaticamente. Assim, quando não existe
    // escolha persistida, a BrainScreen ainda pode detectar null
    // no storage e mostrar o modal obrigatório de primeira escolha.
    _currentMode =
        stored ??
        _defaultMode;

    _initializedScope = scope;
    _initialized = true;

    return _currentMode!;
  }

  // ============================================================
  // SET MODE
  // ============================================================

  Future<
    BrainDataMode
  >
  setMode(
    BrainDataMode mode,
  ) async {
    await _storage.save(
      mode,
    );

    _currentMode = mode;
    _initializedScope = _currentScope;
    _initialized = true;

    return mode;
  }

  // ============================================================
  // LOCAL / CLOUD
  // ============================================================

  Future<
    BrainDataMode
  >
  useLocalMode() {
    return setMode(
      BrainDataMode.local,
    );
  }

  Future<
    BrainDataMode
  >
  useCloudMode() {
    return setMode(
      BrainDataMode.cloud,
    );
  }

  // ============================================================
  // CLOUD SYNC GATE
  // ============================================================

  bool canUseCloudSync({
    required bool isAuthenticated,
  }) {
    // Se a conta mudou e o serviço ainda não foi inicializado
    // para o novo scope, falha fechado: nada de Cloud.
    if (!isInitializedForCurrentScope) {
      return false;
    }

    if (!allowsCloudSync) {
      return false;
    }

    if (requiresAuthentication &&
        !isAuthenticated) {
      return false;
    }

    return true;
  }

  // ============================================================
  // RESET
  // ============================================================

  Future<
    BrainDataMode
  >
  reset() async {
    await _storage.clear();

    _currentMode = _defaultMode;
    _initializedScope = _currentScope;
    _initialized = true;

    return _currentMode!;
  }
}
