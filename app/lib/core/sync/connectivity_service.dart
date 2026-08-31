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
    this.checkInterval = const Duration(
      seconds: 15,
    ),
    this.probeHost = 'supabase.com',
    this.probePort = 443,
  }) : _connectivity =
           connectivity ??
           Connectivity();

  final Connectivity _connectivity;

  final Duration checkInterval;
  final String probeHost;
  final int probePort;

  StreamSubscription<
    List<
      ConnectivityResult
    >
  >?
  _subscription;

  Timer? _timer;

  ConnectionStateStatus _status = ConnectionStateStatus.checking;

  DateTime? _lastCheckedAt;

  bool _started = false;
  bool _checking = false;

  ConnectionStateStatus get status => _status;

  bool get isOnline =>
      _status ==
      ConnectionStateStatus.online;

  bool get isOffline =>
      _status ==
      ConnectionStateStatus.offline;

  bool get isChecking =>
      _status ==
      ConnectionStateStatus.checking;

  DateTime? get lastCheckedAt => _lastCheckedAt;

  bool get isStarted => _started;

  Future<
    void
  >
  start() async {
    if (_started) {
      return;
    }

    _started = true;

    _subscription = _connectivity.onConnectivityChanged.listen(
      (
        _,
      ) {
        unawaited(
          checkNow(),
        );
      },
    );

    await checkNow();

    _timer = Timer.periodic(
      checkInterval,
      (
        _,
      ) {
        unawaited(
          checkNow(),
        );
      },
    );
  }

  Future<
    bool
  >
  checkNow() async {
    if (_checking) {
      return isOnline;
    }

    _checking = true;

    try {
      final connectivityResults = await _connectivity.checkConnectivity();

      final hasNetworkInterface = connectivityResults.any(
        (
          result,
        ) =>
            result !=
            ConnectivityResult.none,
      );

      if (!hasNetworkInterface) {
        _setStatus(
          ConnectionStateStatus.offline,
        );

        return false;
      }

      final reachable = await _probeRemote();

      _setStatus(
        reachable
            ? ConnectionStateStatus.online
            : ConnectionStateStatus.offline,
      );

      return reachable;
    } catch (
      _
    ) {
      _setStatus(
        ConnectionStateStatus.offline,
      );

      return false;
    } finally {
      _checking = false;
      _lastCheckedAt = DateTime.now();
    }
  }

  Future<
    bool
  >
  _probeRemote() async {
    Socket? socket;

    try {
      socket = await Socket.connect(
        probeHost,
        probePort,
        timeout: const Duration(
          seconds: 3,
        ),
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

  void _setStatus(
    ConnectionStateStatus value,
  ) {
    if (_status ==
        value) {
      return;
    }

    _status = value;

    notifyListeners();
  }

  Future<
    void
  >
  stop() async {
    _timer?.cancel();
    _timer = null;

    await _subscription?.cancel();
    _subscription = null;

    _started = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _subscription?.cancel();

    super.dispose();
  }
}
