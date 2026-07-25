import 'package:flutter/material.dart';

import '../../app_dependencies.dart';

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
  @override
  void initState() {
    super.initState();

    trainingController.load();
  }

  Future<
    void
  >
  completeActivity() async {
    await trainingController.save();

    // Atualiza evolução do usuário

    await evolutionController.saveToday();

    if (!mounted) return;

    setState(
      () {},
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
              activities: trainingController.history,
            );
          },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final controller = trainingController;

    final minutes =
        controller.currentSeconds ~/
        60;

    return AnimatedBuilder(
      animation: controller,

      builder:
          (
            context,
            child,
          ) {
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
                      streak: controller.streak,
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    WeekTracker(
                      completedDays: controller.completedDays,

                      days: controller.days,

                      selectedDay: controller.selectedDay,

                      onDayTap: controller.selectDay,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    ActivityTimer(
                      title: "Tempo de atividade",

                      onTimeChanged: controller.updateTimer,
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    Card(
                      child: ListTile(
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

                      children: controller.activityOptions.map(
                        (
                          activity,
                        ) {
                          return SizedBox(
                            width: 105,

                            child: ActivityCard(
                              activity: activity,

                              selected:
                                  controller.selectedActivity ==
                                  activity,

                              onTap: () {
                                controller.selectActivity(
                                  activity,
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
          },
    );
  }
}
