import 'package:flutter/material.dart';

import '../app/dependencies/app_dependencies.dart';

import '../widgets/generic/activity_timer.dart';
import '../widgets/generic/study_calendar.dart';

import 'widgets/study_header.dart';
import 'widgets/streak_card.dart';
import 'widgets/current_time_card.dart';
import 'widgets/history_button.dart';

import 'brain/screen/brain_screen.dart';
import 'brain/services/brain_storage.dart';
import 'history/history_screen.dart';

import 'services/study_day_service.dart';
import 'widgets/dialogs/study_day_dialog.dart';

class StudyScreen
    extends
        StatefulWidget {
  const StudyScreen({
    super.key,
  });

  @override
  State<
    StudyScreen
  >
  createState() {
    return _StudyScreenState();
  }
}

class _StudyScreenState
    extends
        State<
          StudyScreen
        > {
  // ============================================================
  // CALENDAR
  // ============================================================

  late DateTime _selectedDate;

  // ============================================================
  // DAY MODAL
  // ============================================================

  late final StudyDayService _studyDayService;

  bool _openingDay = false;

  // ============================================================
  // DATAS COM CONTEÚDO
  // ============================================================

  List<
    DateTime
  >
  _contentDates =
      const <
        DateTime
      >[];

  bool _loadingContentDates = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _selectedDate = _today();

    _studyDayService = StudyDayService(
      repository: studyRepository,
      brainStorage: const BrainStorage(),
    );

    studyController.addListener(
      refresh,
    );

    studyController.loadStudies();

    _loadContentDates();
  }

  // ============================================================
  // REFRESH
  // ============================================================

  void refresh() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    studyController.removeListener(
      refresh,
    );

    super.dispose();
  }

  // ============================================================
  // HISTÓRICO
  // ============================================================

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) {
              return const HistoryScreen();
            },
      ),
    );
  }

  // ============================================================
  // CÉREBRO
  // ============================================================

  Future<
    void
  >
  openBrain() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) {
              return const BrainScreen();
            },
      ),
    );

    if (!mounted) {
      return;
    }

    // ========================================================
    // RECARREGAR DATAS COM CONTEÚDO
    // ========================================================
    //
    // Se o usuário criou, editou ou removeu uma anotação no
    // Cérebro, atualizamos os indicadores do calendário assim
    // que ele volta para Conhecimento.
    //
    // ========================================================

    await _loadContentDates();
  }

  // ============================================================
  // LOAD CONTENT DATES
  // ============================================================
  //
  // Carrega as datas que possuem anotações criadas no Cérebro.
  //
  // Essas datas são enviadas para StudyCalendar.contentDates.
  //
  // ============================================================

  Future<
    void
  >
  _loadContentDates() async {
    if (_loadingContentDates) {
      return;
    }

    _loadingContentDates = true;

    try {
      final dates = await _studyDayService.loadContentDates();

      if (!mounted) {
        return;
      }

      setState(
        () {
          _contentDates = dates;
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[STUDY] Erro ao carregar datas com conteúdo: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    } finally {
      _loadingContentDates = false;
    }
  }

  // ============================================================
  // SELECT DATE
  // ============================================================
  //
  // O StudyCalendar continua genérico.
  //
  // Ele apenas informa a data por onDateSelected.
  //
  // Aqui fazemos a regra específica de Conhecimento:
  //
  // 1. seleciona a data;
  // 2. mantém o StudyController compatível;
  // 3. abre o modal daquele dia.
  //
  // ============================================================

  Future<
    void
  >
  _selectDate(
    DateTime date,
  ) async {
    final normalizedDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    setState(
      () {
        _selectedDate = normalizedDate;
      },
    );

    final index =
        normalizedDate.weekday -
        DateTime.monday;

    if (index >=
            0 &&
        index <
            studyController.days.length) {
      studyController.selectDay(
        index,
      );
    }

    await _openStudyDayModal(
      normalizedDate,
    );
  }

  // ============================================================
  // OPEN DAY MODAL
  // ============================================================

  Future<
    void
  >
  _openStudyDayModal(
    DateTime date,
  ) async {
    if (_openingDay) {
      return;
    }

    _openingDay = true;

    try {
      final summary = await _studyDayService.loadDay(
        date,
      );

      if (!mounted) {
        return;
      }

      await StudyDayDialog.show(
        context,
        summary: summary,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[STUDY DAY] '
        'Erro carregando conteúdo: '
        '$error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível carregar os dados deste dia: $error',
          ),
        ),
      );
    } finally {
      _openingDay = false;
    }
  }

  // ============================================================
  // COMPLETED DATES
  // ============================================================

  List<
    DateTime
  >
  get _completedDates {
    final monday = _startOfCurrentWeek();

    final completedDates =
        <
          DateTime
        >[];

    for (
      var index = 0;
      index <
          studyController.completedDays.length;
      index++
    ) {
      if (!studyController.completedDays[index]) {
        continue;
      }

      completedDates.add(
        monday.add(
          Duration(
            days: index,
          ),
        ),
      );
    }

    return completedDates;
  }

  // ============================================================
  // START OF CURRENT WEEK
  // ============================================================

  DateTime _startOfCurrentWeek() {
    final now = _today();

    return now.subtract(
      Duration(
        days:
            now.weekday -
            DateTime.monday,
      ),
    );
  }

  // ============================================================
  // TODAY
  // ============================================================

  DateTime _today() {
    final now = DateTime.now();

    return DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  // ============================================================
  // SALVAR ESTUDO
  // ============================================================

  Future<
    void
  >
  saveStudy() async {
    try {
      final dayIndex =
          _selectedDate.weekday -
          DateTime.monday;

      if (dayIndex >=
              0 &&
          dayIndex <
              studyController.days.length) {
        studyController.selectDay(
          dayIndex,
        );
      }

      await studyController.saveStudy();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Estudo salvo em '
            '${_selectedDate.day.toString().padLeft(2, '0')}/'
            '${_selectedDate.month.toString().padLeft(2, '0')}/'
            '${_selectedDate.year} 📚✅',
          ),
        ),
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível salvar o estudo: $error',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentMinutes =
        studyController.currentSeconds ~/
        60;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Conhecimento 📚',
        ),
        actions: [
          IconButton(
            tooltip: 'Cérebro',
            icon: const Icon(
              Icons.psychology_outlined,
            ),
            onPressed: openBrain,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(
          24,
        ),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // =================================================
              // HEADER
              // =================================================
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: StudyHeader(),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

                  StreakCard(
                    streak: studyController.streak,
                  ),
                ],
              ),

              const SizedBox(
                height: 25,
              ),

              // =================================================
              // CALENDAR
              // =================================================
              StudyCalendar(
                selectedDate: _selectedDate,
                completedDates: _completedDates,
                contentDates: _contentDates,
                onDateSelected: _selectDate,
              ),

              const SizedBox(
                height: 24,
              ),

              // =================================================
              // TIMER
              // =================================================
              SizedBox(
                width: double.infinity,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 560,
                    ),
                    child: ActivityTimer(
                      title: 'Tempo estudado',
                      onTimeChanged: studyController.updateTimer,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // =================================================
              // CURRENT TIME
              // =================================================
              CurrentTimeCard(
                minutes: currentMinutes,
              ),

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // SAVE
              // =================================================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saveStudy,
                  icon: const Icon(
                    Icons.save,
                  ),
                  label: const Text(
                    'Salvar estudo',
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              // =================================================
              // BRAIN
              // =================================================
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: openBrain,
                  icon: const Icon(
                    Icons.psychology_outlined,
                  ),
                  label: const Text(
                    'Cérebro',
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              // =================================================
              // HISTORY
              // =================================================
              HistoryButton(
                onPressed: openHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
