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
                _,
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
                          context,
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                          true,
                        );
                      },
                      child: const Text(
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
    final memorize =
        concept.type ==
        BrainConceptType.memorize;

    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            memorize
                ? Icons.psychology
                : Icons.bookmark_outline,
          ),
        ),
        title: Text(
          concept.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
            Chip(
              avatar: Icon(
                memorize
                    ? Icons.memory
                    : Icons.archive_outlined,
                size: 18,
              ),
              label: Text(
                memorize
                    ? 'Memorizar'
                    : 'Guardar',
              ),
            ),
          ],
        ),
        trailing:
            PopupMenuButton<
              String
            >(
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
          Container(
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
                  'Transforme sua anotação em conceitos para consultar ou revisar futuramente.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
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
