import 'package:flutter/material.dart';

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
  List<
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
  trainingOptions = [
    "🏋️ Peito",

    "🦵 Pernas",

    "🏃 Corrida",

    "🔥 Full Body",
  ];

  String? selectedTraining;

  List<
    String
  >
  completedWorkouts = [];

  int streak = 0;

  void toggleDay(
    int index,
  ) {
    setState(
      () {
        completedDays[index] = !completedDays[index];

        streak = completedDays
            .where(
              (
                day,
              ) => day,
            )
            .length;
      },
    );
  }

  void completeTraining() {
    if (selectedTraining ==
        null) {
      return;
    }

    setState(
      () {
        completedWorkouts.add(
          selectedTraining!,
        );

        selectedTraining = null;
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
          "Treino 💪",
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
                "Sua evolução física começa aqui.",

                style: TextStyle(
                  fontSize: 28,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                "Escolha seu treino de hoje e mantenha sua evolução.",

                style: TextStyle(
                  fontSize: 18,
                ),
              ),

              const SizedBox(
                height: 35,
              ),

              WeekTracker(
                completedDays: completedDays,

                onDayTap: toggleDay,
              ),

              const SizedBox(
                height: 35,
              ),

              const Text(
                "Hoje:",

                style: TextStyle(
                  fontSize: 22,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              ...trainingOptions.map(
                (
                  training,
                ) {
                  return Card(
                    child: ListTile(
                      title: Text(
                        training,
                      ),

                      trailing:
                          selectedTraining ==
                              training
                          ? const Icon(
                              Icons.check_circle,

                              color: Colors.green,
                            )
                          : null,

                      onTap: () {
                        setState(
                          () {
                            selectedTraining = training;
                          },
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(
                height: 20,
              ),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton(
                  onPressed: completeTraining,

                  child: const Text(
                    "Concluir treino",
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

                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    "$streak dias de evolução",
                  ),
                ),
              ),

              const SizedBox(
                height: 25,
              ),

              const Text(
                "Treinos realizados",

                style: TextStyle(
                  fontSize: 22,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              if (completedWorkouts.isEmpty)
                const Text(
                  "Nenhum treino concluído ainda.",
                ),

              ...completedWorkouts.map(
                (
                  workout,
                ) {
                  return Card(
                    child: ListTile(
                      leading: const Text(
                        "✅",

                        style: TextStyle(
                          fontSize: 25,
                        ),
                      ),

                      title: Text(
                        workout,
                      ),

                      subtitle: const Text(
                        "Treino concluído",
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
