part of '../brain_screen.dart';

// ============================================================
// BRAIN DASHBOARD OPENING LOCK
// ============================================================
//
// Impede que múltiplas instâncias da Dashboard sejam abertas
// quando o usuário clica rapidamente no botão "Meu Brain".
//
// ============================================================

final Expando<
  bool
>
_brainDashboardOpeningLock =
    Expando<
      bool
    >(
      'brainDashboardOpeningLock',
    );

// Presentation-only helpers for the Brain screen shell.
extension _BrainScreenLayout
    on
        _BrainScreenState {
  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
  ) {
    return AppBar(
      toolbarHeight: 58,
      titleSpacing: 18,

      // ========================================================
      // TÍTULO
      // ========================================================
      title: const Text(
        'Cérebro',
      ),

      actions: [
        // ======================================================
        // CRIAÇÃO RÁPIDA
        // ======================================================
        BrainAddKnowledgeButton(
          isSaving: _controller.isSaving,
          onPressed: _showCreateNoteDialog,
        ),

        Container(
          width: 1,
          height: 22,
          margin: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 18,
          ),
          color:
              Theme.of(
                context,
              ).dividerColor.withValues(
                alpha: 0.40,
              ),
        ),

        // ======================================================
        // MEU BRAIN
        // ======================================================
        Tooltip(
          message: 'Meu Brain',
          child: IconButton(
            onPressed: _isBrainDashboardOpening
                ? null
                : () {
                    _showBrainDashboard();
                  },
            icon: const Icon(
              Icons.psychology_alt_outlined,
              size: 22,
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),
      ],
    );
  }

  // ============================================================
  // DASHBOARD OPENING STATE
  // ============================================================

  bool get _isBrainDashboardOpening {
    return _brainDashboardOpeningLock[this] ??
        false;
  }

  void _setBrainDashboardOpening(
    bool value,
  ) {
    _brainDashboardOpeningLock[this] = value;

    if (mounted) {
      _mutateState(
        () {},
      );
    }
  }

  // ============================================================
  // BRAIN DASHBOARD
  // ============================================================

  Future<
    void
  >
  _showBrainDashboard() async {
    // ==========================================================
    // BLOQUEAR ABERTURA DUPLICADA
    // ==========================================================

    if (!mounted ||
        _controller.isSaving ||
        _isBrainDashboardOpening) {
      return;
    }

    _setBrainDashboardOpening(
      true,
    );

    try {
      // ========================================================
      // CARREGAR CONTAGENS REAIS
      // ========================================================

      final results =
          await Future.wait<
            List<
              BrainConcept
            >
          >(
            [
              _controller.loadConceptsByType(
                BrainConceptType.concept,
              ),
              _controller.loadConceptsByType(
                BrainConceptType.question,
              ),
            ],
          );

      if (!mounted) {
        return;
      }

      final int conceptCount = results[0].length;
      final int questionCount = results[1].length;

      // ========================================================
      // ABRIR DASHBOARD
      // ========================================================

      await showDialog<
        void
      >(
        context: context,
        barrierDismissible: true,
        builder:
            (
              dialogContext,
            ) {
              return Dialog(
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                clipBehavior: Clip.antiAlias,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                    maxHeight: 680,
                  ),
                  child: _buildBrainDashboardContent(
                    dialogContext,
                    conceptCount: conceptCount,
                    questionCount: questionCount,
                  ),
                ),
              );
            },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'BrainScreen: erro ao abrir Meu Brain: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    } finally {
      // ========================================================
      // LIBERAR NOVA ABERTURA
      // ========================================================

      if (mounted) {
        _setBrainDashboardOpening(
          false,
        );
      } else {
        _brainDashboardOpeningLock[this] = false;
      }
    }
  }

  // ============================================================
  // DASHBOARD CONTENT
  // ============================================================

  Widget _buildBrainDashboardContent(
    BuildContext dialogContext, {
    required int conceptCount,
    required int questionCount,
  }) {
    return Material(
      color: Theme.of(
        dialogContext,
      ).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          20,
          24,
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==================================================
            // HEADER
            // ==================================================
            Row(
              children: [
                Icon(
                  Icons.psychology_alt_outlined,
                  size: 25,
                  color: Theme.of(
                    dialogContext,
                  ).colorScheme.primary,
                ),

                const SizedBox(
                  width: 10,
                ),

                Expanded(
                  child: Text(
                    'Meu Brain',
                    style:
                        Theme.of(
                          dialogContext,
                        ).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),

                IconButton(
                  tooltip: 'Fechar',
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // VISÃO GERAL
            // ==================================================
            Text(
              'Visão geral',
              style:
                  Theme.of(
                    dialogContext,
                  ).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),

            const SizedBox(
              height: 10,
            ),

            Row(
              children: [
                // ==============================================
                // CONCEITOS
                // ==============================================
                Expanded(
                  child: _buildBrainDashboardMetric(
                    context: dialogContext,
                    value: conceptCount,
                    label: 'conceitos',
                    icon: BrainConceptType.concept.icon,
                    color: BrainConceptType.concept.color,
                  ),
                ),

                const SizedBox(
                  width: 10,
                ),

                // ==============================================
                // PERGUNTAS
                // ==============================================
                Expanded(
                  child: _buildBrainDashboardMetric(
                    context: dialogContext,
                    value: questionCount,
                    label: 'perguntas',
                    icon: BrainConceptType.question.icon,
                    color: BrainConceptType.question.color,
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 20,
            ),

            const Divider(
              height: 1,
            ),

            const SizedBox(
              height: 20,
            ),

            // ==================================================
            // EXPLORAR + ATALHOS
            // ==================================================
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Explorar',
                    style:
                        Theme.of(
                          dialogContext,
                        ).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),

                // ==============================================
                // CONCEITO
                // ==============================================
                _buildBrainDashboardTypeShortcut(
                  context: dialogContext,
                  type: BrainConceptType.concept,
                ),

                // ==============================================
                // PERGUNTA
                // ==============================================
                _buildBrainDashboardTypeShortcut(
                  context: dialogContext,
                  type: BrainConceptType.question,
                ),

                // ==============================================
                // EXEMPLO
                // ==============================================
                _buildBrainDashboardTypeShortcut(
                  context: dialogContext,
                  type: BrainConceptType.example,
                ),

                // ==============================================
                // ATENÇÃO
                // ==============================================
                _buildBrainDashboardTypeShortcut(
                  context: dialogContext,
                  type: BrainConceptType.warning,
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            // ==================================================
            // MAPA DO CONHECIMENTO
            // ==================================================
            _buildBrainDashboardAction(
              context: dialogContext,
              icon: Icons.hub_outlined,
              iconColor: Theme.of(
                dialogContext,
              ).colorScheme.primary,
              title: 'Mapa do conhecimento',
              subtitle: 'Explore visualmente o seu Brain',
              onTap: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                _focusBrainVisual();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD TYPE SHORTCUT
  // ============================================================

  Widget _buildBrainDashboardTypeShortcut({
    required BuildContext context,
    required BrainConceptType type,
  }) {
    return Tooltip(
      message: type.label,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
        padding: const EdgeInsets.all(
          5,
        ),
        onPressed: _controller.isSaving
            ? null
            : () {
                Navigator.of(
                  context,
                ).pop();

                _openTypeScreen(
                  type,
                );
              },
        icon: Icon(
          type.icon,
          size: 18,
          color: type.color,
        ),
      ),
    );
  }

  // ============================================================
  // DASHBOARD METRIC
  // ============================================================
  //
  // Versão compacta dos cards da "Visão geral".
  //
  // Antes:
  // - padding 16
  // - ícone 38 x 38
  // - número titleLarge
  //
  // Agora:
  // - padding vertical 10
  // - ícone 30 x 30
  // - número 18
  //
  // ============================================================

  Widget _buildBrainDashboardMetric({
    required BuildContext context,
    required int value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          // ====================================================
          // ÍCONE COMPACTO
          // ====================================================
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                8,
              ),
            ),
            child: Icon(
              icon,
              size: 17,
              color: color,
            ),
          ),

          const SizedBox(
            width: 9,
          ),

          // ====================================================
          // NÚMERO + LABEL
          // ====================================================
          Expanded(
            child: Row(
              children: [
                Text(
                  '$value',
                  style:
                      Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                ),

                const SizedBox(
                  width: 6,
                ),

                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
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
  // DASHBOARD ACTION
  // ============================================================

  Widget _buildBrainDashboardAction({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(
        12,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          12,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: iconColor.withValues(
                    alpha: 0.09,
                  ),
                  borderRadius: BorderRadius.circular(
                    9,
                  ),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: iconColor,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),

                    if (subtitle !=
                        null) ...[
                      const SizedBox(
                        height: 2,
                      ),

                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAPA DO CONHECIMENTO
  // ============================================================

  void _focusBrainVisual() {
    // Implementação futura do mapa do conhecimento.
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight -
                      48,
                ),
                child: Align(
                  alignment: const Alignment(
                    0,
                    -0.30,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 760,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_brainVisualReady &&
                            _brainVisualController !=
                                null) ...[
                          Center(
                            child: EvolvingBrain(
                              controller: _brainVisualController!,
                              size: 172,
                              config: const BrainVisualConfig(
                                birthDuration: Duration(
                                  milliseconds: 7200,
                                ),
                                branchGrowthDuration: Duration(
                                  milliseconds: 1900,
                                ),
                                branchSettleDuration: Duration(
                                  milliseconds: 380,
                                ),
                                searchPulseDuration: Duration(
                                  milliseconds: 2500,
                                ),
                              ),
                              onBirthCompleted: _onBrainBirthCompleted,
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),
                        ],

                        // ==================================================
                        // BUSCA
                        // ==================================================
                        _buildSearchField(
                          context,
                        ),

                        if (_searchQuery.trim().isNotEmpty) ...[
                          const SizedBox(
                            height: 12,
                          ),

                          _buildSearchResults(
                            context,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
    );
  }
}
