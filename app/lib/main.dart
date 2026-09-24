import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'core/constants/app_info.dart';
import 'core/database/app_database.dart';
import 'core/updater/update_installation_service.dart';
import 'app/dependencies/app_dependencies.dart';
import 'routine/windows/mind_map_window.dart';

// ============================================================
// WINDOW TYPES
// ============================================================

const String _mainWindowType = 'main';

const String _mindMapWindowType = 'mind_map';

// ============================================================
// MAIN
// ============================================================

Future<void> main(List<String> args) async {
  final startupTotal = Stopwatch()..start();

  void startupLog(String message) {
    debugPrint(
      '[STARTUP][MAIN] +${startupTotal.elapsedMilliseconds}ms $message',
    );
  }

  startupLog('main iniciado');

  // ==========================================================
  // UPDATER PREFLIGHT
  // ==========================================================
  //
  // O instalador verifica a identidade exata do bundle antes
  // de ativar uma nova versão.
  //
  // Esta verificação deve acontecer ANTES de inicializar o
  // Flutter, abrir janelas, carregar .env ou acessar o banco.
  //
  // Não executa migrações nem inicia serviços do aplicativo.
  //
  // ==========================================================

  if (args.contains('--evrylux-update-preflight')) {
    stdout.writeln(
      'EVRYLUX_PREFLIGHT:${jsonEncode({'version': AppInfo.version, 'dataSchema': AppDatabase.schemaVersion})}',
    );

    await stdout.flush();
    exit(0);
  }

  // ==========================================================
  // FLUTTER
  // ==========================================================

  WidgetsFlutterBinding.ensureInitialized();
  startupLog('WidgetsFlutterBinding pronto');

  // ==========================================================
  // UPDATER HEALTH
  // ==========================================================

  final healthArguments = args.where(
    (value) => value.startsWith('--evrylux-update-health='),
  );

  final updateHealthNonce = healthArguments.isEmpty
      ? null
      : healthArguments.first.substring('--evrylux-update-health='.length);

  // ==========================================================
  // CURRENT WINDOW
  // ==========================================================

  final windowControllerStage = Stopwatch()..start();
  final windowController = await WindowController.fromCurrentEngine();
  startupLog(
    'WindowController pronto (${windowControllerStage.elapsedMilliseconds}ms)',
  );

  final windowArguments = windowController.arguments.trim();

  final windowType = _resolveWindowType(windowArguments);

  // ==========================================================
  // WINDOW MANAGER
  // ==========================================================
  //
  // Necessário em todas as engines.
  //
  // ==========================================================

  final windowManagerStage = Stopwatch()..start();
  await windowManager.ensureInitialized();
  startupLog(
    'windowManager pronto (${windowManagerStage.elapsedMilliseconds}ms)',
  );

  // ==========================================================
  // SECONDARY MIND MAP WINDOW
  // ==========================================================
  //
  // A janela secundária é SOMENTE uma view/editora temporária.
  //
  // Ela NÃO inicializa:
  //
  // - Supabase;
  // - AppDatabase;
  // - ConnectivityService;
  // - SyncService;
  // - SyncQueue.
  //
  // O estado entra e sai pelo WindowMethodChannel.
  //
  // ==========================================================

  if (windowType == _mindMapWindowType) {
    runApp(MindMapWindowApp(arguments: windowArguments));

    return;
  }

  // ==========================================================
  // MAIN WINDOW - ENV
  // ==========================================================

  final dotenvStage = Stopwatch()..start();
  await dotenv.load(fileName: '.env');
  startupLog('dotenv carregado (${dotenvStage.elapsedMilliseconds}ms)');

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();

  final supabasePublishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim();

  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    throw StateError('SUPABASE_URL não foi configurada no arquivo .env.');
  }

  if (supabasePublishableKey == null || supabasePublishableKey.isEmpty) {
    throw StateError(
      'SUPABASE_PUBLISHABLE_KEY não foi configurada no arquivo .env.',
    );
  }

  // ==========================================================
  // SUPABASE - MAIN ENGINE ONLY
  // ==========================================================

  final supabaseStage = Stopwatch()..start();
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  startupLog('Supabase pronto (${supabaseStage.elapsedMilliseconds}ms)');

  // ==========================================================
  // LOCAL DATABASE - MAIN ENGINE ONLY
  // ==========================================================

  final databaseStage = Stopwatch()..start();
  await appDatabase.initialize();
  startupLog('AppDatabase pronto (${databaseStage.elapsedMilliseconds}ms)');

  // ==========================================================
  // OFFLINE-FIRST - MAIN ENGINE ONLY
  // ==========================================================

  final offlineStage = Stopwatch()..start();
  await initializeOfflineFirst();
  startupLog(
    'initializeOfflineFirst concluído (${offlineStage.elapsedMilliseconds}ms)',
  );

  runApp(GhostApp(evolutionController: evolutionController));
  startupLog('runApp chamado');

  WidgetsBinding.instance.addPostFrameCallback((_) {
    startupLog('primeiro frame renderizado');
  });

  // A healthy acknowledgement means initialization completed and the main
  // engine rendered a frame. It does not claim every feature was tested.
  if (updateHealthNonce != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(
        UpdateInstallationService.reportHealthy(
          nonce: updateHealthNonce,
          version: AppInfo.version,
        ).catchError((Object error) {
          debugPrint(
            '[UPDATER] Não foi possível confirmar a inicialização: $error',
          );
        }),
      );
    });
  }
}

// ============================================================
// RESOLVE WINDOW TYPE
// ============================================================

String _resolveWindowType(String arguments) {
  final value = arguments.trim();

  if (value.isEmpty) {
    return _mainWindowType;
  }

  if (value == _mindMapWindowType) {
    return _mindMapWindowType;
  }

  try {
    final decoded = jsonDecode(value);

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);

      final window = map['window']?.toString().trim();

      if (window == _mindMapWindowType) {
        return _mindMapWindowType;
      }
    }
  } catch (_) {
    // Argumento inválido -> janela principal.
  }

  return _mainWindowType;
}
