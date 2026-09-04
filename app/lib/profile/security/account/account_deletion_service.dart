import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/app_database.dart';
import '../../../study/brain/devices/security/brain_device_secure_storage.dart';
import '../../../study/brain/security/keys/brain_key_storage.dart';
import '../../../study/brain/settings/storage/brain_data_mode_storage.dart';
import '../devices/services/account_device_identity_service.dart';

class AccountDeletionService {
  AccountDeletionService({
    required SupabaseClient client,
    required AppDatabase appDatabase,
    required BrainKeyStorage brainKeyStorage,
    required BrainDeviceSecureStorage brainDeviceSecureStorage,
    required BrainDataModeStorage brainDataModeStorage,
    required AccountDeviceIdentityService accountDeviceIdentityService,
  })  : _client = client,
        _appDatabase = appDatabase,
        _brainKeyStorage = brainKeyStorage,
        _brainDeviceSecureStorage = brainDeviceSecureStorage,
        _brainDataModeStorage = brainDataModeStorage,
        _accountDeviceIdentityService = accountDeviceIdentityService;

  final SupabaseClient _client;
  final AppDatabase _appDatabase;
  final BrainKeyStorage _brainKeyStorage;
  final BrainDeviceSecureStorage _brainDeviceSecureStorage;
  final BrainDataModeStorage _brainDataModeStorage;
  final AccountDeviceIdentityService _accountDeviceIdentityService;

  Future<void> deleteAllData({
    String? vaultId,
  }) async {
    await _invokeRemoteCleanup(
      mode: 'data',
    );

    await _wipeLocalData(
      vaultId: vaultId,
    );
  }

  Future<void> deleteAccount({
    String? vaultId,
  }) async {
    await _invokeRemoteCleanup(
      mode: 'account',
    );

    await _wipeLocalData(
      vaultId: vaultId,
    );

    try {
      await _client.auth.signOut(
        scope: SignOutScope.local,
      );
    } catch (_) {
      // A conta já pode ter sido removida no servidor.
    }
  }

  Future<void> _invokeRemoteCleanup({
    required String mode,
  }) async {
    if (_client.auth.currentSession == null) {
      throw StateError(
        'Sessão autenticada necessária para esta operação.',
      );
    }

    final response = await _client.functions.invoke(
      'account-cleanup',
      body: <String, dynamic>{
        'mode': mode,
      },
    );

    if (response.status < 200 ||
        response.status >= 300) {
      throw StateError(
        'Falha na exclusão remota. HTTP ${response.status}.',
      );
    }

    final data = response.data;

    if (data is Map &&
        data['ok'] != true) {
      throw StateError(
        data['error']?.toString() ??
            'O servidor não confirmou a exclusão.',
      );
    }
  }

  Future<void> _wipeLocalData({
    String? vaultId,
  }) async {
    final normalizedVaultId = vaultId?.trim();

    if (normalizedVaultId != null &&
        normalizedVaultId.isNotEmpty) {
      await _brainKeyStorage.deleteKeyBundle(
        vaultId: normalizedVaultId,
      );
    }

    await _brainDeviceSecureStorage.clear();
    await _accountDeviceIdentityService.clear();
    await _brainDataModeStorage.clear();

    _clearLocalDatabaseTables();

    await _clearKnownPreferences();
    await _deleteManagedDirectories();
  }

  void _clearLocalDatabaseTables() {
    if (!_appDatabase.isOpen) {
      return;
    }

    const tables = <String>[
      'sync_queue',
      'training_activity_plans',
      'local_board_attachments',
      'local_board_comments',
      'local_board_comment_scopes',
      'profile_cache',
      'local_reminders',
      'local_routines',
      'local_finance',
      'local_finance_history_cache',
      'local_finance_objective_cache',
      'local_finance_price_cache',
    ];

    _appDatabase.transaction<void>(
      () {
        for (final table in tables) {
          final exists = _appDatabase.db.select(
            '''
SELECT 1
FROM sqlite_master
WHERE type = 'table'
  AND name = ?
LIMIT 1
''',
            <Object?>[
              table,
            ],
          );

          if (exists.isEmpty) {
            continue;
          }

          _appDatabase.db.execute(
            'DELETE FROM "$table";',
          );
        }
      },
    );
  }

  Future<void> _clearKnownPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    const keys = <String>[
      'training_data',
      'training_plan_data',
      'study_data',
      'finance_data',
      'evolution_history',
      'journey_history',
      'crypto_transactions',
      'evrylux.brain.data_mode.v1',
    ];

    for (final key in keys) {
      await prefs.remove(
        key,
      );
    }
  }

  Future<void> _deleteManagedDirectories() async {
    final documents = await getApplicationDocumentsDirectory();

    final paths = <String>[
      '${documents.path}/ghost_brain',
      '${documents.path}/evrylux_brain',
      '${documents.path}/evrylux/boards',
    ];

    for (final path in paths) {
      final directory = Directory(
        path,
      );

      if (await directory.exists()) {
        await directory.delete(
          recursive: true,
        );
      }
    }
  }
}
