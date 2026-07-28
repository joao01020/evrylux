import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';

import '../../widgets/generic/week_tracker.dart';

import 'widgets/history_dialog.dart';
import 'widgets/training_consistency_card.dart';
import 'widgets/training_coverage_card.dart';
import 'widgets/training_header.dart';
import 'widgets/training_registration_section.dart';
import 'widgets/training_weekly_goal_card.dart';

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
  createState() {
    return _TrainingScreenState();
  }
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
  _completeActivity() async {
    final saved = await trainingController.save();

    if (!mounted) {
      return;
    }

    if (!saved) {
      _showMessage(
        trainingController.errorMessage ??
            'Não foi possível registrar o treino.',
      );

      return;
    }

    await evolutionController.saveToday();

    if (!mounted) {
      return;
    }

    _showMessage(
      trainingController.successMessage ??
          'Treino registrado com sucesso.',
    );

    trainingController.clearMessages();
  }

  void _showHistory() {
    showDialog<
      void
    >(
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

  void _showMessage(
    String message,
  ) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final controller = trainingController;

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
                  'Saúde 💪',
                ),
              ),
              body: controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : SingleChildScrollView(
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
                            height: 24,
                          ),

                          TrainingWeeklyGoalCard(
                            weeklyGoal: controller.weeklyGoal,
                            onGoalChanged: controller.setWeeklyGoal,
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          TrainingConsistencyCard(
                            consistency: controller.consistencyIndex,
                            completedTrainings: controller.monthlyCompletedTrainings,
                            expectedTrainings: controller.expectedTrainingsUntilToday,
                            weeklyGoal: controller.weeklyGoal,
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          TrainingCoverageCard(
                            coverage: controller.monthlyCoverage,
                          ),

                          const SizedBox(
                            height: 28,
                          ),

                          TrainingRegistrationSection(
                            controller: controller,
                            onComplete: _completeActivity,
                            onOpenHistory: _showHistory,
                          ),

                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
            );
          },
    );
  }
}
