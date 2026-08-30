import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart';

import '../utils/date_formatter.dart';

class JourneyCalendar
    extends
        StatefulWidget {
  const JourneyCalendar({
    super.key,
    required this.selectedDate,
    required this.onSelect,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final DateTime selectedDate;

  final ValueChanged<
    DateTime
  >
  onSelect;

  // ============================================================
  // STATE
  // ============================================================

  @override
  State<
    JourneyCalendar
  >
  createState() {
    return _JourneyCalendarState();
  }
}

class _JourneyCalendarState
    extends
        State<
          JourneyCalendar
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFFFFFFF,
  );

  static const Color _surface = Color(
    0xFFF7FBF1,
  );

  static const Color _surfaceSoft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  // ============================================================
  // MESES
  // ============================================================

  static const List<
    String
  >
  _months = [
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
  ];

  // ============================================================
  // DIAS DA SEMANA
  // ============================================================

  static const List<
    String
  >
  _weekDays = [
    'DOM',
    'SEG',
    'TER',
    'QUA',
    'QUI',
    'SEX',
    'SÁB',
  ];

  // ============================================================
  // MÊS VISÍVEL
  // ============================================================

  late DateTime _visibleMonth;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _visibleMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      1,
    );
  }

  // ============================================================
  // UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant JourneyCalendar oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    // ==========================================================
    // SINCRONIZA APENAS QUANDO A DATA SELECIONADA MUDAR
    // PARA OUTRO MÊS
    // ==========================================================

    if (oldWidget.selectedDate.year !=
            widget.selectedDate.year ||
        oldWidget.selectedDate.month !=
            widget.selectedDate.month) {
      _visibleMonth = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        1,
      );
    }
  }

  // ============================================================
  // MÊS ANTERIOR
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Aqui NÃO chamamos widget.onSelect().
  //
  // Portanto:
  //
  // clicar na seta
  //      ↓
  // troca somente o mês
  //      ↓
  // NÃO abre modal
  //
  // ============================================================

  void _previousMonth() {
    setState(
      () {
        _visibleMonth = DateTime(
          _visibleMonth.year,
          _visibleMonth.month -
              1,
          1,
        );
      },
    );
  }

  // ============================================================
  // PRÓXIMO MÊS
  // ============================================================

  void _nextMonth() {
    setState(
      () {
        _visibleMonth = DateTime(
          _visibleMonth.year,
          _visibleMonth.month +
              1,
          1,
        );
      },
    );
  }

  // ============================================================
  // MESMA DATA
  // ============================================================

  bool _sameDate(
    DateTime first,
    DateTime second,
  ) {
    return first.year ==
            second.year &&
        first.month ==
            second.month &&
        first.day ==
            second.day;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final firstDay = DateTime(
      _visibleMonth.year,
      _visibleMonth.month,
      1,
    );

    final totalDays = DateTime(
      _visibleMonth.year,
      _visibleMonth.month +
          1,
      0,
    ).day;

    // ==========================================================
    // PRIMEIRA COLUNA DO MÊS
    // ==========================================================
    //
    // DateTime.weekday:
    //
    // segunda = 1
    // terça   = 2
    // ...
    // domingo = 7
    //
    // O calendário começa no domingo:
    //
    // domingo = 0
    // segunda = 1
    // ...
    // sábado  = 6
    //
    // ==========================================================

    final leadingEmptyDays =
        firstDay.weekday %
        7;

    final totalCells =
        leadingEmptyDays +
        totalDays;

    final rows =
        (totalCells /
                7)
            .ceil();

    final completeGridCells =
        rows *
        7;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: _border,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(
              0x0D000000,
            ),
            blurRadius: 18,
            offset: Offset(
              0,
              6,
            ),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==================================================
            // HEADER
            // ==================================================
            _buildHeader(),

            const SizedBox(
              height: 18,
            ),

            // ==================================================
            // DIAS DA SEMANA
            // ==================================================
            _buildWeekHeader(),

            const SizedBox(
              height: 8,
            ),

            // ==================================================
            // CALENDÁRIO
            // ==================================================
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: completeGridCells,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 7,
                mainAxisSpacing: 7,
                mainAxisExtent: 48,
              ),
              itemBuilder:
                  (
                    context,
                    index,
                  ) {
                    final dayIndex =
                        index -
                        leadingEmptyDays;

                    // ===============================================
                    // CÉLULAS VAZIAS
                    // ===============================================

                    if (dayIndex <
                            0 ||
                        dayIndex >=
                            totalDays) {
                      return const SizedBox.shrink();
                    }

                    final day =
                        dayIndex +
                        1;

                    final date = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month,
                      day,
                    );

                    return _buildDay(
                      context: context,
                      date: date,
                    );
                  },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        // ======================================================
        // MÊS / ANO
        // ======================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _months[_visibleMonth.month -
                    1],
                style: const TextStyle(
                  color: _text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(
                height: 2,
              ),

              Text(
                '${_visibleMonth.year}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // MÊS ANTERIOR
        // ======================================================
        _navigationButton(
          icon: Icons.chevron_left_rounded,
          tooltip: 'Mês anterior',
          onTap: _previousMonth,
        ),

        const SizedBox(
          width: 8,
        ),

        // ======================================================
        // PRÓXIMO MÊS
        // ======================================================
        _navigationButton(
          icon: Icons.chevron_right_rounded,
          tooltip: 'Próximo mês',
          onTap: _nextMonth,
        ),
      ],
    );
  }

  // ============================================================
  // BOTÃO DE NAVEGAÇÃO
  // ============================================================

  Widget _navigationButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            11,
          ),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _surfaceSoft,
              borderRadius: BorderRadius.circular(
                11,
              ),
              border: Border.all(
                color: _border,
              ),
            ),
            child: Icon(
              icon,
              color: _primaryDark,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CABEÇALHO DA SEMANA
  // ============================================================

  Widget _buildWeekHeader() {
    return Row(
      children: _weekDays.map(
        (
          day,
        ) {
          return Expanded(
            child: Center(
              child: Text(
                day,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }

  // ============================================================
  // DIA
  // ============================================================

  Widget _buildDay({
    required BuildContext context,
    required DateTime date,
  }) {
    // ==========================================================
    // SELECIONADO
    // ==========================================================
    //
    // Só mostramos selecionado se a data realmente for a
    // selectedDate.
    //
    // Ao navegar para outro mês pelas setas, nenhum novo dia
    // é automaticamente selecionado.
    //
    // ==========================================================

    final selected = _sameDate(
      date,
      widget.selectedDate,
    );

    // ==========================================================
    // HOJE
    // ==========================================================

    final today = _sameDate(
      date,
      DateTime.now(),
    );

    // ==========================================================
    // REGISTRO
    // ==========================================================

    final key = DateFormatter.key(
      date,
    );

    final completed = journeyController.hasRecord(
      key,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          13,
        ),

        // ======================================================
        // SOMENTE CLICAR NO DIA DISPARA onSelect
        // ======================================================
        onTap: () {
          widget.onSelect(
            date,
          );
        },

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            // ================================================
            // FUNDO
            // ================================================
            color: selected
                ? _primary
                : today
                ? _surface
                : Colors.transparent,

            borderRadius: BorderRadius.circular(
              13,
            ),

            // ================================================
            // BORDA
            // ================================================
            border: Border.all(
              color: selected
                  ? _primary
                  : today
                  ? _primaryDark.withValues(
                      alpha: 0.32,
                    )
                  : Colors.transparent,
              width: selected
                  ? 1.2
                  : 1,
            ),

            // ================================================
            // SOMBRA
            // ================================================
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: _primaryDark.withValues(
                        alpha: 0.10,
                      ),
                      blurRadius: 8,
                      offset: const Offset(
                        0,
                        3,
                      ),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ==============================================
              // NÚMERO
              // ==============================================
              Text(
                '${date.day}',
                style: TextStyle(
                  color: selected
                      ? _primaryDark
                      : _text,
                  fontSize: 14,
                  fontWeight:
                      selected ||
                          today
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),

              // ==============================================
              // REGISTRO
              // ==============================================
              if (completed)
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: _primaryDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
