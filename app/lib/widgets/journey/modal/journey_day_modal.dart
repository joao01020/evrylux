import 'package:flutter/material.dart';

import '../../../screens/evolution/my_journey/models/day_summary.dart';

import '../../../app/app_dependencies.dart';

class JourneyDayModal
    extends
        StatefulWidget {
  final DaySummary summary;

  const JourneyDayModal({
    super.key,

    required this.summary,
  });

  @override
  State<
    JourneyDayModal
  >
  createState() => _JourneyDayModalState();
}

class _JourneyDayModalState
    extends
        State<
          JourneyDayModal
        > {
  final TextEditingController controller = TextEditingController();

  Future<
    void
  >
  save() async {
    final text = controller.text.trim();

    if (text.isEmpty) {
      return;
    }

    await journeyController.saveNote(
      widget.summary.date,

      text,
    );

    controller.clear();

    setState(
      () {},
    );
  }

  Future<
    void
  >
  deleteNote(
    String note,
  ) async {
    final confirm =
        await showDialog<
          bool
        >(
          context: context,

          builder:
              (
                context,
              ) {
                return AlertDialog(
                  title: const Text(
                    "Excluir anotação?",
                  ),

                  content: const Text(
                    "Essa anotação será removida da sua jornada.",
                  ),

                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          false,
                        );
                      },

                      child: const Text(
                        "Cancelar",
                      ),
                    ),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          true,
                        );
                      },

                      child: const Text(
                        "Excluir",
                      ),
                    ),
                  ],
                );
              },
        );

    if (confirm !=
        true) {
      return;
    }

    await journeyController.deleteNote(
      widget.summary.date,

      note,
    );

    setState(
      () {},
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            "Anotação removida",
          ),
        ),
      );
    }
  }

  String weekday(
    DateTime date,
  ) {
    const days = [
      "Domingo",

      "Segunda-feira",

      "Terça-feira",

      "Quarta-feira",

      "Quinta-feira",

      "Sexta-feira",

      "Sábado",
    ];

    return days[date.weekday %
        7];
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final date = DateTime.parse(
      widget.summary.date,
    );

    final notes = journeyController.getDayHistory(
      widget.summary.date,
    );

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),

      child: Container(
        padding: const EdgeInsets.all(
          20,
        ),

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            20,
          ),

          color: Theme.of(
            context,
          ).colorScheme.surface,
        ),

        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        weekday(
                          date,
                        ),

                        style: const TextStyle(
                          color: Colors.grey,

                          fontSize: 16,
                        ),
                      ),

                      Text(
                        "${date.day}/${date.month}/${date.year}",

                        style: const TextStyle(
                          fontSize: 26,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  IconButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                      );
                    },

                    icon: const Icon(
                      Icons.close,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                "Resumo do dia",

                style: TextStyle(
                  fontSize: 20,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              _infoCard(
                icon: Icons.fitness_center,

                title: "Treinos",

                value: "${widget.summary.workouts} realizados",
              ),

              _infoCard(
                icon: Icons.menu_book,

                title: "Estudos",

                value: "${widget.summary.studiesMinutes} minutos",
              ),

              _infoCard(
                icon: Icons.savings,

                title: "Financeiro",

                value: "R\$ ${widget.summary.savedMoney}",
              ),

              const SizedBox(
                height: 20,
              ),

              const Text(
                "Anotações",

                style: TextStyle(
                  fontSize: 20,

                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              if (notes.isEmpty)
                const Text(
                  "Nenhuma anotação.",
                )
              else
                Column(
                  children: notes.map(
                    (
                      note,
                    ) {
                      return Dismissible(
                        key: ValueKey(
                          note,
                        ),

                        direction: DismissDirection.endToStart,

                        background: Container(
                          alignment: Alignment.centerRight,

                          padding: const EdgeInsets.only(
                            right: 20,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.red,

                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),

                          child: const Icon(
                            Icons.delete,

                            color: Colors.white,
                          ),
                        ),

                        confirmDismiss:
                            (
                              _,
                            ) async {
                              await deleteNote(
                                note,
                              );

                              return false;
                            },

                        child: Container(
                          width: double.infinity,

                          margin: const EdgeInsets.only(
                            bottom: 10,
                          ),

                          padding: const EdgeInsets.all(
                            12,
                          ),

                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,

                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),

                          child: Text(
                            "📝 $note",
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),

              const SizedBox(
                height: 20,
              ),

              TextField(
                controller: controller,

                maxLines: 3,

                decoration: const InputDecoration(
                  hintText: "Escreva sua evolução desse dia...",

                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 15,
              ),

              SizedBox(
                width: double.infinity,

                child: ElevatedButton.icon(
                  onPressed: save,

                  icon: const Icon(
                    Icons.save,
                  ),

                  label: const Text(
                    "Salvar anotação",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,

    required String title,

    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),

      padding: const EdgeInsets.all(
        14,
      ),

      decoration: BoxDecoration(
        color: Colors.grey.shade200,

        borderRadius: BorderRadius.circular(
          12,
        ),
      ),

      child: Row(
        children: [
          Icon(
            icon,
          ),

          const SizedBox(
            width: 12,
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                value,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
