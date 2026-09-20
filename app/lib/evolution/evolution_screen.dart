import 'package:flutter/material.dart';

import 'controllers/evolution_controller.dart';

import 'my_journey/journey_screen.dart';

import 'insights/insights_screen.dart';

class EvolutionScreen
    extends
        StatefulWidget {
  const EvolutionScreen({
    super.key,
    required this.controller,
  });

  final EvolutionController controller;

  @override
  State<
    EvolutionScreen
  >
  createState() {
    return _EvolutionScreenState();
  }
}

class _EvolutionScreenState
    extends
        State<
          EvolutionScreen
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
  // STATE
  // ============================================================

  String? hovered;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    widget.controller.load();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder:
          (
            context,
            _,
          ) {
            final data = widget.controller.evolution;

            return Scaffold(
              backgroundColor: _background,

              // ====================================================
              // APP BAR
              // ====================================================
              appBar: AppBar(
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: _background,
                surfaceTintColor: Colors.transparent,
                title: const Text(
                  'Minha Evolução',
                  style: TextStyle(
                    color: _text,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                iconTheme: const IconThemeData(
                  color: _primaryDark,
                ),
              ),

              // ====================================================
              // BODY
              // ====================================================
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
                    // =================================================
                    // INTRO
                    // =================================================
                    _buildIntro(),

                    const SizedBox(
                      height: 26,
                    ),

                    // =================================================
                    // SECTION
                    // =================================================
                    const Text(
                      'Evolução dos pilares',
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
                      'Veja como cada área está evoluindo ao longo do tempo.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    // =================================================
                    // CHART
                    // =================================================
                    _buildChartCard(
                      knowledge: data.knowledge,
                      health: data.health,
                      finance: data.finance,
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    // =================================================
                    // ACTIONS
                    // =================================================
                    _buildActions(
                      context,
                    ),
                  ],
                ),
              ),
            );
          },
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
              Icons.trending_up_rounded,
              color: _primaryDark,
              size: 27,
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
                  'Sua jornada',
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
                  'Acompanhe sua evolução em conhecimento, saúde e patrimônio.',
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
  // CHART CARD
  // ============================================================

  Widget _buildChartCard({
    required double knowledge,
    required double health,
    required double finance,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        18,
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
        height: 260,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: chartBar(
                value: knowledge,
                icon: Icons.psychology_alt_outlined,
                title: 'Conhecimento',
                id: 'knowledge',
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: chartBar(
                value: health,
                icon: Icons.favorite_border_rounded,
                title: 'Saúde',
                id: 'health',
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: chartBar(
                value: finance,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Finanças',
                id: 'finance',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CHART BAR
  // ============================================================

  Widget chartBar({
    required double value,
    required IconData icon,
    required String title,
    required String id,
  }) {
    final safeValue = value.isFinite
        ? value.clamp(
            0.0,
            1.0,
          )
        : 0.0;

    final active =
        hovered ==
        id;

    final percentage =
        (safeValue *
                100)
            .round();

    return MouseRegion(
      onEnter:
          (
            _,
          ) {
            setState(
              () {
                hovered = id;
              },
            );
          },
      onExit:
          (
            _,
          ) {
            setState(
              () {
                hovered = null;
              },
            );
          },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ====================================================
          // VALUE
          // ====================================================
          AnimatedDefaultTextStyle(
            duration: const Duration(
              milliseconds: 180,
            ),
            style: TextStyle(
              color: active
                  ? _primaryDark
                  : _text,
              fontSize: active
                  ? 20
                  : 18,
              fontWeight: FontWeight.w900,
            ),
            child: Text(
              '$percentage%',
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // ====================================================
          // BAR AREA
          // ====================================================
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 250,
                ),
                curve: Curves.easeOut,
                width: active
                    ? 64
                    : 56,
                height:
                    safeValue <=
                        0
                    ? 6
                    : 170 *
                          safeValue,
                constraints: const BoxConstraints(
                  minHeight: 6,
                ),
                decoration: BoxDecoration(
                  color: active
                      ? _primary
                      : _primary.withValues(
                          alpha: 0.72,
                        ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color: active
                        ? _primaryDark.withValues(
                            alpha: 0.18,
                          )
                        : _border,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: _primaryDark.withValues(
                              alpha: 0.10,
                            ),
                            blurRadius: 10,
                            offset: const Offset(
                              0,
                              4,
                            ),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // ICON
          // ====================================================
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: active
                  ? _primary
                  : _surfaceSoft,
              borderRadius: BorderRadius.circular(
                12,
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

          const SizedBox(
            height: 8,
          ),

          // ====================================================
          // LABEL
          // ====================================================
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions(
    BuildContext context,
  ) {
    return Row(
      children: [
        // ======================================================
        // JOURNEY
        // ======================================================
        Expanded(
          child: _ActionCard(
            icon: Icons.calendar_month_outlined,
            title: 'Minha Jornada',
            subtitle: 'Veja sua evolução dia a dia.',
            filled: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (
                        _,
                      ) {
                        return const JourneyScreen();
                      },
                ),
              );
            },
          ),
        ),

        const SizedBox(
          width: 12,
        ),

        // ======================================================
        // INSIGHTS
        // ======================================================
        Expanded(
          child: _ActionCard(
            icon: Icons.insights_outlined,
            title: 'Insights',
            subtitle: 'Entenda seus padrões e progresso.',
            filled: false,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (
                        _,
                      ) {
                        return const InsightsScreen();
                      },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// ACTION CARD
// ============================================================

class _ActionCard
    extends
        StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;

  final String title;

  final String subtitle;

  final bool filled;

  final VoidCallback onTap;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          16,
        ),
        child: Ink(
          padding: const EdgeInsets.all(
            16,
          ),
          decoration: BoxDecoration(
            color: filled
                ? _primary
                : _surface,
            borderRadius: BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: filled
                  ? _primary
                  : _border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: filled
                      ? Colors.white.withValues(
                          alpha: 0.55,
                        )
                      : _primary,
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  icon,
                  color: _primaryDark,
                  size: 21,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _primaryDark,
                size: 15,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
