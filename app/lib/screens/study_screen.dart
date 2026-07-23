import 'dart:async';

import 'package:flutter/material.dart';

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

  int streak = 0;

  Timer? timer;

  int seconds = 0;

  bool running = false;

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

  void startTimer() {
    if (running) return;

    setState(
      () {
        running = true;
      },
    );

    timer = Timer.periodic(
      const Duration(
        seconds: 1,
      ),

      (
        timer,
      ) {
        setState(
          () {
            seconds++;
          },
        );
      },
    );
  }

  void pauseTimer() {
    timer?.cancel();

    setState(
      () {
        running = false;
      },
    );
  }

  void resetTimer() {
    timer?.cancel();

    setState(
      () {
        seconds = 0;

        running = false;
      },
    );
  }

  String formatTime() {
    int hours =
        seconds ~/
        3600;

    int minutes =
        (seconds %
            3600) ~/
        60;

    int secs =
        seconds %
        60;

    return "${hours.toString().padLeft(2, '0')}:"
        "${minutes.toString().padLeft(2, '0')}:"
        "${secs.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    timer?.cancel();

    super.dispose();
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

            Card(
              child: Padding(
                padding: const EdgeInsets.all(
                  20,
                ),

                child: Column(
                  children: [
                    const Text(
                      "Tempo estudado",

                      style: TextStyle(
                        fontSize: 18,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 15,
                    ),

                    Text(
                      formatTime(),

                      style: const TextStyle(
                        fontSize: 40,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [
                        IconButton(
                          icon: Icon(
                            running
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),

                          iconSize: 40,

                          onPressed: running
                              ? pauseTimer
                              : startTimer,
                        ),

                        IconButton(
                          icon: const Icon(
                            Icons.restart_alt,
                          ),

                          iconSize: 35,

                          onPressed: resetTimer,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
