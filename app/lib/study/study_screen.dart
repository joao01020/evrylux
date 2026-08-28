import 'package:flutter/material.dart';

import '../app/dependencies/app_dependencies.dart';

import '../widgets/generic/activity_timer.dart';
import '../widgets/generic/study_calendar.dart';

import 'widgets/study_header.dart';
import 'widgets/streak_card.dart';
import 'widgets/current_time_card.dart';

import 'brain/screen/brain_screen.dart';

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
  // SAVE STATE
  // ============================================================

  bool _isSaving = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _selectedDate = _today();

    studyController.addListener(
      refresh,
    );

    studyController.loadStudies();
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
  // CÉREBRO
  // ============================================================

  void openBrain() {
    Navigator.push(
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
  }

  // ============================================================
  // SELECT DATE
  // ============================================================

  void _selectDate(
    DateTime date,
  ) {
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

    if (index <
        0) {
      return;
    }

    if (index >=
        studyController.days.length) {
      return;
    }

    studyController.selectDay(
      index,
    );
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
  // SAVE STUDY
  // ============================================================

  Future<
    void
  >
  saveStudy() async {
    if (_isSaving) {
      return;
    }

    setState(
      () {
        _isSaving = true;
      },
    );

    try {
      // --------------------------------------------------------
      // Garante que o dia selecionado no calendário esteja
      // selecionado também no controller atual.
      // --------------------------------------------------------

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
    } finally {
      if (mounted) {
        setState(
          () {
            _isSaving = false;
          },
        );
      }
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
              // =====================================
              // HEADER
              // =====================================
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

              // =====================================
              // CALENDAR
              // =====================================
              StudyCalendar(
                selectedDate: _selectedDate,

                completedDates: _completedDates,

                onDateSelected: _selectDate,
              ),

              const SizedBox(
                height: 24,
              ),

              // =====================================
              // TIMER
              // =====================================
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

                      onSave: _isSaving
                          ? null
                          : saveStudy,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              // =====================================
              // CURRENT TIME
              // =====================================
              CurrentTimeCard(
                minutes: currentMinutes,
              ),

              const SizedBox(
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
