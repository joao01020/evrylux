import 'package:flutter/material.dart';

import 'reminder_day_status.dart';

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
    required this.reminderStatus,
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

  // ============================================================
  // LEMBRETE
  // ============================================================
  //
  // Agora o card recebe o estado COMPLETO do lembrete.
  //
  // Isso permite diferenciar:
  //
  // none
  //   -> nenhum lembrete
  //
  // active
  //   -> existe pelo menos um lembrete futuro
  //
  // expired
  //   -> existem apenas lembretes que já passaram
  //
  // mixed
  //   -> existem lembretes expirados e futuros no mesmo dia
  //
  // ============================================================

  final ReminderDayStatus reminderStatus;

  // ============================================================
  // AÇÕES
  // ============================================================

  final VoidCallback onTap;

  // ============================================================
  // CORES PRINCIPAIS
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

  static const Color _inactiveDot = Color(
    0xFFC7D4C8,
  );

  // ============================================================
  // CORES DOS LEMBRETES
  // ============================================================

  static const Color _activeReminder = Color(
    0xFF347A3D,
  );

  static const Color _expiredReminder = Color(
    0xFF9A6B57,
  );

  static const Color _mixedReminder = Color(
    0xFFC47A24,
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
          // O lembrete não altera a borda.
          //
          // Assim o calendário continua visualmente limpo
          // e o sino é responsável por representar o lembrete.
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
            // INDICADOR INFERIOR
            // ==================================================
            _buildBottomIndicator(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INDICADOR INFERIOR
  // ============================================================
  //
  // Prioridade:
  //
  // 1. lembrete
  // 2. conteúdo/progresso
  // 3. ponto vazio
  //
  // ============================================================

  Widget _buildBottomIndicator() {
    // ==========================================================
    // LEMBRETE
    // ==========================================================

    if (reminderStatus !=
        ReminderDayStatus.none) {
      return _buildReminderIndicator();
    }

    // ==========================================================
    // PROGRESSO
    // ==========================================================

    if (hasContent) {
      return SizedBox(
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
      );
    }

    // ==========================================================
    // PONTO PADRÃO
    // ==========================================================

    return Container(
      width: 5,
      height: 5,
      decoration: BoxDecoration(
        color: selected
            ? _green
            : _inactiveDot,
        shape: BoxShape.circle,
      ),
    );
  }

  // ============================================================
  // INDICADOR DE LEMBRETE
  // ============================================================

  Widget _buildReminderIndicator() {
    final color = _reminderColor();

    final tooltip = _reminderTooltip();

    final icon = _reminderIcon();

    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: 22,
        height: 16,
        child: Center(
          child: Icon(
            icon,
            size: 13,
            color: color,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ÍCONE DO LEMBRETE
  // ============================================================

  IconData _reminderIcon() {
    switch (reminderStatus) {
      case ReminderDayStatus.none:
        return Icons.notifications_none_rounded;

      case ReminderDayStatus.active:
        return Icons.notifications_none_rounded;

      case ReminderDayStatus.expired:
        return Icons.notifications_off_outlined;

      case ReminderDayStatus.mixed:
        return Icons.notifications_active_outlined;
    }
  }

  // ============================================================
  // COR DO LEMBRETE
  // ============================================================

  Color _reminderColor() {
    switch (reminderStatus) {
      case ReminderDayStatus.none:
        return _inactiveDot;

      case ReminderDayStatus.active:
        return selected
            ? _green
            : _activeReminder;

      case ReminderDayStatus.expired:
        return _expiredReminder;

      case ReminderDayStatus.mixed:
        return _mixedReminder;
    }
  }

  // ============================================================
  // TOOLTIP DO LEMBRETE
  // ============================================================

  String _reminderTooltip() {
    switch (reminderStatus) {
      case ReminderDayStatus.none:
        return 'Nenhum lembrete';

      case ReminderDayStatus.active:
        return 'Há lembrete programado';

      case ReminderDayStatus.expired:
        return 'Há lembrete expirado';

      case ReminderDayStatus.mixed:
        return 'Há lembretes ativos e expirados';
    }
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
