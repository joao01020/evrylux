import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// BRAIN SEARCH HELP DIALOG
// ============================================================
//
// Modal de ajuda da busca natural.
//
// OBJETIVO:
//
// Ensinar COMO pesquisar sem transformar os próprios modelos
// em conteúdo pesquisável.
//
// REGRA VISUAL:
//
// modelos terminados em:
//
// …
//
// ainda precisam ser completados.
//
// Exemplo visual:
//
// perguntas sobre…
//
// Texto realmente enviado para o campo:
//
// perguntas sobre
//
// O caractere "…" é apenas uma indicação visual.
//
// Pesquisas que já são completas não recebem reticências:
//
// o que estudei ontem
//
// Dessa forma o usuário consegue distinguir imediatamente:
//
// - estruturas que precisam de complemento;
// - consultas que já podem ser executadas.
//
// ============================================================

class BrainSearchHelpDialog
    extends
        StatefulWidget {
  const BrainSearchHelpDialog({
    super.key,
    required this.onUseExample,
  });

  final ValueChanged<
    String
  >
  onUseExample;

  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    void
  >
  show({
    required BuildContext context,
    required ValueChanged<
      String
    >
    onUseExample,
  }) {
    return showDialog<
      void
    >(
      context: context,
      barrierDismissible: true,
      builder:
          (
            dialogContext,
          ) {
            return BrainSearchHelpDialog(
              onUseExample: onUseExample,
            );
          },
    );
  }

  @override
  State<
    BrainSearchHelpDialog
  >
  createState() {
    return _BrainSearchHelpDialogState();
  }
}

// ============================================================
// STATE
// ============================================================

