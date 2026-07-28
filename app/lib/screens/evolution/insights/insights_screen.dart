import 'package:flutter/material.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final List<String> days = ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"];

  final List<double> knowledge = [0, 0, 0, 0, 0, 0, 0];

  final List<double> health = [0, 0, 0, 0, 0, 0, 0];

  final List<double> finance = [0, 0, 0, 0, 0, 0, 0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Insights 📊")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Análise semanal",

              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Comparação dos pilares por dia.",

              style: TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 30),

            SizedBox(
              height: 260,

              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,

                    mainAxisAlignment: MainAxisAlignment.spaceAround,

                    children: List.generate(days.length, (index) {
                      return Expanded(child: dayColumn(index));
                    }),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            legend(),
          ],
        ),
      ),
    );
  }

  Widget dayColumn(int index) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,

      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,

            crossAxisAlignment: CrossAxisAlignment.end,

            children: [
              bar(knowledge[index], Colors.blue, "Conhecimento"),

              const SizedBox(width: 3),

              bar(health[index], Colors.red, "Saúde"),

              const SizedBox(width: 3),

              bar(finance[index], Colors.green, "Financeiro"),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Text(days[index], style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget bar(double value, Color color, String title) {
    return Tooltip(
      message: "$title\n${value.toInt()}%",

      child: Container(
        width: 8,

        height: value == 0 ? 3 : (value / 100) * 150,

        decoration: BoxDecoration(
          color: color,

          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }

  Widget legend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Legenda",

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            item(Colors.blue, "🧠 Conhecimento"),

            item(Colors.red, "❤️ Saúde"),

            item(Colors.green, "💰 Financeiro"),
          ],
        ),
      ),
    );
  }

  Widget item(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        children: [
          Container(
            width: 14,

            height: 14,

            decoration: BoxDecoration(
              color: color,

              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(width: 10),

          Text(text),
        ],
      ),
    );
  }
}
