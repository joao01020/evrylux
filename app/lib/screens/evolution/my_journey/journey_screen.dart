import 'package:flutter/material.dart';

import '../../../app_dependencies.dart';

import 'models/day_summary.dart';

import '../../../widgets/journey/journey_calendar.dart';

import '../../../widgets/journey/modal/journey_day_modal.dart';

import '../../../widgets/journey/utils/date_formatter.dart';

class JourneyScreen
    extends
        StatefulWidget {
  const JourneyScreen({
    super.key,
  });

  @override
  State<
    JourneyScreen
  >
  createState() => _JourneyScreenState();
}

class _JourneyScreenState
    extends
        State<
          JourneyScreen
        > {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    journeyController.addListener(
      refresh,
    );

    trainingController.addListener(
      refresh,
    );

    studyController.addListener(
      refresh,
    );

    journeyController.load();

    trainingController.load();

    studyController.loadStudies();

    financeController.loadData();
  }

  void refresh() {
    if (mounted) {
      setState(
        () {},
      );
    }
  }

  @override
  void dispose() {
    journeyController.removeListener(
      refresh,
    );

    trainingController.removeListener(
      refresh,
    );

    studyController.removeListener(
      refresh,
    );

    super.dispose();
  }

  void openDayDetails(
    DateTime date,
  ) {
    setState(
      () {
        selectedDate = date;
      },
    );

    final key = DateFormatter.key(
      date,
    );

    // ==============================
    // TREINOS
    // ==============================

    final workouts = trainingController.history.where(
      (
        item,
      ) {
        return item.contains(
          key,
        );
      },
    ).length;

    // ==============================
    // ESTUDOS
    // ==============================

    final studiesMinutes = studyController.studies
        .where(
          (
            study,
          ) {
            return study.day ==
                key;
          },
        )
        .fold(
          0,
          (
            total,
            study,
          ) {
            return total +
                study.minutes;
          },
        );

    // ==============================
    // FINANCEIRO
    // ==============================

    final savedMoney = financeController.model.invested;

    // ==============================
    // NOTAS
    // ==============================

    final notes = journeyController.getDayHistory(
      key,
    );

    final summary = DaySummary(
      date: key,

      notes: notes,

      workouts: workouts,

      studiesMinutes: studiesMinutes,

      savedMoney: savedMoney,
    );

    showDialog(
      context: context,

      builder:
          (
            _,
          ) {
            return JourneyDayModal(
              summary: summary,
            );
          },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Minha Jornada 📅",
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          24,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Seu histórico",

              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              "Seu caminho de evolução diário.",

              style: TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            JourneyCalendar(
              selectedDate: selectedDate,

              onSelect: openDayDetails,
            ),
          ],
        ),
      ),
    );
  }
}
