import 'package:flutter/foundation.dart';

import '../models/brain_data_mode.dart';
import '../services/brain_data_mode_service.dart';

// ============================================================
// BRAIN DATA MODE CONTROLLER
// ============================================================
//
// Controller de apresentação para futuras telas de Settings.
//
// Não conhece:
//
// - Supabase;
// - SyncQueue;
// - Vault internals;
// - Master Key.
//
// A Fase 06 poderá consultar:
//
// controller/service
//        ↓
// canUseCloudSync(...)
//        ↓
// somente então enfileirar ciphertext.
//
// ============================================================

class BrainDataModeController extends ChangeNotifier {
  BrainDataModeController({required BrainDataModeService service})
    : _service = service;

  final BrainDataModeService _service;

  bool _isLoading = false;
  bool _isSaving = false;

  BrainDataMode? _mode;

  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isLoading {
    return _isLoading;
  }

  bool get isSaving {
    return _isSaving;
  }

  bool get isBusy {
    return _isLoading || _isSaving;
  }

  BrainDataMode? get mode {
    return _mode;
  }

  bool get isInitialized {
    return _mode != null;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  bool get isLocalMode {
    return _mode == BrainDataMode.local;
  }

  bool get isCloudMode {
    return _mode == BrainDataMode.cloud;
  }

  bool get allowsCloudSync {
    return _mode?.allowsCloudSync ?? false;
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_isLoading) {
      return;
    }

    if (_mode != null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _mode = await _service.initialize();
    } catch (error) {
      _errorMessage = 'Não foi possível carregar o modo de dados do Cérebro.';

      debugPrint('[BRAIN DATA MODE] Erro ao inicializar: $error');
    } finally {
      _isLoading = false;

      notifyListeners();
    }
  }

  // ============================================================
  // SET MODE
  // ============================================================

  Future<bool> setMode(BrainDataMode mode) async {
    if (_isSaving) {
      return false;
    }

    if (_mode == mode) {
      return true;
    }

    _isSaving = true;
    _errorMessage = null;

    notifyListeners();

    try {
      _mode = await _service.setMode(mode);

      return true;
    } catch (error) {
      _errorMessage = 'Não foi possível alterar o modo de dados do Cérebro.';

      debugPrint('[BRAIN DATA MODE] Erro ao salvar: $error');

      return false;
    } finally {
      _isSaving = false;

      notifyListeners();
    }
  }

  // ============================================================
  // LOCAL / CLOUD SHORTCUTS
  // ============================================================

  Future<bool> useLocalMode() {
    return setMode(BrainDataMode.local);
  }

  Future<bool> useCloudMode() {
    return setMode(BrainDataMode.cloud);
  }

  // ============================================================
  // CLOUD GATE
  // ============================================================

  bool canUseCloudSync({required bool isAuthenticated}) {
    if (_mode == null) {
      return false;
    }

    return _service.canUseCloudSync(isAuthenticated: isAuthenticated);
  }

  // ============================================================
  // ERROR
  // ============================================================

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }
}
