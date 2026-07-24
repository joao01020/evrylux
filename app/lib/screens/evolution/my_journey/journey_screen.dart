import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class JourneyScreen
    extends
        StatefulWidget {
  const JourneyScreen({
    super.key,
  });

  @override
  State<
    JourneyScreen
  >
  createState() => _JourneyScreenState();
}

class _JourneyScreenState
    extends
        State<
          JourneyScreen
        > {
  DateTime selectedDate = DateTime.now();

  final Map<
    String,
    List<
      String
    >
  >
  history = {};

  String get selectedKey {
    return "${selectedDate.year}-"
        "${selectedDate.month.toString().padLeft(2, '0')}-"
        "${selectedDate.day.toString().padLeft(2, '0')}";
  }

  void createNoteDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,

      builder:
          (
            context,
          ) {
            return AlertDialog(
              title: Text(
                "Anotação ${selectedDate.day}/${selectedDate.month}",
              ),

              content: TextField(
                controller: controller,

                maxLines: 4,

                decoration: const InputDecoration(
                  hintText: "Escreva sua evolução do dia...",

                  border: OutlineInputBorder(),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },

                  child: const Text(
                    "Cancelar",
                  ),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      return;
                    }

                    setState(
                      () {
                        if (history[selectedKey] ==
                            null) {
                          history[selectedKey] = [];
                        }

                        history[selectedKey]!.add(
                          controller.text.trim(),
                        );
                      },
                    );

                    Navigator.pop(
                      context,
                    );
                  },

                  child: const Text(
                    "Salvar",
                  ),
                ),
              ],
            );
          },
    );
  }

  void openDayMenu(
    BuildContext context,
    Offset position,
    int day,
  ) {
    showMenu(
      context: context,

      position: RelativeRect.fromLTRB(
        position.dx,

        position.dy,

        position.dx +
            10,

        position.dy +
            10,
      ),

      items: [
        const PopupMenuItem(
          value: "note",

          child: Row(
            children: [
              Icon(
                Icons.edit,
              ),

              SizedBox(
                width: 10,
              ),

              Text(
                "Criar anotação",
              ),
            ],
          ),
        ),
      ],
    ).then(
      (
        value,
      ) {
        if (value ==
            "note") {
          setState(
            () {
              selectedDate = DateTime(
                selectedDate.year,

                selectedDate.month,

                day,
              );
            },
          );

          createNoteDialog();
        }
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Minha Jornada 📅",
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
              "Seu histórico",

              style: TextStyle(
                fontSize: 30,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            const Text(
              "Clique com botão direito no dia para adicionar uma evolução.",

              style: TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(
              height: 30,
            ),

            calendar(),

            const SizedBox(
              height: 35,
            ),

            const Text(
              "Registro do dia",

              style: TextStyle(
                fontSize: 22,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            selectedDayHistory(),
          ],
        ),
      ),
    );
  }

  Widget calendar() {
    final daysInMonth = DateTime(
      selectedDate.year,

      selectedDate.month +
          1,

      0,
    ).day;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),

        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left,
                  ),

                  onPressed: () {
                    setState(
                      () {
                        selectedDate = DateTime(
                          selectedDate.year,

                          selectedDate.month -
                              1,
                        );
                      },
                    );
                  },
                ),

                Text(
                  "${selectedDate.month}/${selectedDate.year}",

                  style: const TextStyle(
                    fontSize: 20,

                    fontWeight: FontWeight.bold,
                  ),
                ),

                IconButton(
                  icon: const Icon(
                    Icons.chevron_right,
                  ),

                  onPressed: () {
                    setState(
                      () {
                        selectedDate = DateTime(
                          selectedDate.year,

                          selectedDate.month +
                              1,
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            GridView.builder(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: daysInMonth,

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,

                mainAxisSpacing: 8,

                crossAxisSpacing: 8,
              ),

              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final day =
                        index +
                        1;

                    final key =
                        "${selectedDate.year}-"
                        "${selectedDate.month.toString().padLeft(2, '0')}-"
                        "${day.toString().padLeft(2, '0')}";

                    final completed = history.containsKey(
                      key,
                    );

                    final selected =
                        selectedDate.day ==
                        day;

                    return Listener(
                      onPointerDown:
                          (
                            event,
                          ) {
                            if (event.kind ==
                                    PointerDeviceKind.mouse &&
                                event.buttons ==
                                    kSecondaryMouseButton) {
                              openDayMenu(
                                context,

                                event.position,

                                day,
                              );
                            }
                          },

                      child: GestureDetector(
                        onTap: () {
                          setState(
                            () {
                              selectedDate = DateTime(
                                selectedDate.year,

                                selectedDate.month,

                                day,
                              );
                            },
                          );
                        },

                        child: Container(
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.blue
                                : completed
                                ? Colors.green
                                : Colors.grey.shade200,

                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),

                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                Text(
                                  "$day",

                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,

                                    color:
                                        selected ||
                                            completed
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),

                                if (completed)
                                  const Text(
                                    "✓",

                                    style: TextStyle(
                                      color: Colors.white,

                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }

  Widget selectedDayHistory() {
    final data = history[selectedKey];

    if (data ==
        null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(
            20,
          ),

          child: Text(
            "Nenhuma anotação nesse dia.",
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          20,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: data.map(
            (
              item,
            ) {
              return Padding(
                padding: const EdgeInsets.only(
                  bottom: 12,
                ),

                child: Text(
                  "✅ $item",

                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}
