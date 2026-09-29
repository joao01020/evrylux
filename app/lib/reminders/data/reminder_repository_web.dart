import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reminder_model.dart';

class ReminderRepository {
  ReminderRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  static const String _table = 'reminders';

  final SupabaseClient _client;

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }
    return user;
  }

  Future<List<ReminderModel>> getAll() async {
    final user = _requireUser();
    final rows = await _client
        .from(_table)
        .select()
        .eq('user_id', user.id)
        .order('remind_at');

    return rows
        .map<ReminderModel>(
          (row) => ReminderModel.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList(growable: false);
  }

  Future<List<ReminderModel>> getPending() async {
    final all = await getAll();
    return all.where((item) => !item.completed).toList(growable: false);
  }

  Future<List<ReminderModel>> getDue() async {
    final now = DateTime.now().toUtc();
    final all = await getAll();
    return all
        .where(
          (item) =>
              !item.completed &&
              item.notifyInApp &&
              !item.sentInApp &&
              !item.remindAt.isAfter(now),
        )
        .toList(growable: false);
  }

  Future<ReminderModel?> getById(String id) async {
    final user = _requireUser();
    final row = await _client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) return null;
    return ReminderModel.fromJson(
      Map<String, dynamic>.from(row),
    );
  }

  Future<ReminderModel> create({
    required String title,
    required String message,
    required DateTime remindAt,
    String? sourceType,
    String? sourceId,
    bool notifyInApp = true,
    bool notifyTelegram = false,
  }) async {
    final user = _requireUser();
    final id = _uuid();

    final payload = <String, dynamic>{
      'id': id,
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

    final row = await _client
        .from(_table)
        .insert(payload)
        .select()
        .single();

    return ReminderModel.fromJson(
      Map<String, dynamic>.from(row),
    );
  }

  Future<ReminderModel> update(ReminderModel reminder) async {
    final user = _requireUser();

    final payload = Map<String, dynamic>.from(reminder.toJson())
      ..remove('id')
      ..remove('user_id')
      ..remove('created_at');

    final row = await _client
        .from(_table)
        .update(payload)
        .eq('id', reminder.id)
        .eq('user_id', user.id)
        .select()
        .single();

    return ReminderModel.fromJson(
      Map<String, dynamic>.from(row),
    );
  }

  Future<ReminderModel> markInAppAsSent(String id) async {
    return _patch(id, <String, dynamic>{'sent_in_app': true});
  }

  Future<ReminderModel> markTelegramAsSent(String id) async {
    return _patch(id, <String, dynamic>{'sent_telegram': true});
  }

  Future<ReminderModel> complete(String id) async {
    return _patch(id, <String, dynamic>{'completed': true});
  }

  Future<ReminderModel> reopen(String id) async {
    return _patch(
      id,
      <String, dynamic>{
        'completed': false,
        'sent_in_app': false,
      },
    );
  }

  Future<bool> delete(String id) async {
    final user = _requireUser();
    await _client
        .from(_table)
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
    return true;
  }

  Future<ReminderModel> _patch(
    String id,
    Map<String, dynamic> values,
  ) async {
    final user = _requireUser();
    final row = await _client
        .from(_table)
        .update(values)
        .eq('id', id)
        .eq('user_id', user.id)
        .select()
        .single();

    return ReminderModel.fromJson(
      Map<String, dynamic>.from(row),
    );
  }

  String _uuid() {
    final random = Random.secure();
    String hex(int count) => List<String>.generate(
      count,
      (_) => random.nextInt(16).toRadixString(16),
    ).join();

    return '${hex(8)}-${hex(4)}-4${hex(3)}-'
        '${(8 + random.nextInt(4)).toRadixString(16)}${hex(3)}-${hex(12)}';
  }
}
