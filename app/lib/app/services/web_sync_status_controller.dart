import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum WebSyncVisualState { checking, syncing, online, error }

class WebSyncStatusController extends ChangeNotifier {
  WebSyncStatusController({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  WebSyncVisualState _state = WebSyncVisualState.checking;
  WebSyncVisualState get state => _state;

  RealtimeChannel? _channel;
  Timer? _settleTimer;
  bool _disposed = false;

  Future<void> initialize() async {
    if (_disposed || _channel != null) return;

    _setState(WebSyncVisualState.checking);

    try {
      _channel = _client
          .channel('evrylux_web_sync_status')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            callback: (_) => markSyncing(),
          );

      _channel!.subscribe();
      _setState(WebSyncVisualState.online);
    } catch (_) {
      _setState(WebSyncVisualState.error);
    }
  }

  void markChecking() {
    _settleTimer?.cancel();
    _setState(WebSyncVisualState.checking);
  }

  void markSyncing() {
    _settleTimer?.cancel();
    _setState(WebSyncVisualState.syncing);
    _settleTimer = Timer(const Duration(milliseconds: 850), () {
      if (!_disposed) _setState(WebSyncVisualState.online);
    });
  }

  void markOnline() {
    _settleTimer?.cancel();
    _setState(WebSyncVisualState.online);
  }

  void markError() {
    _settleTimer?.cancel();
    _setState(WebSyncVisualState.error);
  }

  Future<T> runDatabaseSync<T>(Future<T> Function() action) async {
    markSyncing();
    try {
      final value = await action();
      markOnline();
      return value;
    } catch (_) {
      markError();
      rethrow;
    }
  }

  void _setState(WebSyncVisualState value) {
    if (_disposed || _state == value) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _settleTimer?.cancel();
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      unawaited(_client.removeChannel(channel));
    }
    super.dispose();
  }
}
