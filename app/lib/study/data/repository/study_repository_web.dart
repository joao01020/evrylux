import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'study_repository_contract.dart';

import '../../../core/storage/storage_service.dart';

class StudyRepository implements StudyRepositoryContract {
  StudyRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }
    return user;
  }

  Future<Map<String, dynamic>> load() async {
    final data = await StorageService.getStudy();
    return Map<String, dynamic>.from(data);
  }

  Future<void> save(String day, int minutes) async {
    final user = _requireUser();
    final normalizedDay = _normalizeDay(day);

    if (minutes < 0) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'Os minutos de estudo não podem ser negativos.',
      );
    }

    await StorageService.saveStudy(normalizedDay, minutes);

    final entityId = _entityId(userId: user.id, day: normalizedDay);

    try {
      await _client.from('study_data').upsert(<String, dynamic>{
        'id': entityId,
        'user_id': user.id,
        'day': normalizedDay,
        'minutes': minutes,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (error) {
      debugPrint('[STUDY WEB] Sync remoto adiado: $error');
    }
  }

  Future<void> saveMany(Map<String, dynamic> values) async {
    for (final entry in values.entries) {
      await save(entry.key, _toInt(entry.value));
    }
  }

  Future<int> getTotalMinutes() async {
    final data = await load();
    var total = 0;
    for (final value in data.values) {
      total += _toInt(value);
    }
    return total;
  }

  Future<int> getMinutes(String day) async {
    final data = await load();
    return _toInt(data[_normalizeDay(day)]);
  }

  Future<bool> hasLocalData() async {
    final data = await load();
    return data.isNotEmpty;
  }

  String _normalizeDay(String value) {
    final day = value.trim().toLowerCase();
    const aliases = <String, String>{
      'segunda-feira': 'segunda',
      'terça-feira': 'terça',
      'terca-feira': 'terça',
      'terca': 'terça',
      'quarta-feira': 'quarta',
      'quinta-feira': 'quinta',
      'sexta-feira': 'sexta',
      'sábado': 'sábado',
      'sabado': 'sábado',
      'domingo': 'domingo',
    };
    return aliases[day] ?? day;
  }

  String _entityId({required String userId, required String day}) {
    return '$userId:$day';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
