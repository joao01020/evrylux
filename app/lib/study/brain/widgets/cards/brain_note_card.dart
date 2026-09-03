import 'package:flutter/material.dart';

import '../../models/brain_file.dart';

// ============================================================
// BRAIN NOTE CARD
// ============================================================
//
// FASE 09 — CAPTURA SEM TEMA
//
// O card não exibe mais note.topic.
//
// Em vez disso, mostramos uma pequena prévia do conteúdo.
// Assim conhecimentos novos não aparecem como "Sem tema" e
// anotações antigas também deixam de depender visualmente de Tema.
//
// ============================================================

class BrainNoteCard extends StatelessWidget {
  const BrainNoteCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onOpen,
    required this.onDelete,
  });

  // ============================================================
  // DATA
  // ============================================================

  final BrainFile note;

  final bool isSelected;

  // ============================================================
  // ACTIONS
  // ============================================================

  final VoidCallback onOpen;

  final VoidCallback onDelete;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final preview = _buildPreview(
      note.content,
    );

    return Card(
      color: isSelected
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer
          : null,
      child: ListTile(
        onTap: onOpen,
        leading: const Icon(
          Icons.description_outlined,
        ),
        title: Text(
          note.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: preview.isEmpty
            ? null
            : Text(
                preview,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: IconButton(
          tooltip: 'Excluir',
          onPressed: onDelete,
          icon: const Icon(
            Icons.delete_outline,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT PREVIEW
  // ============================================================

  String _buildPreview(
    String content,
  ) {
    final normalized = content
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        )
        .trim();

    if (normalized.isEmpty) {
      return '';
    }

    return normalized;
  }
}
