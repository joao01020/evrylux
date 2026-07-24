import 'package:flutter/material.dart';

import 'my_journey/journey_screen.dart';
import 'insights/insights_screen.dart';

class EvolutionScreen
    extends
        StatefulWidget {
  const EvolutionScreen({
    super.key,
  });

  @override
  State<
    EvolutionScreen
  >
  createState() => _EvolutionScreenState();
}

class _EvolutionScreenState
    extends
        State<
          EvolutionScreen
        > {
  double knowledge = 0.0;

  double health = 0.0;

  double finance = 0.0;

  String? hovered;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Minha Evolução 📈",
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          24,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Sua jornada",

              style: TextStyle(
                fontSize: 30,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              "Acompanhe sua evolução em mente, corpo e patrimônio.",

              style: TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(
              height: 35,
            ),

            const Text(
              "Evolução dos pilares",

              style: TextStyle(
                fontSize: 22,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            evolutionChart(),

            const SizedBox(
              height: 50,
            ),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder:
                          (
                            _,
                          ) => const JourneyScreen(),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.calendar_month,
                ),

                label: const Text(
                  "Minha Jornada 📅",
                ),
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder:
                          (
                            _,
                          ) => const InsightsScreen(),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.bar_chart,
                ),

                label: const Text(
                  "Insights 📊",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget evolutionChart() {
    return SizedBox(
      height: 250,

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,

        crossAxisAlignment: CrossAxisAlignment.end,

        children: [
          chartBar(
            knowledge,
            "🧠",
            "knowledge",
          ),

          chartBar(
            health,
            "❤️",
            "health",
          ),

          chartBar(
            finance,
            "💰",
            "finance",
          ),
        ],
      ),
    );
  }

  Widget chartBar(
    double value,

    String icon,

    String id,
  ) {
    bool active =
        hovered ==
        id;

    return MouseRegion(
      onEnter:
          (
            _,
          ) {
            setState(
              () {
                hovered = id;
              },
            );
          },

      onExit:
          (
            _,
          ) {
            setState(
              () {
                hovered = null;
              },
            );
          },

      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,

        children: [
          AnimatedOpacity(
            duration: const Duration(
              milliseconds: 200,
            ),

            opacity: active
                ? 1
                : 0,

            child: Text(
              "${(value * 100).round()}%",

              style: const TextStyle(
                fontSize: 18,

                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          AnimatedContainer(
            duration: const Duration(
              milliseconds: 300,
            ),

            width: active
                ? 65
                : 55,

            height:
                value ==
                    0
                ? 5
                : value *
                      180,

            decoration: BoxDecoration(
              color: active
                  ? Colors.blue
                  : Colors.green,

              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Text(
            icon,

            style: const TextStyle(
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }
}
