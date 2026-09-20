import 'package:flutter/material.dart';

class InsightsScreen
    extends
        StatefulWidget {
  const InsightsScreen({
    super.key,
  });

  @override
  State<
    InsightsScreen
  >
  createState() {
    return _InsightsScreenState();
  }
}

class _InsightsScreenState
    extends
        State<
          InsightsScreen
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFF7FBF1,
  );

  static const Color _surface = Color(
    0xFFFFFFFF,
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
  // DIAS
  // ============================================================

  final List<
    String
  >
  days = [
    'Seg',
    'Ter',
    'Qua',
    'Qui',
    'Sex',
    'Sáb',
    'Dom',
  ];

  // ============================================================
  // DADOS
  // ============================================================

  final List<
    double
  >
  knowledge = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ];

  final List<
    double
  >
  health = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ];

  final List<
    double
  >
  finance = [
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ];

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(
          color: _primaryDark,
        ),
        title: const Text(
          'Insights',
          style: TextStyle(
            color: _text,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          18,
          24,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================================================
            // INTRO
            // ==================================================
            _buildIntro(),

            const SizedBox(
              height: 26,
            ),

            // ==================================================
            // TÍTULO DO GRÁFICO
            // ==================================================
            const Text(
              'Análise semanal',
              style: TextStyle(
                color: _text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(
              height: 5,
            ),

            const Text(
              'Compare seus pilares ao longo dos últimos dias.',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                height: 1.4,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            // ==================================================
            // CHART
            // ==================================================
            _buildChart(),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // LEGENDA
            // ==================================================
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        22,
      ),
      decoration: BoxDecoration(
        color: _surface,
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
      child: Row(
        children: [
          // ====================================================
          // ÍCONE
          // ====================================================
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(
                15,
              ),
            ),
            child: const Icon(
              Icons.insights_outlined,
              color: _primaryDark,
              size: 26,
            ),
          ),

          const SizedBox(
            width: 16,
          ),

          // ====================================================
          // TEXTO
          // ====================================================
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seus padrões',
                  style: TextStyle(
                    color: _text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),

                SizedBox(
                  height: 5,
                ),

                Text(
                  'Entenda como conhecimento, saúde e finanças evoluem durante a semana.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHART
  // ============================================================

  Widget _buildChart() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color: _border,
        ),
      ),
      child: SizedBox(
        height: 270,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
            days.length,
            (
              index,
            ) {
              return Expanded(
                child: _dayColumn(
                  index,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DAY COLUMN
  // ============================================================

  Widget _dayColumn(
    int index,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // ======================================================
        // BARS
        // ======================================================
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _bar(
                value: knowledge[index],
                type: _InsightType.knowledge,
                title: 'Conhecimento',
              ),

              const SizedBox(
                width: 3,
              ),

              _bar(
                value: health[index],
                type: _InsightType.health,
                title: 'Saúde',
              ),

              const SizedBox(
                width: 3,
              ),

              _bar(
                value: finance[index],
                type: _InsightType.finance,
                title: 'Financeiro',
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        // ======================================================
        // DIA
        // ======================================================
        Text(
          days[index],
          style: const TextStyle(
            color: _muted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BAR
  // ============================================================

  Widget _bar({
    required double value,
    required _InsightType type,
    required String title,
  }) {
    final safeValue = value.isFinite
        ? value.clamp(
            0.0,
            100.0,
          )
        : 0.0;

    final color = _colorForType(
      type,
    );

    return Tooltip(
      message: '$title\n${safeValue.toStringAsFixed(0)}%',
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 250,
        ),
        curve: Curves.easeOut,
        width: 9,
        height:
            safeValue <=
                0
            ? 4
            : (safeValue /
                      100) *
                  175,
        constraints: const BoxConstraints(
          minHeight: 4,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(
            999,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COLOR FOR TYPE
  // ============================================================

  Color _colorForType(
    _InsightType type,
  ) {
    switch (type) {
      case _InsightType.knowledge:
        return _primaryDark;

      case _InsightType.health:
        return _primary;

      case _InsightType.finance:
        return _primaryDark.withValues(
          alpha: 0.58,
        );
    }
  }

  // ============================================================
  // LEGEND
  // ============================================================

  Widget _buildLegend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        18,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilares',
            style: TextStyle(
              color: _text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _legendItem(
                icon: Icons.psychology_alt_outlined,
                text: 'Conhecimento',
                color: _colorForType(
                  _InsightType.knowledge,
                ),
              ),

              _legendItem(
                icon: Icons.favorite_border_rounded,
                text: 'Saúde',
                color: _colorForType(
                  _InsightType.health,
                ),
              ),

              _legendItem(
                icon: Icons.account_balance_wallet_outlined,
                text: 'Financeiro',
                color: _colorForType(
                  _InsightType.finance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LEGEND ITEM
  // ============================================================

  Widget _legendItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: _surfaceSoft,
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: _border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ====================================================
          // INDICADOR
          // ====================================================
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ====================================================
          // ICON
          // ====================================================
          Icon(
            icon,
            color: _primaryDark,
            size: 17,
          ),

          const SizedBox(
            width: 6,
          ),

          // ====================================================
          // TEXT
          // ====================================================
          Text(
            text,
            style: const TextStyle(
              color: _text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// INSIGHT TYPE
// ============================================================

enum _InsightType {
  knowledge,
  health,
  finance,
}
