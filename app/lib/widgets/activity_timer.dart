import 'dart:async';

import 'package:flutter/material.dart';

class ActivityTimer
    extends
        StatefulWidget {
  const ActivityTimer({
    super.key,

    this.title = "Tempo",

    required this.onTimeChanged,
  });

  final String title;

  final Function(
    int seconds,
  )
  onTimeChanged;

  @override
  State<
    ActivityTimer
  >
  createState() => _ActivityTimerState();
}

class _ActivityTimerState
    extends
        State<
          ActivityTimer
        > {
  Timer? timer;

  int seconds = 0;

  bool running = false;

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
        _,
      ) {
        setState(
          () {
            seconds++;
          },
        );

        widget.onTimeChanged(
          seconds,
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
        running = false;

        seconds = 0;
      },
    );

    widget.onTimeChanged(
      seconds,
    );
  }

  String formatTime() {
    final minutes =
        seconds ~/
        60;

    final secs =
        seconds %
        60;

    return "${minutes.toString().padLeft(2, '0')}:"
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          20,
        ),

        child: Column(
          children: [
            Text(
              widget.title,

              style: const TextStyle(
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

                  onPressed: resetTimer,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
