import 'package:shared_preferences/shared_preferences.dart';

import '../models/brain_data_mode.dart';

// ============================================================
// BRAIN DATA MODE STORAGE
// ============================================================
//
// Persiste SOMENTE a preferência operacional do Cérebro:
//
// local
// cloud
//
// A preferência é isolada por usuário quando existe um scope.
// Isso é importante para que uma conta nova no mesmo dispositivo
// não herde silenciosamente a escolha feita por outra conta.
//
// Não armazena conteúdo, chaves ou credenciais.
//
// ============================================================

abstract class BrainDataModeStorage {
  const BrainDataModeStorage();

  Future<
    BrainDataMode?
  >
  load();

  Future<
    void
  >
  save(
    BrainDataMode mode,
  );

  Future<
    void
  >
  clear();
}

// ============================================================
// SHARED PREFERENCES IMPLEMENTATION
// ============================================================

class SharedPreferencesBrainDataModeStorage
    extends
        BrainDataModeStorage {
  SharedPreferencesBrainDataModeStorage({
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

  // Chave antiga, usada antes do isolamento por conta.
  // Mantida somente para migração segura da conta já ativa.
  static const String legacyStorageKey = 'evrylux.brain.data_mode.v1';

  // Prefixo atual, isolado por usuário.
  static const String scopedStorageKeyPrefix = 'evrylux.brain.data_mode.v2';

  final Future<
    SharedPreferences
  >
  Function()
  _preferencesProvider;

  final String? Function()? _scopeProvider;

  // ============================================================
  // SCOPE
  // ============================================================

  String? get currentScope {
    final raw = _scopeProvider?.call()?.trim();

    if (raw ==
            null ||
        raw.isEmpty) {
      return null;
    }

    return raw;
  }

  String get _storageKey {
    final scope = currentScope;

    if (scope ==
        null) {
      // Sem usuário autenticado, usamos a chave legada somente
      // como namespace local temporário. Cloud continua protegido
      // pelos gates de autenticação do restante da arquitetura.
      return legacyStorageKey;
    }

    return '$scopedStorageKeyPrefix.$scope';
  }

  // ============================================================
  // LOAD
  // ============================================================

  @override
  Future<
    BrainDataMode?
  >
  load() async {
    final preferences = await _preferencesProvider();

    final key = _storageKey;

    var raw = preferences.getString(
      key,
    );

    // ----------------------------------------------------------
    // MIGRAÇÃO V1 -> V2
    // ----------------------------------------------------------
    //
    // Se existe usuário autenticado e ainda não existe escolha
    // específica para ele, migramos UMA vez o valor legado.
    // Depois removemos a chave global antiga.
    //
    // Resultado:
    // - a conta já existente mantém sua escolha;
    // - uma conta nova no mesmo computador não herda essa escolha;
    // - a conta nova verá o modal de primeira configuração.
    //
    // ----------------------------------------------------------

    final scope = currentScope;

    if (scope !=
            null &&
        (raw ==
                null ||
            raw.trim().isEmpty) &&
        preferences.containsKey(
          legacyStorageKey,
        )) {
      final legacyRaw = preferences.getString(
        legacyStorageKey,
      );

      final legacyMode = BrainDataMode.tryParse(
        legacyRaw,
      );

      if (legacyMode !=
          null) {
        final migrated = await preferences.setString(
          key,
          legacyMode.storageValue,
        );

        if (!migrated) {
          throw StateError(
            'Não foi possível migrar o modo de dados do Cérebro.',
          );
        }

        await preferences.remove(
          legacyStorageKey,
        );

        raw = legacyMode.storageValue;
      } else {
        // Valor legado inválido não deve escolher um modo pelo
        // usuário. Removemos e deixamos a primeira escolha aberta.
        await preferences.remove(
          legacyStorageKey,
        );
      }
    }

    if (raw ==
            null ||
        raw.trim().isEmpty) {
      return null;
    }

    // Valor inválido nunca habilita Cloud implicitamente.
    // Retornar null faz a UI pedir uma escolha explícita.
    return BrainDataMode.tryParse(
      raw,
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  @override
  Future<
    void
  >
  save(
    BrainDataMode mode,
  ) async {
    final preferences = await _preferencesProvider();

    final saved = await preferences.setString(
      _storageKey,
      mode.storageValue,
    );

    if (!saved) {
      throw StateError(
        'Não foi possível salvar o modo de dados do Cérebro.',
      );
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
    final preferences = await _preferencesProvider();

    final key = _storageKey;

    final removed = await preferences.remove(
      key,
    );

    if (!removed &&
        preferences.containsKey(
          key,
        )) {
      throw StateError(
        'Não foi possível remover o modo de dados do Cérebro.',
      );
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

class InMemoryBrainDataModeStorage
    extends
        BrainDataModeStorage {
  BrainDataMode? _mode;

  BrainDataMode? get storedMode {
    return _mode;
  }

  @override
  Future<
    BrainDataMode?
  >
  load() async {
    return _mode;
  }

  @override
  Future<
    void
  >
  save(
    BrainDataMode mode,
  ) async {
    _mode = mode;
  }

  @override
  Future<
    void
  >
  clear() async {
    _mode = null;
  }
}
