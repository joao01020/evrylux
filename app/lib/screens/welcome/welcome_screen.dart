import 'package:flutter/material.dart';

import '../evolution/controllers/evolution_controller.dart';

import '../evolution/evolution_screen.dart';
import '../finance/finance_screen.dart';
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
      "name": "Estudar",
      "emoji": "🧠",
      "description": "Evolua sua mente através dos estudos e aprendizado.",
    },

    {
      "name": "Treinar",
      "emoji": "❤️",
      "description": "Cuide do seu corpo através de movimento e hábitos saudáveis.",
    },

    {
      "name": "Financeiro",
      "emoji": "💰",
      "description": "Organize suas finanças e acompanhe sua evolução financeira.",
    },

    {
      "name": "Evolução",
      "emoji": "📈",
      "description": "Veja seu progresso e acompanhe sua transformação.",
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
        if (!mounted) return;

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
    Widget? page;

    switch (name) {
      case "Estudar":
        page = const StudyScreen();

        break;

      case "Treinar":
        page = const TrainingScreen();

        break;

      case "Financeiro":
        page = const FinanceScreen();

        break;

      case "Evolução":
        page = EvolutionScreen(
          controller: widget.controller,
        );

        break;
    }

    if (page !=
        null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (
                _,
              ) => page!,
        ),
      );
    }
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
                  "Olá, 👋 João Vitor",

                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            AnimatedOpacity(
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

                child: Column(
                  children: [
                    const SizedBox(
                      height: 150,
                    ),

                    const Text(
                      "Qual evolução deseja iniciar?",

                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),

                    const SizedBox(
                      height: 40,
                    ),

                    ...objectives.map(
                      (
                        objective,
                      ) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),

                          child: Card(
                            child: ListTile(
                              leading: Text(
                                objective["emoji"]!,

                                style: const TextStyle(
                                  fontSize: 30,
                                ),
                              ),

                              title: Text(
                                objective["name"]!,

                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              subtitle: Text(
                                objective["description"]!,
                              ),

                              onTap: () {
                                openObjective(
                                  objective["name"]!,
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
          ],
        ),
      ),
    );
  }
}
