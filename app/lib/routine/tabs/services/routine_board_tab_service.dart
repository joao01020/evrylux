import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/routine_board_tab.dart';

class RoutineBoardTabService {
  RoutineBoardTabService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<RoutineBoardTab>> loadOrCreateDefault(DateTime date) async {
    final userId = _requiredUserId();
    final dateKey = _dateKey(date);

    final response = await _client
        .from('routine_board_tabs')
        .select()
        .eq('user_id', userId)
        .eq('routine_date', dateKey)
        .order('sort_order');

    final tabs = response
        .map((row) => RoutineBoardTab.fromMap(Map<String, dynamic>.from(row)))
        .where((tab) => tab.id.isNotEmpty)
        .toList();

    if (tabs.isNotEmpty) {
      tabs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return tabs;
    }

    final defaultTab = RoutineBoardTab(
      id: RoutineBoardTab.createId(),
      name: 'Lousa',
      sortOrder: 0,
      isDefault: true,
    );

    await saveTab(date: date, tab: defaultTab);

    return <RoutineBoardTab>[defaultTab];
  }

  Future<RoutineBoardTab> createTab({
    required DateTime date,
    required String name,
    required int sortOrder,
  }) async {
    final tab = RoutineBoardTab(
      id: RoutineBoardTab.createId(),
      name: name.trim().isEmpty ? 'Nova aba' : name.trim(),
      sortOrder: sortOrder,
      isDefault: false,
    );

    await saveTab(date: date, tab: tab);

    return tab;
  }

  Future<void> saveTab({
    required DateTime date,
    required RoutineBoardTab tab,
  }) async {
    final userId = _requiredUserId();

    await _client
        .from('routine_board_tabs')
        .upsert(
          tab.toDatabaseMap(userId: userId, date: date),
          onConflict: 'id',
        );
  }

  Future<void> saveTabs({
    required DateTime date,
    required Iterable<RoutineBoardTab> tabs,
  }) async {
    final userId = _requiredUserId();
    final rows = tabs
        .map((tab) => tab.toDatabaseMap(userId: userId, date: date))
        .toList();

    if (rows.isEmpty) {
      return;
    }

    await _client.from('routine_board_tabs').upsert(rows, onConflict: 'id');
  }

  Future<void> deleteTab(RoutineBoardTab tab) async {
    final userId = _requiredUserId();

    await _client
        .from('routine_board_tabs')
        .delete()
        .eq('id', tab.id)
        .eq('user_id', userId);
  }

  String _requiredUserId() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado para acessar abas da rotina.');
    }
    return user.id;
  }

  String _dateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
