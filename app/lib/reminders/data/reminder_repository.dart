import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reminder_model.dart';

class ReminderRepository {
  ReminderRepository({
    SupabaseClient? client,
  }) : _client =
           client ??
           Supabase.instance.client;

  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _client;

  // ============================================================
  // TABLE
  // ============================================================

  static const String _table = 'reminders';

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
  // GET ALL
  // ============================================================

  Future<
    List<
      ReminderModel
    >
  >
  getAll() async {
    final user = _requireUser();

    final response = await _client
        .from(
          _table,
        )
        .select()
        .eq(
          'user_id',
          user.id,
        )
        .order(
          'remind_at',
          ascending: true,
        );

    return (response
            as List)
        .map(
          (
            item,
          ) {
            return ReminderModel.fromJson(
              Map<
                String,
                dynamic
              >.from(
                item
                    as Map,
              ),
            );
          },
        )
        .toList();
  }

  // ============================================================
  // GET PENDING
  // ============================================================

  Future<
    List<
      ReminderModel
    >
  >
  getPending() async {
    final user = _requireUser();

    final response = await _client
        .from(
          _table,
        )
        .select()
        .eq(
          'user_id',
          user.id,
        )
        .eq(
          'completed',
          false,
        )
        .order(
          'remind_at',
          ascending: true,
        );

    return (response
            as List)
        .map(
          (
            item,
          ) {
            return ReminderModel.fromJson(
              Map<
                String,
                dynamic
              >.from(
                item
                    as Map,
              ),
            );
          },
        )
        .toList();
  }

  // ============================================================
  // GET DUE
  // ============================================================

  Future<
    List<
      ReminderModel
    >
  >
  getDue() async {
    final user = _requireUser();

    final now = DateTime.now().toUtc().toIso8601String();

    final response = await _client
        .from(
          _table,
        )
        .select()
        .eq(
          'user_id',
          user.id,
        )
        .eq(
          'completed',
          false,
        )
        .eq(
          'notify_in_app',
          true,
        )
        .eq(
          'sent_in_app',
          false,
        )
        .lte(
          'remind_at',
          now,
        )
        .order(
          'remind_at',
          ascending: true,
        );

    return (response
            as List)
        .map(
          (
            item,
          ) {
            return ReminderModel.fromJson(
              Map<
                String,
                dynamic
              >.from(
                item
                    as Map,
              ),
            );
          },
        )
        .toList();
  }

  // ============================================================
  // GET BY ID
  // ============================================================

  Future<
    ReminderModel?
  >
  getById(
    String id,
  ) async {
    final user = _requireUser();

    final response = await _client
        .from(
          _table,
        )
        .select()
        .eq(
          'id',
          id,
        )
        .eq(
          'user_id',
          user.id,
        )
        .maybeSingle();

    if (response ==
        null) {
      return null;
    }

    return ReminderModel.fromJson(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<
    ReminderModel
  >
  create({
    required String title,
    required String message,
    required DateTime remindAt,
    String? sourceType,
    String? sourceId,
    bool notifyInApp = true,
    bool notifyTelegram = false,
  }) async {
    final user = _requireUser();

    final data = {
      'user_id': user.id,
      'title': title.trim(),
      'message': message.trim(),
      'remind_at': remindAt.toUtc().toIso8601String(),
      'source_type': sourceType,
      'source_id': sourceId,
      'notify_in_app': notifyInApp,
      'notify_telegram': notifyTelegram,
      'sent_in_app': false,
      'sent_telegram': false,
      'completed': false,
    };

    final response = await _client
        .from(
          _table,
        )
        .insert(
          data,
        )
        .select()
        .single();

    return ReminderModel.fromJson(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<
    ReminderModel
  >
  update(
    ReminderModel reminder,
  ) async {
    final user = _requireUser();

    final response = await _client
        .from(
          _table,
        )
        .update(
          {
            'title': reminder.title.trim(),
            'message': reminder.message.trim(),
            'remind_at': reminder.remindAt.toUtc().toIso8601String(),
            'source_type': reminder.sourceType,
            'source_id': reminder.sourceId,
            'notify_in_app': reminder.notifyInApp,
            'notify_telegram': reminder.notifyTelegram,
            'sent_in_app': reminder.sentInApp,
            'sent_telegram': reminder.sentTelegram,
            'completed': reminder.completed,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        )
        .eq(
          'id',
          reminder.id,
        )
        .eq(
          'user_id',
          user.id,
        )
        .select()
        .single();

    return ReminderModel.fromJson(
      Map<
        String,
        dynamic
      >.from(
        response,
      ),
    );
  }

  // ============================================================
  // MARK IN APP AS SENT
  // ============================================================

  Future<
    void
  >
  markInAppAsSent(
    String id,
  ) async {
    final user = _requireUser();

    await _client
        .from(
          _table,
        )
        .update(
          {
            'sent_in_app': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        )
        .eq(
          'id',
          id,
        )
        .eq(
          'user_id',
          user.id,
        );
  }

  // ============================================================
  // MARK TELEGRAM AS SENT
  // ============================================================

  Future<
    void
  >
  markTelegramAsSent(
    String id,
  ) async {
    final user = _requireUser();

    await _client
        .from(
          _table,
        )
        .update(
          {
            'sent_telegram': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        )
        .eq(
          'id',
          id,
        )
        .eq(
          'user_id',
          user.id,
        );
  }

  // ============================================================
  // COMPLETE
  // ============================================================

  Future<
    void
  >
  complete(
    String id,
  ) async {
    final user = _requireUser();

    await _client
        .from(
          _table,
        )
        .update(
          {
            'completed': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        )
        .eq(
          'id',
          id,
        )
        .eq(
          'user_id',
          user.id,
        );
  }

  // ============================================================
  // REOPEN
  // ============================================================

  Future<
    void
  >
  reopen(
    String id,
  ) async {
    final user = _requireUser();

    await _client
        .from(
          _table,
        )
        .update(
          {
            'completed': false,
            'sent_in_app': false,
            'sent_telegram': false,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
        )
        .eq(
          'id',
          id,
        )
        .eq(
          'user_id',
          user.id,
        );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  delete(
    String id,
  ) async {
    final user = _requireUser();

    await _client
        .from(
          _table,
        )
        .delete()
        .eq(
          'id',
          id,
        )
        .eq(
          'user_id',
          user.id,
        );
  }
}
