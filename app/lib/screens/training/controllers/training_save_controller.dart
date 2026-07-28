import 'package:flutter/foundation.dart';

import '../helpers/training_date_helper.dart';
import '../models/training_model.dart';
import '../services/training_service.dart';
import '../states/training_state.dart';

class TrainingSaveController
    extends
        ChangeNotifier {
  final TrainingService service;

  final TrainingState state;

  TrainingSaveController({
    required this.service,
    required this.state,
  });

  // =========================================================
  // SALVAR TREINO DA INTERFACE
  // =========================================================

  Future<
    bool
  >
  save() async {
    if (state.isSaving) {
      return false;
    }

    state.clearMessages();

    if (!state.hasSelectedActivities) {
      state.setError(
        'Selecione pelo menos uma atividade antes de salvar.',
      );

      notifyListeners();

      return false;
    }

    state.selectedDay ??= TrainingDateHelper.getDayName(
      DateTime.now(),
    );

    state.isSaving = true;

    notifyListeners();

    try {
      final now = DateTime.now();

      final minutes =
          state.currentSeconds ~/
          60;

      final activitiesToSave =
          List<
            String
          >.from(
            state.selectedActivities,
          );

      for (final activity in activitiesToSave) {
        final training = TrainingModel(
          day: state.selectedDay!,
          training: activity,
          minutes: minutes,
          date: now,
        );

        await service.saveTraining(
          training,
        );
      }

      await _reloadTrainings();

      final totalActivities = activitiesToSave.length;

      state.clearSelectedActivities();
      state.resetTimer();

      if (totalActivities ==
          1) {
        state.setSuccess(
          'Treino registrado com sucesso.',
        );
      } else {
        state.setSuccess(
          '$totalActivities atividades registradas com sucesso.',
        );
      }

      return true;
    } catch (
      error,
      stackTrace
    ) {
      state.setError(
        'Não foi possível salvar o treino.',
      );

      debugPrint(
        'Erro salvando treino: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return false;
    } finally {
      state.isSaving = false;

      notifyListeners();
    }
  }

  // =========================================================
  // SALVAR TREINO DIRETAMENTE
  // =========================================================

  Future<
    bool
  >
  saveTraining(
    TrainingModel model,
  ) async {
    if (state.isSaving) {
      return false;
    }

    state.isSaving = true;
    state.clearMessages();

    notifyListeners();

    try {
      await service.saveTraining(
        model,
      );

      await _reloadTrainings();

      state.setSuccess(
        'Treino registrado com sucesso.',
      );

      return true;
    } catch (
      error,
      stackTrace
    ) {
      state.setError(
        'Não foi possível salvar o treino.',
      );

      debugPrint(
        'Erro salvando treino diretamente: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return false;
    } finally {
      state.isSaving = false;

      notifyListeners();
    }
  }

  // =========================================================
  // SALVAR VÁRIOS TREINOS
  // =========================================================

  Future<
    bool
  >
  saveTrainings(
    Iterable<
      TrainingModel
    >
    models,
  ) async {
    if (state.isSaving) {
      return false;
    }

    final trainingsToSave =
        List<
          TrainingModel
        >.from(
          models,
        );

    if (trainingsToSave.isEmpty) {
      state.setError(
        'Nenhum treino foi informado para salvar.',
      );

      notifyListeners();

      return false;
    }

    state.isSaving = true;
    state.clearMessages();

    notifyListeners();

    try {
      for (final training in trainingsToSave) {
        await service.saveTraining(
          training,
        );
      }

      await _reloadTrainings();

      if (trainingsToSave.length ==
          1) {
        state.setSuccess(
          'Treino registrado com sucesso.',
        );
      } else {
        state.setSuccess(
          '${trainingsToSave.length} treinos registrados com sucesso.',
        );
      }

      return true;
    } catch (
      error,
      stackTrace
    ) {
      state.setError(
        'Não foi possível salvar os treinos.',
      );

      debugPrint(
        'Erro salvando vários treinos: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return false;
    } finally {
      state.isSaving = false;

      notifyListeners();
    }
  }

  // =========================================================
  // RECARREGAR TREINOS APÓS SALVAR
  // =========================================================

  Future<
    void
  >
  _reloadTrainings() async {
    final loadedTrainings = await service.getTrainings();

    state.setTrainings(
      loadedTrainings,
    );
  }
}
