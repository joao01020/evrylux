import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class EvolutionCalendar
    extends
        StatefulWidget {
  final Map<
    String,
    List<
      String
    >
  >
  history;

  final DateTime selectedDate;

  final Function(
    DateTime,
  )
  onDateSelected;

  final Function(
    DateTime,
  )
  onCreateNote;

  const EvolutionCalendar({
    super.key,

    required this.history,

    required this.selectedDate,

    required this.onDateSelected,

    required this.onCreateNote,
  });

  @override
  State<
    EvolutionCalendar
  >
  createState() => _EvolutionCalendarState();
}

class _EvolutionCalendarState
    extends
        State<
          EvolutionCalendar
        > {
  late DateTime currentDate;

  @override
  void initState() {
    super.initState();

    currentDate = widget.selectedDate;
  }

  String dateKey(
    DateTime date,
  ) {
    return "${date.year}-"
        "${date.month.toString().padLeft(2, '0')}-"
        "${date.day.toString().padLeft(2, '0')}";
  }

  void openMenu(
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

      items: const [
        PopupMenuItem(
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
          final date = DateTime(
            currentDate.year,

            currentDate.month,

            day,
          );

          widget.onCreateNote(
            date,
          );
        }
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final daysInMonth = DateTime(
      currentDate.year,

      currentDate.month +
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
                        currentDate = DateTime(
                          currentDate.year,

                          currentDate.month -
                              1,
                        );
                      },
                    );
                  },
                ),

                Text(
                  "${currentDate.month}/${currentDate.year}",

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
                        currentDate = DateTime(
                          currentDate.year,

                          currentDate.month +
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

                crossAxisSpacing: 8,

                mainAxisSpacing: 8,
              ),

              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final day =
                        index +
                        1;

                    final date = DateTime(
                      currentDate.year,

                      currentDate.month,

                      day,
                    );

                    final key = dateKey(
                      date,
                    );

                    final completed = widget.history.containsKey(
                      key,
                    );

                    final selected =
                        widget.selectedDate.day ==
                            day &&
                        widget.selectedDate.month ==
                            currentDate.month &&
                        widget.selectedDate.year ==
                            currentDate.year;

                    return Listener(
                      onPointerDown:
                          (
                            event,
                          ) {
                            if (event.kind ==
                                    PointerDeviceKind.mouse &&
                                event.buttons ==
                                    kSecondaryMouseButton) {
                              openMenu(
                                context,

                                event.position,

                                day,
                              );
                            }
                          },

                      child: GestureDetector(
                        onTap: () {
                          widget.onDateSelected(
                            date,
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
}
