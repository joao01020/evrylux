import 'package:flutter/material.dart';

import '../../models/attachments/board_attachment.dart';
import '../../models/attachments/board_attachment_type.dart';

class DocumentBlock
    extends
        StatelessWidget {
  const DocumentBlock({
    super.key,
    required this.attachment,
    required this.onOpen,
    this.onDelete,
    this.onDrag,
    this.onDragEnd,
  });

  final BoardAttachment attachment;

  final VoidCallback onOpen;

  final VoidCallback? onDelete;

  // ============================================================
  // DRAG
  // ============================================================
  //
  // Permite arrastar o próprio card branco do documento.
  //
  // Clique rápido continua abrindo o arquivo.
  //
  // Clique + arraste move o bloco na lousa.
  //
  // ============================================================

  final ValueChanged<
    Offset
  >?
  onDrag;

  final VoidCallback? onDragEnd;

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _soft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _error = Color(
    0xFFB3261E,
  );

  @override
  Widget build(
    BuildContext context,
  ) {
    final canDrag =
        onDrag !=
        null;

    return MouseRegion(
      cursor: canDrag
          ? SystemMouseCursors.grab
          : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,

        // ======================================================
        // DRAG
        // ======================================================
        onPanUpdate: canDrag
            ? (
                details,
              ) {
                onDrag?.call(
                  details.delta,
                );
              }
            : null,

        onPanEnd: canDrag
            ? (
                _,
              ) {
                onDragEnd?.call();
              }
            : null,

        onPanCancel: canDrag
            ? () {
                onDragEnd?.call();
              }
            : null,

        // ======================================================
        // CONTEÚDO
        // ======================================================
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(
              14,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                12,
              ),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(
                  14,
                ),
                border: Border.all(
                  color: _border,
                ),
              ),
              child: Row(
                children: [
                  // ==================================================
                  // ÍCONE
                  // ==================================================
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _soft,
                      borderRadius: BorderRadius.circular(
                        11,
                      ),
                      border: Border.all(
                        color: _border,
                      ),
                    ),
                    child: Icon(
                      _iconForType(
                        attachment.type,
                      ),
                      color: _primary,
                      size: 21,
                    ),
                  ),

                  const SizedBox(
                    width: 11,
                  ),

                  // ==================================================
                  // INFORMAÇÕES
                  // ==================================================
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          attachment.fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        Wrap(
                          spacing: 8,
                          runSpacing: 3,
                          children: [
                            Text(
                              attachment.type.label,
                              style: const TextStyle(
                                color: _primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),

                            Text(
                              _formatBytes(
                                attachment.sizeBytes,
                              ),
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            if (attachment.hasRemoteCopy)
                              const Text(
                                'Sincronizado',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  // ==================================================
                  // ABRIR
                  // ==================================================
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: IconButton(
                      tooltip: 'Abrir documento',
                      onPressed: onOpen,
                      icon: const Icon(
                        Icons.open_in_new_rounded,
                        size: 19,
                        color: _primary,
                      ),
                    ),
                  ),

                  // ==================================================
                  // EXCLUIR
                  // ==================================================
                  if (onDelete !=
                      null)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: IconButton(
                        tooltip: 'Remover documento',
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: _error,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static IconData _iconForType(
    BoardAttachmentType type,
  ) {
    switch (type) {
      case BoardAttachmentType.markdown:
        return Icons.description_outlined;

      case BoardAttachmentType.text:
        return Icons.notes_rounded;

      case BoardAttachmentType.unknown:
        return Icons.insert_drive_file_outlined;
    }
  }

  static String _formatBytes(
    int bytes,
  ) {
    if (bytes <
        1024) {
      return '$bytes B';
    }

    final kb =
        bytes /
        1024;

    if (kb <
        1024) {
      return '${kb.toStringAsFixed(kb < 10 ? 1 : 0)} KB';
    }

    final mb =
        kb /
        1024;

    return '${mb.toStringAsFixed(mb < 10 ? 1 : 0)} MB';
  }
}
