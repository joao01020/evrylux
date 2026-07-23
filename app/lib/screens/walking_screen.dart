import 'package:flutter/material.dart';

import '../widgets/activity_timer.dart';
import '../widgets/week_tracker.dart';

class WalkingScreen
    extends
        StatefulWidget {
  const WalkingScreen({
    super.key,
  });

  @override
  State<
    WalkingScreen
  >
  createState() => _WalkingScreenState();
}

class _WalkingScreenState
    extends
        State<
          WalkingScreen
        > {
  int steps = 0;

  double distance = 0;

  int streak = 0;

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

  void addWalking() {
    setState(
      () {
        steps += 500;
        distance += 0.4;
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
          "Caminhada 🚶",
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sua jornada começa aqui.",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                "Caminhar é o primeiro passo para evoluir seu corpo e sua mente.",
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

              const ActivityTimer(
                title: "Tempo de caminhada",
              ),

              const SizedBox(
                height: 25,
              ),

              Card(
                child: ListTile(
                  leading: const Text(
                    "🚶",
                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),
                  title: const Text(
                    "Passos",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "$steps passos hoje",
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.add,
                    ),
                    onPressed: addWalking,
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              Card(
                child: ListTile(
                  leading: const Text(
                    "📍",
                    style: TextStyle(
                      fontSize: 30,
                    ),
                  ),
                  title: const Text(
                    "Distância",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "${distance.toStringAsFixed(1)} km percorridos",
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.add,
                    ),
                    onPressed: addWalking,
                  ),
                ),
              ),

              const SizedBox(
                height: 15,
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
                    "$streak dias marcados",
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
