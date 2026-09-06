import 'package:flutter/material.dart';

import '../app/dependencies/app_dependencies.dart';

import 'body_map/widgets/body_map_dialog.dart';
import 'models/training_model.dart';

import '../widgets/generic/study_calendar.dart';

import 'widgets/dialogs/training_history_edit_dialog.dart';
import 'widgets/history/training_history_dialog.dart';
import 'widgets/history/training_history_records.dart';
import 'widgets/cards/training_consistency_card.dart';
import 'widgets/cards/training_coverage_card.dart';
import 'widgets/sections/training_registration_section.dart';
import 'widgets/cards/training_weekly_goal_card.dart';

class TrainingScreen
    extends
        StatefulWidget {
  const TrainingScreen({
    super.key,
  });

  @override
  State<
    TrainingScreen
  >
  createState() {
    return _TrainingScreenState();
  }
}

class _TrainingScreenState
    extends
        State<
          TrainingScreen
        > {
  // ============================================================
  // DATA SELECIONADA
  // ============================================================

  late DateTime _selectedDate;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _selectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    );

    trainingController.load();
  }

  // ============================================================
  // DATAS CONCLUÍDAS
  // ============================================================

  List<
    DateTime
  >
  _completedDatesFromHistory(
    List<
      String
    >
    history,
  ) {
    final dates =
        <
          DateTime
        >[];

    for (final item in history) {
      final date = _extractDate(
        item,
      );

      if (date ==
          null) {
        continue;
      }

      final alreadyExists = dates.any(
        (
          existing,
        ) {
          return _isSameDate(
            existing,
            date,
          );
        },
      );

      if (!alreadyExists) {
        dates.add(
          date,
        );
      }
    }

    return dates;
  }

  // ============================================================
  // EXTRAIR DATA
  // ============================================================

  DateTime? _extractDate(
    String value,
  ) {
    final expression = RegExp(
      r'(\d{2})/(\d{2})/(\d{4})',
    );

    final match = expression.firstMatch(
      value,
    );

    if (match ==
        null) {
      return null;
    }

    final day = int.tryParse(
      match.group(
            1,
          ) ??
          '',
    );

    final month = int.tryParse(
      match.group(
            2,
          ) ??
          '',
    );

    final year = int.tryParse(
      match.group(
            3,
          ) ??
          '',
    );

    if (day ==
            null ||
        month ==
            null ||
        year ==
            null) {
      return null;
    }

    if (month <
            1 ||
        month >
            12 ||
        day <
            1 ||
        day >
            31) {
      return null;
    }

    final date = DateTime(
      year,
      month,
      day,
    );

    if (date.day !=
            day ||
        date.month !=
            month ||
        date.year !=
            year) {
      return null;
    }

    return date;
  }

  // ============================================================
  // MESMO DIA
  // ============================================================

  bool _isSameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }

  // ============================================================
  // SELECIONAR DATA
  // ============================================================

  void _selectDate(
    DateTime date,
  ) {
    final selected = DateTime(
      date.year,
      date.month,
      date.day,
    );

    setState(
      () {
        _selectedDate = selected;
      },
    );

    trainingController.selectDay(
      selected.weekday -
          1,
    );
  }

  // ============================================================
  // REGISTRAR TREINO
  // ============================================================

  Future<
    void
  >
  _completeActivity() async {
    final saved = await trainingController.save();

    if (!mounted) {
      return;
    }

    if (!saved) {
      _showMessage(
        trainingController.errorMessage ??
            'Não foi possível registrar o treino.',
      );

      return;
    }

    await evolutionController.saveToday();

    if (!mounted) {
      return;
    }

    _showMessage(
      trainingController.successMessage ??
          'Treino registrado com sucesso.',
    );

    trainingController.clearMessages();
  }

  // ============================================================
  // HISTÓRICO
  // ============================================================

  Future<
    void
  >
  _showHistory() async {
    await showDialog<
      void
    >(
      context: context,
      barrierDismissible: true,
      builder:
          (
            modalContext,
          ) {
            return AnimatedBuilder(
              animation: trainingController,
              builder:
                  (
                    context,
                    child,
                  ) {
                    final trainings = trainingController.state.trainings;

                    final entries = trainings
                        .map(
                          _toHistoryEntry,
                        )
                        .toList(
                          growable: false,
                        );

                    return TrainingHistoryDialog(
                      entries: entries,
                      onEdit:
                          (
                            entry,
                          ) async {
                            await _editHistoryEntry(
                              modalContext,
                              entry,
                            );
                          },
                      onDelete:
                          (
                            entry,
                          ) async {
                            await _deleteHistoryEntry(
                              modalContext,
                              entry,
                            );
                          },
                    );
                  },
            );
          },
    );
  }

  // ============================================================
  // TRAINING -> HISTORY ENTRY
  // ============================================================

  TrainingHistoryEntry _toHistoryEntry(
    TrainingModel training,
  ) {
    return TrainingHistoryEntry(
      id: _historyEntryId(
        training,
      ),
      title: training.training,
      activity: training.training,
      date: training.date.toLocal(),
      subtitle: training.day,
      completed: true,
    );
  }

  // ============================================================
  // ID VISUAL DO REGISTRO
  // ============================================================
  //
  // TrainingModel ainda não possui um id persistente próprio.
  //
  // Enquanto isso, usamos os campos que identificam o registro
  // atual para fazer a ponte entre o gráfico/lista e o model.
  //
  // ============================================================

  String _historyEntryId(
    TrainingModel training,
  ) {
    return '${training.day}|'
        '${training.training}|'
        '${training.date.toUtc().toIso8601String()}';
  }

  // ============================================================
  // ENCONTRAR TRAINING ORIGINAL
  // ============================================================

  TrainingModel? _findTrainingByHistoryEntry(
    TrainingHistoryEntry entry,
  ) {
    for (final training in trainingController.state.trainings) {
      if (_historyEntryId(
            training,
          ) ==
          entry.id) {
        return training;
      }
    }

    return null;
  }

  // ============================================================
  // EDITAR PELO NOVO HISTÓRICO
  // ============================================================

  Future<
    void
  >
  _editHistoryEntry(
    BuildContext modalContext,
    TrainingHistoryEntry entry,
  ) async {
    final original = _findTrainingByHistoryEntry(
      entry,
    );

    if (original ==
        null) {
      if (mounted) {
        _showMessage(
          'Não foi possível localizar esse treino.',
        );
      }

      return;
    }

    final updated = await TrainingHistoryEditDialog.show(
      modalContext,
      training: original,
    );

    if (updated ==
        null) {
      return;
    }

    final success = await _editHistoryTraining(
      original,
      updated,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Treino atualizado.'
          : 'Não foi possível atualizar o treino.',
    );
  }

  // ============================================================
  // APAGAR PELO NOVO HISTÓRICO
  // ============================================================

  Future<
    void
  >
  _deleteHistoryEntry(
    BuildContext modalContext,
    TrainingHistoryEntry entry,
  ) async {
    final training = _findTrainingByHistoryEntry(
      entry,
    );

    if (training ==
        null) {
      if (mounted) {
        _showMessage(
          'Não foi possível localizar esse treino.',
        );
      }

      return;
    }

    final confirmed =
        await showDialog<
          bool
        >(
          context: modalContext,
          builder:
              (
                context,
              ) {
                final colorScheme = Theme.of(
                  context,
                ).colorScheme;

                return AlertDialog(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colorScheme.error,
                  ),
                  title: const Text(
                    'Apagar treino?',
                  ),
                  content: Text(
                    '${training.training}\n'
                    '${_formatHistoryDate(training.date)}\n\n'
                    'Essa ação removerá o registro do histórico.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                      ),
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(
                          true,
                        );
                      },
                      child: const Text(
                        'Apagar',
                      ),
                    ),
                  ],
                );
              },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    final success = await _deleteHistoryTraining(
      training,
    );

    if (!mounted) {
      return;
    }

    _showMessage(
      success
          ? 'Treino apagado.'
          : 'Não foi possível apagar o treino.',
    );
  }

  // ============================================================
  // FORMATAR DATA DO HISTÓRICO
  // ============================================================

  String _formatHistoryDate(
    DateTime date,
  ) {
    final local = date.toLocal();

    final day = local.day.toString().padLeft(
      2,
      '0',
    );

    final month = local.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/${local.year}';
  }

  // ============================================================
  // EDITAR REGISTRO DO HISTÓRICO
  // ============================================================

  Future<
    bool
  >
  _editHistoryTraining(
    TrainingModel original,
    TrainingModel updated,
  ) async {
    try {
      await trainingService.updateTraining(
        original: original,
        updated: updated,
      );

      await trainingController.load(
        force: true,
      );

      if (!mounted) {
        return true;
      }

      return true;
    } catch (
      error
    ) {
      debugPrint(
        '[TRAINING HISTORY] '
        'Erro editando treino: '
        '$error',
      );

      return false;
    }
  }

  // ============================================================
  // APAGAR REGISTRO DO HISTÓRICO
  // ============================================================

  Future<
    bool
  >
  _deleteHistoryTraining(
    TrainingModel training,
  ) async {
    try {
      await trainingService.deleteTraining(
        training,
      );

      await trainingController.load(
        force: true,
      );

      if (!mounted) {
        return true;
      }

      return true;
    } catch (
      error
    ) {
      debugPrint(
        '[TRAINING HISTORY] '
        'Erro apagando treino: '
        '$error',
      );

      return false;
    }
  }

  // ============================================================
  // MODAL - PLANO SEMANAL
  // ============================================================

  Future<
    void
  >
  _showWeeklyPlanModal() async {
    await showModalBottomSheet<
      void
    >(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface,
      constraints: const BoxConstraints(
        maxWidth: 660,
      ),
      builder:
          (
            modalContext,
          ) {
            return AnimatedBuilder(
              animation: trainingController,
              builder:
                  (
                    context,
                    child,
                  ) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        24 +
                            MediaQuery.of(
                              context,
                            ).viewInsets.bottom,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ModalHeader(
                              icon: Icons.calendar_month_rounded,
                              title: 'Seu plano semanal',
                              subtitle: 'Defina quantos dias você quer treinar.',
                              onClose: () {
                                Navigator.of(
                                  modalContext,
                                ).pop();
                              },
                            ),

                            const SizedBox(
                              height: 22,
                            ),

                            TrainingWeeklyGoalCard(
                              weeklyGoal: trainingController.weeklyGoal,
                              onGoalChanged: trainingController.setWeeklyGoal,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
            );
          },
    );
  }

  // ============================================================
  // MODAL - REGISTRAR TREINO
  // ============================================================

  Future<
    void
  >
  _showTrainingRegistrationModal() async {
    await showModalBottomSheet<
      void
    >(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface,
      constraints: const BoxConstraints(
        maxWidth: 660,
      ),
      builder:
          (
            modalContext,
          ) {
            return AnimatedBuilder(
              animation: trainingController,
              builder:
                  (
                    context,
                    child,
                  ) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        24 +
                            MediaQuery.of(
                              context,
                            ).viewInsets.bottom,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ModalHeader(
                              icon: Icons.fitness_center_rounded,
                              title: 'Registrar treino',
                              subtitle: 'Marque o que você treinou hoje.',
                              onClose: () {
                                Navigator.of(
                                  modalContext,
                                ).pop();
                              },
                            ),

                            const SizedBox(
                              height: 22,
                            ),

                            TrainingRegistrationSection(
                              controller: trainingController,
                              onComplete: _completeActivity,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
            );
          },
    );
  }

  // ============================================================
  // MODAL - RITMO DO MÊS
  // ============================================================

  Future<
    void
  >
  _showMonthlyRhythmModal() async {
    await showModalBottomSheet<
      void
    >(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface,
      constraints: const BoxConstraints(
        maxWidth: 660,
      ),
      builder:
          (
            modalContext,
          ) {
            return AnimatedBuilder(
              animation: trainingController,
              builder:
                  (
                    context,
                    child,
                  ) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        4,
                        20,
                        24 +
                            MediaQuery.of(
                              context,
                            ).viewInsets.bottom,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ModalHeader(
                              icon: Icons.local_fire_department_rounded,
                              title: 'Seu ritmo neste mês',
                              subtitle: 'Veja sua consistência e evolução no mês atual.',
                              onClose: () {
                                Navigator.of(
                                  modalContext,
                                ).pop();
                              },
                            ),

                            const SizedBox(
                              height: 22,
                            ),

                            TrainingConsistencyCard(
                              consistency: trainingController.consistencyIndex,
                              completedTrainings: trainingController.monthlyCompletedTrainings,
                              expectedTrainings: trainingController.expectedTrainingsUntilToday,
                              weeklyGoal: trainingController.weeklyGoal,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
            );
          },
    );
  }

  // ============================================================
  // MODAL - MAPA CORPORAL
  // ============================================================

  Future<
    void
  >
  _showBodyMapModal() async {
    await BodyMapDialog.show(
      context,
      controller: bodyMapController,
      service: bodyMapService,
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final controller = trainingController;

    return AnimatedBuilder(
      animation: controller,
      builder:
          (
            context,
            child,
          ) {
            final completedDates = _completedDatesFromHistory(
              controller.history,
            );

            return Scaffold(
              // ==================================================
              // APP BAR
              // ==================================================
              appBar: AppBar(),

              // ==================================================
              // BODY
              // ==================================================
              body: controller.isInitialLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : LayoutBuilder(
                      builder:
                          (
                            context,
                            constraints,
                          ) {
                            // ============================================
                            // RESPONSIVIDADE VERTICAL
                            // ============================================
                            //
                            // Em alturas menores reduzimos espaçamentos.
                            //
                            // Se ainda assim o conteúdo não couber, usamos
                            // um SingleChildScrollView como fallback seguro,
                            // MAS com a barra visual desativada.
                            //
                            // Resultado:
                            // - nenhuma faixa amarela/preta;
                            // - nenhuma barra de rolagem visível;
                            // - janela pode ficar menor sem quebrar;
                            // - mouse wheel/touchpad continuam funcionando.
                            //
                            // ============================================

                            final compact =
                                constraints.maxHeight <
                                620;

                            final veryCompact =
                                constraints.maxHeight <
                                560;

                            final ultraCompact =
                                constraints.maxHeight <
                                500;

                            final verticalPadding = ultraCompact
                                ? 4.0
                                : veryCompact
                                ? 6.0
                                : compact
                                ? 10.0
                                : 20.0;

                            final calendarGap = ultraCompact
                                ? 3.0
                                : veryCompact
                                ? 5.0
                                : compact
                                ? 7.0
                                : 12.0;

                            final coverageGap = ultraCompact
                                ? 6.0
                                : veryCompact
                                ? 8.0
                                : compact
                                ? 12.0
                                : 24.0;

                            final bottomGap = ultraCompact
                                ? 0.0
                                : veryCompact
                                ? 2.0
                                : compact
                                ? 6.0
                                : 18.0;

                            return ScrollConfiguration(
                              behavior:
                                  ScrollConfiguration.of(
                                    context,
                                  ).copyWith(
                                    scrollbars: false,
                                  ),
                              child: SingleChildScrollView(
                                physics: const ClampingScrollPhysics(),
                                padding: EdgeInsets.fromLTRB(
                                  20,
                                  verticalPadding,
                                  20,
                                  verticalPadding,
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight:
                                        (constraints.maxHeight -
                                                (verticalPadding *
                                                    2))
                                            .clamp(
                                              0.0,
                                              double.infinity,
                                            ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // ==================================
                                      // CALENDÁRIO
                                      // ==================================
                                      StudyCalendar(
                                        selectedDate: _selectedDate,
                                        completedDates: completedDates,
                                        onDateSelected: _selectDate,
                                      ),

                                      SizedBox(
                                        height: calendarGap,
                                      ),

                                      // ==================================
                                      // ATALHOS
                                      // ==================================
                                      Wrap(
                                        spacing: 10,
                                        runSpacing: ultraCompact
                                            ? 6
                                            : 10,
                                        children: [
                                          _ModalShortcutButton(
                                            tooltip: 'Plano semanal',
                                            icon: Icons.calendar_month_rounded,
                                            onTap: _showWeeklyPlanModal,
                                          ),

                                          _ModalShortcutButton(
                                            tooltip: 'Registrar treino',
                                            icon: Icons.fitness_center_rounded,
                                            onTap: _showTrainingRegistrationModal,
                                          ),

                                          _ModalShortcutButton(
                                            tooltip: 'Seu ritmo neste mês',
                                            icon: Icons.local_fire_department_rounded,
                                            onTap: _showMonthlyRhythmModal,
                                          ),

                                          _ModalShortcutButton(
                                            tooltip: 'Mapa corporal',
                                            icon: Icons.accessibility_new_rounded,
                                            onTap: _showBodyMapModal,
                                          ),

                                          _ModalShortcutButton(
                                            tooltip: 'Histórico',
                                            icon: Icons.history_rounded,
                                            onTap: _showHistory,
                                          ),
                                        ],
                                      ),

                                      SizedBox(
                                        height: coverageGap,
                                      ),

                                      // ==================================
                                      // COBERTURA
                                      // ==================================
                                      TrainingCoverageCard(
                                        coverage: controller.monthlyCoverage,
                                      ),

                                      SizedBox(
                                        height: bottomGap,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                    ),
            );
          },
    );
  }
}

// ============================================================
// BOTÃO DOS ATALHOS
// ============================================================
//
// Botão compacto dos atalhos da tela de treino.
//
// Estado normal:
// - fundo quase branco/esverdeado;
// - borda verde muito suave;
// - ícone verde acinzentado.
//
// Hover:
// - usa exatamente o verde claro da identidade EVRYLUX;
// - ícone escurece;
// - botão cresce levemente;
// - recebe uma sombra suave.
//
// ============================================================

class _ModalShortcutButton
    extends
        StatefulWidget {
  const _ModalShortcutButton({
    required this.tooltip,
    required this.icon,
    required this.onTap,
  });

  final String tooltip;

  final IconData icon;

  final VoidCallback onTap;

  @override
  State<
    _ModalShortcutButton
  >
  createState() {
    return _ModalShortcutButtonState();
  }
}

class _ModalShortcutButtonState
    extends
        State<
          _ModalShortcutButton
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _normalBackground = Color(
    0xFFF7FBF5,
  );

  static const Color _hoverBackground = Color(
    0xFFBCF0B4,
  );

  static const Color _normalBorder = Color(
    0xFFD9E7D5,
  );

  static const Color _hoverBorder = Color(
    0xFFA2D99B,
  );

  static const Color _normalIcon = Color(
    0xFF657366,
  );

  static const Color _hoverIcon = Color(
    0xFF315E35,
  );

  // ============================================================
  // ESTADO
  // ============================================================

  bool _hovered = false;

  bool _pressed = false;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final backgroundColor = _hovered
        ? _hoverBackground
        : _normalBackground;

    final borderColor = _hovered
        ? _hoverBorder
        : _normalBorder;

    final iconColor = _hovered
        ? _hoverIcon
        : _normalIcon;

    return Tooltip(
      message: widget.tooltip,

      waitDuration: const Duration(
        milliseconds: 420,
      ),

      child: MouseRegion(
        cursor: SystemMouseCursors.click,

        onEnter:
            (
              _,
            ) {
              if (_hovered) {
                return;
              }

              setState(
                () {
                  _hovered = true;
                },
              );
            },

        onExit:
            (
              _,
            ) {
              if (!_hovered &&
                  !_pressed) {
                return;
              }

              setState(
                () {
                  _hovered = false;
                  _pressed = false;
                },
              );
            },

        child: GestureDetector(
          behavior: HitTestBehavior.opaque,

          onTap: widget.onTap,

          onTapDown:
              (
                _,
              ) {
                setState(
                  () {
                    _pressed = true;
                  },
                );
              },

          onTapUp:
              (
                _,
              ) {
                setState(
                  () {
                    _pressed = false;
                  },
                );
              },

          onTapCancel: () {
            setState(
              () {
                _pressed = false;
              },
            );
          },

          child: AnimatedScale(
            duration: const Duration(
              milliseconds: 130,
            ),

            curve: Curves.easeOutCubic,

            scale: _pressed
                ? 0.95
                : _hovered
                ? 1.055
                : 1.0,

            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 180,
              ),

              curve: Curves.easeOutCubic,

              width: 44,

              height: 44,

              decoration: BoxDecoration(
                color: backgroundColor,

                borderRadius: BorderRadius.circular(
                  13,
                ),

                border: Border.all(
                  color: borderColor,
                  width: 1,
                ),

                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: _hoverIcon.withValues(
                            alpha: 0.12,
                          ),
                          blurRadius: 15,
                          offset: const Offset(
                            0,
                            5,
                          ),
                        ),
                      ]
                    : const [],
              ),

              child: Center(
                child: AnimatedScale(
                  duration: const Duration(
                    milliseconds: 160,
                  ),

                  curve: Curves.easeOutCubic,

                  scale: _hovered
                      ? 1.06
                      : 1.0,

                  child: Icon(
                    widget.icon,
                    size: 21,
                    color: iconColor,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HEADER DOS MODAIS
// ============================================================

class _ModalHeader
    extends
        StatelessWidget {
  const _ModalHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final VoidCallback onClose;

  @override
  Widget build(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 3,
              ),

              Text(
                subtitle,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          tooltip: 'Fechar',
          onPressed: onClose,
          icon: const Icon(
            Icons.close_rounded,
          ),
        ),
      ],
    );
  }
}
