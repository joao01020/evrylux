import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';

import '../../widgets/generic/activity_timer.dart';
import '../../widgets/generic/week_tracker.dart';

import '../../widgets/study/study_header.dart';
import '../../widgets/study/streak_card.dart';
import '../../widgets/study/current_time_card.dart';
import '../../widgets/study/history_button.dart';

import 'brain/brain_screen.dart';
import 'history/history_screen.dart';

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
  final double timerScale = 0.75;

  @override
  void initState() {
    super.initState();

    studyController.addListener(
      refresh,
    );

    studyController.loadStudies();
  }

  void refresh() {
    if (!mounted) return;

    setState(
      () {},
    );
  }

  @override
  void dispose() {
    studyController.removeListener(
      refresh,
    );

    super.dispose();
  }

  // =========================================================
  // HISTÓRICO
  // =========================================================

  void openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const HistoryScreen(),
      ),
    );
  }

  // =========================================================
  // CÉREBRO
  // =========================================================

  void openBrain() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => const BrainScreen(),
      ),
    );
  }

  // =========================================================
  // SALVAR ESTUDO
  // =========================================================

  Future<
    void
  >
  saveStudy() async {
    await studyController.saveStudy();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          "Estudo salvo com sucesso 📚✅",
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final currentMinutes =
        studyController.currentSeconds ~/
        60;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Conhecimento 📚",
        ),
        actions: [
          IconButton(
            tooltip: "Cérebro",
            icon: const Icon(
              Icons.psychology_outlined,
            ),
            onPressed: openBrain,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: StudyHeader(),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  StreakCard(
                    streak: studyController.streak,
                  ),
                ],
              ),

              const SizedBox(
                height: 25,
              ),

              SizedBox(
                height: 70,
                child: WeekTracker(
                  completedDays: studyController.completedDays,
                  selectedDay: studyController.selectedDay,
                  days: studyController.days,
                  onDayTap: studyController.selectDay,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Transform.scale(
                scale: timerScale,
                child: ActivityTimer(
                  title: "Tempo estudado",
                  onTimeChanged: studyController.updateTimer,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              CurrentTimeCard(
                minutes: currentMinutes,
              ),

              const SizedBox(
                height: 20,
              ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saveStudy,
                  icon: const Icon(
                    Icons.save,
                  ),
                  label: const Text(
                    "Salvar estudo",
                  ),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: openBrain,
                  icon: const Icon(
                    Icons.psychology_outlined,
                  ),
                  label: const Text(
                    "Cérebro",
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              HistoryButton(
                onPressed: openHistory,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
