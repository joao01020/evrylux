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

  // ============================================================
  // TITLE
  // ============================================================

  final String title;

  // ============================================================
  // TIME CHANGED
  // ============================================================
  //
  // Informa para a tela/controller o tempo atual em segundos.
  //
  // ============================================================

  final void Function(
    int seconds,
  )
  onTimeChanged;

  // ============================================================
  // SAVE
  // ============================================================
  //
  // Pode receber:
  //
  // void Function()
  //
  // ou:
  //
  // Future<void> Function()
  //
  // Isso permite usar diretamente:
  //
  // onSave: saveStudy
  //
  // ============================================================

  final FutureOr<
    void
  >
  Function()?
  onSave;

  @override
  State<
    ActivityTimer
  >
  createState() {
    return _ActivityTimerState();
  }
}

class _ActivityTimerState
    extends
        State<
          ActivityTimer
        > {
  // ============================================================
  // TIMERS
  // ============================================================

  Timer? timer;

  Timer? colorTimer;

  // ============================================================
  // STATE
  // ============================================================

  int seconds = 0;

  bool running = false;

  bool minuteCompleted = false;

  bool saving = false;

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

        // ======================================================
        // SINCRONIZAR TEMPO
        // ======================================================

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

    timer = null;

    if (!mounted) {
      return;
    }

    setState(
      () {
        running = false;
      },
    );

    // ==========================================================
    // GARANTIR SINCRONIZAÇÃO
    // ==========================================================

    widget.onTimeChanged(
      seconds,
    );
  }

  // ============================================================
  // RESET
  // ============================================================

  void resetTimer() {
    timer?.cancel();

    timer = null;

    colorTimer?.cancel();

    colorTimer = null;

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
  //
  // Ao clicar no ícone:
  //
  // 1. pega exatamente o tempo atual;
  // 2. envia para onTimeChanged;
  // 3. chama o método de salvamento da tela;
  // 4. mostra loading enquanto estiver salvando.
  //
  // O timer NÃO é zerado automaticamente.
  //
  // ============================================================

  Future<
    void
  >
  saveTimer() async {
    final onSave = widget.onSave;

    if (onSave ==
            null ||
        saving) {
      return;
    }

    // ==========================================================
    // NÃO SALVAR 00:00
    // ==========================================================

    if (seconds <=
        0) {
      return;
    }

    // ==========================================================
    // GARANTIR TEMPO ATUAL
    // ==========================================================

    widget.onTimeChanged(
      seconds,
    );

    if (!mounted) {
      return;
    }

    setState(
      () {
        saving = true;
      },
    );

    try {
      await Future<
        void
      >.sync(
        onSave,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[ACTIVITY TIMER] '
        'Erro ao salvar tempo: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted) {
        setState(
          () {
            saving = false;
          },
        );
      }
    }
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
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          20,
        ),
        child: Column(
          children: [
            // ==================================================
            // TITLE
            // ==================================================
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

            // ==================================================
            // TIME
            // ==================================================
            AnimatedDefaultTextStyle(
              duration: const Duration(
                milliseconds: 300,
              ),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: minuteCompleted
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
              child: Text(
                formatTime(),
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            // ==================================================
            // ACTIONS
            // ==================================================
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ==============================================
                // PLAY / PAUSE
                // ==============================================
                IconButton(
                  tooltip: running
                      ? 'Pausar'
                      : 'Iniciar',
                  icon: Icon(
                    running
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                  iconSize: 40,
                  onPressed: running
                      ? pauseTimer
                      : startTimer,
                ),

                const SizedBox(
                  width: 2,
                ),

                // ==============================================
                // RESET
                // ==============================================
                IconButton(
                  tooltip: 'Reiniciar',
                  icon: const Icon(
                    Icons.restart_alt_rounded,
                  ),
                  iconSize: 23,
                  onPressed: resetTimer,
                ),

                // ==============================================
                // SAVE
                // ==============================================
                if (widget.onSave !=
                    null) ...[
                  const SizedBox(
                    width: 2,
                  ),

                  IconButton(
                    tooltip: 'Salvar tempo estudado',
                    onPressed:
                        saving ||
                            seconds <=
                                0
                        ? null
                        : saveTimer,
                    icon: saving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : const Icon(
                            Icons.save_outlined,
                          ),
                    iconSize: 22,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
