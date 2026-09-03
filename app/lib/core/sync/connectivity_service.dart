import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

enum ConnectionStateStatus {
  online,
  offline,
  checking,
}

class ConnectivityService
    extends
        ChangeNotifier {
  ConnectivityService({
    Connectivity? connectivity,
    this.probeHost = 'supabase.com',
    this.probePort = 443,
    this.probeTimeout = const Duration(
      seconds: 3,
    ),
    this.probeCacheDuration = const Duration(
      seconds: 30,
    ),
  }) : _connectivity =
           connectivity ??
           Connectivity();

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final Connectivity _connectivity;

  // ============================================================
  // PROBE
  // ============================================================

  final String probeHost;

  final int probePort;

  final Duration probeTimeout;

  /// Durante este período reutilizamos o resultado do último
  /// probe remoto.
  ///
  /// Isso evita abrir sockets repetidamente quando vários
  /// serviços perguntam pela conexão quase ao mesmo tempo.
  final Duration probeCacheDuration;

  // ============================================================
  // SUBSCRIPTION
  // ============================================================

  StreamSubscription<
    List<
      ConnectivityResult
    >
  >?
  _subscription;

  // ============================================================
  // STATE
  // ============================================================

  ConnectionStateStatus _status = ConnectionStateStatus.checking;

  DateTime? _lastCheckedAt;

  DateTime? _lastRemoteProbeAt;

  bool _started = false;

  bool _checking = false;

  bool _disposed = false;

  // ============================================================
  // GETTERS
  // ============================================================

  ConnectionStateStatus get status {
    return _status;
  }

  bool get isOnline {
    return _status ==
        ConnectionStateStatus.online;
  }

  bool get isOffline {
    return _status ==
        ConnectionStateStatus.offline;
  }

  bool get isChecking {
    return _checking;
  }

  bool get isStarted {
    return _started;
  }

  DateTime? get lastCheckedAt {
    return _lastCheckedAt;
  }

  DateTime? get lastRemoteProbeAt {
    return _lastRemoteProbeAt;
  }

  // ============================================================
  // START
  // ============================================================

  Future<
    void
  >
  start() async {
    if (_disposed ||
        _started) {
      return;
    }

    _started = true;

    // ==========================================================
    // EVENT DRIVEN
    // ==========================================================
    //
    // Não fazemos mais Timer.periodic aqui.
    //
    // O sistema operacional informa quando a conectividade muda.
    //
    // Assim não abrimos um socket para o Supabase a cada
    // poucos segundos sem necessidade.
    //
    // ==========================================================

    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Uma única verificação real na inicialização.
    await checkNow(
      forceRemoteProbe: true,
    );
  }

  // ============================================================
  // CONNECTIVITY EVENT
  // ============================================================

  void _onConnectivityChanged(
    List<
      ConnectivityResult
    >
    results,
  ) {
    if (_disposed ||
        !_started) {
      return;
    }

    final hasInterface = _hasNetworkInterface(
      results,
    );

    if (!hasInterface) {
      _lastCheckedAt = DateTime.now();

      _setStatus(
        ConnectionStateStatus.offline,
      );

      return;
    }

    // A interface reapareceu.
    //
    // Fazemos um probe real porque:
    //
    // Wi-Fi/Ethernet ativo != internet disponível.
    unawaited(
      checkNow(
        forceRemoteProbe: true,
      ),
    );
  }

  // ============================================================
  // CHECK NOW
  // ============================================================

  Future<
    bool
  >
  checkNow({
    bool forceRemoteProbe = false,
  }) async {
    if (_disposed) {
      return false;
    }

    // Outra checagem já está em andamento.
    //
    // Não abrimos um segundo socket simultaneamente.
    if (_checking) {
      return isOnline;
    }

    // ==========================================================
    // CACHE DO PROBE
    // ==========================================================

    if (!forceRemoteProbe &&
        _canReuseLastProbe()) {
      return isOnline;
    }

    _checking = true;

    try {
      final results = await _connectivity.checkConnectivity();

      final hasInterface = _hasNetworkInterface(
        results,
      );

      if (!hasInterface) {
        _setStatus(
          ConnectionStateStatus.offline,
        );

        return false;
      }

      final reachable = await _probeRemote();

      _lastRemoteProbeAt = DateTime.now();

      _setStatus(
        reachable
            ? ConnectionStateStatus.online
            : ConnectionStateStatus.offline,
      );

      return reachable;
    } catch (
      error
    ) {
      debugPrint(
        '[CONNECTIVITY] '
        'Falha ao verificar conexão: $error',
      );

      _setStatus(
        ConnectionStateStatus.offline,
      );

      return false;
    } finally {
      _checking = false;

      _lastCheckedAt = DateTime.now();
    }
  }

  // ============================================================
  // REUSE PROBE
  // ============================================================

  bool _canReuseLastProbe() {
    final last = _lastRemoteProbeAt;

    if (last ==
        null) {
      return false;
    }

    final elapsed = DateTime.now().difference(
      last,
    );

    return elapsed <
        probeCacheDuration;
  }

  // ============================================================
  // NETWORK INTERFACE
  // ============================================================

  bool _hasNetworkInterface(
    List<
      ConnectivityResult
    >
    results,
  ) {
    return results.any(
      (
        result,
      ) =>
          result !=
          ConnectivityResult.none,
    );
  }

  // ============================================================
  // REMOTE PROBE
  // ============================================================

  Future<
    bool
  >
  _probeRemote() async {
    Socket? socket;

    try {
      socket = await Socket.connect(
        probeHost,
        probePort,
        timeout: probeTimeout,
      );

      return true;
    } catch (
      _
    ) {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  void _setStatus(
    ConnectionStateStatus value,
  ) {
    if (_status ==
        value) {
      return;
    }

    final previous = _status;

    _status = value;

    debugPrint(
      '[CONNECTIVITY] '
      '${previous.name} -> ${value.name}',
    );

    if (!_disposed) {
      notifyListeners();
    }
  }

  // ============================================================
  // STOP
  // ============================================================

  Future<
    void
  >
  stop() async {
    if (!_started) {
      return;
    }

    await _subscription?.cancel();

    _subscription = null;

    _started = false;
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

    unawaited(
      _subscription?.cancel() ??
          Future<
            void
          >.value(),
    );

    _subscription = null;

    super.dispose();
  }
}
