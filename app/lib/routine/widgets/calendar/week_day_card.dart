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

  // ============================================================
  // DADOS
  // ============================================================

  final DateTime day;
  final bool selected;
  final bool today;
  final double progress;
  final bool hasContent;
  final VoidCallback onTap;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _green = Color(
    0xFF347A3D,
  );

  static const Color _greenLight = Color(
    0xFFC9F2C5,
  );

  static const Color _greenBorder = Color(
    0xFFA9DEA5,
  );

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _border = Color(
    0xFFDCE8DA,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
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
              ? _greenLight
              : _surface,

          borderRadius: BorderRadius.circular(
            16,
          ),

          // ====================================================
          // BORDA
          // ====================================================
          //
          // Prioridade:
          //
          // 1. selecionado
          // 2. possui conteúdo
          // 3. hoje
          // 4. dia normal
          //
          // ====================================================
          border: Border.all(
            color: selected
                ? _greenBorder
                : hasContent
                ? _green
                : today
                ? _green.withValues(
                    alpha: .65,
                  )
                : _border,

            width: selected
                ? 1.4
                : hasContent
                ? 2
                : today
                ? 1.4
                : 1,
          ),

          boxShadow: [
            if (selected)
              const BoxShadow(
                color: Color(
                  0x14000000,
                ),
                blurRadius: 8,
                offset: Offset(
                  0,
                  3,
                ),
              ),
          ],
        ),
        child: Column(
          children: [
            // ==================================================
            // DIA DA SEMANA
            // ==================================================
            Text(
              _shortWeekday(
                day.weekday,
              ),
              style: TextStyle(
                color: selected
                    ? _green
                    : _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(
              height: 4,
            ),

            // ==================================================
            // NÚMERO DO DIA
            // ==================================================
            Text(
              '${day.day}',
              style: TextStyle(
                color: selected
                    ? _green
                    : _text,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const Spacer(),

            // ==================================================
            // PROGRESSO
            // ==================================================
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
                  backgroundColor: selected
                      ? const Color(
                          0xFFB8E8B5,
                        )
                      : const Color(
                          0xFFE4ECE4,
                        ),
                  valueColor:
                      const AlwaysStoppedAnimation<
                        Color
                      >(
                        _green,
                      ),
                ),
              )
            else
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: selected
                      ? _green
                      : const Color(
                          0xFFC7D4C8,
                        ),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIA DA SEMANA
  // ============================================================

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
