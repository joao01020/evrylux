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

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _primary = Color(
    0xFF7C5CFF,
  );

  static const Color _primarySoft = Color(
    0xFF9B87FF,
  );

  static const Color _surface = Color(
    0xFF15171D,
  );

  static const Color _surfaceSelected = Color(
    0xFF211D35,
  );

  static const Color _border = Color(
    0xFF292C35,
  );

  static const Color _textPrimary = Color(
    0xFFF5F7FA,
  );

  static const Color _textSecondary = Color(
    0xFF8D93A1,
  );

  static const Color _success = Color(
    0xFF7BE495,
  );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final safeScale =
        scale <=
            0
        ? 1.0
        : scale;

    return SizedBox(
      height:
          72 *
          safeScale,

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: List.generate(
          days.length,
          (
            index,
          ) {
            final day = days[index];

            final completed =
                index <
                    completedDays.length
                ? completedDays[index]
                : false;

            final selected =
                selectedDay ==
                day;

            return Expanded(
              child: _buildDay(
                day: day,
                index: index,
                completed: completed,
                selected: selected,
                scale: safeScale,
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // DAY
  // ============================================================

  Widget _buildDay({
    required String day,
    required int index,
    required bool completed,
    required bool selected,
    required double scale,
  }) {
    final firstLetter = day.isNotEmpty
        ? day
              .substring(
                0,
                1,
              )
              .toUpperCase()
        : '';

    final shortDay =
        day.length >=
            3
        ? day.substring(
            0,
            3,
          )
        : day;

    return Tooltip(
      message: completed
          ? '$day concluído'
          : day,

      child: InkWell(
        borderRadius: BorderRadius.circular(
          12 *
              scale,
        ),

        onTap: () {
          onDayTap(
            index,
          );
        },

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),

          curve: Curves.easeOut,

          margin: EdgeInsets.symmetric(
            horizontal:
                3 *
                scale,
          ),

          padding: EdgeInsets.symmetric(
            vertical:
                4 *
                scale,
          ),

          decoration: BoxDecoration(
            color: selected
                ? _surfaceSelected
                : Colors.transparent,

            borderRadius: BorderRadius.circular(
              12 *
                  scale,
            ),

            border: Border.all(
              color: selected
                  ? _primary.withValues(
                      alpha: 0.42,
                    )
                  : Colors.transparent,
            ),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              // ====================================
              // CIRCLE
              // ====================================
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),

                curve: Curves.easeOut,

                width:
                    34 *
                    scale,

                height:
                    34 *
                    scale,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  color: _circleColor(
                    completed: completed,
                    selected: selected,
                  ),

                  border: Border.all(
                    color: _circleBorderColor(
                      completed: completed,
                      selected: selected,
                    ),

                    width: selected
                        ? 1.5
                        : 1,
                  ),

                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: _primary.withValues(
                              alpha: 0.22,
                            ),

                            blurRadius:
                                10 *
                                scale,

                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),

                child: Center(
                  child: completed
                      ? Icon(
                          Icons.check_rounded,

                          size:
                              16 *
                              scale,

                          color: selected
                              ? Colors.white
                              : _success,
                        )
                      : Text(
                          firstLetter,

                          style: TextStyle(
                            fontSize:
                                12 *
                                scale,

                            color: selected
                                ? Colors.white
                                : _textSecondary,

                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              SizedBox(
                height:
                    4 *
                    scale,
              ),

              // ====================================
              // LABEL
              // ====================================
              Flexible(
                child: Text(
                  shortDay,

                  maxLines: 1,

                  overflow: TextOverflow.ellipsis,

                  style: TextStyle(
                    fontSize:
                        10 *
                        scale,

                    height: 1,

                    color: selected
                        ? _primarySoft
                        : completed
                        ? _textPrimary
                        : _textSecondary,

                    fontWeight:
                        selected ||
                            completed
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CIRCLE COLOR
  // ============================================================

  Color _circleColor({
    required bool completed,
    required bool selected,
  }) {
    if (selected) {
      return _primary;
    }

    if (completed) {
      return _success.withValues(
        alpha: 0.10,
      );
    }

    return _surface;
  }

  // ============================================================
  // CIRCLE BORDER
  // ============================================================

  Color _circleBorderColor({
    required bool completed,
    required bool selected,
  }) {
    if (selected) {
      return _primarySoft;
    }

    if (completed) {
      return _success.withValues(
        alpha: 0.45,
      );
    }

    return _border;
  }
}
