part of '../brain_screen.dart';

// Presentation-only helpers for the Brain screen shell.
extension _BrainScreenLayout on _BrainScreenState {
  // ============================================================
  // CATEGORY BUTTON
  // ============================================================

  Widget _buildTypeButton({required BrainConceptType type}) {
    return Tooltip(
      message: type.label,
      child: IconButton(
        onPressed: _controller.isSaving
            ? null
            : () {
                _openTypeScreen(type);
              },
        icon: Icon(type.icon, size: 20, color: type.color),
      ),
    );
  }


  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 58,
      titleSpacing: 18,
      title: const Row(
        children: [
          Icon(Icons.psychology_alt_outlined, size: 22),
          SizedBox(width: 9),
          Text('Cérebro'),
        ],
      ),
      actions: [
        Tooltip(
          message: 'Novo conhecimento',
          child: IconButton(
            onPressed: _controller.isSaving ? null : _showCreateNoteDialog,
            icon: const Icon(Icons.add_rounded),
          ),
        ),

        Container(
          width: 1,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 18),
          color: Theme.of(context).dividerColor.withValues(alpha: 0.40),
        ),

        _buildTypeButton(type: BrainConceptType.concept),

        _buildTypeButton(type: BrainConceptType.question),

        _buildTypeButton(type: BrainConceptType.example),

        _buildTypeButton(type: BrainConceptType.warning),

        const SizedBox(width: 10),
      ],
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
            child: Align(
              alignment: const Alignment(0, -0.30),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_brainVisualReady &&
                        _brainVisualController != null) ...[
                      Center(
                        child: EvolvingBrain(
                          controller: _brainVisualController!,
                          size: 172,
                          config: const BrainVisualConfig(
                            birthDuration: Duration(milliseconds: 7200),
                            branchGrowthDuration: Duration(milliseconds: 1900),
                            branchSettleDuration: Duration(milliseconds: 380),
                            searchPulseDuration: Duration(milliseconds: 2500),
                          ),
                          onBirthCompleted: _onBrainBirthCompleted,
                        ),
                      ),

                      const SizedBox(height: 14),
                    ],

                    _buildSearchField(context),

                    if (_searchQuery.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),

                      _buildSearchResults(context),
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
