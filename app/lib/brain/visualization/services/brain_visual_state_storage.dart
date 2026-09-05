import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../../../core/storage/user_storage_scope.dart';

import '../models/brain_growth_planner.dart';

// ============================================================
// PERSISTED STATE
// ============================================================

@immutable
class BrainVisualPersistedState {
  const BrainVisualPersistedState({
    required this.introSeen,
    required this.growthState,
  });

  final bool introSeen;

  final BrainGrowthState growthState;

  factory BrainVisualPersistedState.empty() {
    return const BrainVisualPersistedState(
      introSeen: false,
      growthState: BrainGrowthState.empty(),
    );
  }
}

// ============================================================
// STORAGE
// ============================================================

/// Persiste somente o estado VISUAL do Cérebro.
///
/// Não armazena:
///
/// - conteúdo das anotações;
/// - texto de conhecimentos;
/// - embeddings;
/// - chaves;
/// - resultados de busca;
/// - conteúdo do Vault.
///
/// Ele guarda apenas:
///
/// - se o nascimento do cérebro já aconteceu;
/// - quais clusters ocupam quais ramificações;
/// - quantidade de itens associada a cada cluster;
/// - nível visual derivado desses dados.
///
/// ============================================================

class BrainVisualStateStorage {
  const BrainVisualStateStorage({
    required UserStorageScope storageScope,
  }) : _storageScope = storageScope;

  final UserStorageScope _storageScope;

  // ============================================================
  // FILE
  // ============================================================

  static const String _fileName = 'brain_visual_state.json';

  // ============================================================
  // CURRENT VERSION
  // ============================================================

  static const int _version = 3;

  // ============================================================
  // STATE FILE
  // ============================================================

  Future<
    File
  >
  _stateFile() async {
    final directory = await _storageScope.uiDirectory;

    return File(
      '${directory.path}/$_fileName',
    );
  }

