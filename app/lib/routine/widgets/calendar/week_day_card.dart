import 'package:flutter/material.dart';

class WeekDayCard
    extends
        StatelessWidget {
  const WeekDayCard({
    super.key,
    required this.day,
    required this.selected,
    required this.today,
    required this.progress,
    required this.hasContent,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final double progress;
  final bool hasContent;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    const primary = Color(
      0xFF7C5CFF,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        16,
      ),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        width: 67,
        padding: const EdgeInsets.symmetric(
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected
              ? primary
              : const Color(
                  0xFF111319,
                ),
          borderRadius: BorderRadius.circular(
            16,
          ),
          border: Border.all(
            color: selected
                ? primary
                : today
                ? primary.withValues(
                    alpha: .7,
                  )
                : const Color(
                    0xFF272B36,
                  ),
          ),
        ),
        child: Column(
          children: [
            Text(
              _shortWeekday(
                day.weekday,
              ),
              style: TextStyle(
                color: selected
                    ? Colors.white70
                    : const Color(
                        0xFF9298A6,
                      ),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              '${day.day}',
              style: const TextStyle(
                color: Color(
                  0xFFF5F7FA,
                ),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            if (hasContent)
              SizedBox(
                width: 35,
                child: LinearProgressIndicator(
                  value: progress
                      .clamp(
                        0.0,
                        1.0,
                      )
                      .toDouble(),
                  minHeight: 3,
                  borderRadius: BorderRadius.circular(
                    4,
                  ),
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(
                    selected
                        ? Colors.white
                        : primary,
                  ),
                ),
              )
            else
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _shortWeekday(
    int weekday,
  ) {
    return const [
      'SEG',
      'TER',
      'QUA',
      'QUI',
      'SEX',
      'SÁB',
      'DOM',
    ][weekday -
        1];
  }
}
