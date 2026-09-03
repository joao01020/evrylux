import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/brain_controller.dart';
import '../../models/brain_source.dart';
import 'brain_source_dialog.dart';

// ============================================================
// BRAIN SOURCES SECTION
// ============================================================
//
// FASE 13 — FONTES DO CONHECIMENTO
//
// Seção visual para:
//
// - listar fontes;
// - adicionar;
// - editar;
// - excluir;
// - copiar referência.
//
// A seção trabalha diretamente com BrainController.
//
// ============================================================

class BrainSourcesSection extends StatelessWidget {
  const BrainSourcesSection({super.key, required this.controller});

  final BrainController controller;

  // ============================================================
  // ADD
  // ============================================================

  Future<void> _addSource(BuildContext context) async {
    final source = await BrainSourceDialog.show(context: context);

    if (source == null) {
      return;
    }

    await controller.addSource(source);
  }

  // ============================================================
  // EDIT
  // ============================================================

  Future<void> _editSource(BuildContext context, BrainSource source) async {
    final updated = await BrainSourceDialog.show(
      context: context,
      initialSource: source,
    );

    if (updated == null) {
      return;
    }

    await controller.updateSource(updated);
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteSource(BuildContext context, BrainSource source) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remover fonte?'),
          content: Text(
            'A fonte "${source.title}" será removida desta anotação.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancelar'),
            ),

            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await controller.removeSource(source.id);
  }

  // ============================================================
  // COPY
  // ============================================================

  Future<void> _copyReference(BuildContext context, BrainSource source) async {
    await Clipboard.setData(ClipboardData(text: source.reference));

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Referência copiada.'),
          duration: Duration(seconds: 1),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final sources = controller.sources;

        final selectedNote = controller.selectedNote;

        final canAdd = selectedNote != null;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerLow.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.link_rounded, size: 20),

                  const SizedBox(width: 8),

                  const Expanded(
                    child: Text(
                      'Fontes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  if (sources.isNotEmpty)
                    Text(
                      '${sources.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),

              const SizedBox(height: 10),

              if (sources.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    canAdd
                        ? 'Nenhuma fonte adicionada.'
                        : 'Salve a anotação antes de adicionar fontes.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                for (var index = 0; index < sources.length; index++) ...[
                  _SourceTile(
                    source: sources[index],
                    onCopy: () {
                      _copyReference(context, sources[index]);
                    },
                    onEdit: () {
                      _editSource(context, sources[index]);
                    },
                    onDelete: () {
                      _deleteSource(context, sources[index]);
                    },
                  ),

                  if (index != sources.length - 1) const SizedBox(height: 8),
                ],

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: canAdd
                      ? () {
                          _addSource(context);
                        }
                      : null,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Adicionar fonte'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// SOURCE TILE
// ============================================================

class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.source,
    required this.onCopy,
    required this.onEdit,
    required this.onDelete,
  });

  final BrainSource source;

  final VoidCallback onCopy;

  final VoidCallback onEdit;

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _iconForType(source.type),
              size: 18,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),

                const SizedBox(height: 2),

                Text(source.type.label, style: theme.textTheme.bodySmall),

                const SizedBox(height: 6),

                SelectableText(
                  source.reference,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),

                if (source.hasAuthor) ...[
                  const SizedBox(height: 5),

                  Text(
                    'Autor: ${source.author}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],

                if (source.hasNote) ...[
                  const SizedBox(height: 5),

                  Text(source.note!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),

          PopupMenuButton<String>(
            tooltip: 'Ações',
            onSelected: (value) {
              switch (value) {
                case 'copy':
                  onCopy();
                  break;

                case 'edit':
                  onEdit();
                  break;

                case 'delete':
                  onDelete();
                  break;
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<String>(
                  value: 'copy',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.copy_rounded),
                    title: Text('Copiar referência'),
                  ),
                ),

                PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Editar'),
                  ),
                ),

                PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.delete_outline_rounded),
                    title: Text('Remover'),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
    );
  }

  IconData _iconForType(BrainSourceType type) {
    switch (type) {
      case BrainSourceType.url:
        return Icons.language_rounded;

      case BrainSourceType.book:
        return Icons.menu_book_rounded;

      case BrainSourceType.pdf:
        return Icons.picture_as_pdf_rounded;

      case BrainSourceType.file:
        return Icons.insert_drive_file_outlined;

      case BrainSourceType.video:
        return Icons.play_circle_outline_rounded;

      case BrainSourceType.lesson:
        return Icons.school_outlined;

      case BrainSourceType.other:
        return Icons.link_rounded;
    }
  }
}
