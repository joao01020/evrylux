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
    // O Dashboard agora abre imediatamente e não executa consultas
    // de contagem. Por enquanto, exibe somente a área "Explorar".
    if (!mounted ||
        _controller.isSaving ||
        _isBrainDashboardOpening) {
      return;
    }

    _setBrainDashboardOpening(
      true,
    );

    try {
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
    BuildContext dialogContext,
  ) {
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
            // EXPLORAR
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

                _buildBrainDashboardTypeShortcut(
                  context: dialogContext,
                  type: BrainConceptType.concept,
                ),

                _buildBrainDashboardTypeShortcut(
                  context: dialogContext,
                  type: BrainConceptType.question,
                ),

                _buildBrainDashboardTypeShortcut(
                  context: dialogContext,
                  type: BrainConceptType.example,
                ),

                _buildBrainDashboardTypeShortcut(
                  context: dialogContext,
                  type: BrainConceptType.warning,
                ),
              ],
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
