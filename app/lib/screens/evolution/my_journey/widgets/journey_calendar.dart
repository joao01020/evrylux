import 'package:flutter/material.dart';

import '../../../../app/dependencies/app_dependencies.dart';

import '../utils/date_formatter.dart';

import 'journey_day_card.dart';

class JourneyCalendar
    extends
        StatelessWidget {
  final DateTime selectedDate;

  final Function(
    DateTime,
  )
  onSelect;

  const JourneyCalendar({
    super.key,

    required this.selectedDate,

    required this.onSelect,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final totalDays = DateTime(
      selectedDate.year,

      selectedDate.month +
          1,

      0,
    ).day;

    const weekDays = [
      "Dom",

      "Seg",

      "Ter",

      "Qua",

      "Qui",

      "Sex",

      "Sáb",
    ];

    return Card(
      elevation: 2,

      child: Padding(
        padding: const EdgeInsets.all(
          14,
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Row(
              children: weekDays.map(
                (
                  day,
                ) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,

                        style: const TextStyle(
                          fontWeight: FontWeight.bold,

                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ).toList(),
            ),

            const SizedBox(
              height: 10,
            ),

            GridView.builder(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: totalDays,

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,

                crossAxisSpacing: 6,

                mainAxisSpacing: 6,

                mainAxisExtent: 42,
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
                      selectedDate.year,

                      selectedDate.month,

                      day,
                    );

                    final key = DateFormatter.key(
                      date,
                    );

                    return JourneyDayCard(
                      date: date,

                      selected:
                          date.day ==
                          selectedDate.day,

                      completed: journeyController.hasRecord(
                        key,
                      ),

                      onTap: () {
                        onSelect(
                          date,
                        );
                      },
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }
}
