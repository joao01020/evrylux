import 'package:flutter/material.dart';

import '../../core/storage/storage_service.dart';

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
  final List<
    bool
  >
  completedDays = List.filled(
    7,
    false,
  );

  final List<
    String
  >
  days = [
    "segunda",
    "terça",
    "quarta",
    "quinta",
    "sexta",
    "sábado",
    "domingo",
  ];

  String? selectedDay;

  int streak = 0;

  int currentSeconds = 0;

  int totalStudyMinutes = 0;

  final List<
    String
  >
  completedStudies = [];

  final double timerScale = 0.75;

  @override
  void initState() {
    super.initState();

    loadStudies();
  }

  Future<
    void
  >
  loadStudies() async {
    final data = await StorageService.getStudy();

    int total = 0;

    final List<
      String
    >
    history = [];

    data.forEach(
      (
        day,
        value,
      ) {
        final minutes = int.parse(
          value.toString(),
        );

        total += minutes;

        history.add(
          "$day - $minutes minutos",
        );
      },
    );

    if (!mounted) return;

    setState(
      () {
        totalStudyMinutes = total;

        completedStudies
          ..clear()
          ..addAll(
            history,
          );

        streak = data.length;

        for (
          int i = 0;
          i <
              days.length;
          i++
        ) {
          completedDays[i] = data.containsKey(
            days[i],
          );
        }
      },
    );
  }

  void selectDay(
    int index,
  ) {
    setState(
      () {
        selectedDay = days[index];
      },
    );
  }

  void updateTimer(
    int seconds,
  ) {
    setState(
      () {
        currentSeconds = seconds;
      },
    );
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
        currentSeconds ~/
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
                    streak: streak,
                  ),
                ],
              ),

              const SizedBox(
                height: 25,
              ),

              SizedBox(
                height: 70,
                child: WeekTracker(
                  completedDays: completedDays,
                  selectedDay: selectedDay,
                  days: days,
                  onDayTap: selectDay,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Transform.scale(
                scale: timerScale,
                child: ActivityTimer(
                  title: "Tempo estudado",
                  onTimeChanged: updateTimer,
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
