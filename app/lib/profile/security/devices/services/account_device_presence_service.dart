import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_info.dart';
import '../repositories/account_device_repository.dart';
import 'account_device_identity_service.dart';

typedef AccountDeviceRevokedCallback =
    Future<
      void
    >
    Function();

class AccountDevicePresenceService {
  AccountDevicePresenceService({
    required SupabaseClient client,
    required AccountDeviceRepository repository,
    required AccountDeviceIdentityService identityService,
    this.heartbeatInterval = const Duration(
      minutes: 1,
    ),
  })  : _client = client,
        _repository = repository,
        _identityService = identityService;

  final SupabaseClient _client;

  final AccountDeviceRepository _repository;

  final AccountDeviceIdentityService _identityService;

  final Duration heartbeatInterval;

  Timer? _timer;

  bool _running = false;

  bool _checking = false;

  String? _runningForUserId;

  AccountDeviceRevokedCallback? _onRevoked;

  bool get isRunning => _running;

  Future<
    void
  >
  start({
    required AccountDeviceRevokedCallback onRevoked,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      stop();

      return;
    }

    _onRevoked = onRevoked;

    if (_running &&
        _runningForUserId == user.id) {
      return;
    }

    stop();

    _running = true;
    _runningForUserId = user.id;

    final active = await _registerCurrentDevice();

    if (!active) {
      await _handleRevoked();

      return;
    }

    _timer = Timer.periodic(
      heartbeatInterval,
      (
        _,
      ) {
        unawaited(
          _heartbeat(),
        );
      },
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _running = false;
    _checking = false;
    _runningForUserId = null;
    _onRevoked = null;
  }

  Future<
    bool
  >
  _registerCurrentDevice() async {
    try {
      final deviceId = await _identityService.getOrCreateDeviceId();

      return await _repository.registerDevice(
        deviceId: deviceId,
        deviceName: _identityService.deviceName,
        platform: _identityService.platformLabel,
        appVersion: AppInfo.version,
      );
    } catch (
      error
    ) {
      debugPrint(
        '[ACCOUNT DEVICE] Falha ao registrar dispositivo: $error',
      );

      // Falha de rede não deve expulsar o usuário.
      // O estado de revogação só é considerado quando o servidor
      // responde explicitamente false.
      return true;
    }
  }

  Future<
    void
  >
  _heartbeat() async {
    if (!_running ||
        _checking) {
      return;
    }

    final user = _client.auth.currentUser;

    if (user == null ||
        user.id != _runningForUserId) {
      stop();

      return;
    }

    _checking = true;

    try {
      final deviceId = await _identityService.getOrCreateDeviceId();

      final active = await _repository.touchDevice(
        deviceId: deviceId,
        deviceName: _identityService.deviceName,
        platform: _identityService.platformLabel,
        appVersion: AppInfo.version,
      );

      if (!active) {
        await _handleRevoked();
      }
    } catch (
      error
    ) {
      debugPrint(
        '[ACCOUNT DEVICE] Heartbeat indisponível: $error',
      );
    } finally {
      _checking = false;
    }
  }

  Future<
    void
  >
  _handleRevoked() async {
    if (!_running) {
      return;
    }

    final callback = _onRevoked;

    stop();

    if (callback != null) {
      await callback();
    }
  }
}
