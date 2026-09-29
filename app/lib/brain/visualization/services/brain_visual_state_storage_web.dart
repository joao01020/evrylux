import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/brain_growth_planner.dart';

class BrainVisualPersistedState {
  const BrainVisualPersistedState({
    required this.introSeen,
    required this.growthState,
  });

  final bool introSeen;
  final BrainGrowthState growthState;

  factory BrainVisualPersistedState.empty() => const BrainVisualPersistedState(
    introSeen: false,
    growthState: BrainGrowthState.empty(),
  );
}

/// Implementação Web do mesmo storage visual usado pelo Brain desktop.
///
/// O navegador não possui `dart:io`, portanto o estado puramente visual
/// fica em SharedPreferences (localStorage). Nenhum conteúdo do Brain ou
/// material criptográfico é salvo aqui.
class BrainVisualStateStorage {
  const BrainVisualStateStorage({required Object storageScope});

  static const String _legacyKey = 'evrylux.brain.visual_state.web.v3';
  static const String _keyPrefix = 'evrylux.brain.visual_state.web.v4';
  static const String _remoteIntroKey = 'brain_intro_seen';

  String get _scope {
    final userId = Supabase.instance.client.auth.currentUser?.id.trim();
    if (userId == null || userId.isEmpty) return 'anonymous';
    return userId;
  }

  String get _key => '$_keyPrefix.$_scope';

  Future<Map<String, dynamic>> _readMap() async {
    final prefs = await SharedPreferences.getInstance();

    String? raw = prefs.getString(_key);

    // Migra o estado Web anterior para a chave isolada por usuário.
    if ((raw == null || raw.trim().isEmpty) && prefs.containsKey(_legacyKey)) {
      final legacyRaw = prefs.getString(_legacyKey);
      if (legacyRaw != null && legacyRaw.trim().isNotEmpty) {
        raw = legacyRaw;
        await prefs.setString(_key, legacyRaw);
      }
    }

    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}

    return <String, dynamic>{};
  }

  Future<void> _writeMap(Map<String, dynamic> map) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(map));
  }

  bool _metadataIntroSeen() {
    final metadata = Supabase.instance.client.auth.currentUser?.userMetadata;
    return metadata?[_remoteIntroKey] == true;
  }

  Future<bool> readIntroSeen() async {
    final map = await _readMap();

    if (map['intro_seen'] == true) {
      return true;
    }

    // A marca remota faz o onboarding ser por conta, não por navegador.
    if (_metadataIntroSeen()) {
      map['intro_seen'] = true;
      await _writeMap(map);
      return true;
    }

    return false;
  }

  Future<void> writeIntroSeen(bool value) async {
    final map = await _readMap();
    map['intro_seen'] = value;
    await _writeMap(map);

    // Persistência por conta. Falha de rede não impede o uso local.
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: <String, dynamic>{_remoteIntroKey: value}),
      );
    } catch (_) {
      // O estado local já foi salvo. A próxima sessão poderá sincronizar.
    }
  }

  Future<BrainVisualPersistedState> readState({
    String profileKey = 'default',
  }) async {
    final map = await _readMap();

    final profiles = map['profiles'];
    final profile = profiles is Map && profiles[profileKey] is Map
        ? Map<String, dynamic>.from(profiles[profileKey] as Map)
        : <String, dynamic>{};

    var growthState = const BrainGrowthState.empty();

    final rawGrowth = profile['growth_state_v1'];
    if (rawGrowth is Map) {
      try {
        growthState = BrainGrowthState.fromMap(
          Map<String, dynamic>.from(rawGrowth),
        );
      } catch (_) {
        growthState = const BrainGrowthState.empty();
      }
    }

    return BrainVisualPersistedState(
      introSeen: await readIntroSeen(),
      growthState: growthState,
    );
  }

  Future<void> writeState(
    BrainVisualPersistedState state, {
    String profileKey = 'default',
  }) async {
    final map = await _readMap();

    final profiles = map['profiles'] is Map
        ? Map<String, dynamic>.from(map['profiles'] as Map)
        : <String, dynamic>{};

    final profile = profiles[profileKey] is Map
        ? Map<String, dynamic>.from(profiles[profileKey] as Map)
        : <String, dynamic>{};

    profile['growth_state_v1'] = state.growthState.toMap();
    profile['intro_seen'] = state.introSeen;

    profiles[profileKey] = profile;
    map['profiles'] = profiles;
    map['intro_seen'] = state.introSeen;

    await _writeMap(map);

    // Mantém a flag de onboarding também por conta no Supabase Auth.
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(
            data: <String, dynamic>{
              _remoteIntroKey: state.introSeen,
            },
          ),
        );
      } catch (_) {}
    }
  }

  Future<BrainGrowthState> readGrowthState({
    String profileKey = 'default',
  }) async {
    final state = await readState(profileKey: profileKey);
    return state.growthState;
  }

  Future<void> writeGrowthState(
    BrainGrowthState growthState, {
    String profileKey = 'default',
  }) async {
    final current = await readState(profileKey: profileKey);

    await writeState(
      BrainVisualPersistedState(
        introSeen: current.introSeen,
        growthState: growthState,
      ),
      profileKey: profileKey,
    );
  }
}
