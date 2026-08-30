import 'package:flutter/material.dart';

class BoardCommentEditor
    extends
        StatefulWidget {
  const BoardCommentEditor({
    super.key,
    required this.onSubmit,
    required this.onCancel,
    this.initialValue = '',
  });

  final ValueChanged<
    String
  >
  onSubmit;

  final VoidCallback onCancel;

  final String initialValue;

  @override
  State<
    BoardCommentEditor
  >
  createState() => _BoardCommentEditorState();
}

class _BoardCommentEditorState
    extends
        State<
          BoardCommentEditor
        > {
  // ============================================================
  // CONTROLLER / FOCUS
  // ============================================================

  late final TextEditingController _controller;

  late final FocusNode _focusNode;

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
    0xFF7A8190,
  );

  static const Color _blue = Color(
    0xFF3859FF,
  );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialValue,
    );

    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _focusNode.requestFocus();
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.dispose();

    _focusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  void _submit() {
    final value = _controller.text.trim();

    if (value.isEmpty) {
      return;
    }

    widget.onSubmit(
      value,
    );
  }

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
              blurRadius: 18,
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
            // INPUT
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                15,
                12,
                12,
                8,
              ),

              child: TextField(
                controller: _controller,

                focusNode: _focusNode,

                minLines: 1,

                maxLines: 4,

                style: const TextStyle(
                  color: _text,
                  fontSize: 13,
                  height: 1.35,
                ),

                textInputAction: TextInputAction.newline,

                decoration: const InputDecoration(
                  isDense: true,

                  border: InputBorder.none,

                  hintText: 'Adicione um comentário. Use @',

                  hintStyle: TextStyle(
                    color: _muted,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            // ==================================================
            // ACTIONS
            // ==================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                0,
                8,
                8,
              ),

              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Cancelar',

                    onPressed: widget.onCancel,

                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: _muted,
                    ),
                  ),

                  const Spacer(),

                  IconButton(
                    tooltip: 'Emoji',

                    onPressed: () {},

                    icon: const Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      size: 20,
                      color: _muted,
                    ),
                  ),

                  IconButton(
                    tooltip: 'Enviar',

                    onPressed: _submit,

                    icon: const Icon(
                      Icons.send_rounded,
                      size: 20,
                      color: _blue,
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
}
