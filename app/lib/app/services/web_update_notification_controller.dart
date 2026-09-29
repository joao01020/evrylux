import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/notifications/models/app_update_notification.dart';
import 'web_sync_status_controller.dart';

class WebUpdateNotificationController extends ChangeNotifier {
  WebUpdateNotificationController({
    required this.syncStatus,
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  static const _readVersionKey = 'evrylux.web.notifications.read_version.v1';

  final SupabaseClient _client;
  final WebSyncStatusController syncStatus;

  AppUpdateNotification? _notification;
  AppUpdateNotification? get notification => _notification;

  bool _refreshing = false;
  bool get refreshing => _refreshing;

  String? _error;
  String? get error => _error;

  bool get hasUnread => _notification?.isUnread == true;

  RealtimeChannel? _channel;
  bool _disposed = false;

  Future<void> initialize() async {
    // Carregar notificações não representa sincronização global do app.
    // Portanto, não altera o indicador da nuvem.
    await refresh(silent: true);
    _startRealtime();
  }

  Future<void> refresh({bool silent = false}) async {
    if (_disposed || _refreshing) return;

    _refreshing = true;
    if (!silent) _error = null;
    notifyListeners();
    try {
      final rows = await _client
          .from('app_updates')
          .select()
          .eq('active', true)
          .order('published_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) {
        _notification = null;
      } else {
        final item = AppUpdateNotification.fromMap(
          Map<String, dynamic>.from(rows.first),
        );
        final prefs = await SharedPreferences.getInstance();
        final readVersion = prefs.getString(_readVersionKey);
        _notification = item.copyWith(isRead: readVersion == item.version);
      }

      _error = null;
    } catch (error) {
      if (!silent) _error = error.toString();
    } finally {
      _refreshing = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> markAsRead() async {
    final current = _notification;
    if (current == null || current.isRead) return;

    _notification = current.copyWith(isRead: true);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_readVersionKey, current.version);
  }

  void _startRealtime() {
    if (_disposed || _channel != null) return;

    _channel = _client
        .channel('evrylux_web_app_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_updates',
          callback: (_) {
            // Mudança remota real: anima a nuvem.
            // O refresh visual do painel não altera o status global.
            syncStatus.markSyncing();
            unawaited(refresh(silent: true));
          },
        );

    _channel!.subscribe();
  }

  @override
  void dispose() {
    _disposed = true;
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      unawaited(_client.removeChannel(channel));
    }
    super.dispose();
  }
}
