import 'package:flutter/material.dart';

class FinanceWeekTracker
    extends
        StatelessWidget {
  final List<
    bool
  >
  completedDays;

  final String? selectedDay;

  final List<
    String
  >
  days;

  final Function(
    int,
  )
  onDayTap;

  const FinanceWeekTracker({
    super.key,

    required this.completedDays,

    required this.selectedDay,

    required this.days,

    required this.onDayTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(
          16,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Semana",

              style: TextStyle(
                fontSize: 22,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: List.generate(
                days.length,

                (
                  index,
                ) {
                  final bool completed = completedDays[index];

                  final bool selected =
                      selectedDay ==
                      days[index];

                  return GestureDetector(
                    onTap: () {
                      onDayTap(
                        index,
                      );
                    },

                    child: Column(
                      children: [
                        Container(
                          width: 42,

                          height: 42,

                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.blue
                                : completed
                                ? Colors.green
                                : Colors.grey.shade200,

                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),

                          child: Center(
                            child: Text(
                              days[index]
                                  .substring(
                                    0,
                                    3,
                                  )
                                  .toUpperCase(),

                              style: TextStyle(
                                fontSize: 12,

                                fontWeight: FontWeight.bold,

                                color:
                                    selected ||
                                        completed
                                    ? Colors.white
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        if (completed)
                          const Icon(
                            Icons.check_circle,

                            color: Colors.green,

                            size: 18,
                          )
                        else
                          const SizedBox(
                            height: 18,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
