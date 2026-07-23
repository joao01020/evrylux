import 'package:flutter/material.dart';

import '../models/objective.dart';
import '../widgets/objective_card.dart';
import 'objective_screen.dart';

class WelcomeScreen
    extends
        StatefulWidget {
  const WelcomeScreen({
    super.key,
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
    Objective
  >
  objectives = const [
    Objective(
      name: "Caminhada",

      emoji: "🚶",

      description: "Melhore sua resistência e conexão com o corpo.",
    ),

    Objective(
      name: "Estudos",

      emoji: "📚",

      description: "Construa conhecimento e evolução mental todos os dias.",
    ),

    Objective(
      name: "Treino",

      emoji: "💪",

      description: "Desenvolva força, disciplina e evolução física.",
    ),

    Objective(
      name: "Leitura",

      emoji: "📖",

      description: "Expanda sua mente através dos livros.",
    ),
  ];

  Objective? selectedObjective;

  void startObjective() {
    if (selectedObjective ==
        null) {
      return;
    }

    Navigator.push(
      context,

      MaterialPageRoute(
        builder:
            (
              context,
            ) => ObjectiveScreen(
              objective: selectedObjective!,
            ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 60,
            ),

            const Text(
              "Olá 👋",

              style: TextStyle(
                fontSize: 32,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            const Text(
              "Qual objetivo deseja iniciar?",

              style: TextStyle(
                fontSize: 20,
              ),
            ),

            const SizedBox(
              height: 40,
            ),

            ...objectives.map(
              (
                item,
              ) => ObjectiveCard(
                objective: item,

                selected:
                    selectedObjective ==
                    item,

                onTap: () {
                  setState(
                    () {
                      selectedObjective = item;
                    },
                  );
                },
              ),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,

              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                ),

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,

                    foregroundColor: Colors.white,

                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                    ),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        30,
                      ),
                    ),
                  ),

                  onPressed:
                      selectedObjective ==
                          null
                      ? null
                      : startObjective,

                  child: const Text(
                    "Começar",

                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}
