import 'package:flutter/material.dart';

import '../../models/brain_concept.dart';
import '../dialogs/brain_concept_dialog.dart';

class BrainConceptsSection
    extends
        StatelessWidget {
  const BrainConceptsSection({
    super.key,
    required this.concepts,
    required this.onChanged,
  });

  final List<
    BrainConcept
  >
  concepts;

  final Future<
    void
  >
  Function(
    List<
      BrainConcept
    >
    concepts,
  )
  onChanged;

  // =========================================================
  // ADICIONAR
  // =========================================================

  Future<
    void
  >
  _addConcept(
    BuildContext context,
  ) async {
    final concept =
        await showDialog<
          BrainConcept
        >(
          context: context,
          builder:
              (
                _,
              ) {
                return const BrainConceptDialog();
              },
        );

    if (concept ==
        null) {
      return;
    }

    final updated = [
      ...concepts,
      concept,
    ];

    await onChanged(
      updated,
    );
  }

  // =========================================================
  // EDITAR
  // =========================================================

  Future<
    void
  >
  _editConcept(
    BuildContext context,
    BrainConcept concept,
  ) async {
    final edited =
        await showDialog<
          BrainConcept
        >(
          context: context,
          builder:
              (
                _,
              ) {
                return BrainConceptDialog(
                  initialConcept: concept,
                );
              },
        );

    if (edited ==
        null) {
      return;
    }

    final updated = concepts.map(
      (
        item,
      ) {
        if (item.id ==
            edited.id) {
          return edited;
        }

        return item;
      },
    ).toList();

    await onChanged(
      updated,
    );
  }

  // =========================================================
  // EXCLUIR
  // =========================================================

  Future<
    void
  >
  _deleteConcept(
    BuildContext context,
    BrainConcept concept,
  ) async {
    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  title: const Text(
                    'Excluir conhecimento?',
                  ),

                  content: Text(
                    'Deseja remover "${concept.title}"?',
                  ),

                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      },
                      icon: const Icon(
                        Icons.delete_outline,
                      ),
                      label: const Text(
                        'Excluir',
                      ),
                    ),
                  ],
                );
              },
        );

    if (confirmed !=
        true) {
      return;
    }

    final updated = concepts.where(
      (
        item,
      ) {
        return item.id !=
            concept.id;
      },
    ).toList();

    await onChanged(
      updated,
    );
  }

  // =========================================================
  // CARD
  // =========================================================

  Widget _buildConceptCard(
    BuildContext context,
    BrainConcept concept,
  ) {
    final color = concept.color;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 8,
        ),

        // ===================================================
        // ICON
        // ===================================================
        leading: Container(
          width: 44,

          height: 44,

          decoration: BoxDecoration(
            color: color.withValues(
              alpha: 0.10,
            ),

            borderRadius: BorderRadius.circular(
              12,
            ),

            border: Border.all(
              color: color.withValues(
                alpha: 0.28,
              ),
            ),
          ),

          child: Center(
            child: Icon(
              concept.icon,

              color: color,

              size: 22,
            ),
          ),
        ),

        // ===================================================
        // TITLE
        // ===================================================
        title: Row(
          children: [
            Text(
              concept.emoji,

              style: const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(
              width: 7,
            ),

            Expanded(
              child: Text(
                concept.title,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        // ===================================================
        // SUBTITLE
        // ===================================================
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(
              height: 6,
            ),

            Text(
              concept.description,

              maxLines: 3,

              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(
              height: 8,
            ),

            Wrap(
              spacing: 8,

              runSpacing: 8,

              children: [
                Chip(
                  avatar: Icon(
                    concept.icon,

                    size: 16,

                    color: color,
                  ),

                  label: Text(
                    concept.label,
                  ),

                  side: BorderSide(
                    color: color.withValues(
                      alpha: 0.30,
                    ),
                  ),

                  backgroundColor: color.withValues(
                    alpha: 0.08,
                  ),
                ),

                Chip(
                  avatar: const Icon(
                    Icons.folder_outlined,
                    size: 16,
                  ),

                  label: Text(
                    '${concept.folderName}/',
                  ),
                ),
              ],
            ),
          ],
        ),

        // ===================================================
        // MENU
        // ===================================================
        trailing:
            PopupMenuButton<
              String
            >(
              tooltip: 'Opções',

              onSelected:
                  (
                    value,
                  ) async {
                    switch (value) {
                      case 'edit':
                        await _editConcept(
                          context,
                          concept,
                        );
                        break;

                      case 'delete':
                        await _deleteConcept(
                          context,
                          concept,
                        );
                        break;
                    }
                  },

              itemBuilder:
                  (
                    _,
                  ) {
                    return const [
                      PopupMenuItem(
                        value: 'edit',

                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                            ),

                            SizedBox(
                              width: 12,
                            ),

                            Text(
                              'Editar',
                            ),
                          ],
                        ),
                      ),

                      PopupMenuItem(
                        value: 'delete',

                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                            ),

                            SizedBox(
                              width: 12,
                            ),

                            Text(
                              'Excluir',
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
            ),
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(
        24,
      ),

      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest,

        borderRadius: BorderRadius.circular(
          16,
        ),
      ),

      child: const Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            size: 46,
          ),

          SizedBox(
            height: 12,
          ),

          Text(
            'Nenhum conhecimento cadastrado.',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(
            height: 8,
          ),

          Text(
            'Transforme sua anotação em conceitos, perguntas, exemplos ou atenções.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        const Divider(
          height: 40,
        ),

        Row(
          children: [
            const Icon(
              Icons.psychology_alt_outlined,
            ),

            const SizedBox(
              width: 8,
            ),

            Text(
              'Conhecimentos',

              style: Theme.of(
                context,
              ).textTheme.titleLarge,
            ),

            const Spacer(),

            FilledButton.icon(
              onPressed: () async {
                await _addConcept(
                  context,
                );
              },

              icon: const Icon(
                Icons.add,
              ),

              label: const Text(
                'Adicionar',
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 20,
        ),

        if (concepts.isEmpty)
          _buildEmptyState(
            context,
          )
        else
          ...concepts.map(
            (
              concept,
            ) {
              return _buildConceptCard(
                context,
                concept,
              );
            },
          ),
      ],
    );
  }
}
