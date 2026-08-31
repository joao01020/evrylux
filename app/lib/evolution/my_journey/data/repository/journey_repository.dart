import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide
        LocalStorage;

import '../../../../core/storage/local_storage.dart';

import '../../../../core/sync/sync_item.dart';
import '../../../../core/sync/sync_queue.dart';
import '../../../../core/sync/sync_service.dart';

import '../../models/journey_model.dart';

class JourneyRepository {
  JourneyRepository({
    required this.storage,
    SupabaseClient? client,
    SyncQueue? syncQueue,
    SyncService? syncService,
  }) : _client =
           client ??
           Supabase.instance.client,
       _syncQueue = syncQueue,
       _syncService = syncService;

  // ============================================================
  // STORAGE
  // ============================================================

  final LocalStorage storage;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseClient _client;

  final SyncQueue? _syncQueue;

  final SyncService? _syncService;

  // ============================================================
  // LOCAL KEY
  // ============================================================

  static const String key = 'journey_history';

  // ============================================================
  // SYNC ENTITY
  // ============================================================

  static const String _entityType = 'journey_day';

  // ============================================================
  // CURRENT USER
  // ============================================================

  User _requireUser() {
    final user = _client.auth.currentUser;

    if (user ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    return user;
  }

  // ============================================================
  // SALVAR JORNADA
  // ============================================================
  //
  // OFFLINE-FIRST:
  //
  // 1. salva primeiro no LocalStorage;
  // 2. registra a alteração na SyncQueue;
  // 3. solicita sincronização;
  // 4. Supabase será atualizado quando houver conexão.
  //
  // ============================================================

  Future<
    void
  >
  save(
    JourneyModel model,
  ) async {
    final user = _requireUser();

    final normalizedDate = _normalizeDate(
      model.date,
    );

    final normalizedNotes = model.notes
        .map(
          (
            note,
          ) => note.trim(),
        )
        .where(
          (
            note,
          ) => note.isNotEmpty,
        )
        .toList(
          growable: false,
        );

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================

    final data = await load();

    data[normalizedDate] = normalizedNotes;

    await _saveLocalMap(
      data,
    );

    debugPrint(
      '[JOURNEY REPOSITORY] '
      '$normalizedDate salvo localmente.',
    );

    // ==========================================================
    // SYNC QUEUE
    // ==========================================================

    final queue = _syncQueue;

    if (queue ==
        null) {
      return;
    }

    final entityId = _entityId(
      userId: user.id,
      date: normalizedDate,
    );

    await queue.enqueue(
      entityType: _entityType,
      entityId: entityId,
      operation: SyncOperation.update,
      payload: {
        'id': entityId,
        'user_id': user.id,
        'date': normalizedDate,
        'notes': normalizedNotes,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // CARREGAR HISTÓRICO
  // ============================================================
  //
  // O LocalStorage continua sendo a fonte imediata.
  //
  // Portanto a jornada abre mesmo sem internet.
  //
  // ============================================================

  Future<
    Map<
      String,
      List<
        String
      >
    >
  >
  load() async {
    final saved = await storage.get(
      key,
    );

    if (saved ==
            null ||
        saved.trim().isEmpty) {
      return <
        String,
        List<
          String
        >
      >{};
    }

    try {
      final dynamic decoded = jsonDecode(
        saved,
      );

      if (decoded
          is! Map) {
        return <
          String,
          List<
            String
          >
        >{};
      }

      final result =
          <
            String,
            List<
              String
            >
          >{};

      decoded.forEach(
        (
          rawKey,
          rawValue,
        ) {
          if (rawValue
              is! List) {
            return;
          }

          final date = rawKey.toString().trim();

          if (date.isEmpty) {
            return;
          }

          result[date] = rawValue
              .map(
                (
                  item,
                ) => item.toString(),
              )
              .toList(
                growable: false,
              );
        },
      );

      return result;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[JOURNEY REPOSITORY] '
        'Erro ao decodificar histórico local: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      return <
        String,
        List<
          String
        >
      >{};
    }
  }

  // ============================================================
  // CARREGAR DIA
  // ============================================================

  Future<
    List<
      String
    >
  >
  loadDay(
    String date,
  ) async {
    final normalizedDate = _normalizeDate(
      date,
    );

    final data = await load();

    return List<
      String
    >.unmodifiable(
      data[normalizedDate] ??
          const <
            String
          >[],
    );
  }

  // ============================================================
  // EXISTE DIA
  // ============================================================

  Future<
    bool
  >
  exists(
    String date,
  ) async {
    final normalizedDate = _normalizeDate(
      date,
    );

    final data = await load();

    return data.containsKey(
      normalizedDate,
    );
  }

  // ============================================================
  // EXCLUIR DIA
  // ============================================================
  //
  // A exclusão também é local-first.
  //
  // ============================================================

  Future<
    void
  >
  deleteDay(
    String date,
  ) async {
    final user = _requireUser();

    final normalizedDate = _normalizeDate(
      date,
    );

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================

    final data = await load();

    data.remove(
      normalizedDate,
    );

    await _saveLocalMap(
      data,
    );

    // ==========================================================
    // SYNC QUEUE
    // ==========================================================

    final queue = _syncQueue;

    if (queue ==
        null) {
      return;
    }

    final entityId = _entityId(
      userId: user.id,
      date: normalizedDate,
    );

    await queue.enqueue(
      entityType: _entityType,
      entityId: entityId,
      operation: SyncOperation.delete,
      payload: {
        'id': entityId,
        'user_id': user.id,
        'date': normalizedDate,
      },
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // LIMPAR HISTÓRICO
  // ============================================================

  Future<
    void
  >
  clear() async {
    final user = _requireUser();

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================

    await _saveLocalMap(
      const <
        String,
        List<
          String
        >
      >{},
    );

    // ==========================================================
    // SYNC QUEUE
    // ==========================================================
    //
    // clear representa exclusão em lote.
    //
    // ==========================================================

    final queue = _syncQueue;

    if (queue ==
        null) {
      return;
    }

    final entityId = _clearEntityId(
      user.id,
    );

    await queue.enqueue(
      entityType: _entityType,
      entityId: entityId,
      operation: SyncOperation.delete,
      payload: {
        'id': entityId,
        'user_id': user.id,
        'delete_scope': 'all',
      },
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // SUBSTITUIR CACHE LOCAL
  // ============================================================
  //
  // Pode ser usado futuramente por um refresh remoto sem passar
  // novamente pela fila de sincronização.
  //
  // ============================================================

  Future<
    void
  >
  replaceLocal(
    Map<
      String,
      List<
        String
      >
    >
    data,
  ) async {
    final normalized =
        <
          String,
          List<
            String
          >
        >{};

    for (final entry in data.entries) {
      final date = _normalizeDate(
        entry.key,
      );

      normalized[date] = entry.value
          .map(
            (
              note,
            ) => note.trim(),
          )
          .where(
            (
              note,
            ) => note.isNotEmpty,
          )
          .toList(
            growable: false,
          );
    }

    await _saveLocalMap(
      normalized,
    );
  }

  // ============================================================
  // HAS LOCAL DATA
  // ============================================================

  Future<
    bool
  >
  hasLocalData() async {
    final data = await load();

    return data.isNotEmpty;
  }

  // ============================================================
  // SAVE LOCAL MAP
  // ============================================================

  Future<
    void
  >
  _saveLocalMap(
    Map<
      String,
      List<
        String
      >
    >
    data,
  ) async {
    await storage.save(
      key,
      jsonEncode(
        data,
      ),
    );
  }

  // ============================================================
  // NORMALIZE DATE
  // ============================================================

  String _normalizeDate(
    String date,
  ) {
    final normalized = date.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        date,
        'date',
        'A data da jornada não pode estar vazia.',
      );
    }

    return normalized;
  }

  // ============================================================
  // ENTITY ID
  // ============================================================

  String _entityId({
    required String userId,
    required String date,
  }) {
    return 'journey_'
        '${_safeId(userId)}_'
        '${_safeId(date)}';
  }

  // ============================================================
  // CLEAR ENTITY ID
  // ============================================================

  String _clearEntityId(
    String userId,
  ) {
    return 'journey_clear_'
        '${_safeId(userId)}';
  }

  // ============================================================
  // SAFE ID
  // ============================================================

  String _safeId(
    String value,
  ) {
    return value.replaceAll(
      RegExp(
        r'[^a-zA-Z0-9_-]',
      ),
      '_',
    );
  }
}
