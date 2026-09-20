import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// BRAIN LOCAL PATH STORAGE
// ============================================================
//
// Responsável por persistir o caminho local escolhido pelo usuário
// para armazenar o Brain.
//
// Exemplo:
//
// Linux:
// /home/joao/Documentos/EVRYLUX/Brain
//
// macOS:
// /Users/brenda/Documents/EVRYLUX/Brain
//
// IMPORTANTE:
//
// Este storage salva SOMENTE o caminho.
//
// Ele NÃO:
// - cria a pasta;
// - move arquivos;
// - apaga arquivos;
// - salva Master Key;
// - salva segredos criptográficos.
//
// A criação física da pasta fica sob responsabilidade do
// BrainStorage.
//
// ============================================================

abstract class BrainLocalPathStorage {
  const BrainLocalPathStorage();

  Future<
    String?
  >
  load();

  Future<
    void
  >
  save(
    String path,
  );

  Future<
    void
  >
  clear();
}

// ============================================================
// SHARED PREFERENCES IMPLEMENTATION
// ============================================================
//
// O scopeProvider permite manter um caminho diferente por conta.
//
// Exemplo:
//
// evrylux.brain.local_path.v1.usuario-123
//
// ============================================================

class SharedPreferencesBrainLocalPathStorage
    extends
        BrainLocalPathStorage {
  SharedPreferencesBrainLocalPathStorage({
    Future<
      SharedPreferences
    >
    Function()?
    preferencesProvider,
    String? Function()? scopeProvider,
  }) : _preferencesProvider =
           preferencesProvider ??
           SharedPreferences.getInstance,
       _scopeProvider = scopeProvider;

  static const String _baseKey = 'evrylux.brain.local_path.v1';

  final Future<
    SharedPreferences
  >
  Function()
  _preferencesProvider;

  final String? Function()? _scopeProvider;

  // ============================================================
  // STORAGE KEY
  // ============================================================

  String get _storageKey {
    final scope = _scopeProvider?.call()?.trim();

    if (scope ==
            null ||
        scope.isEmpty) {
      return _baseKey;
    }

    return '$_baseKey.$scope';
  }

  // ============================================================
  // LOAD
  // ============================================================

  @override
  Future<
    String?
  >
  load() async {
    try {
      final preferences = await _preferencesProvider();

      final value = preferences.getString(
        _storageKey,
      );

      final cleanValue =
          value?.trim() ??
          '';

      if (cleanValue.isEmpty) {
        return null;
      }

      return cleanValue;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'BrainLocalPathStorage: erro ao carregar caminho local.',
      );

      debugPrint(
        'BrainLocalPathStorage: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // SAVE
  // ============================================================

  @override
  Future<
    void
  >
  save(
    String path,
  ) async {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) {
      throw const FormatException(
        'O caminho local do Brain não pode estar vazio.',
      );
    }

    try {
      final preferences = await _preferencesProvider();

      final saved = await preferences.setString(
        _storageKey,
        cleanPath,
      );

      if (!saved) {
        throw StateError(
          'Não foi possível salvar o caminho local do Brain.',
        );
      }

      debugPrint(
        'BrainLocalPathStorage: caminho salvo.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'BrainLocalPathStorage: erro ao salvar caminho local.',
      );

      debugPrint(
        'BrainLocalPathStorage: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  @override
  Future<
    void
  >
  clear() async {
    try {
      final preferences = await _preferencesProvider();

      await preferences.remove(
        _storageKey,
      );

      debugPrint(
        'BrainLocalPathStorage: caminho local removido.',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'BrainLocalPathStorage: erro ao remover caminho local.',
      );

      debugPrint(
        'BrainLocalPathStorage: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    }
  }
}

// ============================================================
// IN MEMORY IMPLEMENTATION
// ============================================================
//
// Útil para testes.
//
// ============================================================

class InMemoryBrainLocalPathStorage
    extends
        BrainLocalPathStorage {
  String? _path;

  String? get storedPath {
    return _path;
  }

  @override
  Future<
    String?
  >
  load() async {
    final value =
        _path?.trim() ??
        '';

    if (value.isEmpty) {
      return null;
    }

    return value;
  }

  @override
  Future<
    void
  >
  save(
    String path,
  ) async {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) {
      throw const FormatException(
        'O caminho local do Brain não pode estar vazio.',
      );
    }

    _path = cleanPath;
  }

  @override
  Future<
    void
  >
  clear() async {
    _path = null;
  }
}
