import 'package:flutter/material.dart';

class BrainSearchHelpDialog
    extends
        StatelessWidget {
  const BrainSearchHelpDialog({
    required this.onUseExample,
    super.key,
  });

  final ValueChanged<
    String
  >
  onUseExample;

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
      builder:
          (
            context,
          ) {
            return BrainSearchHelpDialog(
              onUseExample: onUseExample,
            );
          },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );
    final colorScheme = theme.colorScheme;
    final mediaQuery = MediaQuery.of(
      context,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight:
              mediaQuery.size.height *
              0.84,
        ),
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(
            26,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(
                context,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildAiIntro(
                        context,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      _buildSection(
                        context: context,
                        icon: Icons.auto_awesome_rounded,
                        title: 'Assistente com IA',
                        subtitle: 'Faça perguntas sobre o que já existe no seu Cérebro.',
                        initiallyExpanded: true,
                        accent: true,
                        children: [
                          _buildInfoBox(
                            context: context,
                            icon: Icons.keyboard_return_rounded,
                            title: 'Pressione Enter para ativar a IA',
                            text:
                                'A IA não é chamada enquanto você digita. '
                                'Escreva a pergunta completa e pressione Enter '
                                'para o EVRYLUX analisar os conhecimentos '
                                'relevantes do seu Cérebro.',
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          _buildExamples(
                            context,
                            [
                              'o que eu já aprendi sobre',
                              'o que eu sei sobre',
                              'o que falta eu aprender sobre',
                              'o que eu deveria revisar sobre',
                              'quais conhecimentos estão relacionados a',
                              'quais perguntas eu ainda tenho sobre',
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      _buildSection(
                        context: context,
                        icon: Icons.search_rounded,
                        title: 'Busca simples',
                        subtitle: 'Procure por qualquer assunto.',
                        children: [
                          _buildExamples(
                            context,
                            [
                              'ESP32',
                              'Flutter',
                              'memória dinâmica',
                              'eletrônica',
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      _buildSection(
                        context: context,
                        icon: Icons.category_outlined,
                        title: 'Tipos de conhecimento',
                        subtitle: 'Pesquise por um tipo específico.',
                        children: [
                          _buildExamples(
                            context,
                            [
                              'conceitos sobre ESP32',
                              'perguntas sobre C++',
                              'exemplos sobre Flutter',
                              'atenções sobre eletrônica',
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      _buildSection(
                        context: context,
                        icon: Icons.calendar_today_outlined,
                        title: 'Datas',
                        subtitle: 'Procure pelo que registrou em um período.',
                        children: [
                          _buildExamples(
                            context,
                            [
                              'o que estudei ontem',
                              'o que anotei essa semana',
                              'o que eu fiz no dia 16',
                              'o que vi no mês passado',
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      _buildSection(
                        context: context,
                        icon: Icons.schedule_rounded,
                        title: 'Períodos do dia',
                        subtitle: 'Combine a pesquisa com manhã, tarde ou noite.',
                        children: [
                          _buildExamples(
                            context,
                            [
                              'o que eu estudei de manhã',
                              'o que fiz hoje à tarde',
                              'o que anotei ontem à noite',
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      _buildSection(
                        context: context,
                        icon: Icons.history_rounded,
                        title: 'Recência',
                        subtitle: 'Encontre o que viu mais recentemente.',
                        children: [
                          _buildExamples(
                            context,
                            [
                              'o que estudei recentemente sobre ESP32',
                              'minhas últimas anotações sobre C++',
                              'o que eu vi por último sobre Flutter',
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      _buildSection(
                        context: context,
                        icon: Icons.format_list_numbered_rounded,
                        title: 'Quantidade',
                        subtitle: 'Escolha quantos resultados deseja encontrar.',
                        children: [
                          _buildExamples(
                            context,
                            [
                              'me mostre 3 perguntas sobre ESP32',
                              'mostre 5 conceitos sobre C++',
                              'mostre só 10 resultados',
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      _buildSection(
                        context: context,
                        icon: Icons.psychology_alt_outlined,
                        title: 'Conhecimento acumulado',
                        subtitle: 'Consulte o que o seu Cérebro já possui.',
                        children: [
                          _buildExamples(
                            context,
                            [
                              'o que eu já sei sobre ESP32',
                              'o que eu já aprendi sobre C++',
                              'o que eu já anotei sobre eletrônica',
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 14,
                      ),
                      _buildFooterHint(
                        context,
                      ),
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

  Widget _buildHeader(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        18,
        14,
        14,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(
              alpha: 0.42,
            ),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Como pesquisar no Cérebro',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  'Use os modelos abaixo como ponto de partida.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
    );
  }

  Widget _buildAiIntro(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(
          alpha: 0.07,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(
                alpha: 0.11,
              ),
              borderRadius: BorderRadius.circular(
                11,
              ),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 19,
              color: colorScheme.primary,
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
                  'Pesquisa + inteligência do Cérebro',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 4,
                ),
                Text(
                  'Pesquisas simples continuam locais. '
                  'Perguntas inteligentes podem usar a IA para resumir, '
                  'relacionar e sugerir próximos caminhos com base no '
                  'conhecimento relevante já registrado.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<
      Widget
    >
    children,
    bool initiallyExpanded = false,
    bool accent = false,
  }) {
    final theme = Theme.of(
      context,
    );
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: accent
            ? colorScheme.primary.withValues(
                alpha: 0.045,
              )
            : colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.22,
              ),
        borderRadius: BorderRadius.circular(
          15,
        ),
        border: Border.all(
          color: accent
              ? colorScheme.primary.withValues(
                  alpha: 0.20,
                )
              : theme.dividerColor.withValues(
                  alpha: 0.32,
                ),
        ),
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 2,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            14,
          ),
          leading: Icon(
            icon,
            size: 20,
            color: accent
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String text,
  }) {
    final theme = Theme.of(
      context,
    );
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        13,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(
          alpha: 0.72,
        ),
        borderRadius: BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color: colorScheme.primary.withValues(
            alpha: 0.17,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: colorScheme.primary,
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

  Widget _buildExamples(
    BuildContext context,
    List<
      String
    >
    examples,
  ) {
    return Column(
      children: [
        for (
          var index = 0;
          index <
              examples.length;
          index++
        ) ...[
          _buildExampleTile(
            context,
            examples[index],
          ),
          if (index !=
              examples.length -
                  1)
            const SizedBox(
              height: 7,
            ),
        ],
      ],
    );
  }

  Widget _buildExampleTile(
    BuildContext context,
    String example,
  ) {
    final theme = Theme.of(
      context,
    );
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(
          alpha: 0.65,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: theme.dividerColor.withValues(
            alpha: 0.26,
          ),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(
          12,
        ),
        onTap: () {
          onUseExample(
            example,
          );

          Navigator.of(
            context,
          ).pop();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  example,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              Text(
                'Usar',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(
                width: 4,
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterHint(
    BuildContext context,
  ) {
    final theme = Theme.of(
      context,
    );
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 17,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          child: Text(
            'Dica: ao tocar em “Usar”, o exemplo é colocado no campo. '
            'Para perguntas com IA, complete a frase e pressione Enter.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
