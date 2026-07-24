import 'package:flutter/material.dart';

import '../core/storage/storage_service.dart';
import '../widgets/activity_timer.dart';
import '../widgets/week_tracker.dart';

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

    final List<
      String
    >
    history = [];

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
            context,
          ) {
            return AlertDialog(
              title: const Text(
                "Histórico 📚",
              ),

              content: SizedBox(
                width: 300,

                height: 300,

                child: completedActivities.isEmpty
                    ? const Center(
                        child: Text(
                          "Nenhuma atividade concluída.",
                        ),
                      )
                    : ListView.builder(
                        itemCount: completedActivities.length,

                        itemBuilder:
                            (
                              context,
                              index,
                            ) {
                              return Card(
                                child: ListTile(
                                  dense: true,

                                  leading: const Text(
                                    "✅",
                                  ),

                                  title: Text(
                                    completedActivities[index],

                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              );
                            },
                      ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  child: const Text(
                    "Fechar",
                  ),
                ),
              ],
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
            const Text(
              "Sua evolução física começa aqui.",

              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    "Escolha sua atividade de hoje e mantenha sua evolução.",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "🔥",
                          style: TextStyle(
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          "$streak",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          "dias",
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
              height: 8,
            ),

            ...activityOptions.map(
              (
                activity,
              ) {
                return Card(
                  child: ListTile(
                    dense: true,

                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),

                    title: Text(
                      activity,

                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),

                    trailing:
                        selectedActivity ==
                            activity
                        ? const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          )
                        : null,

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
            ),

            const SizedBox(
              height: 10,
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