class _BrainSearchHelpDialogState
    extends
        State<
          BrainSearchHelpDialog
        > {
  // ============================================================
  // EXPANDED SECTION
  // ============================================================
  //
  // null:
  // todas as seções ficam recolhidas.
  //
  // int:
  // somente a seção correspondente fica aberta.
  //
  // ============================================================

  int? _expandedSectionIndex;

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

    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 680,
          maxHeight: 720,
        ),
        child: Material(
          color: colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  18,
                  12,
                  14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Como pesquisar no Cérebro',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            'Use os modelos abaixo como ponto de partida.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(
                height: 1,
                color: theme.dividerColor.withValues(
                  alpha: 0.45,
                ),
              ),

              // ==================================================
              // CONTENT
              // ==================================================
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ==========================================
                      // REGRA GERAL
                      // ==========================================
                      _buildIntroCard(
                        context,
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      // ==========================================
                      // SEÇÕES
                      // ==========================================
                      for (
                        var index = 0;
                        index <
                            _sections.length;
                        index++
                      ) ...[
                        _buildSection(
                          context: context,
                          section: _sections[index],
                          index: index,
                          expanded:
                              _expandedSectionIndex ==
                              index,
                        ),

                        if (index !=
                            _sections.length -
                                1)
                          const SizedBox(
                            height: 8,
                          ),
                      ],
                    ],
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
  // INTRO
  // ============================================================
  //
  // Uma única explicação para todo o modal.
  //
  // Evita repetir:
  //
  // "complete com..."
  //
  // dentro de cada categoria.
  //
  // ============================================================

  Widget _buildIntroCard(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(
          alpha: 0.20,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: colorScheme.primary,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Text(
              'Os modelos definem como pesquisar. '
              'Quando houver “…”, complete com o que estiver faltando. '
              'A pesquisa só começa quando a estrutura estiver completa.',
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _buildSection({
    required BuildContext context,
    required _SearchHelpSection section,
    required int index,
    required bool expanded,
  }) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(
          alpha: 0.45,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.55,
          ),
        ),
      ),
      child: Column(
        children: [
          // ====================================================
          // SECTION HEADER
          // ====================================================
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(
                12,
              ),
              onTap: () {
                setState(
                  () {
                    if (expanded) {
                      _expandedSectionIndex = null;
                    } else {
                      _expandedSectionIndex = index;
                    }
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      section.icon,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          const SizedBox(
                            height: 2,
                          ),

                          Text(
                            section.description,
                            maxLines: expanded
                                ? 2
                                : 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    AnimatedRotation(
                      turns: expanded
                          ? 0.5
                          : 0,
                      duration: const Duration(
                        milliseconds: 180,
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // EXPANDED CONTENT
          // ====================================================
          AnimatedCrossFade(
            duration: const Duration(
              milliseconds: 180,
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                0,
                10,
                10,
              ),
              child: Column(
                children: [
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant.withValues(
                      alpha: 0.45,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  for (
                    var exampleIndex = 0;
                    exampleIndex <
                        section.examples.length;
                    exampleIndex++
                  ) ...[
                    _buildExampleCard(
                      context: context,
                      example: section.examples[exampleIndex],
                    ),

                    if (exampleIndex !=
                        section.examples.length -
                            1)
                      const SizedBox(
                        height: 7,
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXAMPLE CARD
  // ============================================================

  Widget _buildExampleCard({
    required BuildContext context,
    required _SearchHelpExample example,
  }) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        8,
        7,
        8,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(
          alpha: 0.70,
        ),
        borderRadius: BorderRadius.circular(
          10,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.60,
          ),
        ),
      ),
      child: Row(
        children: [
          // ====================================================
          // MODELO
          // ====================================================
          Expanded(
            child: SelectableText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: example.text,
                  ),

                  if (example.requiresCompletion)
                    TextSpan(
                      text: '…',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          // ====================================================
          // COPIAR
          // ====================================================
          //
          // Copiamos somente o texto real.
          //
          // As reticências NÃO fazem parte da consulta.
          //
          // ====================================================
          IconButton(
            tooltip: 'Copiar',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(
              minWidth: 34,
              minHeight: 34,
            ),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: example.text,
                ),
              );

              if (!context.mounted) {
                return;
              }

              ScaffoldMessenger.of(
                  context,
                )
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Modelo copiado.',
                    ),
                    duration: Duration(
                      seconds: 1,
                    ),
                  ),
                );
            },
            icon: const Icon(
              Icons.copy_rounded,
              size: 17,
            ),
          ),

          const SizedBox(
            width: 2,
          ),

          // ====================================================
          // USAR
          // ====================================================
          //
          // Modelo incompleto:
          //
          // "perguntas sobre"
          //
          // enviamos:
          //
          // "perguntas sobre "
          //
          // para o cursor ficar pronto para o complemento.
          //
          // ----------------------------------------------------
          //
          // Pesquisa completa:
          //
          // "o que estudei ontem"
          //
          // enviamos exatamente a consulta.
          //
          // ====================================================
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).pop();

              final query = example.requiresCompletion
                  ? '${example.text} '
                  : example.text;

              widget.onUseExample(
                query,
              );
            },
            icon: const Icon(
              Icons.north_west_rounded,
              size: 15,
            ),
            label: const Text(
              'Usar',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DATA
  // ============================================================
  //
  // requiresCompletion = true
  //
  // Significa que aquele modelo NÃO é uma pesquisa completa.
  //
  // Visualmente mostramos:
  //
  // …
  //
  // mas isso nunca é enviado para o campo.
  //
  // ------------------------------------------------------------
  //
  // requiresCompletion = false
  //
  // A frase já possui informação suficiente para pesquisar.
  //
  // ============================================================

  static const List<
    _SearchHelpSection
  >
  _sections = [
    // ==========================================================
    // BUSCA SIMPLES
    // ==========================================================
    _SearchHelpSection(
      title: 'Busca simples',
      description: 'Procure por qualquer assunto.',
      icon: Icons.search_rounded,
      examples: [
        _SearchHelpExample(
          text: 'algo sobre',
          requiresCompletion: true,
        ),
        _SearchHelpExample(
          text: 'onde eu falei de',
          requiresCompletion: true,
        ),
        _SearchHelpExample(
          text: 'aquele conteúdo sobre',
          requiresCompletion: true,
        ),
        _SearchHelpExample(
          text: 'a anotação que falava de',
          requiresCompletion: true,
        ),
      ],
    ),

    // ==========================================================
    // TIPOS
    // ==========================================================
    _SearchHelpSection(
      title: 'Tipos de conhecimento',
      description: 'Pesquise por um tipo específico.',
      icon: Icons.category_outlined,
      examples: [
        _SearchHelpExample(
          text: 'conceitos sobre',
          requiresCompletion: true,
        ),
        _SearchHelpExample(
          text: 'perguntas sobre',
          requiresCompletion: true,
        ),
        _SearchHelpExample(
          text: 'exemplos sobre',
          requiresCompletion: true,
        ),
        _SearchHelpExample(
          text: 'atenções sobre',
          requiresCompletion: true,
        ),
      ],
    ),

    // ==========================================================
    // DATAS
    // ==========================================================
    _SearchHelpSection(
      title: 'Datas',
      description: 'Procure pelo que registrou em um período.',
      icon: Icons.calendar_today_outlined,
      examples: [
        _SearchHelpExample(
          text: 'o que eu fiz no dia',
          requiresCompletion: true,
        ),

        // Já é uma pesquisa completa.
        _SearchHelpExample(
          text: 'o que estudei ontem',
        ),

        // Já é uma pesquisa completa.
        _SearchHelpExample(
          text: 'o que anotei essa semana',
        ),

        // Já é uma pesquisa completa.
        _SearchHelpExample(
          text: 'o que vi no mês passado',
        ),
      ],
    ),

    // ==========================================================
    // PERÍODOS DO DIA
    // ==========================================================
    _SearchHelpSection(
      title: 'Períodos do dia',
      description: 'Combine a pesquisa com manhã, tarde ou noite.',
      icon: Icons.schedule_rounded,
      examples: [
        // Completa.
        _SearchHelpExample(
          text: 'o que eu estudei de manhã',
        ),

        // Completa.
        _SearchHelpExample(
          text: 'o que fiz hoje à tarde',
        ),

        // Completa.
        _SearchHelpExample(
          text: 'o que anotei ontem à noite',
        ),

        // Precisa de uma data.
        _SearchHelpExample(
          text: 'o que anotei na manhã de',
          requiresCompletion: true,
        ),
      ],
    ),

    // ==========================================================
    // RECÊNCIA
    // ==========================================================
    _SearchHelpSection(
      title: 'Recência',
      description: 'Encontre o que viu mais recentemente.',
      icon: Icons.history_rounded,
      examples: [
        _SearchHelpExample(
          text: 'o que estudei recentemente sobre',
          requiresCompletion: true,
        ),
        _SearchHelpExample(
          text: 'minhas últimas anotações sobre',
          requiresCompletion: true,
        ),
        _SearchHelpExample(
          text: 'o que eu vi por último sobre',
          requiresCompletion: true,
        ),
      ],
    ),

    // ==========================================================
    // QUANTIDADE
    // ==========================================================
    _SearchHelpSection(
      title: 'Quantidade',
      description: 'Escolha quantos resultados deseja encontrar.',
      icon: Icons.format_list_numbered_rounded,
      examples: [
        // Precisa do assunto.
        _SearchHelpExample(
          text: 'me mostre 5 resultados sobre',
          requiresCompletion: true,
        ),

        // Precisa do assunto.
        _SearchHelpExample(
          text: 'me mostre 3 perguntas sobre',
          requiresCompletion: true,
        ),

        // Já é completa.
        _SearchHelpExample(
          text: 'mostre só 10 resultados',
        ),
      ],
    ),

    // ==========================================================
    // CONHECIMENTO ACUMULADO
    // ==========================================================
    _SearchHelpSection(
      title: 'Conhecimento acumulado',
      description: 'Consulte o que o seu Cérebro já possui.',
      icon: Icons.psychology_alt_outlined,
      examples: [
        _SearchHelpExample(
          text: 'o que eu já sei sobre',
          requiresCompletion: true,
        ),
        _SearchHelpExample(
          text: 'o que eu já aprendi sobre',
          requiresCompletion: true,
        ),
        _SearchHelpExample(
          text: 'o que eu já anotei sobre',
          requiresCompletion: true,
        ),
      ],
    ),
  ];
}

// ============================================================
// SEARCH HELP SECTION
// ============================================================

class _SearchHelpSection {
  const _SearchHelpSection({
    required this.title,
    required this.description,
    required this.icon,
    required this.examples,
  });

  final String title;

  final String description;

  final IconData icon;

  final List<
    _SearchHelpExample
  >
  examples;
}

// ============================================================
// SEARCH HELP EXAMPLE
// ============================================================
//
// Representa um modelo mostrado na interface.
//
// text:
//
// texto REAL que será copiado/enviado.
//
// requiresCompletion:
//
// true:
//
//   o modelo ainda precisa receber informação.
//
//   visualmente:
//   perguntas sobre…
//
//   realmente enviado:
//   perguntas sobre
//
// false:
//
//   a consulta já é completa.
//
//   exemplo:
//   o que estudei ontem
//
// ============================================================

class _SearchHelpExample {
  const _SearchHelpExample({
    required this.text,
    this.requiresCompletion = false,
  });

  final String text;

  final bool requiresCompletion;
}
