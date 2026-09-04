import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/account_device.dart';

class AccountDeviceRepository {
  AccountDeviceRepository({
    SupabaseClient? client,
  }) : _client = client ??
            Supabase.instance.client;

  final SupabaseClient _client;

  void _requireAuth() {
    if (_client.auth.currentUser == null ||
        _client.auth.currentSession == null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }
  }

  String getCurrentSessionId() {
    _requireAuth();

    final accessToken = _client.auth.currentSession!.accessToken;

    final parts = accessToken.split(
      '.',
    );

    if (parts.length !=
        3) {
      throw const FormatException(
        'JWT da sessão inválido.',
      );
    }

    final normalized = base64Url.normalize(
      parts[1],
    );

    final decoded = utf8.decode(
      base64Url.decode(
        normalized,
      ),
    );

    final payload = jsonDecode(
      decoded,
    );

    if (payload is! Map) {
      throw const FormatException(
        'Payload JWT inválido.',
      );
    }

    final sessionId = payload['session_id'];

    if (sessionId is! String ||
        sessionId.trim().isEmpty) {
      throw const FormatException(
        'session_id não encontrado no JWT.',
      );
    }

    return sessionId.trim();
  }

  Future<
    bool
  >
  registerDevice({
    required String deviceId,
    required String deviceName,
    required String platform,
    required String appVersion,
  }) async {
    _requireAuth();

    final result = await _client.rpc(
      'register_user_device',
      params: {
        'p_device_id': deviceId,
        'p_device_name': deviceName,
        'p_platform': platform,
        'p_app_version': appVersion,
      },
    );

    return result == true;
  }

  Future<
    bool
  >
  touchDevice({
    required String deviceId,
    required String deviceName,
    required String platform,
    required String appVersion,
  }) async {
    _requireAuth();

    final result = await _client.rpc(
      'touch_user_device',
      params: {
        'p_device_id': deviceId,
        'p_device_name': deviceName,
        'p_platform': platform,
        'p_app_version': appVersion,
      },
    );

    return result == true;
  }

  Future<
    List<
      AccountDevice
    >
  >
  listActiveDevices() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return const <
        AccountDevice
      >[];
    }

    final result = await _client
        .from(
          'user_devices',
        )
        .select()
        .eq(
          'user_id',
          user.id,
        )
        .isFilter(
          'revoked_at',
          null,
        )
        .isFilter(
          'ended_at',
          null,
        )
        .order(
          'last_seen_at',
          ascending: false,
        );

    return result
        .map(
          (row) => AccountDevice.fromMap(
            Map<String, dynamic>.from(
              row,
            ),
          ),
        )
        .toList(
          growable: false,
        );
  }

  Future<
    void
  >
  revokeSession(
    String sessionId,
  ) async {
    _requireAuth();

    await _client.rpc(
      'revoke_user_device',
      params: {
        'p_session_id': sessionId,
      },
    );
  }

  Future<
    void
  >
  disconnectCurrentDevice() async {
    if (_client.auth.currentUser == null ||
        _client.auth.currentSession == null) {
      return;
    }

    await _client.rpc(
      'disconnect_current_user_device',
    );
  }
}
