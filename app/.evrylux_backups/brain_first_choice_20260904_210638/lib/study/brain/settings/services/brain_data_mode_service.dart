import '../models/brain_data_mode.dart';
import '../storage/brain_data_mode_storage.dart';

// ============================================================
// BRAIN DATA MODE SERVICE
// ============================================================
//
// Fonte de verdade da decisão:
//
// LOCAL
// ou
// CLOUD
//
// IMPORTANTE:
//
// Esta Fase 05 NÃO implementa o sync E2EE.
//
// Ela somente define o gate:
//
// local
//   -> Brain não pode sincronizar.
//
// cloud
//   -> Brain pode entrar no fluxo de sync E2EE da Fase 06.
//
// Nunca interpretar "cloud" como autorização para enviar
// plaintext.
//
// ============================================================

class BrainDataModeService {
  BrainDataModeService({
    required BrainDataModeStorage storage,
    BrainDataMode defaultMode = BrainDataMode.local,
  }) : _storage = storage,
       _defaultMode = defaultMode;

  final BrainDataModeStorage _storage;

  final BrainDataMode _defaultMode;

  BrainDataMode? _currentMode;

  bool _initialized = false;

  // ============================================================
  // STATE
  // ============================================================

  bool get isInitialized {
    return _initialized;
  }

  BrainDataMode get currentMode {
    if (!_initialized || _currentMode == null) {
      throw StateError('BrainDataModeService ainda não foi inicializado.');
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

  Future<BrainDataMode> initialize() async {
    if (_initialized && _currentMode != null) {
      return _currentMode!;
    }

    final stored = await _storage.load();

    _currentMode = stored ?? _defaultMode;

    _initialized = true;

    return _currentMode!;
  }

  // ============================================================
  // SET MODE
  // ============================================================

  Future<BrainDataMode> setMode(BrainDataMode mode) async {
    await _storage.save(mode);

    _currentMode = mode;
    _initialized = true;

    return mode;
  }

  // ============================================================
  // LOCAL
  // ============================================================

  Future<BrainDataMode> useLocalMode() {
    return setMode(BrainDataMode.local);
  }

  // ============================================================
  // CLOUD
  // ============================================================

  Future<BrainDataMode> useCloudMode() {
    return setMode(BrainDataMode.cloud);
  }

  // ============================================================
  // CLOUD SYNC GATE
  // ============================================================

  bool canUseCloudSync({required bool isAuthenticated}) {
    if (!allowsCloudSync) {
      return false;
    }

    if (requiresAuthentication && !isAuthenticated) {
      return false;
    }

    return true;
  }

  // ============================================================
  // RESET
  // ============================================================

  Future<BrainDataMode> reset() async {
    await _storage.clear();

    _currentMode = _defaultMode;
    _initialized = true;

    return _currentMode!;
  }
}
