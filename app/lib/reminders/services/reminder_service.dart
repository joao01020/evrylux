import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/reminder_controller.dart';
import '../models/reminder_model.dart';

typedef ReminderDueCallback =
    Future<
      void
    >
    Function(
      ReminderModel reminder,
    );

class ReminderService {
  ReminderService({
    required this.controller,
    this.checkInterval = const Duration(
      seconds: 30,
    ),
  });

  // ============================================================
  // CONTROLLER
  // ============================================================

  final ReminderController controller;

  // ============================================================
  // INTERVALO
  // ============================================================

  final Duration checkInterval;

  // ============================================================
  // TIMER
  // ============================================================

  Timer? _timer;

  // ============================================================
  // ESTADO
  // ============================================================

  bool _running = false;

  bool _checking = false;

  bool _disposed = false;

  // ============================================================
  // CALLBACK
  // ============================================================

  ReminderDueCallback? _onReminderDue;

  // ============================================================
  // DISPATCH GUARD
  // ============================================================

  final Set<
    String
  >
  _dispatchingIds =
      <
        String
      >{};

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isRunning {
    return _running;
  }

  bool get isChecking {
    return _checking;
  }

  bool get isDisposed {
    return _disposed;
  }

  // ============================================================
  // START
  // ============================================================

  Future<
    void
  >
  start({
    required ReminderDueCallback onReminderDue,
  }) async {
    if (_disposed) {
      return;
    }

    _onReminderDue = onReminderDue;

    if (_running) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user ==
        null) {
      debugPrint(
        '[REMINDER SERVICE] '
        'Usuário não autenticado. Serviço não iniciado.',
      );

      return;
    }

    _running = true;

    debugPrint(
      '[REMINDER SERVICE] Iniciado.',
    );

    try {
      // ========================================================
      // CARGA INICIAL
      // ========================================================
      //
      // Fazemos uma carga completa apenas uma vez no start.
      //
      // Depois disso, o timer usa somente refreshDue(), que
      // consulta os lembretes vencidos no SQLite.
      //
      // ========================================================

      await controller.load();

      // ========================================================
      // VERIFICA IMEDIATAMENTE
      // ========================================================

      await checkNow();

      // ========================================================
      // VERIFICA PERIODICAMENTE
      // ========================================================

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
    } catch (
      error,
      stackTrace
    ) {
      _running = false;

      debugPrint(
        '[REMINDER SERVICE] '
        'Erro ao iniciar: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      rethrow;
    }
  }

  // ============================================================
  // CHECK NOW
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Agora NÃO executamos controller.refresh() completo a cada
  // 30 segundos.
  //
  // Em vez disso usamos:
  //
  // controller.refreshDue()
  //
  // Esse método consulta especificamente os lembretes vencidos
  // no SQLite local.
  //
  // Vantagens:
  //
  // - funciona offline;
  // - evita chamadas remotas desnecessárias;
  // - reduz trabalho do controller;
  // - reduz consumo de rede;
  // - evita flicker da UI;
  // - mantém o serviço mais leve.
  //
  // ============================================================

  Future<
    void
  >
  checkNow() async {
    if (_disposed ||
        !_running ||
        _checking) {
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;

    if (user ==
        null) {
      debugPrint(
        '[REMINDER SERVICE] '
        'Sem usuário autenticado. Checagem ignorada.',
      );

      return;
    }

    _checking = true;

    try {
      // ========================================================
      // BUSCA SOMENTE VENCIDOS
      // ========================================================

      final dueReminders = await controller.refreshDue();

      if (dueReminders.isEmpty) {
        return;
      }

      final ordered =
          List<
              ReminderModel
            >.from(
              dueReminders,
            )
            ..sort(
              (
                first,
                second,
              ) => first.remindAt.compareTo(
                second.remindAt,
              ),
            );

      debugPrint(
        '[REMINDER SERVICE] '
        '${ordered.length} lembrete(s) vencido(s).',
      );

      // ========================================================
      // DISPARA UM POR UM
      // ========================================================

      for (final reminder in ordered) {
        if (_disposed ||
            !_running) {
          break;
        }

        if (_dispatchingIds.contains(
          reminder.id,
        )) {
          continue;
        }

        await _dispatchReminder(
          reminder,
        );
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[REMINDER SERVICE] '
        'Erro ao verificar lembretes: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );
    } finally {
      _checking = false;
    }
  }

  // ============================================================
  // DISPATCH
  // ============================================================

  Future<
    void
  >
  _dispatchReminder(
    ReminderModel reminder,
  ) async {
    final callback = _onReminderDue;

    if (callback ==
        null) {
      return;
    }

    final reminderId = reminder.id.trim();

    if (reminderId.isEmpty) {
      debugPrint(
        '[REMINDER SERVICE] '
        'Lembrete sem id. Ignorado.',
      );

      return;
    }

    if (_dispatchingIds.contains(
      reminderId,
    )) {
      return;
    }

    _dispatchingIds.add(
      reminderId,
    );

    try {
      debugPrint(
        '[REMINDER SERVICE] '
        'Disparando: ${reminder.title}',
      );

      // ========================================================
      // MOSTRA NO APP
      // ========================================================

      await callback(
        reminder,
      );

      // ========================================================
      // MARCA COMO ENVIADO NO APP
      // ========================================================
      //
      // O ReminderRepository salva primeiro no SQLite.
      //
      // Mesmo sem internet:
      //
      // sent_in_app = true
      //      ↓
      // SQLite
      //      ↓
      // SyncQueue
      //
      // Isso impede que o mesmo lembrete reapareça a cada ciclo.
      //
      // ========================================================

      final success = await controller.markInAppAsSent(
        reminderId,
      );

      if (!success) {
        debugPrint(
          '[REMINDER SERVICE] '
          'Não foi possível marcar '
          '$reminderId como enviado.',
        );
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[REMINDER SERVICE] '
        'Erro ao disparar lembrete '
        '$reminderId: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );
    } finally {
      _dispatchingIds.remove(
        reminderId,
      );
    }
  }

  // ============================================================
  // RESTART
  // ============================================================

  Future<
    void
  >
  restart() async {
    if (_disposed) {
      return;
    }

    final callback = _onReminderDue;

    if (callback ==
        null) {
      return;
    }

    stop();

    await start(
      onReminderDue: callback,
    );
  }

  // ============================================================
  // STOP
  // ============================================================

  void stop() {
    _timer?.cancel();

    _timer = null;

    _running = false;

    _checking = false;

    _dispatchingIds.clear();

    debugPrint(
      '[REMINDER SERVICE] Parado.',
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    stop();

    _onReminderDue = null;
  }
}
