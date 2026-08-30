import 'package:flutter/material.dart';

import '../../models/comments/board_comment.dart';

class BoardCommentCard
    extends
        StatelessWidget {
  const BoardCommentCard({
    super.key,
    required this.comment,
    required this.onClose,
    required this.onResolve,
    required this.onDelete,
  });

  final BoardComment comment;

  final VoidCallback onClose;

  final VoidCallback onResolve;

  final VoidCallback onDelete;

  // ============================================================
  // CORES
  // ============================================================

  static const Color _surface = Color(
    0xFFFFFFFF,
  );

  static const Color _border = Color(
    0xFFE1E5E9,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF737B89,
  );

  static const Color _blue = Color(
    0xFF3859FF,
  );

  static const Color _blueSoft = Color(
    0xFFE9EDFF,
  );

  static const Color _green = Color(
    0xFF347A3D,
  );

  static const Color _danger = Color(
    0xFFC43A52,
  );

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,

      child: Container(
        width: 340,

        decoration: BoxDecoration(
          color: _surface,

          borderRadius: BorderRadius.circular(
            16,
          ),

          border: Border.all(
            color: _border,
          ),

          boxShadow: const [
            BoxShadow(
              color: Color(
                0x26000000,
              ),
              blurRadius: 20,
              offset: Offset(
                0,
                7,
              ),
            ),
          ],
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            // ==================================================
            // HEADER
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                12,
                10,
                8,
                8,
              ),

              child: Row(
                children: [
                  _buildAvatar(),

                  const SizedBox(
                    width: 9,
                  ),

                  Expanded(
                    child: Text(
                      comment.authorName,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,

                      style: const TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),

                  Text(
                    _formatTime(
                      comment.createdAt,
                    ),

                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(
                    width: 4,
                  ),

                  PopupMenuButton<
                    _CommentAction
                  >(
                    tooltip: 'Opções',

                    color: _surface,

                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: _muted,
                      size: 19,
                    ),

                    onSelected:
                        (
                          action,
                        ) {
                          switch (action) {
                            case _CommentAction.resolve:
                              onResolve();
                              break;

                            case _CommentAction.delete:
                              onDelete();
                              break;
                          }
                        },

                    itemBuilder:
                        (
                          _,
                        ) => [
                          PopupMenuItem(
                            value: _CommentAction.resolve,

                            child: Row(
                              children: [
                                Icon(
                                  comment.resolved
                                      ? Icons.refresh_rounded
                                      : Icons.check_circle_outline_rounded,
                                  size: 18,
                                  color: _green,
                                ),

                                const SizedBox(
                                  width: 9,
                                ),

                                Text(
                                  comment.resolved
                                      ? 'Reabrir'
                                      : 'Resolver',
                                ),
                              ],
                            ),
                          ),

                          const PopupMenuItem(
                            value: _CommentAction.delete,

                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: _danger,
                                ),

                                SizedBox(
                                  width: 9,
                                ),

                                Text(
                                  'Excluir',
                                  style: TextStyle(
                                    color: _danger,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),

                  IconButton(
                    tooltip: 'Fechar',

                    onPressed: onClose,

                    icon: const Icon(
                      Icons.close_rounded,
                      color: _muted,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              height: 1,
              color: _border,
            ),

            // ==================================================
            // MESSAGE
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                14,
                13,
                14,
                14,
              ),

              child: Align(
                alignment: Alignment.centerLeft,

                child: Text(
                  comment.message,

                  style: TextStyle(
                    color: comment.resolved
                        ? _muted
                        : _text,

                    fontSize: 13,

                    height: 1.45,

                    decoration: comment.resolved
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ),
            ),

            // ==================================================
            // RESOLVED
            // ==================================================
            if (comment.resolved)
              Container(
                width: double.infinity,

                margin: const EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  12,
                ),

                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),

                decoration: BoxDecoration(
                  color: const Color(
                    0xFFEAF5EB,
                  ),

                  borderRadius: BorderRadius.circular(
                    10,
                  ),

                  border: Border.all(
                    color: const Color(
                      0xFFC7DFC9,
                    ),
                  ),
                ),

                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: _green,
                    ),

                    SizedBox(
                      width: 7,
                    ),

                    Text(
                      'Comentário resolvido',
                      style: TextStyle(
                        color: _green,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // AVATAR
  // ============================================================

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,

      decoration: const BoxDecoration(
        color: _blueSoft,
        shape: BoxShape.circle,
      ),

      child: const Icon(
        Icons.chat_bubble_outline_rounded,
        color: _blue,
        size: 16,
      ),
    );
  }

  // ============================================================
  // TIME
  // ============================================================

  String _formatTime(
    DateTime date,
  ) {
    final now = DateTime.now();

    final difference = now.difference(
      date,
    );

    if (difference.inMinutes <
        1) {
      return 'agora';
    }

    if (difference.inMinutes <
        60) {
      return '${difference.inMinutes} min';
    }

    if (difference.inHours <
        24) {
      return '${difference.inHours} h';
    }

    if (difference.inDays <
        7) {
      return '${difference.inDays} d';
    }

    final day = date.day.toString().padLeft(
      2,
      '0',
    );

    final month = date.month.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month';
  }
}

// ============================================================
// ACTIONS
// ============================================================

enum _CommentAction {
  resolve,
  delete,
}
