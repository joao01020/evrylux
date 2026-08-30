import 'package:flutter/material.dart';

import '../../app/dependencies/app_dependencies.dart';

import 'models/day_summary.dart';

import 'utils/date_formatter.dart';

import 'widgets/journey_calendar.dart';

import 'widgets/modal/journey_day_modal.dart';

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
  createState() {
    return _JourneyScreenState();
  }
}

class _JourneyScreenState
    extends
        State<
          JourneyScreen
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFF7FBF1,
  );

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _surfaceSoft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  // ============================================================
  // STATE
  // ============================================================

  DateTime selectedDate = DateTime.now();

  // ============================================================
  // INIT
  // ============================================================

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

  // ============================================================
  // OPEN DAY
  // ============================================================

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

    // ==========================================================
    // TREINOS
    // ==========================================================

    final workouts = trainingController.history.where(
      (
        item,
      ) {
        return item.contains(
          key,
        );
      },
    ).length;

    // ==========================================================
    // ESTUDOS
    // ==========================================================

    final studiesMinutes = studyController.studies
        .where(
          (
            study,
          ) {
            return study.day ==
                key;
          },
        )
        .fold<
          int
        >(
          0,
          (
            total,
            study,
          ) {
            return total +
                study.minutes;
          },
        );

    // ==========================================================
    // FINANCEIRO
    // ==========================================================

    final savedMoney = financeController.model.invested;

    // ==========================================================
    // NOTAS
    // ==========================================================

    final notes = journeyController.getDayHistory(
      key,
    );

    // ==========================================================
    // SUMMARY
    // ==========================================================

    final summary = DaySummary(
      date: key,
      notes: notes,
      workouts: workouts,
      studiesMinutes: studiesMinutes,
      savedMoney: savedMoney,
    );

    // ==========================================================
    // MODAL
    // ==========================================================

    showDialog<
      void
    >(
      context: context,
      builder:
          (
            dialogContext,
          ) {
            return JourneyDayModal(
              summary: summary,
            );
          },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,

        title: const Text(
          'Minha Jornada',
          style: TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),

        iconTheme: const IconThemeData(
          color: _primaryDark,
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          18,
          24,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // INTRO
            // ==================================================
            _buildIntro(),

            const SizedBox(
              height: 24,
            ),

            // ==================================================
            // CALENDAR LABEL
            // ==================================================
            const Text(
              'Calendário',
              style: TextStyle(
                color: _text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            const Text(
              'Selecione um dia para visualizar os detalhes da sua jornada.',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // CALENDAR
            // ==================================================
            JourneyCalendar(
              selectedDate: selectedDate,
              onSelect: openDayDetails,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        22,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: _border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0D000000,
            ),
            blurRadius: 18,
            offset: Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ====================================================
          // ÍCONE
          // ====================================================
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(
                15,
              ),
            ),
            child: const Icon(
              Icons.timeline_rounded,
              color: _primaryDark,
              size: 25,
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          // ====================================================
          // TEXTO
          // ====================================================
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seu histórico',
                  style: TextStyle(
                    color: _text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  'Acompanhe sua evolução diária e veja como seus hábitos se constroem ao longo do tempo.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
