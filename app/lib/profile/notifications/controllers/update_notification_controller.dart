import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_update_notification.dart';
import '../services/app_update_service.dart';

class UpdateNotificationController extends ChangeNotifier {
  UpdateNotificationController({
    required this.service,
  });

  final AppUpdateService service;

  AppUpdateNotification? _notification;

  bool _initialLoading = false;
  bool _refreshing = false;
  bool _initialized = false;
  bool _disposed = false;

  RealtimeChannel? _realtimeChannel;

  String? _errorMessage;

  AppUpdateNotification? get notification => _notification;

  String get currentVersion => service.currentVersion;

  // Compatibilidade com widgets/callers antigos.
  // Loading agora significa somente ausência inicial de cache.
  bool get loading => _initialLoading;

  bool get initialLoading => _initialLoading;

  bool get refreshing => _refreshing;

  bool get initialized => _initialized;

  String? get errorMessage => _errorMessage;

  bool get hasError =>
      _errorMessage != null && _errorMessage!.trim().isNotEmpty;

  bool get hasUpdate => _notification != null;

  bool get hasUnread => _notification?.isUnread ?? false;

  int get unreadCount => hasUnread ? 1 : 0;

  // ============================================================
  // INITIALIZE
  // ============================================================
  //
  // 1. carrega SQLite;
  // 2. libera UI imediatamente;
  // 3. refresh remoto continua em background.
  //
  // ============================================================

  Future<void> initialize() async {
    if (_disposed || _initialized) {
      return;
    }

    _initialized = true;
    _initialLoading = true;
    _errorMessage = null;

    _safeNotifyListeners();

    try {
      _notification = await service.loadCachedUpdate();
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[UPDATE NOTIFICATION] Erro ao carregar cache: $error',
      );
      debugPrint(
        stackTrace.toString(),
      );
    } finally {
      _initialLoading = false;
      _safeNotifyListeners();
    }

    if (_disposed) {
      return;
    }

    _startRealtime();

    unawaited(
      checkForUpdates(
        silent: true,
      ),
    );
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> checkForUpdates({
    bool silent = false,
  }) async {
    if (_disposed || _refreshing) {
      return;
    }

    _refreshing = true;

    if (!silent) {
      _errorMessage = null;
    }

    _safeNotifyListeners();

    try {
      final result = await service.checkForUpdate();

      if (_disposed) {
        return;
      }

      _notification = result;
      _errorMessage = null;
    } catch (
      error,
      stackTrace
    ) {
      if (!silent) {
        _errorMessage = error.toString();
      }

      debugPrint(
        '[UPDATE NOTIFICATION] Erro ao verificar atualização: $error',
      );
      debugPrint(
        stackTrace.toString(),
      );
    } finally {
      _refreshing = false;
      _safeNotifyListeners();
    }
  }


  // ============================================================
  // REALTIME
  // ============================================================

  void _startRealtime() {
    if (_disposed || _realtimeChannel != null) {
      return;
    }

    _realtimeChannel = service.subscribeToRealtime(
      onChanged: () {
        if (_disposed) {
          return;
        }

        // O evento chega imediatamente pelo Realtime.
        // Em seguida buscamos o snapshot mais recente para cobrir
        // INSERT, UPDATE, DELETE e mudanças de active sem duplicar
        // regra de negócio dentro do listener.
        unawaited(
          checkForUpdates(
            silent: true,
          ),
        );
      },
    );
  }

  Future<void> _stopRealtime() async {
    final channel = _realtimeChannel;

    _realtimeChannel = null;

    if (channel == null) {
      return;
    }

    await service.unsubscribeFromRealtime(
      channel,
    );
  }

  // ============================================================
  // READ STATE
  // ============================================================

  void markAsRead() {
    final current = _notification;

    if (_disposed || current == null || current.isRead) {
      return;
    }

    final updated = current.copyWith(
      isRead: true,
    );

    _notification = updated;
    _safeNotifyListeners();

    unawaited(
      service.saveCachedUpdate(
        updated,
      ),
    );
  }

  void markAsUnread() {
    final current = _notification;

    if (_disposed || current == null || !current.isRead) {
      return;
    }

    final updated = current.copyWith(
      isRead: false,
    );

    _notification = updated;
    _safeNotifyListeners();

    unawaited(
      service.saveCachedUpdate(
        updated,
      ),
    );
  }

  void clear() {
    if (_disposed || _notification == null) {
      return;
    }

    _notification = null;
    _safeNotifyListeners();

    unawaited(
      service.clearCachedUpdate(),
    );
  }

  void clearError() {
    if (_disposed || _errorMessage == null) {
      return;
    }

    _errorMessage = null;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    unawaited(
      _stopRealtime(),
    );

    super.dispose();
  }
}
