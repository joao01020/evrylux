import 'package:flutter/material.dart';

import '../../controllers/brain_visual_controller.dart';
import 'brain_growth_debug_panel.dart';

/// ============================================================
/// EVRYLUX — BRAIN VISUAL DEBUG SCREEN
/// ============================================================
///
/// Tela isolada para testar somente a evolução visual do cérebro.
///
/// Esta tela NÃO:
///
/// - cria conhecimento real;
/// - abre dialogs do Brain;
/// - salva conteúdo no Vault;
/// - sincroniza com Supabase;
/// - altera notas reais do usuário.
///
/// Serve somente para:
///
/// - testar nascimento;
/// - testar criação de novos ramos;
/// - testar evolução dos níveis;
/// - testar distribuição dos ramos;
/// - testar pesquisa/pulso;
/// - visualizar o estado extremo.
///
/// ============================================================

class BrainVisualDebugScreen
    extends
        StatefulWidget {
  const BrainVisualDebugScreen({
    super.key,
  });

  @override
  State<
    BrainVisualDebugScreen
  >
  createState() {
    return _BrainVisualDebugScreenState();
  }
}

class _BrainVisualDebugScreenState
    extends
        State<
          BrainVisualDebugScreen
        > {
  // ============================================================
  // CONTROLLER
  // ============================================================

  late final BrainVisualController _controller;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller = BrainVisualController(
      knowledgeCount: 0,

      // ========================================================
      // INTRO
      // ========================================================
      //
      // true:
      // abre diretamente com a silhueta pronta.
      //
      // false:
      // executa também a animação de nascimento.
      //
      // Como esta é uma tela de debug, deixamos true para
      // testar os ramos imediatamente.
      //
      // O botão "Repetir nascimento" continua disponível
      // dentro do painel.
      //
      // ========================================================
      introSeen: true,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ========================================================
      // APP BAR
      // ========================================================
      appBar: AppBar(
        titleSpacing: 20,

        title: const Text(
          'Brain Visual Debug',
        ),

        actions: [
          // ====================================================
          // RESET RÁPIDO
          // ====================================================
          IconButton(
            tooltip: 'Resetar cérebro',
            onPressed: () {
              _controller.resetGrowthState();
            },
            icon: const Icon(
              Icons.restart_alt_rounded,
            ),
          ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 820,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ============================================
                  // CABEÇALHO
                  // ============================================
                  _DebugHeader(
                    theme: theme,
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ============================================
                  // PAINEL PRINCIPAL
                  // ============================================
                  BrainGrowthDebugPanel(
                    controller: _controller,

                    // Mantemos próximo do tamanho usado
                    // na tela real do Brain.
                    brainSize: 190,

                    showBrain: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================
/// DEBUG HEADER
/// ============================================================

class _DebugHeader
    extends
        StatelessWidget {
  const _DebugHeader({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: theme.dividerColor.withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(
                alpha: 0.10,
              ),
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              Icons.science_outlined,
              size: 20,
              color: theme.colorScheme.primary,
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
                  'Ambiente de teste visual',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 4,
                ),

                Text(
                  'As alterações feitas aqui servem apenas para '
                  'testar o crescimento e a distribuição visual '
                  'do cérebro. Nenhum conhecimento real é criado.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(
                      alpha: 0.65,
                    ),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
