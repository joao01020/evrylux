import 'package:flutter/material.dart';

// ============================================================
// STREAK CARD
// ============================================================
//
// Indicador compacto de sequência de estudos.
//
// Visual:
// - sem emoji;
// - ícone Material moderno;
// - fundo verde muito suave;
// - borda discreta;
// - plural correto: 1 dia / N dias.
//
// ============================================================

class StreakCard
    extends
        StatelessWidget {
  const StreakCard({
    super.key,
    required this.streak,
  });

  final int streak;

  // ============================================================
  // LABEL
  // ============================================================

  String get _label {
    if (streak ==
        1) {
      return '1 dia';
    }

    return '$streak dias';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    const background = Color(
      0xFFF4FAF1,
    );

    const iconBackground = Color(
      0xFFDDF7D7,
    );

    const border = Color(
      0xFFD7E8D3,
    );

    const foreground = Color(
      0xFF315E35,
    );

    return Tooltip(
      message:
          streak ==
              1
          ? '1 dia seguido estudando'
          : '$streak dias seguidos estudando',
      waitDuration: const Duration(
        milliseconds: 450,
      ),
      child: Container(
        height: 42,
        padding: const EdgeInsets.fromLTRB(
          7,
          6,
          12,
          6,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: border,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(
                alpha: 0.035,
              ),
              blurRadius: 10,
              offset: const Offset(
                0,
                3,
              ),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ====================================================
            // ÍCONE
            // ====================================================
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(
                  10,
                ),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                size: 18,
                color: foreground,
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            // ====================================================
            // CONTAGEM
            // ====================================================
            Text(
              _label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
