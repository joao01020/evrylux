import 'package:flutter/material.dart';

import '../../controllers/evolution/evolution_controller.dart';

import 'my_journey/journey_screen.dart';

import 'insights/insights_screen.dart';

class EvolutionScreen extends StatefulWidget {
  final EvolutionController controller;

  const EvolutionScreen({super.key, required this.controller});

  @override
  State<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends State<EvolutionScreen> {
  String? hovered;

  @override
  void initState() {
    super.initState();

    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,

      builder: (context, _) {
        final data = widget.controller.evolution;

        return Scaffold(
          appBar: AppBar(title: const Text("Minha Evolução 📈")),

          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                const Text(
                  "Sua jornada",

                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Acompanhe sua evolução em mente, corpo e patrimônio.",

                  style: TextStyle(fontSize: 18),
                ),

                const SizedBox(height: 35),

                const Text(
                  "Evolução dos pilares",

                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 250,

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,

                    crossAxisAlignment: CrossAxisAlignment.end,

                    children: [
                      chartBar(data.knowledge, "🧠", "knowledge"),

                      chartBar(data.health, "❤️", "health"),

                      chartBar(data.finance, "💰", "finance"),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(builder: (_) => const JourneyScreen()),
                    );
                  },

                  icon: const Icon(Icons.calendar_month),

                  label: const Text("Minha Jornada 📅"),
                ),

                const SizedBox(height: 15),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(builder: (_) => const InsightsScreen()),
                    );
                  },

                  icon: const Icon(Icons.bar_chart),

                  label: const Text("Insights 📊"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget chartBar(double value, String icon, String id) {
    final active = hovered == id;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          hovered = id;
        });
      },

      onExit: (_) {
        setState(() {
          hovered = null;
        });
      },

      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,

        children: [
          Text(
            "${(value * 100).round()}%",

            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          AnimatedContainer(
            duration: const Duration(milliseconds: 300),

            width: active ? 65 : 55,

            height: value == 0 ? 5 : value * 180,

            decoration: BoxDecoration(
              color: active ? Colors.blue : Colors.green,

              borderRadius: BorderRadius.circular(12),
            ),
          ),

          const SizedBox(height: 10),

          Text(icon, style: const TextStyle(fontSize: 28)),
        ],
      ),
    );
  }
}
