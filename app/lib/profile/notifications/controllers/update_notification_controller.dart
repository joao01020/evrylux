import 'package:flutter/foundation.dart';

import '../models/app_update_notification.dart';
import '../services/app_update_service.dart';

class UpdateNotificationController
    extends
        ChangeNotifier {
  UpdateNotificationController({
    required this.service,
  });

  // ============================================================
  // SERVICE
  // ============================================================

  final AppUpdateService service;

  // ============================================================
  // STATE
  // ============================================================

  AppUpdateNotification? _notification;

  bool _loading = false;

  bool _initialized = false;

  bool _disposed = false;

  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  AppUpdateNotification? get notification {
    return _notification;
  }

  bool get loading {
    return _loading;
  }

  bool get initialized {
    return _initialized;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  bool get hasError {
    return _errorMessage !=
        null;
  }

  // ============================================================
  // POSSUI ATUALIZAÇÃO
  // ============================================================

  bool get hasUpdate {
    return _notification !=
        null;
  }

  // ============================================================
  // POSSUI NÃO LIDA
  // ============================================================

  bool get hasUnread {
    return _notification?.isUnread ??
        false;
  }

  // ============================================================
  // CONTADOR
  // ============================================================
  //
  // Como atualmente trabalhamos apenas com a atualização mais
  // recente, o contador será sempre:
  //
  // 0 ou 1
  //
  // ============================================================

  int get unreadCount {
    return hasUnread
        ? 1
        : 0;
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  initialize() async {
    if (_disposed ||
        _initialized) {
      return;
    }

    _initialized = true;

    await checkForUpdates();
  }

  // ============================================================
  // CHECK
  // ============================================================

  Future<
    void
  >
  checkForUpdates() async {
    if (_disposed ||
        _loading) {
      return;
    }

    _setLoading(
      true,
    );

    _errorMessage = null;

    try {
      final result = await service.checkForUpdate();

      if (_disposed) {
        return;
      }

      // ========================================================
      // PRESERVAR ESTADO DE LEITURA
      // ========================================================
      //
      // Se a mesma versão já estava carregada e o usuário já
      // havia lido, não voltamos para não lida.
      //
      // ========================================================

      final current = _notification;

      if (result ==
          null) {
        _notification = null;
      } else if (current !=
              null &&
          current.version ==
              result.version) {
        _notification = result.copyWith(
          isRead: current.isRead,
        );
      } else {
        _notification = result.copyWith(
          isRead: false,
        );
      }
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[UPDATE NOTIFICATION] '
        'Erro ao verificar atualização: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // MARK AS READ
  // ============================================================

  void markAsRead() {
    final current = _notification;

    if (_disposed ||
        current ==
            null ||
        current.isRead) {
      return;
    }

    _notification = current.copyWith(
      isRead: true,
    );

    _safeNotifyListeners();
  }

  // ============================================================
  // MARK AS UNREAD
  // ============================================================

  void markAsUnread() {
    final current = _notification;

    if (_disposed ||
        current ==
            null ||
        !current.isRead) {
      return;
    }

    _notification = current.copyWith(
      isRead: false,
    );

    _safeNotifyListeners();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clear() {
    if (_disposed ||
        _notification ==
            null) {
      return;
    }

    _notification = null;

    _safeNotifyListeners();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (_disposed ||
        _errorMessage ==
            null) {
      return;
    }

    _errorMessage = null;

    _safeNotifyListeners();
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(
    bool value,
  ) {
    if (_disposed ||
        _loading ==
            value) {
      return;
    }

    _loading = value;

    _safeNotifyListeners();
  }

  // ============================================================
  // NOTIFY
  // ============================================================

  void _safeNotifyListeners() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    super.dispose();
  }
}
