import 'package:flutter/material.dart';

import '../../controllers/study/study_controller.dart';

import '../../widgets/generic/activity_timer.dart';
import '../../widgets/generic/week_tracker.dart';

import '../../widgets/study/study_header.dart';
import '../../widgets/study/streak_card.dart';
import '../../widgets/study/current_time_card.dart';
import '../../widgets/study/history_button.dart';

import 'history/history_screen.dart';

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
  createState() => _StudyScreenState();
}

class _StudyScreenState
    extends
        State<
          StudyScreen
        > {
  late StudyController controller;

  final double timerScale = 0.75;

  @override
  void initState() {
    super.initState();

    controller = StudyController();

    controller.addListener(
      refresh,
    );

    controller.loadStudies();
  }

  void refresh() {
    if (!mounted) return;

    setState(
      () {},
    );
  }

  @override
  void dispose() {
    controller.removeListener(
      refresh,
    );

    controller.dispose();

    super.dispose();
  }

  void openHistory() {
    Navigator.push(
      context,

      MaterialPageRoute(
        builder:
            (
              _,
            ) => const HistoryScreen(),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentMinutes =
        controller.currentSeconds ~/
        60;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Conhecimento 📚",
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(
          24,
        ),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
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
                    streak: controller.streak,
                  ),
                ],
              ),

              const SizedBox(
                height: 25,
              ),

              SizedBox(
                height: 70,

                child: WeekTracker(
                  completedDays: controller.completedDays,

                  selectedDay: controller.selectedDay,

                  days: controller.days,

                  onDayTap: controller.selectDay,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Transform.scale(
                scale: timerScale,

                child: ActivityTimer(
                  title: "Tempo estudado",

                  onTimeChanged: controller.updateTimer,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              CurrentTimeCard(
                minutes: currentMinutes,
              ),

              const SizedBox(
                height: 30,
              ),

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
