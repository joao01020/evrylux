import 'package:flutter/material.dart';

class WeekTracker
    extends
        StatelessWidget {
  final List<
    bool
  >
  completedDays;

  final List<
    String
  >
  days;

  final String? selectedDay;

  final Function(
    int,
  )
  onDayTap;

  final double scale;

  const WeekTracker({
    super.key,

    required this.completedDays,

    required this.days,

    required this.selectedDay,

    required this.onDayTap,

    this.scale = 1.0,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Transform.scale(
      scale: scale,

      child: SizedBox(
        height:
            75 *
            scale,

        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: List.generate(
            days.length,

            (
              index,
            ) {
              final day = days[index];

              final completed = completedDays[index];

              final selected =
                  selectedDay ==
                  day;

              return GestureDetector(
                onTap: () {
                  onDayTap(
                    index,
                  );
                },

                child: Column(
                  mainAxisSize: MainAxisSize.min,

                  children: [
                    Container(
                      width:
                          38 *
                          scale,

                      height:
                          38 *
                          scale,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        color: selected
                            ? Colors.blue
                            : completed
                            ? Colors.green
                            : Colors.grey.shade300,
                      ),

                      child: Center(
                        child: Text(
                          day
                              .substring(
                                0,
                                1,
                              )
                              .toUpperCase(),

                          style: TextStyle(
                            fontSize:
                                14 *
                                scale,

                            color:
                                selected ||
                                    completed
                                ? Colors.white
                                : Colors.black,

                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      height:
                          5 *
                          scale,
                    ),

                    Text(
                      day.substring(
                        0,
                        3,
                      ),

                      style: TextStyle(
                        fontSize:
                            12 *
                            scale,

                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
