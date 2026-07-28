import 'package:flutter/material.dart';

import '../models/brain_file.dart';
import '../widgets/brain_empty_notes.dart';
import '../widgets/brain_note_card.dart';

class BrainNotesSection
    extends
        StatelessWidget {
  final List<
    BrainFile
  >
  notes;

  final BrainFile? selectedNote;

  final ValueChanged<
    BrainFile
  >
  onOpenNote;

  final ValueChanged<
    BrainFile
  >
  onDeleteNote;

  const BrainNotesSection({
    super.key,
    required this.notes,
    required this.selectedNote,
    required this.onOpenNote,
    required this.onDeleteNote,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anotações salvas',
          style: Theme.of(
            context,
          ).textTheme.titleLarge,
        ),

        const SizedBox(
          height: 12,
        ),

        if (notes.isEmpty)
          const BrainEmptyNotes()
        else
          ...notes.map(
            (
              note,
            ) {
              final isSelected =
                  selectedNote?.path ==
                  note.path;

              return BrainNoteCard(
                note: note,
                isSelected: isSelected,
                onOpen: () {
                  onOpenNote(
                    note,
                  );
                },
                onDelete: () {
                  onDeleteNote(
                    note,
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
