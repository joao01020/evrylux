import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/telegram_connection.dart';
import '../services/telegram_connection_service.dart';

class TelegramConnectionController
    extends
        ChangeNotifier {
  TelegramConnectionController({
    required this.service,
  });

  // ============================================================
  // SERVICE
  // ============================================================

  final TelegramConnectionService service;

  // ============================================================
  // STATE
  // ============================================================

  TelegramConnection? _connection;

  bool _loading = false;

  bool _connecting = false;

  bool _testing = false;

  bool _disconnecting = false;

  bool _waitingForConnection = false;

  String? _errorMessage;

  int _pollGeneration = 0;

  bool _disposed = false;

  // ============================================================
  // GETTERS
  // ============================================================

  TelegramConnection? get connection {
    return _connection;
  }

  bool get isConnected {
    return _connection?.enabled ==
        true;
  }

  bool get loading {
    return _loading;
  }

  bool get connecting {
    return _connecting;
  }

  bool get testing {
    return _testing;
  }

  bool get disconnecting {
    return _disconnecting;
  }

  bool get waitingForConnection {
    return _waitingForConnection;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void _notify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  load({
    bool notify = true,
  }) async {
    if (_disposed) {
      return;
    }

    if (_loading) {
      return;
    }

    _loading = true;
    _errorMessage = null;

    if (notify) {
      _notify();
    }

    try {
      _connection = await service.loadConnection();
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = _friendlyError(
        error,
      );

      debugPrint(
        '[TELEGRAM] Erro ao carregar conexão: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );
    } finally {
      _loading = false;

      if (notify) {
        _notify();
      }
    }
  }

  // ============================================================
  // BEGIN CONNECTION
  // ============================================================

  Future<
    bool
  >
  beginConnection() async {
    if (_disposed) {
      return false;
    }

    if (_connecting) {
      return false;
    }

    _connecting = true;

    _errorMessage = null;

    _notify();

    try {
      debugPrint(
        '[TELEGRAM] Iniciando conexão com o Telegram.',
      );

      final uri = await service.createConnectionLink();

      await service.openConnectionLink(
        uri,
      );

      debugPrint(
        '[TELEGRAM] Link aberto. '
        'Aguardando conclusão no Telegram.',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = _friendlyError(
        error,
      );

      debugPrint(
        '[TELEGRAM] Erro ao iniciar conexão: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      return false;
    } finally {
      _connecting = false;

      _notify();
    }
  }

  // ============================================================
  // REFRESH CONNECTION
  // ============================================================
  //
  // Atualização manual.
  //
  // Esta versão pode notificar a interface.
  //
  // O polling interno usa _checkConnectionSilently().
  //
  // ============================================================

  Future<
    bool
  >
  refreshConnection() async {
    if (_disposed) {
      return false;
    }

    try {
      final previousConnection = _connection;

      final nextConnection = await service.loadConnection();

      _connection = nextConnection;

      _errorMessage = null;

      final connectionChanged =
          previousConnection?.userId !=
              nextConnection?.userId ||
          previousConnection?.chatId !=
              nextConnection?.chatId ||
          previousConnection?.enabled !=
              nextConnection?.enabled;

      if (connectionChanged) {
        _notify();
      }

      return isConnected;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = _friendlyError(
        error,
      );

      debugPrint(
        '[TELEGRAM] Erro ao verificar conexão: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      _notify();

      return false;
    }
  }

  // ============================================================
  // SILENT CONNECTION CHECK
  // ============================================================
  //
  // Usado exclusivamente pelo polling.
  //
  // Não gera logs enquanto nada muda.
  // Não atualiza UI a cada tentativa.
  //
  // ============================================================

  Future<
    bool
  >
  _checkConnectionSilently() async {
    if (_disposed) {
      return false;
    }

    try {
      final nextConnection = await service.loadConnection();

      if (nextConnection ==
              null ||
          nextConnection.enabled !=
              true) {
        return false;
      }

      final wasConnected = isConnected;

      _connection = nextConnection;

      _errorMessage = null;

      if (!wasConnected) {
        debugPrint(
          '[TELEGRAM] Conexão com o Telegram concluída.',
        );

        _notify();
      }

      return true;
    } catch (
      error,
      stackTrace
    ) {
      // Não imprimimos repetidamente o mesmo erro durante
      // cada ciclo do polling.
      //
      // O erro é registrado apenas uma vez pelo waitForConnection.
      throw _TelegramPollingException(
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // WAIT FOR CONNECTION
  // ============================================================

  Future<
    bool
  >
  waitForConnection({
    Duration timeout = const Duration(
      minutes: 2,
    ),
    Duration interval = const Duration(
      seconds: 2,
    ),
  }) async {
    if (_disposed) {
      return false;
    }

    if (isConnected) {
      return true;
    }

    final generation = ++_pollGeneration;

    final deadline = DateTime.now().add(
      timeout,
    );

    _waitingForConnection = true;

    _errorMessage = null;

    _notify();

    debugPrint(
      '[TELEGRAM] Aguardando conclusão da conexão.',
    );

    try {
      while (!_disposed &&
          DateTime.now().isBefore(
            deadline,
          )) {
        // ======================================================
        // CANCELLED
        // ======================================================

        if (generation !=
            _pollGeneration) {
          debugPrint(
            '[TELEGRAM] Espera pela conexão cancelada.',
          );

          return isConnected;
        }

        // ======================================================
        // CHECK
        // ======================================================

        try {
          final connected = await _checkConnectionSilently();

          if (connected) {
            return true;
          }
        } on _TelegramPollingException catch (
          pollingError
        ) {
          _errorMessage = _friendlyError(
            pollingError.error,
          );

          debugPrint(
            '[TELEGRAM] Erro durante espera da conexão: '
            '${pollingError.error}',
          );

          debugPrint(
            pollingError.stackTrace.toString(),
          );

          _notify();

          return false;
        }

        // ======================================================
        // WAIT
        // ======================================================

        await Future<
          void
        >.delayed(
          interval,
        );
      }

      // ========================================================
      // TIMEOUT
      // ========================================================

      if (generation ==
              _pollGeneration &&
          !isConnected) {
        debugPrint(
          '[TELEGRAM] Tempo de espera pela conexão expirado.',
        );
      }

      return isConnected;
    } finally {
      // Só a execução atual pode remover o estado waiting.
      //
      // Isso evita que uma espera antiga encerre uma mais nova.
      if (generation ==
          _pollGeneration) {
        _waitingForConnection = false;

        _notify();
      }
    }
  }

  // ============================================================
  // CANCEL WAITING
  // ============================================================

  void cancelWaiting() {
    if (_disposed) {
      return;
    }

    final wasWaiting = _waitingForConnection;

    _pollGeneration++;

    _waitingForConnection = false;

    if (wasWaiting) {
      debugPrint(
        '[TELEGRAM] Espera pela conexão cancelada.',
      );

      _notify();
    }
  }

  // ============================================================
  // SEND TEST
  // ============================================================

  Future<
    bool
  >
  sendTest() async {
    if (_disposed) {
      return false;
    }

    if (_testing) {
      return false;
    }

    _testing = true;

    _errorMessage = null;

    _notify();

    try {
      await service.sendTestMessage();

      debugPrint(
        '[TELEGRAM] Mensagem de teste enviada.',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = _friendlyError(
        error,
      );

      debugPrint(
        '[TELEGRAM] Erro ao enviar teste: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      return false;
    } finally {
      _testing = false;

      _notify();
    }
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  Future<
    bool
  >
  disconnect() async {
    if (_disposed) {
      return false;
    }

    if (_disconnecting) {
      return false;
    }

    _disconnecting = true;

    _errorMessage = null;

    _notify();

    try {
      // Para qualquer polling antes de remover
      // a conexão.
      cancelWaiting();

      await service.disconnect();

      _connection = null;

      debugPrint(
        '[TELEGRAM] Conexão removida.',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = _friendlyError(
        error,
      );

      debugPrint(
        '[TELEGRAM] Erro ao desconectar: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      return false;
    } finally {
      _disconnecting = false;

      _notify();
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (_disposed) {
      return;
    }

    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    _notify();
  }

  // ============================================================
  // FRIENDLY ERROR
  // ============================================================

  String _friendlyError(
    Object error,
  ) {
    final text = error.toString();

    if (text.startsWith(
      'Bad state: ',
    )) {
      return text.substring(
        'Bad state: '.length,
      );
    }

    return text;
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

    _pollGeneration++;

    _waitingForConnection = false;

    super.dispose();
  }
}

// ============================================================
// POLLING ERROR
// ============================================================
//
// Wrapper interno usado para transportar erro + stack trace
// sem imprimir uma mensagem em cada ciclo.
//
// ============================================================

class _TelegramPollingException
    implements
        Exception {
  const _TelegramPollingException({
    required this.error,
    required this.stackTrace,
  });

  final Object error;

  final StackTrace stackTrace;
}
