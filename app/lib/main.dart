import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'app/dependencies/app_dependencies.dart';

import 'routine/windows/mind_map_window.dart';

// ============================================================
// WINDOW TYPES
// ============================================================

const String
_mainWindowType = 'main';

const String
_mindMapWindowType = 'mind_map';

// ============================================================
// MAIN
// ============================================================

Future<
  void
>
main(
  List<
    String
  >
  args,
) async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // CURRENT WINDOW
  // ==========================================================
  //
  // desktop_multi_window cria uma Flutter Engine independente
  // para cada janela.
  //
  // Por isso descobrimos primeiro qual janela está sendo
  // inicializada antes de iniciar serviços globais.
  //
  // ==========================================================

  final windowController = await WindowController.fromCurrentEngine();

  final windowArguments = windowController.arguments.trim();

  final windowType = _resolveWindowType(
    windowArguments,
  );

  // ==========================================================
  // ENV
  // ==========================================================

  await dotenv.load(
    fileName: '.env',
  );

  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();

  final supabasePublishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY']?.trim();

  if (supabaseUrl ==
          null ||
      supabaseUrl.isEmpty) {
    throw StateError(
      'SUPABASE_URL não foi configurada no arquivo .env.',
    );
  }

  if (supabasePublishableKey ==
          null ||
      supabasePublishableKey.isEmpty) {
    throw StateError(
      'SUPABASE_PUBLISHABLE_KEY não foi configurada no arquivo .env.',
    );
  }

  // ==========================================================
  // SUPABASE
  // ==========================================================
  //
  // Cada Flutter Engine precisa inicializar o Supabase.
  //
  // Isso inclui:
  //
  // - janela principal;
  // - janela do mapa mental.
  //
  // ==========================================================

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  // ==========================================================
  // LOCAL DATABASE
  // ==========================================================
  //
  // O SQLite pode ser usado pelas diferentes janelas.
  //
  // Inicializamos a conexão local nesta engine antes de abrir
  // a interface.
  //
  // IMPORTANTE:
  //
  // initializeOfflineFirst() será iniciado somente na janela
  // principal para evitar múltiplos SyncServices processando
  // a mesma fila simultaneamente em engines diferentes.
  //
  // ==========================================================

  await appDatabase.initialize();

  // ==========================================================
  // WINDOW MANAGER
  // ==========================================================
  //
  // Cada janela do desktop_multi_window possui sua própria
  // Flutter Engine.
  //
  // window_manager precisa ser inicializado também dentro
  // da janela secundária.
  //
  // ==========================================================

  await windowManager.ensureInitialized();

  // ==========================================================
  // WINDOW ROUTER
  // ==========================================================

  switch (windowType) {
    // ========================================================
    // MIND MAP WINDOW
    // ========================================================
    //
    // A janela secundária usa o banco local, mas não inicia
    // outro SyncService.
    //
    // Isso evita:
    //
    // - duas filas sendo processadas ao mesmo tempo;
    // - requisições duplicadas ao Supabase;
    // - concorrência desnecessária entre engines.
    //
    // ========================================================

    case _mindMapWindowType:
      runApp(
        MindMapWindowApp(
          arguments: windowArguments,
        ),
      );

      return;

    // ========================================================
    // MAIN WINDOW
    // ========================================================

    case _mainWindowType:
    default:
      // ======================================================
      // OFFLINE-FIRST
      // ======================================================
      //
      // Inicializa:
      //
      // AppDatabase
      //      ↓
      // Sync handlers
      //      ↓
      // ConnectivityService
      //      ↓
      // SyncService
      //
      // A partir daqui:
      //
      // FinanceRepository salva primeiro localmente.
      //
      // Se estiver offline:
      //
      // SQLite
      //   +
      // SyncQueue
      //
      // guardam a alteração.
      //
      // Quando a conexão voltar:
      //
      // SyncService
      //      ↓
      // Supabase
      //
      // ======================================================

      await initializeOfflineFirst();

      runApp(
        GhostApp(
          evolutionController: evolutionController,
        ),
      );

      return;
  }
}

// ============================================================
// RESOLVE WINDOW TYPE
// ============================================================

String
_resolveWindowType(
  String arguments,
) {
  final value = arguments.trim();

  if (value.isEmpty) {
    return _mainWindowType;
  }

  if (value ==
      _mindMapWindowType) {
    return _mindMapWindowType;
  }

  try {
    final decoded = jsonDecode(
      value,
    );

    if (decoded
        is Map) {
      final map =
          Map<
            String,
            dynamic
          >.from(
            decoded,
          );

      final window = map['window']?.toString().trim();

      if (window ==
          _mindMapWindowType) {
        return _mindMapWindowType;
      }
    }
  } catch (
    _
  ) {
    // Ignora argumento inválido.
  }

  return _mainWindowType;
}
