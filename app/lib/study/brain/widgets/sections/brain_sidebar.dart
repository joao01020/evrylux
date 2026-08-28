import 'package:flutter/material.dart';

import '../../models/brain_file.dart';
import '../cards/brain_empty_notes.dart';
import '../cards/brain_note_card.dart';

class BrainSidebar
    extends
        StatelessWidget {
  final List<
    BrainFile
  >
  notes;
  final BrainFile? selectedNote;

  final VoidCallback onCreateNote;
  final ValueChanged<
    BrainFile
  >
  onOpenNote;
  final ValueChanged<
    BrainFile
  >
  onDeleteNote;

  const BrainSidebar({
    super.key,
    required this.notes,
    required this.selectedNote,
    required this.onCreateNote,
    required this.onOpenNote,
    required this.onDeleteNote,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(
            16,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onCreateNote,
              icon: const Icon(
                Icons.add,
              ),
              label: const Text(
                'Nova anotação',
              ),
            ),
          ),
        ),
        const Divider(
          height: 1,
        ),
        Expanded(
          child: notes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(
                      20,
                    ),
                    child: BrainEmptyNotes(
                      title: 'Nenhuma anotação salva.',
                      description: 'Crie uma nova anotação para ela aparecer aqui.',
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(
                    12,
                  ),
                  itemCount: notes.length,
                  itemBuilder:
                      (
                        context,
                        index,
                      ) {
                        final note = notes[index];

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
        ),
      ],
    );
  }
}