  // ============================================================
  // READ MAP
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  _readMap() async {
    try {
      final file = await _stateFile();

      if (!await file.exists()) {
        return <
          String,
          dynamic
        >{};
      }

      final raw = await file.readAsString();

      if (raw.trim().isEmpty) {
        return <
          String,
          dynamic
        >{};
      }

      final decoded = jsonDecode(
        raw,
      );

      if (decoded
          is! Map) {
        return <
          String,
          dynamic
        >{};
      }

      return Map<
        String,
        dynamic
      >.from(
        decoded,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[BRAIN VISUAL] '
        'Não foi possível ler o estado visual: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return <
        String,
        dynamic
      >{};
    }
  }

  // ============================================================
  // WRITE MAP
  // ============================================================

  Future<
    void
  >
  _writeMap(
    Map<
      String,
      dynamic
    >
    map,
  ) async {
    try {
      final file = await _stateFile();

      map['version'] = _version;

      await file.writeAsString(
        const JsonEncoder.withIndent(
          '  ',
        ).convert(
          map,
        ),
        flush: true,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[BRAIN VISUAL] '
        'Não foi possível salvar o estado visual: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // PROFILE MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  _readProfile(
    Map<
      String,
      dynamic
    >
    map,
    String profileKey,
  ) {
    final profiles = map['profiles'];

    if (profiles
        is! Map) {
      return <
        String,
        dynamic
      >{};
    }

    final profile = profiles[profileKey];

    if (profile
        is! Map) {
      return <
        String,
        dynamic
      >{};
    }

    return Map<
      String,
      dynamic
    >.from(
      profile,
    );
  }

  // ============================================================
  // READ COMPLETE STATE
  // ============================================================

  Future<
    BrainVisualPersistedState
  >
  readState({
    String profileKey = 'default',
  }) async {
    final map = await _readMap();

    final profile = _readProfile(
      map,
      profileKey,
    );

    // ========================================================
    // INTRO
    // ========================================================

    final introSeen =
        profile['intro_seen_v9'] ==
        true;

    // ========================================================
    // GROWTH STATE
    // ========================================================

    final rawGrowth = profile['growth_state_v1'];

    BrainGrowthState growthState = const BrainGrowthState.empty();

    if (rawGrowth
        is Map) {
      try {
        growthState = BrainGrowthState.fromMap(
          Map<
            String,
            dynamic
          >.from(
            rawGrowth,
          ),
        );
      } catch (
        error,
        stackTrace
      ) {
        debugPrint(
          '[BRAIN VISUAL] '
          'Estado de crescimento inválido: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );
      }
    }

    return BrainVisualPersistedState(
      introSeen: introSeen,
      growthState: growthState,
    );
  }

  // ============================================================
  // WRITE COMPLETE STATE
  // ============================================================

  Future<
    void
  >
  writeState({
    required bool introSeen,
    required BrainGrowthState growthState,
    String profileKey = 'default',
  }) async {
    final map = await _readMap();

    final profiles =
        map['profiles']
            is Map
        ? Map<
            String,
            dynamic
          >.from(
            map['profiles']
                as Map,
          )
        : <
            String,
            dynamic
          >{};

    final profile =
        profiles[profileKey]
            is Map
        ? Map<
            String,
            dynamic
          >.from(
            profiles[profileKey]
                as Map,
          )
        : <
            String,
            dynamic
          >{};

    profile['intro_seen_v9'] = introSeen;

    profile['growth_state_v1'] = growthState.toMap();

    profiles[profileKey] = profile;

    map['profiles'] = profiles;

    await _writeMap(
      map,
    );
  }

  // ============================================================
  // READ INTRO
  // ============================================================

  Future<
    bool
  >
  readIntroSeen({
    String profileKey = 'default',
  }) async {
    final state = await readState(
      profileKey: profileKey,
    );

    return state.introSeen;
  }

  // ============================================================
  // WRITE INTRO
  // ============================================================

  Future<
    void
  >
  writeIntroSeen(
    bool value, {
    String profileKey = 'default',
  }) async {
    final current = await readState(
      profileKey: profileKey,
    );

    await writeState(
      introSeen: value,
      growthState: current.growthState,
      profileKey: profileKey,
    );
  }

  // ============================================================
  // READ GROWTH STATE
  // ============================================================

  Future<
    BrainGrowthState
  >
  readGrowthState({
    String profileKey = 'default',
  }) async {
    final state = await readState(
      profileKey: profileKey,
    );

    return state.growthState;
  }

  // ============================================================
  // WRITE GROWTH STATE
  // ============================================================

  Future<
    void
  >
  writeGrowthState(
    BrainGrowthState growthState, {
    String profileKey = 'default',
  }) async {
    final current = await readState(
      profileKey: profileKey,
    );

    await writeState(
      introSeen: current.introSeen,
      growthState: growthState,
      profileKey: profileKey,
    );
  }

  // ============================================================
  // CLEAR GROWTH STATE
  // ============================================================
  //
  // Para desenvolvimento e testes.
  //
  // Mantém introSeen.
  //
  // ============================================================

  Future<
    void
  >
  clearGrowthState({
    String profileKey = 'default',
  }) async {
    final current = await readState(
      profileKey: profileKey,
    );

    await writeState(
      introSeen: current.introSeen,
      growthState: const BrainGrowthState.empty(),
      profileKey: profileKey,
    );
  }

  // ============================================================
  // RESET PROFILE
  // ============================================================
  //
  // Apaga apenas o estado visual daquele perfil.
  //
  // ============================================================

  Future<
    void
  >
  resetProfile({
    String profileKey = 'default',
  }) async {
    try {
      final map = await _readMap();

      final profiles =
          map['profiles']
              is Map
          ? Map<
              String,
              dynamic
            >.from(
              map['profiles']
                  as Map,
            )
          : <
              String,
              dynamic
            >{};

      profiles.remove(
        profileKey,
      );

      map['profiles'] = profiles;

      await _writeMap(
        map,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[BRAIN VISUAL] '
        'Não foi possível resetar o perfil: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // RESET EVERYTHING
  // ============================================================
  //
  // Somente para desenvolvimento.
  //
  // ============================================================

  Future<
    void
  >
  resetAll() async {
    try {
      final file = await _stateFile();

      if (await file.exists()) {
        await file.delete();
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[BRAIN VISUAL] '
        'Não foi possível apagar o estado visual: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }
}
