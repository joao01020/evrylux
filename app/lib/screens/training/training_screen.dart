import 'package:flutter/material.dart';

import '../../core/storage/storage_service.dart';

import '../../widgets/generic/activity_timer.dart';
import '../../widgets/generic/week_tracker.dart';

import '../../widgets/training/training_header.dart';
import '../../widgets/training/activity_card.dart';
import '../../widgets/training/history_dialog.dart';

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
  createState() => _TrainingScreenState();
}

class _TrainingScreenState
    extends
        State<
          TrainingScreen
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

  final List<
    String
  >
  activityOptions = [
    "🏋️ Peito",
    "🦵 Pernas",
    "💪 Braço",
    "🔥 Corrida",
    "🚶 Caminhada",
  ];

  String? selectedActivity;

  String? selectedDay;

  int streak = 0;

  int currentSeconds = 0;

  final List<
    String
  >
  completedActivities = [];

  @override
  void initState() {
    super.initState();

    loadActivities();
  }

  Future<
    void
  >
  loadActivities() async {
    final data = await StorageService.getTraining();

    final history =
        <
          String
        >[];

    int newStreak = 0;

    data.forEach(
      (
        day,
        value,
      ) {
        if (value
            is List) {
          for (final item in value) {
            history.add(
              "$day - ${item["training"]} - ${item["minutes"]} min",
            );
          }

          newStreak++;
        } else if (value
            is Map) {
          history.add(
            "$day - ${value["training"]} - ${value["minutes"]} min",
          );

          newStreak++;
        }
      },
    );

    if (!mounted) return;

    setState(
      () {
        completedActivities
          ..clear()
          ..addAll(
            history,
          );

        streak = newStreak;

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

  Future<
    void
  >
  completeActivity() async {
    if (selectedActivity ==
            null ||
        selectedDay ==
            null) {
      return;
    }

    final minutes =
        currentSeconds ~/
        60;

    await StorageService.saveTraining(
      selectedDay!,
      selectedActivity!,
      minutes,
    );

    await loadActivities();

    if (!mounted) return;

    setState(
      () {
        selectedActivity = null;
      },
    );
  }

  void openHistory() {
    showDialog(
      context: context,
      builder:
          (
            _,
          ) {
            return HistoryDialog(
              activities: completedActivities,
            );
          },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final minutes =
        currentSeconds ~/
        60;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Saúde 💪",
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          20,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            TrainingHeader(
              streak: streak,
            ),

            const SizedBox(
              height: 24,
            ),

            WeekTracker(
              completedDays: completedDays,
              days: days,
              selectedDay: selectedDay,
              onDayTap: selectDay,
            ),

            const SizedBox(
              height: 20,
            ),

            ActivityTimer(
              title: "Tempo de atividade",
              onTimeChanged: updateTimer,
            ),

            const SizedBox(
              height: 15,
            ),

            Card(
              child: ListTile(
                dense: true,

                leading: const Text(
                  "⏱️",
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),

                title: const Text(
                  "Tempo atual",
                ),

                subtitle: Text(
                  "$minutes minutos registrados",
                ),
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            const Text(
              "Hoje:",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: activityOptions.map(
                (
                  activity,
                ) {
                  return SizedBox(
                    width: 105,
                    child: ActivityCard(
                      activity: activity,
                      selected:
                          selectedActivity ==
                          activity,
                      onTap: () {
                        setState(
                          () {
                            selectedActivity = activity;
                          },
                        );
                      },
                    ),
                  );
                },
              ).toList(),
            ),

            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: completeActivity,
                child: const Text(
                  "Salvar",
                ),
              ),
            ),

            const SizedBox(
              height: 20,
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
    );
  }
}
