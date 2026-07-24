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

  Timer? colorTimer;

  int seconds = 0;

  bool running = false;

  bool minuteCompleted = false;

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

            if (seconds %
                    60 ==
                0) {
              showMinuteCompleted();
            }
          },
        );

        widget.onTimeChanged(
          seconds,
        );
      },
    );
  }

  void showMinuteCompleted() {
    setState(
      () {
        minuteCompleted = true;
      },
    );

    colorTimer?.cancel();

    colorTimer = Timer(
      const Duration(
        seconds: 1,
      ),

      () {
        if (!mounted) return;

        setState(
          () {
            minuteCompleted = false;
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

    colorTimer?.cancel();

    setState(
      () {
        running = false;

        seconds = 0;

        minuteCompleted = false;
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

    colorTimer?.cancel();

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

            AnimatedDefaultTextStyle(
              duration: const Duration(
                milliseconds: 300,
              ),

              style: TextStyle(
                fontSize: 40,

                fontWeight: FontWeight.bold,

                color: minuteCompleted
                    ? Colors.green
                    : Colors.black,
              ),

              child: Text(
                formatTime(),
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
