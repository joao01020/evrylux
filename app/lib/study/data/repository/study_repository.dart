import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/storage_service.dart';
import '../../../core/sync/sync_item.dart';
import '../../../core/sync/sync_queue.dart';
import '../../../core/sync/sync_service.dart';

class StudyRepository {
  StudyRepository({
    SupabaseClient? client,
    SyncQueue? syncQueue,
    SyncService? syncService,
  }) : _client =
           client ??
           Supabase.instance.client,
       _syncQueue = syncQueue,
       _syncService = syncService;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SupabaseClient _client;

  final SyncQueue? _syncQueue;

  final SyncService? _syncService;

  // ============================================================
  // ENTITY
  // ============================================================

  static const String _entityType = 'study_day';

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
  // LOAD
  // ============================================================
  //
  // O Study já era local-first porque StorageService é a fonte
  // local dos dados.
  //
  // Portanto o carregamento continua imediato e offline.
  //
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  load() async {
    final data = await StorageService.getStudy();

    return Map<
      String,
      dynamic
    >.from(
      data,
    );
  }

  // ============================================================
  // SAVE
  // ============================================================
  //
  // Fluxo:
  //
  // StudyController
  //      ↓
  // StudyService
  //      ↓
  // StudyRepository
  //      ↓
  // StorageService
  //      ↓
  // SyncQueue
  //      ↓
  // SyncService
  //
  // O dado é salvo localmente ANTES de qualquer sincronização.
  //
  // ============================================================

  Future<
    void
  >
  save(
    String day,
    int minutes,
  ) async {
    final user = _requireUser();

    final normalizedDay = _normalizeDay(
      day,
    );

    if (minutes <
        0) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'Os minutos de estudo não podem ser negativos.',
      );
    }

    // ==========================================================
    // LOCAL FIRST
    // ==========================================================

    await StorageService.saveStudy(
      normalizedDay,
      minutes,
    );

    debugPrint(
      '[STUDY REPOSITORY] '
      '$normalizedDay salvo localmente: $minutes min.',
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
      day: normalizedDay,
    );

    await queue.enqueue(
      entityType: _entityType,
      entityId: entityId,
      operation: SyncOperation.update,
      payload: {
        'id': entityId,
        'user_id': user.id,
        'day': normalizedDay,
        'minutes': minutes,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
    );

    _syncService?.requestSync();
  }

  // ============================================================
  // SAVE MANY
  // ============================================================
  //
  // Útil para importar/restaurar um conjunto de dias.
  //
  // ============================================================

  Future<
    void
  >
  saveMany(
    Map<
      String,
      dynamic
    >
    values,
  ) async {
    for (final entry in values.entries) {
      final minutes = _toInt(
        entry.value,
      );

      await save(
        entry.key,
        minutes,
      );
    }
  }

  // ============================================================
  // TOTAL MINUTES
  // ============================================================

  Future<
    int
  >
  getTotalMinutes() async {
    final data = await load();

    var total = 0;

    for (final value in data.values) {
      total += _toInt(
        value,
      );
    }

    return total;
  }

  // ============================================================
  // MINUTES FOR DAY
  // ============================================================

  Future<
    int
  >
  getMinutes(
    String day,
  ) async {
    final normalizedDay = _normalizeDay(
      day,
    );

    final data = await load();

    return _toInt(
      data[normalizedDay],
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
  // NORMALIZE DAY
  // ============================================================

  String _normalizeDay(
    String day,
  ) {
    final normalized = day.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        day,
        'day',
        'O dia não pode estar vazio.',
      );
    }

    return normalized;
  }

  // ============================================================
  // ENTITY ID
  // ============================================================
  //
  // ID estável para o mesmo usuário + dia.
  //
  // ============================================================

  String _entityId({
    required String userId,
    required String day,
  }) {
    final safeUser = userId.replaceAll(
      RegExp(
        r'[^a-zA-Z0-9_-]',
      ),
      '_',
    );

    final safeDay = day.replaceAll(
      RegExp(
        r'[^a-zA-Z0-9_-]',
      ),
      '_',
    );

    return 'study_${safeUser}_$safeDay';
  }

  // ============================================================
  // INT
  // ============================================================

  int _toInt(
    dynamic value,
  ) {
    if (value ==
        null) {
      return 0;
    }

    if (value
        is int) {
      return value;
    }

    if (value
        is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }
}
