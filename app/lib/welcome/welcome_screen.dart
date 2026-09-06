import 'dart:async';

import 'package:flutter/material.dart';

import '../evolution/controllers/evolution_controller.dart';
import '../evolution/evolution_screen.dart';
import '../finance/screen/finance_screen.dart';
import '../profile/data/profile_repository.dart';
import '../profile/models/user_profile.dart';
import '../routine/screen/routine_screen.dart';
import '../study/study_screen.dart';
import '../training/training_screen.dart';

class WelcomeScreen
    extends
        StatefulWidget {
  const WelcomeScreen({
    super.key,
    required this.controller,
  });

  final EvolutionController controller;

  @override
  State<
    WelcomeScreen
  >
  createState() {
    return _WelcomeScreenState();
  }
}

class _WelcomeScreenState
    extends
        State<
          WelcomeScreen
        > {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _background = Color(
    0xFFF8FBF4,
  );

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _surfaceSoft = Color(
    0xFFF4F8F1,
  );

  static const Color _border = Color(
    0xFFDCE7DB,
  );

  static const Color _primary = Color(
    0xFFB8EFB0,
  );

  static const Color _primaryDark = Color(
    0xFF365E34,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _mutedSoft = Color(
    0xFF98A29A,
  );

  // ============================================================
  // PROFILE
  // ============================================================

  late final ProfileRepository _profileRepository;

  UserProfile? _profile;

  bool _loadingProfile = true;

  String? _profileError;

  // ============================================================
  // STATE
  // ============================================================

  bool _showOptions = false;

  Timer? _introTimer;

  // ============================================================
  // OBJECTIVES
  // ============================================================

  static const List<
    _WelcomeObjective
  >
  _objectives = [
    _WelcomeObjective(
      name: 'Estudar',
      description: 'Construa conhecimento, registre ideias e desenvolva seu Cérebro.',
      icon: Icons.psychology_alt_outlined,
      accent: Color(
        0xFFBCEFB4,
      ),
      accentDark: Color(
        0xFF3C6B39,
      ),
    ),

    _WelcomeObjective(
      name: 'Treinar',
      description: 'Cuide do corpo, acompanhe treinos e mantenha sua consistência.',
      icon: Icons.favorite_border_rounded,
      accent: Color(
        0xFFFFE0E0,
      ),
      accentDark: Color(
        0xFFA84D4D,
      ),
    ),

    _WelcomeObjective(
      name: 'Financeiro',
      description: 'Organize suas finanças e acompanhe sua evolução financeira.',
      icon: Icons.account_balance_wallet_outlined,
      accent: Color(
        0xFFFFEDBD,
      ),
      accentDark: Color(
        0xFF8A6B22,
      ),
    ),

    _WelcomeObjective(
      name: 'Rotina',
      description: 'Planeje seus dias, organize tarefas e transforme ideias em ação.',
      icon: Icons.calendar_month_outlined,
      accent: Color(
        0xFFDDE8FF,
      ),
      accentDark: Color(
        0xFF46649A,
      ),
    ),

    _WelcomeObjective(
      name: 'Evolução',
      description: 'Veja seu progresso e acompanhe o que mudou ao longo do tempo.',
      icon: Icons.trending_up_rounded,
      accent: Color(
        0xFFE6DEFF,
      ),
      accentDark: Color(
        0xFF66539B,
      ),
    ),
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _profileRepository = ProfileRepository();

    unawaited(
      _loadProfile(),
    );

    _introTimer = Timer(
      const Duration(
        milliseconds: 1250,
      ),
      () {
        if (!mounted) {
          return;
        }

        setState(
          () {
            _showOptions = true;
          },
        );
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _introTimer?.cancel();

    super.dispose();
  }

  // ============================================================
  // LOAD PROFILE
  // ============================================================

  Future<
    void
  >
  _loadProfile() async {
    try {
      final profile = await _profileRepository.getCurrentProfile();

      if (!mounted) {
        return;
      }

      setState(
        () {
          _profile = profile;

          _loadingProfile = false;

          _profileError = null;
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[WELCOME] Erro ao carregar perfil: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _loadingProfile = false;

          _profileError = error.toString();
        },
      );
    }
  }

  // ============================================================
  // DISPLAY NAME
  // ============================================================

  String get _displayName {
    final name = _profile?.fullName.trim();

    if (name ==
            null ||
        name.isEmpty) {
      return 'Usuário';
    }

    return name;
  }

  String get _firstName {
    final displayName = _displayName.trim();

    if (displayName.isEmpty) {
      return 'Usuário';
    }

    return displayName
        .split(
          RegExp(
            r'\s+',
          ),
        )
        .first;
  }

  // ============================================================
  // OPEN OBJECTIVE
  // ============================================================

  void _openObjective(
    String name,
  ) {
    final Widget? page = switch (name) {
      'Estudar' => const StudyScreen(),

      'Treinar' => const TrainingScreen(),

      'Financeiro' => const FinanceScreen(),

      'Rotina' => const RoutineScreen(),

      'Evolução' => EvolutionScreen(
        controller: widget.controller,
      ),

      _ => null,
    };

    if (page ==
        null) {
      return;
    }

    Navigator.of(
      context,
    ).push(
      MaterialPageRoute<
        void
      >(
        builder:
            (
              _,
            ) {
              return page;
            },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,

      body: SafeArea(
        child: Stack(
          children: [
            // ==================================================
            // BACKGROUND DECORATION
            // ==================================================
            const Positioned(
              top: -170,
              right: -120,
              child: _BackgroundGlow(
                size: 430,
              ),
            ),

            const Positioned(
              bottom: -210,
              left: -170,
              child: _BackgroundGlow(
                size: 390,
                opacity: 0.22,
              ),
            ),

            // ==================================================
            // INTRO
            // ==================================================
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _showOptions,

                child: AnimatedOpacity(
                  opacity: _showOptions
                      ? 0
                      : 1,

                  duration: const Duration(
                    milliseconds: 520,
                  ),

                  curve: Curves.easeOutCubic,

                  child: AnimatedSlide(
                    offset: _showOptions
                        ? const Offset(
                            0,
                            -0.05,
                          )
                        : Offset.zero,

                    duration: const Duration(
                      milliseconds: 650,
                    ),

                    curve: Curves.easeInOutCubic,

                    child: Center(
                      child: _buildGreeting(),
                    ),
                  ),
                ),
              ),
            ),

            // ==================================================
            // MAIN CONTENT
            // ==================================================
            Positioned.fill(
              child: IgnorePointer(
                ignoring: !_showOptions,

                child: AnimatedOpacity(
                  opacity: _showOptions
                      ? 1
                      : 0,

                  duration: const Duration(
                    milliseconds: 540,
                  ),

                  curve: Curves.easeOutCubic,

                  child: AnimatedSlide(
                    offset: _showOptions
                        ? Offset.zero
                        : const Offset(
                            0,
                            0.055,
                          ),

                    duration: const Duration(
                      milliseconds: 680,
                    ),

                    curve: Curves.easeOutCubic,

                    child: _buildMainContent(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // GREETING
  // ============================================================

  Widget _buildGreeting() {
    if (_loadingProfile) {
      return const SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: _primaryDark,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,

        children: [
          // ====================================================
          // BRAND
          // ====================================================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),

            decoration: BoxDecoration(
              color: _surface.withValues(
                alpha: 0.80,
              ),

              borderRadius: BorderRadius.circular(
                999,
              ),

              border: Border.all(
                color: _border,
              ),
            ),

            child: const Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                _LeafMark(
                  size: 16,
                ),

                SizedBox(
                  width: 7,
                ),

                Text(
                  'EVRYLUX',
                  style: TextStyle(
                    color: _text,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 26,
          ),

          // ====================================================
          // GREETING
          // ====================================================
          Text(
            'Olá, $_firstName',
            textAlign: TextAlign.center,

            style: const TextStyle(
              color: _text,
              fontSize: 38,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),

          const SizedBox(
            height: 9,
          ),

          const Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              Text(
                'Bom ter você aqui',
                style: TextStyle(
                  color: _muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              SizedBox(
                width: 5,
              ),

              Text(
                '👋',
                style: TextStyle(
                  fontSize: 17,
                ),
              ),
            ],
          ),

          if (_profileError !=
              null) ...[
            const SizedBox(
              height: 18,
            ),

            TextButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
              ),
              label: const Text(
                'Tentar carregar nome novamente',
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent() {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            final compact =
                constraints.maxHeight <
                760;

            final veryCompact =
                constraints.maxHeight <
                650;

            final horizontalPadding =
                constraints.maxWidth <
                    700
                ? 18.0
                : 32.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 860,
                ),

                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact
                        ? 28
                        : 42,
                    horizontalPadding,
                    compact
                        ? 18
                        : 28,
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      // ==================================================
                      // TOP BAR
                      // ==================================================
                      _buildTopBar(
                        compact: compact,
                      ),

                      SizedBox(
                        height: compact
                            ? 26
                            : 34,
                      ),

                      // ==================================================
                      // HEADER
                      // ==================================================
                      _buildContentHeader(
                        compact: compact,
                      ),

                      SizedBox(
                        height: compact
                            ? 20
                            : 28,
                      ),

                      // ==================================================
                      // CARDS
                      // ==================================================
                      Expanded(
                        child: Column(
                          children: [
                            for (
                              var index = 0;
                              index <
                                  _objectives.length;
                              index++
                            ) ...[
                              Expanded(
                                child: _AnimatedObjectiveEntrance(
                                  index: index,
                                  active: _showOptions,
                                  child: _WelcomeObjectiveCard(
                                    objective: _objectives[index],
                                    compact: compact,
                                    veryCompact: veryCompact,
                                    onTap: () {
                                      _openObjective(
                                        _objectives[index].name,
                                      );
                                    },
                                  ),
                                ),
                              ),

                              if (index <
                                  _objectives.length -
                                      1)
                                SizedBox(
                                  height: compact
                                      ? 7
                                      : 10,
                                ),
                            ],
                          ],
                        ),
                      ),

                      if (!veryCompact) ...[
                        const SizedBox(
                          height: 16,
                        ),

                        _buildFooter(),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar({
    required bool compact,
  }) {
    return Row(
      children: [
        const _LeafMark(
          size: 20,
        ),

        const SizedBox(
          width: 8,
        ),

        const Text(
          'EVRYLUX',
          style: TextStyle(
            color: _text,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),

        const Spacer(),

        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact
                ? 10
                : 12,
            vertical: compact
                ? 6
                : 7,
          ),

          decoration: BoxDecoration(
            color: _surfaceSoft,

            borderRadius: BorderRadius.circular(
              999,
            ),

            border: Border.all(
              color: _border,
            ),
          ),

          child: Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              Container(
                width: 7,
                height: 7,

                decoration: const BoxDecoration(
                  color: Color(
                    0xFF5EA75A,
                  ),
                  shape: BoxShape.circle,
                ),
              ),

              const SizedBox(
                width: 7,
              ),

              Text(
                _firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  color: _muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTENT HEADER
  // ============================================================

  Widget _buildContentHeader({
    required bool compact,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 5,
          ),

          decoration: BoxDecoration(
            color: _primary.withValues(
              alpha: 0.43,
            ),

            borderRadius: BorderRadius.circular(
              8,
            ),
          ),

          child: const Text(
            'SEU ESPAÇO DE EVOLUÇÃO',
            style: TextStyle(
              color: _primaryDark,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),

        SizedBox(
          height: compact
              ? 8
              : 11,
        ),

        Text(
          'O que você quer desenvolver hoje?',
          style: TextStyle(
            color: _text,
            fontSize: compact
                ? 24
                : 29,
            height: 1.10,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),

        SizedBox(
          height: compact
              ? 5
              : 7,
        ),

        Text(
          'Escolha uma área para continuar sua evolução.',
          style: TextStyle(
            color: _muted,
            fontSize: compact
                ? 11.5
                : 12.5,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return const Row(
      children: [
        Icon(
          Icons.auto_awesome_outlined,
          color: _mutedSoft,
          size: 13,
        ),

        SizedBox(
          width: 6,
        ),

        Text(
          'Pequenos avanços também contam.',
          style: TextStyle(
            color: _mutedSoft,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// OBJECTIVE MODEL
// ============================================================

class _WelcomeObjective {
  const _WelcomeObjective({
    required this.name,
    required this.description,
    required this.icon,
    required this.accent,
    required this.accentDark,
  });

  final String name;

  final String description;

  final IconData icon;

  final Color accent;

  final Color accentDark;
}

// ============================================================
// OBJECTIVE CARD
// ============================================================

class _WelcomeObjectiveCard
    extends
        StatefulWidget {
  const _WelcomeObjectiveCard({
    required this.objective,
    required this.compact,
    required this.veryCompact,
    required this.onTap,
  });

  final _WelcomeObjective objective;

  final bool compact;

  final bool veryCompact;

  final VoidCallback onTap;

  @override
  State<
    _WelcomeObjectiveCard
  >
  createState() => _WelcomeObjectiveCardState();
}

class _WelcomeObjectiveCardState
    extends
        State<
          _WelcomeObjectiveCard
        > {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _border = Color(
    0xFFDCE7DB,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  bool _hovered = false;

  @override
  Widget build(
    BuildContext context,
  ) {
    final objective = widget.objective;

    return MouseRegion(
      cursor: SystemMouseCursors.click,

      onEnter:
          (
            _,
          ) {
            setState(
              () {
                _hovered = true;
              },
            );
          },

      onExit:
          (
            _,
          ) {
            setState(
              () {
                _hovered = false;
              },
            );
          },

      child: AnimatedScale(
        duration: const Duration(
          milliseconds: 160,
        ),

        curve: Curves.easeOutCubic,

        scale: _hovered
            ? 1.008
            : 1,

        child: AnimatedContainer(
          duration: const Duration(
            milliseconds: 180,
          ),

          curve: Curves.easeOutCubic,

          decoration: BoxDecoration(
            color: _surface,

            borderRadius: BorderRadius.circular(
              18,
            ),

            border: Border.all(
              color: _hovered
                  ? objective.accentDark.withValues(
                      alpha: 0.28,
                    )
                  : _border,
            ),

            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: objective.accentDark.withValues(
                        alpha: 0.07,
                      ),
                      blurRadius: 24,
                      offset: const Offset(
                        0,
                        8,
                      ),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(
                        0x09000000,
                      ),
                      blurRadius: 12,
                      offset: Offset(
                        0,
                        4,
                      ),
                    ),
                  ],
          ),

          child: Material(
            color: Colors.transparent,

            child: InkWell(
              onTap: widget.onTap,

              borderRadius: BorderRadius.circular(
                18,
              ),

              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact
                      ? 15
                      : 18,

                  vertical: widget.veryCompact
                      ? 7
                      : widget.compact
                      ? 10
                      : 13,
                ),

                child: Row(
                  children: [
                    // ============================================
                    // ICON
                    // ============================================
                    AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 180,
                      ),

                      width: widget.veryCompact
                          ? 38
                          : widget.compact
                          ? 42
                          : 46,

                      height: widget.veryCompact
                          ? 38
                          : widget.compact
                          ? 42
                          : 46,

                      decoration: BoxDecoration(
                        color: objective.accent,

                        borderRadius: BorderRadius.circular(
                          widget.compact
                              ? 12
                              : 14,
                        ),
                      ),

                      child: Icon(
                        objective.icon,

                        color: objective.accentDark,

                        size: widget.veryCompact
                            ? 18
                            : widget.compact
                            ? 20
                            : 22,
                      ),
                    ),

                    SizedBox(
                      width: widget.compact
                          ? 13
                          : 16,
                    ),

                    // ============================================
                    // TEXT
                    // ============================================
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            objective.name,

                            style: TextStyle(
                              color: _text,

                              fontSize: widget.veryCompact
                                  ? 13.5
                                  : widget.compact
                                  ? 14.5
                                  : 15.5,

                              height: 1.15,

                              fontWeight: FontWeight.w900,

                              letterSpacing: -0.15,
                            ),
                          ),

                          if (!widget.veryCompact) ...[
                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              objective.description,

                              maxLines: 1,

                              overflow: TextOverflow.ellipsis,

                              style: TextStyle(
                                color: _muted,

                                fontSize: widget.compact
                                    ? 10.5
                                    : 11.5,

                                height: 1.3,

                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(
                      width: widget.compact
                          ? 10
                          : 14,
                    ),

                    // ============================================
                    // ARROW
                    // ============================================
                    AnimatedContainer(
                      duration: const Duration(
                        milliseconds: 180,
                      ),

                      width: 31,

                      height: 31,

                      decoration: BoxDecoration(
                        color: _hovered
                            ? objective.accent
                            : const Color(
                                0xFFF5F7F5,
                              ),

                        shape: BoxShape.circle,
                      ),

                      child: Icon(
                        Icons.arrow_forward_rounded,

                        size: 16,

                        color: _hovered
                            ? objective.accentDark
                            : _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ENTRANCE ANIMATION
// ============================================================

class _AnimatedObjectiveEntrance
    extends
        StatefulWidget {
  const _AnimatedObjectiveEntrance({
    required this.index,
    required this.active,
    required this.child,
  });

  final int index;

  final bool active;

  final Widget child;

  @override
  State<
    _AnimatedObjectiveEntrance
  >
  createState() => _AnimatedObjectiveEntranceState();
}

class _AnimatedObjectiveEntranceState
    extends
        State<
          _AnimatedObjectiveEntrance
        > {
  bool _visible = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _schedule();
  }

  @override
  void didUpdateWidget(
    covariant _AnimatedObjectiveEntrance oldWidget,
  ) {
    super.didUpdateWidget(
      oldWidget,
    );

    if (widget.active &&
        !oldWidget.active) {
      _schedule();
    }
  }

  void _schedule() {
    if (!widget.active) {
      _visible = false;

      return;
    }

    _timer?.cancel();

    _timer = Timer(
      Duration(
        milliseconds:
            90 +
            (widget.index *
                55),
      ),
      () {
        if (!mounted) {
          return;
        }

        setState(
          () {
            _visible = true;
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedOpacity(
      duration: const Duration(
        milliseconds: 360,
      ),

      curve: Curves.easeOutCubic,

      opacity: _visible
          ? 1
          : 0,

      child: AnimatedSlide(
        duration: const Duration(
          milliseconds: 420,
        ),

        curve: Curves.easeOutCubic,

        offset: _visible
            ? Offset.zero
            : const Offset(
                0,
                0.10,
              ),

        child: widget.child,
      ),
    );
  }
}

// ============================================================
// BACKGROUND GLOW
// ============================================================

class _BackgroundGlow
    extends
        StatelessWidget {
  const _BackgroundGlow({
    required this.size,
    this.opacity = 0.30,
  });

  final double size;

  final double opacity;

  @override
  Widget build(
    BuildContext context,
  ) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,

        decoration: BoxDecoration(
          shape: BoxShape.circle,

          gradient: RadialGradient(
            colors: [
              const Color(
                0xFFB8EFB0,
              ).withValues(
                alpha: opacity,
              ),

              const Color(
                0xFFB8EFB0,
              ).withValues(
                alpha: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LEAF MARK
// ============================================================

class _LeafMark
    extends
        StatelessWidget {
  const _LeafMark({
    required this.size,
  });

  final double size;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Transform.rotate(
      angle: -0.38,

      child: Container(
        width: size,
        height:
            size *
            0.72,

        decoration: const BoxDecoration(
          color: Color(
            0xFF69B964,
          ),

          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(
              20,
            ),
            bottomRight: Radius.circular(
              20,
            ),
            topRight: Radius.circular(
              5,
            ),
            bottomLeft: Radius.circular(
              5,
            ),
          ),
        ),
      ),
    );
  }
}
