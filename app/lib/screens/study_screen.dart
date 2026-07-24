import 'package:flutter/material.dart';

import '../core/storage/storage_service.dart';

import '../widgets/activity_timer.dart';
import '../widgets/week_tracker.dart';

import 'study/history/history_screen.dart';

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
  completedDays = [
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ];

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
        key,
        value,
      ) {
        final minutes = int.parse(
          value.toString(),
        );

        total += minutes;

        history.add(
          "$key - $minutes minutos",
        );
      },
    );

    if (!mounted) return;

    setState(
      () {
        totalStudyMinutes = total;

        completedStudies.clear();

        completedStudies.addAll(
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
              const Text(
                "Sua evolução mental começa aqui.",

                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                "Construa conhecimento um pouco todos os dias.",

                style: TextStyle(
                  fontSize: 18,
                ),
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

              Card(
                child: ListTile(
                  leading: const Text(
                    "⏱️",

                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),

                  title: const Text(
                    "Tempo atual",
                  ),

                  subtitle: Text(
                    "$currentMinutes minutos",
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              Card(
                child: ListTile(
                  leading: const Text(
                    "🔥",

                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),

                  title: const Text(
                    "Sequência",
                  ),

                  subtitle: Text(
                    "$streak dias estudados",
                  ),
                ),
              ),

              const SizedBox(
                height: 30,
              ),

              SizedBox(
                width: double.infinity,

                child: OutlinedButton.icon(
                  onPressed: openHistory,

                  icon: const Icon(
                    Icons.history,
                  ),

                  label: const Text(
                    "Histórico 📚",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
