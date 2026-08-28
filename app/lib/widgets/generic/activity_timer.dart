import 'dart:async';

import 'package:flutter/material.dart';

class ActivityTimer
    extends
        StatefulWidget {
  const ActivityTimer({
    super.key,

    this.title = 'Tempo',

    required this.onTimeChanged,

    this.onSave,
  });

  final String title;

  final Function(
    int seconds,
  )
  onTimeChanged;

  final VoidCallback? onSave;

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

  // ============================================================
  // START
  // ============================================================

  void startTimer() {
    if (running) {
      return;
    }

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
        if (!mounted) {
          return;
        }

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

  // ============================================================
  // MINUTE COMPLETED
  // ============================================================

  void showMinuteCompleted() {
    if (!mounted) {
      return;
    }

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
        if (!mounted) {
          return;
        }

        setState(
          () {
            minuteCompleted = false;
          },
        );
      },
    );
  }

  // ============================================================
  // PAUSE
  // ============================================================

  void pauseTimer() {
    timer?.cancel();

    if (!mounted) {
      return;
    }

    setState(
      () {
        running = false;
      },
    );
  }

  // ============================================================
  // RESET
  // ============================================================

  void resetTimer() {
    timer?.cancel();

    colorTimer?.cancel();

    if (!mounted) {
      return;
    }

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

  // ============================================================
  // SAVE
  // ============================================================

  void saveTimer() {
    widget.onSave?.call();
  }

  // ============================================================
  // FORMAT
  // ============================================================

  String formatTime() {
    final minutes =
        seconds ~/
        60;

    final secs =
        seconds %
        60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    timer?.cancel();

    colorTimer?.cancel();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

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

            const SizedBox(
              height: 6,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // =================================================
                // PLAY / PAUSE
                // =================================================
                IconButton(
                  tooltip: running
                      ? 'Pausar'
                      : 'Iniciar',
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

                // =================================================
                // RESET
                // =================================================
                IconButton(
                  tooltip: 'Reiniciar',
                  icon: const Icon(
                    Icons.restart_alt,
                  ),
                  onPressed: resetTimer,
                ),

                // =================================================
                // SAVE
                // =================================================
                if (widget.onSave !=
                    null)
                  IconButton(
                    tooltip: 'Salvar estudo',
                    icon: const Icon(
                      Icons.save_outlined,
                    ),
                    onPressed: saveTimer,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
