import 'dart:async';

import 'package:flutter/foundation.dart';

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

  // ============================================================
  // CALLBACK
  // ============================================================

  ReminderDueCallback? _onReminderDue;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isRunning {
    return _running;
  }

  bool get isChecking {
    return _checking;
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
    _onReminderDue = onReminderDue;

    if (_running) {
      return;
    }

    _running = true;

    debugPrint(
      '[REMINDER SERVICE] Iniciado.',
    );

    // ==========================================================
    // CARREGA OS LEMBRETES
    // ==========================================================

    await controller.load();

    // ==========================================================
    // VERIFICA IMEDIATAMENTE
    // ==========================================================

    await checkNow();

    // ==========================================================
    // VERIFICA PERIODICAMENTE
    // ==========================================================

    _timer = Timer.periodic(
      checkInterval,
      (
        _,
      ) {
        checkNow();
      },
    );
  }

  // ============================================================
  // CHECK NOW
  // ============================================================

  Future<
    void
  >
  checkNow() async {
    if (!_running) {
      return;
    }

    if (_checking) {
      return;
    }

    _checking = true;

    try {
      // ========================================================
      // BUSCA NOVAMENTE NO SUPABASE
      // ========================================================

      await controller.refresh();

      // ========================================================
      // LEMBRETES VENCIDOS
      // ========================================================

      final dueReminders =
          List<
            ReminderModel
          >.from(
            controller.due,
          );

      if (dueReminders.isEmpty) {
        return;
      }

      debugPrint(
        '[REMINDER SERVICE] '
        '${dueReminders.length} lembrete(s) vencido(s).',
      );

      // ========================================================
      // DISPARA UM POR UM
      // ========================================================

      for (final reminder in dueReminders) {
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

      final success = await controller.markInAppAsSent(
        reminder.id,
      );

      if (!success) {
        debugPrint(
          '[REMINDER SERVICE] '
          'Não foi possível marcar '
          '${reminder.id} como enviado.',
        );
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[REMINDER SERVICE] '
        'Erro ao disparar lembrete '
        '${reminder.id}: $error',
      );

      debugPrint(
        stackTrace.toString(),
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

    debugPrint(
      '[REMINDER SERVICE] Parado.',
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    stop();

    _onReminderDue = null;
  }
}
