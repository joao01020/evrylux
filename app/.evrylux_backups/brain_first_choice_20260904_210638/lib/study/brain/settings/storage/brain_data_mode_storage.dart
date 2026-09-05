import 'package:shared_preferences/shared_preferences.dart';

import '../models/brain_data_mode.dart';

// ============================================================
// BRAIN DATA MODE STORAGE
// ============================================================
//
// Persiste SOMENTE a preferência operacional:
//
// local
// cloud
//
// Não armazena:
//
// - Master Key;
// - conteúdo;
// - perguntas;
// - respostas;
// - ciphertext;
// - credenciais.
//
// Portanto SharedPreferences é aceitável para esta configuração
// não sensível.
//
// ============================================================

abstract class BrainDataModeStorage {
  const BrainDataModeStorage();

  Future<BrainDataMode?> load();

  Future<void> save(BrainDataMode mode);

  Future<void> clear();
}

// ============================================================
// SHARED PREFERENCES IMPLEMENTATION
// ============================================================

class SharedPreferencesBrainDataModeStorage extends BrainDataModeStorage {
  SharedPreferencesBrainDataModeStorage({
    Future<SharedPreferences> Function()? preferencesProvider,
  }) : _preferencesProvider =
           preferencesProvider ?? SharedPreferences.getInstance;

  static const String storageKey = 'evrylux.brain.data_mode.v1';

  final Future<SharedPreferences> Function() _preferencesProvider;

  @override
  Future<BrainDataMode?> load() async {
    final preferences = await _preferencesProvider();

    final raw = preferences.getString(storageKey);

    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    final mode = BrainDataMode.tryParse(raw);

    if (mode == null) {
      // Fail closed:
      //
      // configuração desconhecida NÃO habilita cloud
      // implicitamente.
      return BrainDataMode.local;
    }

    return mode;
  }

  @override
  Future<void> save(BrainDataMode mode) async {
    final preferences = await _preferencesProvider();

    final saved = await preferences.setString(storageKey, mode.storageValue);

    if (!saved) {
      throw StateError('Não foi possível salvar o modo de dados do Cérebro.');
    }
  }

  @override
  Future<void> clear() async {
    final preferences = await _preferencesProvider();

    final removed = await preferences.remove(storageKey);

    if (!removed && preferences.containsKey(storageKey)) {
      throw StateError('Não foi possível remover o modo de dados do Cérebro.');
    }
  }
}

// ============================================================
// IN-MEMORY
// ============================================================
//
// Apenas testes/desenvolvimento.
//
// ============================================================

class InMemoryBrainDataModeStorage extends BrainDataModeStorage {
  BrainDataMode? _mode;

  BrainDataMode? get storedMode {
    return _mode;
  }

  @override
  Future<BrainDataMode?> load() async {
    return _mode;
  }

  @override
  Future<void> save(BrainDataMode mode) async {
    _mode = mode;
  }

  @override
  Future<void> clear() async {
    _mode = null;
  }
}
