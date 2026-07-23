import 'package:flutter/material.dart';

import '../widgets/activity_timer.dart';
import '../widgets/week_tracker.dart';

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

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Estudos 📚",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
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
              "Crie consistência estudando um pouco todos os dias.",
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
              title: "Tempo estudado",
            ),

            const SizedBox(
              height: 20,
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
                  "$streak dias estudados",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
