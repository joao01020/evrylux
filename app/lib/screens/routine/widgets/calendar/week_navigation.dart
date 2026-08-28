import 'package:flutter/material.dart';

class WeekNavigation
    extends
        StatelessWidget {
  const WeekNavigation({
    super.key,
    required this.weekStart,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime weekStart;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(
    BuildContext context,
  ) {
    final end = weekStart.add(
      const Duration(
        days: 6,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 10,
      ),
      child: Row(
        children: [
          _NavigationButton(
            icon: Icons.chevron_left_rounded,
            tooltip: 'Semana anterior',
            onTap: onPrevious,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${_monthName(weekStart.month)} ${weekStart.year}',
                  style: const TextStyle(
                    color: Color(
                      0xFFF5F7FA,
                    ),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  '${weekStart.day.toString().padLeft(2, '0')} – '
                  '${end.day.toString().padLeft(2, '0')} '
                  '${_monthName(end.month).toLowerCase()}',
                  style: const TextStyle(
                    color: Color(
                      0xFF9298A6,
                    ),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _NavigationButton(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Próxima semana',
            onTap: onNext,
          ),
        ],
      ),
    );
  }

  String _monthName(
    int month,
  ) {
    return const [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ][month -
        1];
  }
}

class _NavigationButton
    extends
        StatelessWidget {
  const _NavigationButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(
              0xFF111319,
            ),
            borderRadius: BorderRadius.circular(
              12,
            ),
            border: Border.all(
              color: const Color(
                0xFF272B36,
              ),
            ),
          ),
          child: Icon(
            icon,
            color: const Color(
              0xFFF5F7FA,
            ),
          ),
        ),
      ),
    );
  }
}
