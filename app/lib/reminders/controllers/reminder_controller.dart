import 'package:flutter/foundation.dart';

import '../data/reminder_repository.dart';

import '../models/reminder_model.dart';

class ReminderController
    extends
        ChangeNotifier {
  ReminderController({
    ReminderRepository? repository,
  }) : repository =
           repository ??
           ReminderRepository();

  // ============================================================
  // REPOSITORY
  // ============================================================

  final ReminderRepository repository;

  // ============================================================
  // STATE
  // ============================================================

  final List<
    ReminderModel
  >
  _reminders = [];

  bool _loading = false;

  String? _errorMessage;

  // ============================================================
  // GETTERS
  // ============================================================

  List<
    ReminderModel
  >
  get reminders {
    return List.unmodifiable(
      _reminders,
    );
  }

  bool get loading {
    return _loading;
  }

  String? get errorMessage {
    return _errorMessage;
  }

  bool get hasError {
    return _errorMessage !=
        null;
  }

  bool get hasReminders {
    return _reminders.isNotEmpty;
  }

  // ============================================================
  // PENDING
  // ============================================================

  List<
    ReminderModel
  >
  get pending {
    final values = _reminders.where(
      (
        reminder,
      ) {
        return !reminder.completed;
      },
    ).toList();

    values.sort(
      (
        first,
        second,
      ) {
        return first.remindAt.compareTo(
          second.remindAt,
        );
      },
    );

    return values;
  }

  // ============================================================
  // COMPLETED
  // ============================================================

  List<
    ReminderModel
  >
  get completed {
    final values = _reminders.where(
      (
        reminder,
      ) {
        return reminder.completed;
      },
    ).toList();

    values.sort(
      (
        first,
        second,
      ) {
        return second.remindAt.compareTo(
          first.remindAt,
        );
      },
    );

    return values;
  }

  // ============================================================
  // DUE
  // ============================================================

  List<
    ReminderModel
  >
  get due {
    final now = DateTime.now();

    final values = _reminders.where(
      (
        reminder,
      ) {
        return !reminder.completed &&
            reminder.notifyInApp &&
            !reminder.sentInApp &&
            !reminder.remindAt.toLocal().isAfter(
              now,
            );
      },
    ).toList();

    values.sort(
      (
        first,
        second,
      ) {
        return first.remindAt.compareTo(
          second.remindAt,
        );
      },
    );

    return values;
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<
    void
  >
  load() async {
    if (_loading) {
      return;
    }

    _setLoading(
      true,
    );

    _errorMessage = null;

    try {
      final result = await repository.getAll();

      _reminders
        ..clear()
        ..addAll(
          result,
        );
    } catch (
      error
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] Erro ao carregar: $error',
      );
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<
    void
  >
  refresh() async {
    try {
      final result = await repository.getAll();

      _reminders
        ..clear()
        ..addAll(
          result,
        );

      _errorMessage = null;

      notifyListeners();
    } catch (
      error
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] Erro ao atualizar: $error',
      );

      notifyListeners();
    }
  }

  // ============================================================
  // CREATE
  // ============================================================

  Future<
    ReminderModel?
  >
  create({
    required String title,
    required String message,
    required DateTime remindAt,
    String? sourceType,
    String? sourceId,
    bool notifyInApp = true,
    bool notifyTelegram = false,
  }) async {
    final normalizedTitle = title.trim();

    final normalizedMessage = message.trim();

    if (normalizedTitle.isEmpty) {
      _errorMessage = 'Informe um título para o lembrete.';

      notifyListeners();

      return null;
    }

    if (normalizedMessage.isEmpty) {
      _errorMessage = 'Informe uma mensagem para o lembrete.';

      notifyListeners();

      return null;
    }

    _setLoading(
      true,
    );

    _errorMessage = null;

    try {
      final reminder = await repository.create(
        title: normalizedTitle,
        message: normalizedMessage,
        remindAt: remindAt,
        sourceType: sourceType,
        sourceId: sourceId,
        notifyInApp: notifyInApp,
        notifyTelegram: notifyTelegram,
      );

      _reminders.add(
        reminder,
      );

      _sort();

      return reminder;
    } catch (
      error
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] Erro ao criar: $error',
      );

      return null;
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<
    bool
  >
  update(
    ReminderModel reminder,
  ) async {
    _setLoading(
      true,
    );

    _errorMessage = null;

    try {
      final updated = await repository.update(
        reminder,
      );

      final index = _reminders.indexWhere(
        (
          item,
        ) {
          return item.id ==
              updated.id;
        },
      );

      if (index >=
          0) {
        _reminders[index] = updated;
      } else {
        _reminders.add(
          updated,
        );
      }

      _sort();

      return true;
    } catch (
      error
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] Erro ao atualizar: $error',
      );

      return false;
    } finally {
      _setLoading(
        false,
      );
    }
  }

  // ============================================================
  // MARK IN APP AS SENT
  // ============================================================

  Future<
    bool
  >
  markInAppAsSent(
    String id,
  ) async {
    try {
      await repository.markInAppAsSent(
        id,
      );

      final index = _indexOf(
        id,
      );

      if (index >=
          0) {
        _reminders[index] = _reminders[index].copyWith(
          sentInApp: true,
        );

        notifyListeners();
      }

      return true;
    } catch (
      error
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] Erro ao marcar envio interno: $error',
      );

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // MARK TELEGRAM AS SENT
  // ============================================================

  Future<
    bool
  >
  markTelegramAsSent(
    String id,
  ) async {
    try {
      await repository.markTelegramAsSent(
        id,
      );

      final index = _indexOf(
        id,
      );

      if (index >=
          0) {
        _reminders[index] = _reminders[index].copyWith(
          sentTelegram: true,
        );

        notifyListeners();
      }

      return true;
    } catch (
      error
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] Erro ao marcar Telegram: $error',
      );

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // COMPLETE
  // ============================================================

  Future<
    bool
  >
  complete(
    String id,
  ) async {
    try {
      await repository.complete(
        id,
      );

      final index = _indexOf(
        id,
      );

      if (index >=
          0) {
        _reminders[index] = _reminders[index].copyWith(
          completed: true,
        );

        notifyListeners();
      }

      return true;
    } catch (
      error
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] Erro ao concluir: $error',
      );

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // REOPEN
  // ============================================================

  Future<
    bool
  >
  reopen(
    String id,
  ) async {
    try {
      await repository.reopen(
        id,
      );

      final index = _indexOf(
        id,
      );

      if (index >=
          0) {
        _reminders[index] = _reminders[index].copyWith(
          completed: false,
          sentInApp: false,
          sentTelegram: false,
        );

        notifyListeners();
      }

      return true;
    } catch (
      error
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] Erro ao reabrir: $error',
      );

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    bool
  >
  delete(
    String id,
  ) async {
    try {
      await repository.delete(
        id,
      );

      _reminders.removeWhere(
        (
          reminder,
        ) {
          return reminder.id ==
              id;
        },
      );

      notifyListeners();

      return true;
    } catch (
      error
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] Erro ao excluir: $error',
      );

      notifyListeners();

      return false;
    }
  }

  // ============================================================
  // FIND BY ID
  // ============================================================

  ReminderModel? findById(
    String id,
  ) {
    for (final reminder in _reminders) {
      if (reminder.id ==
          id) {
        return reminder;
      }
    }

    return null;
  }

  // ============================================================
  // FIND BY SOURCE
  // ============================================================

  List<
    ReminderModel
  >
  findBySource({
    required String sourceType,
    required String sourceId,
  }) {
    return _reminders.where(
      (
        reminder,
      ) {
        return reminder.sourceType ==
                sourceType &&
            reminder.sourceId ==
                sourceId;
      },
    ).toList();
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (_errorMessage ==
        null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }

  // ============================================================
  // INDEX
  // ============================================================

  int _indexOf(
    String id,
  ) {
    return _reminders.indexWhere(
      (
        reminder,
      ) {
        return reminder.id ==
            id;
      },
    );
  }

  // ============================================================
  // SORT
  // ============================================================

  void _sort() {
    _reminders.sort(
      (
        first,
        second,
      ) {
        return first.remindAt.compareTo(
          second.remindAt,
        );
      },
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(
    bool value,
  ) {
    if (_loading ==
        value) {
      return;
    }

    _loading = value;

    notifyListeners();
  }
}
