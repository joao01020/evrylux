import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ============================================================
// BRAIN SEARCH HELP DIALOG
// ============================================================
//
// Modal de ajuda da busca natural.
//
// Objetivos:
//
// - ensinar o usuário a pesquisar;
// - mostrar exemplos prontos;
// - permitir copiar a frase;
// - permitir usar a frase diretamente no campo de pesquisa.
//
// ============================================================

class BrainSearchHelpDialog extends StatelessWidget {
  const BrainSearchHelpDialog({
    super.key,
    required this.onUseExample,
  });

  final ValueChanged<String> onUseExample;

  // ============================================================
  // SHOW
  // ============================================================

  static Future<void> show({
    required BuildContext context,
    required ValueChanged<String> onUseExample,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return BrainSearchHelpDialog(
          onUseExample: onUseExample,
        );
      },
    );
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

    final colorScheme = theme.colorScheme;

    return Dialog(
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 760,
          maxHeight: 820,
        ),
        child: Column(
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
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(
                        alpha: 0.10,
                      ),
                      borderRadius: BorderRadius.circular(
                        12,
                      ),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.primary,
                    ),
                  ),

                  const SizedBox(
                    width: 12,
                  ),

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
                          'Use frases naturais. Você pode combinar assunto, tipo, data, recência e quantidade.',
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildIntroCard(
                      context,
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    for (
                      var index = 0;
                      index < _sections.length;
                      index++
                    ) ...[
                      _buildSection(
                        context: context,
                        section: _sections[index],
                      ),

                      if (
                        index !=
                        _sections.length - 1
                      )
                        const SizedBox(
                          height: 18,
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INTRO
  // ============================================================

  Widget _buildIntroCard(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(
          alpha: 0.24,
        ),
        borderRadius: BorderRadius.circular(
          14,
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
            Icons.lightbulb_outline_rounded,
            size: 19,
            color: colorScheme.primary,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Text(
              'Você não precisa decorar comandos. Escreva como falaria normalmente. '
              'Use “Copiar” para guardar um exemplo ou “Usar” para enviar a frase '
              'diretamente ao campo de pesquisa.',
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.45,
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              section.icon,
              size: 18,
            ),

            const SizedBox(
              width: 8,
            ),

            Text(
              section.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 4,
        ),

        Text(
          section.description,
          style: Theme.of(
            context,
          ).textTheme.bodySmall,
        ),

        const SizedBox(
          height: 10,
        ),

        for (
          var index = 0;
          index < section.examples.length;
          index++
        ) ...[
          _buildExampleCard(
            context: context,
            example: section.examples[index],
          ),

          if (
            index !=
            section.examples.length - 1
          )
            const SizedBox(
              height: 8,
            ),
        ],
      ],
    );
  }

  // ============================================================
  // EXAMPLE CARD
  // ============================================================

  Widget _buildExampleCard({
    required BuildContext context,
    required String example,
  }) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        8,
        10,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(
          alpha: 0.72,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.70,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              example,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          IconButton(
            tooltip: 'Copiar',
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text: example,
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
                      'Pesquisa copiada.',
                    ),
                    duration: Duration(
                      seconds: 1,
                    ),
                  ),
                );
            },
            icon: const Icon(
              Icons.copy_rounded,
              size: 18,
            ),
          ),

          const SizedBox(
            width: 2,
          ),

          FilledButton.tonalIcon(
            onPressed: () {
              Navigator.of(
                context,
              ).pop();

              onUseExample(
                example,
              );
            },
            icon: const Icon(
              Icons.north_west_rounded,
              size: 16,
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

  static const List<_SearchHelpSection> _sections = [
    _SearchHelpSection(
      title: 'Busca simples',
      description:
          'Procure pelo assunto mesmo sem lembrar o título exato.',
      icon: Icons.search_rounded,
      examples: [
        'onde eu falei de redis?',
        'algo sobre fila fifo',
        'aquele conteúdo sobre stack',
        'a anotação que falava de malloc',
      ],
    ),

    _SearchHelpSection(
      title: 'Tipos de conhecimento',
      description:
          'Peça diretamente conceitos, perguntas, exemplos ou atenções.',
      icon: Icons.category_outlined,
      examples: [
        'perguntas sobre C++',
        'exemplos sobre Flutter',
        'atenções sobre ponteiros',
        'conceitos sobre memória',
      ],
    ),

    _SearchHelpSection(
      title: 'Datas',
      description:
          'Use períodos relativos ou uma data específica.',
      icon: Icons.calendar_today_outlined,
      examples: [
        'o que eu fiz no dia 01/09/2026',
        'o que estudei ontem?',
        'o que anotei essa semana?',
        'o que vi no mês passado?',
      ],
    ),

    _SearchHelpSection(
      title: 'Períodos do dia',
      description:
          'Combine manhã, tarde ou noite com hoje, ontem ou uma data.',
      icon: Icons.schedule_rounded,
      examples: [
        'o que eu estudei de manhã?',
        'o que fiz hoje à tarde?',
        'o que anotei ontem à noite?',
        'o que anotei na manhã de 01/09/2026?',
      ],
    ),

    _SearchHelpSection(
      title: 'Recência',
      description:
          'Encontre o que você viu mais recentemente.',
      icon: Icons.history_rounded,
      examples: [
        'o que estudei recentemente sobre C++',
        'minhas últimas anotações sobre Linux',
        'o que eu vi por último sobre ponteiros',
      ],
    ),

    _SearchHelpSection(
      title: 'Quantidade',
      description:
          'Peça uma quantidade específica de resultados.',
      icon: Icons.format_list_numbered_rounded,
      examples: [
        'me mostre 5 perguntas sobre C++',
        'quais foram os 3 últimos exemplos sobre Flutter?',
        'mostre só 10 resultados',
      ],
    ),

    _SearchHelpSection(
      title: 'Conhecimento acumulado',
      description:
          'Consulte o que o seu Cérebro já possui sobre um assunto.',
      icon: Icons.psychology_alt_outlined,
      examples: [
        'o que eu já sei sobre filas?',
        'o que eu já sei sobre memória?',
        'o que eu já aprendi sobre TCP?',
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

  final List<String> examples;
}
