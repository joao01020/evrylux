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
  _reminders =
      <
        ReminderModel
      >[];

  bool _loading = false;

  String? _errorMessage;

  bool _disposed = false;

  // ============================================================
  // GETTERS
  // ============================================================

  List<
    ReminderModel
  >
  get reminders {
    return List<
      ReminderModel
    >.unmodifiable(
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
    final values = _reminders
        .where(
          (
            reminder,
          ) => !reminder.completed,
        )
        .toList(
          growable: false,
        );

    values.sort(
      (
        first,
        second,
      ) => first.remindAt.compareTo(
        second.remindAt,
      ),
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
    final values = _reminders
        .where(
          (
            reminder,
          ) => reminder.completed,
        )
        .toList(
          growable: false,
        );

    values.sort(
      (
        first,
        second,
      ) => second.remindAt.compareTo(
        first.remindAt,
      ),
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

    final values = _reminders
        .where(
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
        )
        .toList(
          growable: false,
        );

    values.sort(
      (
        first,
        second,
      ) => first.remindAt.compareTo(
        second.remindAt,
      ),
    );

    return values;
  }

  // ============================================================
  // LOAD
  // ============================================================
  //
  // O repository é offline-first.
  //
  // Portanto:
  //
  // online  -> pode atualizar o SQLite pelo Supabase;
  // offline -> retorna o cache local.
  //
  // ============================================================

  Future<
    void
  >
  load() async {
    if (_disposed ||
        _loading) {
      return;
    }

    _setLoading(
      true,
    );

    _errorMessage = null;

    try {
      final result = await repository.getAll();

      _replaceAll(
        result,
      );
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] '
        'Erro ao carregar: $error',
      );

      debugPrint(
        stackTrace.toString(),
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
  //
  // Não ativa loading global para não causar flicker a cada
  // verificação periódica do ReminderService.
  //
  // ============================================================

  Future<
    void
  >
  refresh() async {
    if (_disposed) {
      return;
    }

    try {
      final result = await repository.getAll();

      _replaceAll(
        result,
        notify: false,
      );

      _errorMessage = null;

      _safeNotifyListeners();
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] '
        'Erro ao atualizar: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      _safeNotifyListeners();
    }
  }

  // ============================================================
  // REFRESH DUE ONLY
  // ============================================================
  //
  // Método pensado para o ReminderService.
  //
  // Busca especificamente lembretes vencidos pelo repository,
  // que já usa SQLite offline.
  //
  // Isso evita depender de uma carga remota completa apenas
  // para saber o que precisa ser exibido agora.
  //
  // ============================================================

  Future<
    List<
      ReminderModel
    >
  >
  refreshDue() async {
    if (_disposed) {
      return const <
        ReminderModel
      >[];
    }

    try {
      final result = await repository.getDue();

      _merge(
        result,
      );

      _errorMessage = null;

      _safeNotifyListeners();

      return List<
        ReminderModel
      >.unmodifiable(
        result,
      );
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] '
        'Erro ao carregar vencidos: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      _safeNotifyListeners();

      return const <
        ReminderModel
      >[];
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

      _safeNotifyListeners();

      return null;
    }

    if (normalizedMessage.isEmpty) {
      _errorMessage = 'Informe uma mensagem para o lembrete.';

      _safeNotifyListeners();

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

      _upsertLocal(
        reminder,
        notify: false,
      );

      _sort();

      return reminder;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] '
        'Erro ao criar: $error',
      );

      debugPrint(
        stackTrace.toString(),
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
    if (_disposed) {
      return false;
    }

    _setLoading(
      true,
    );

    _errorMessage = null;

    try {
      final updated = await repository.update(
        reminder,
      );

      _upsertLocal(
        updated,
        notify: false,
      );

      _sort();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] '
        'Erro ao atualizar: $error',
      );

      debugPrint(
        stackTrace.toString(),
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
    if (_disposed) {
      return false;
    }

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

        _safeNotifyListeners();
      }

      _errorMessage = null;

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] '
        'Erro ao marcar envio interno: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      _safeNotifyListeners();

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
    if (_disposed) {
      return false;
    }

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

        _safeNotifyListeners();
      }

      _errorMessage = null;

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] '
        'Erro ao marcar Telegram: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      _safeNotifyListeners();

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
    if (_disposed) {
      return false;
    }

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

        _safeNotifyListeners();
      }

      _errorMessage = null;

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] '
        'Erro ao concluir: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      _safeNotifyListeners();

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
    if (_disposed) {
      return false;
    }

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

        _safeNotifyListeners();
      }

      _errorMessage = null;

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] '
        'Erro ao reabrir: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      _safeNotifyListeners();

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
    if (_disposed) {
      return false;
    }

    try {
      await repository.delete(
        id,
      );

      _reminders.removeWhere(
        (
          reminder,
        ) =>
            reminder.id ==
            id,
      );

      _errorMessage = null;

      _safeNotifyListeners();

      return true;
    } catch (
      error,
      stackTrace
    ) {
      _errorMessage = error.toString();

      debugPrint(
        '[REMINDER CONTROLLER] '
        'Erro ao excluir: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      _safeNotifyListeners();

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
    return _reminders
        .where(
          (
            reminder,
          ) {
            return reminder.sourceType ==
                    sourceType &&
                reminder.sourceId ==
                    sourceId;
          },
        )
        .toList(
          growable: false,
        );
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

    _safeNotifyListeners();
  }

  // ============================================================
  // REPLACE ALL
  // ============================================================

  void _replaceAll(
    List<
      ReminderModel
    >
    values, {
    bool notify = true,
  }) {
    _reminders
      ..clear()
      ..addAll(
        values,
      );

    _sort();

    if (notify) {
      _safeNotifyListeners();
    }
  }

  // ============================================================
  // MERGE
  // ============================================================

  void _merge(
    List<
      ReminderModel
    >
    values,
  ) {
    for (final value in values) {
      _upsertLocal(
        value,
        notify: false,
      );
    }

    _sort();
  }

  // ============================================================
  // UPSERT LOCAL STATE
  // ============================================================

  void _upsertLocal(
    ReminderModel reminder, {
    bool notify = true,
  }) {
    final index = _indexOf(
      reminder.id,
    );

    if (index >=
        0) {
      _reminders[index] = reminder;
    } else {
      _reminders.add(
        reminder,
      );
    }

    if (notify) {
      _sort();

      _safeNotifyListeners();
    }
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
      ) =>
          reminder.id ==
          id,
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
      ) => first.remindAt.compareTo(
        second.remindAt,
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  void _setLoading(
    bool value,
  ) {
    if (_disposed ||
        _loading ==
            value) {
      return;
    }

    _loading = value;

    _safeNotifyListeners();
  }

  // ============================================================
  // NOTIFY
  // ============================================================

  void _safeNotifyListeners() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    super.dispose();
  }
}
