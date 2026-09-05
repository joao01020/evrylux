import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../settings/models/brain_data_mode.dart';
import '../services/brain_initialization_service.dart';

enum BrainExperiencePhase {
  idle,
  initializing,
  waitingForBirth,
  needsDataModeChoice,
  ready,
  failed,
}

/// Coordena a primeira experiência do Brain sem conhecer a UI.
///
/// Não abre dialogs, não navega e não usa timers para sincronizar
/// a animação de nascimento.
class BrainExperienceController extends ChangeNotifier {
  BrainExperienceController({
    required BrainInitializationService initializationService,
  }) : _initializationService = initializationService;

  final BrainInitializationService _initializationService;

  BrainExperiencePhase _phase = BrainExperiencePhase.idle;

  BrainInitializationResult? _initialization;

  Object? _error;

  StackTrace? _stackTrace;

  Completer<void>? _birthCompleter;

  Future<void>? _initializationFuture;

  bool _disposed = false;

  BrainExperiencePhase get phase => _phase;

  BrainInitializationResult? get initialization => _initialization;

  Object? get error => _error;

  StackTrace? get stackTrace => _stackTrace;

  bool get isDisposed => _disposed;

  bool get isInitializing =>
      _phase == BrainExperiencePhase.initializing;

  bool get isWaitingForBirth =>
      _phase == BrainExperiencePhase.waitingForBirth;

  bool get needsDataModeChoice =>
      _phase == BrainExperiencePhase.needsDataModeChoice;

  bool get isReady =>
      _phase == BrainExperiencePhase.ready;

  bool get hasFailed =>
      _phase == BrainExperiencePhase.failed;

  int get knowledgeCount =>
      _initialization?.knowledgeCount ?? 0;

  bool get introSeen =>
      _initialization?.introSeen ?? false;

  BrainDataMode? get storedDataMode =>
      _initialization?.storedDataMode;

  Future<void> initialize() {
    if (_disposed) {
      return Future<void>.value();
    }

    final existing = _initializationFuture;

    if (existing != null) {
      return existing;
    }

    final future = _initializeInternal();

    _initializationFuture = future;

    future.whenComplete(
      () {
        if (identical(
          _initializationFuture,
          future,
        )) {
          _initializationFuture = null;
        }
      },
    );

    return future;
  }

  Future<void> _initializeInternal() async {
    _error = null;
    _stackTrace = null;

    _setPhase(
      BrainExperiencePhase.initializing,
    );

    try {
      final result = await _initializationService.initialize();

      if (_disposed) {
        return;
      }

      _initialization = result;

      if (!result.introSeen) {
        final completer = Completer<void>();

        _birthCompleter = completer;

        _setPhase(
          BrainExperiencePhase.waitingForBirth,
        );

        await completer.future;

        if (_disposed) {
          return;
        }

        await _initializationService.markBirthCompleted();

        if (_disposed) {
          return;
        }

        _initialization = result.copyWith(
          introSeen: true,
        );
      }

      if (_initialization!.storedDataMode == null) {
        _setPhase(
          BrainExperiencePhase.needsDataModeChoice,
        );

        return;
      }

      _setPhase(
        BrainExperiencePhase.ready,
      );
    } catch (error, stackTrace) {
      if (_disposed) {
        return;
      }

      _error = error;
      _stackTrace = stackTrace;

      _setPhase(
        BrainExperiencePhase.failed,
      );

      debugPrint(
        '[BRAIN EXPERIENCE] Falha ao inicializar: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }

  /// Chamado pelo evento real de término de EvolvingBrain.
  Future<void> completeBirth() async {
    if (_disposed ||
        _phase != BrainExperiencePhase.waitingForBirth) {
      return;
    }

    final completer = _birthCompleter;

    if (completer == null ||
        completer.isCompleted) {
      return;
    }

    completer.complete();
  }

  /// Deve ser chamado somente depois que a transição Local / Cloud
  /// tiver sido concluída com sucesso.
  void dataModeChoiceCompleted(
    BrainDataMode selectedMode,
  ) {
    if (_disposed) {
      return;
    }

    final current = _initialization;

    if (current == null) {
      return;
    }

    _initialization = current.copyWith(
      storedDataMode: selectedMode,
    );

    _setPhase(
      BrainExperiencePhase.ready,
    );
  }

  Future<void> retry() async {
    if (_disposed) {
      return;
    }

    final completer = _birthCompleter;

    if (completer != null &&
        !completer.isCompleted) {
      completer.complete();
    }

    _birthCompleter = null;
    _initialization = null;
    _error = null;
    _stackTrace = null;

    _setPhase(
      BrainExperiencePhase.idle,
    );

    await initialize();
  }

  void _setPhase(
    BrainExperiencePhase value,
  ) {
    if (_disposed ||
        _phase == value) {
      return;
    }

    _phase = value;

    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    final completer = _birthCompleter;

    if (completer != null &&
        !completer.isCompleted) {
      completer.complete();
    }

    _birthCompleter = null;

    super.dispose();
  }
}
