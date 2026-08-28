import 'package:flutter/material.dart';

import '../evolution/controllers/evolution_controller.dart';
import '../evolution/evolution_screen.dart';
import '../finance/finance_screen.dart';
import '../routine/screen/routine_screen.dart';
import '../study/study_screen.dart';
import '../training/training_screen.dart';

class WelcomeScreen
    extends
        StatefulWidget {
  final EvolutionController controller;

  const WelcomeScreen({
    super.key,
    required this.controller,
  });

  @override
  State<
    WelcomeScreen
  >
  createState() => _WelcomeScreenState();
}

class _WelcomeScreenState
    extends
        State<
          WelcomeScreen
        > {
  final List<
    Map<
      String,
      String
    >
  >
  objectives = [
    {
      'name': 'Estudar',
      'emoji': '🧠',
      'description': 'Evolua sua mente através dos estudos e aprendizado.',
    },
    {
      'name': 'Treinar',
      'emoji': '❤️',
      'description': 'Cuide do seu corpo através de movimento e hábitos saudáveis.',
    },
    {
      'name': 'Financeiro',
      'emoji': '💰',
      'description': 'Organize suas finanças e acompanhe sua evolução financeira.',
    },
    {
      'name': 'Rotina',
      'emoji': '📅',
      'description': 'Planeje sua semana, organize tarefas e registre suas ideias.',
    },
    {
      'name': 'Evolução',
      'emoji': '📈',
      'description': 'Veja seu progresso e acompanhe sua transformação.',
    },
  ];

  bool showOptions = false;

  @override
  void initState() {
    super.initState();

    Future.delayed(
      const Duration(
        milliseconds: 1200,
      ),
      () {
        if (!mounted) {
          return;
        }

        setState(
          () {
            showOptions = true;
          },
        );
      },
    );
  }

  void openObjective(
    String name,
  ) {
    final Widget? page = switch (name) {
      'Estudar' => const StudyScreen(),
      'Treinar' => const TrainingScreen(),
      'Financeiro' => const FinanceScreen(),
      'Rotina' => const RoutineScreen(),
      'Evolução' => EvolutionScreen(
        controller: widget.controller,
      ),
      _ => null,
    };

    if (page ==
        null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (
              _,
            ) => page,
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(
                milliseconds: 900,
              ),
              curve: Curves.easeInOutCubic,
              alignment: showOptions
                  ? Alignment.topCenter
                  : Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(
                  top: showOptions
                      ? 70
                      : 0,
                ),
                child: const Text(
                  'Olá, 👋 João Vitor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              ignoring: !showOptions,
              child: AnimatedOpacity(
                duration: const Duration(
                  milliseconds: 700,
                ),
                opacity: showOptions
                    ? 1
                    : 0,
                child: AnimatedSlide(
                  duration: const Duration(
                    milliseconds: 900,
                  ),
                  curve: Curves.easeOutCubic,
                  offset: showOptions
                      ? Offset.zero
                      : const Offset(
                          0,
                          0.25,
                        ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      150,
                      16,
                      32,
                    ),
                    children: [
                      const Text(
                        'Qual evolução deseja iniciar?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(
                        height: 32,
                      ),
                      ...objectives.map(
                        (
                          objective,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8,
                            ),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                leading: Text(
                                  objective['emoji']!,
                                  style: const TextStyle(
                                    fontSize: 30,
                                  ),
                                ),
                                title: Text(
                                  objective['name']!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  objective['description']!,
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 16,
                                ),
                                onTap: () {
                                  openObjective(
                                    objective['name']!,
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
