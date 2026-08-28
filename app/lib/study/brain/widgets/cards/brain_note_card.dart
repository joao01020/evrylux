import 'package:flutter/material.dart';

import '../../models/brain_file.dart';

class BrainNoteCard
    extends
        StatelessWidget {
  final BrainFile note;
  final bool isSelected;

  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const BrainNoteCard({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
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
        subtitle: Text(
          note.topic,
          maxLines: 1,
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
}
