import 'package:flutter/material.dart';

// ============================================================
// ROUTINE TEXT EDITOR
// ============================================================

class RoutineTextEditor
    extends
        StatefulWidget {
  const RoutineTextEditor({
    super.key,
    required this.title,
    required this.hint,
    required this.initialValue,
    required this.maxLines,
  });

  final String title;
  final String hint;
  final String initialValue;
  final int maxLines;

  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    String?
  >
  show(
    BuildContext context, {
    required String title,
    String hint = '',
    String initialValue = '',
    int maxLines = 4,
  }) {
    final int safeMaxLines =
        maxLines <
            1
        ? 1
        : maxLines;

    return showGeneralDialog<
      String
    >(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fechar editor',
      barrierColor: Colors.black.withValues(
        alpha: .42,
      ),
      transitionDuration: const Duration(
        milliseconds: 220,
      ),
      transitionBuilder:
          (
            _,
            animation,
            _,
            child,
          ) {
            final Animation<
              double
            >
            curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale:
                    Tween<
                          double
                        >(
                          begin: .97,
                          end: 1,
                        )
                        .animate(
                          curved,
                        ),
                child: child,
              ),
            );
          },
      pageBuilder:
          (
            _,
            _,
            _,
          ) {
            return RoutineTextEditor(
              title: title,
              hint: hint,
              initialValue: initialValue,
              maxLines: safeMaxLines,
            );
          },
    );
  }

  @override
  State<
    RoutineTextEditor
  >
  createState() {
    return _RoutineTextEditorState();
  }
}

// ============================================================
// STATE
// ============================================================

class _RoutineTextEditorState
    extends
        State<
          RoutineTextEditor
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFFFFFFF,
  );

  static const Color _surface = Color(
    0xFFF4F6F5,
  );

  static const Color _surfaceDark = Color(
    0xFFE5E7EB,
  );

  static const Color _border = Color(
    0xFFD1D5DB,
  );

  static const Color _green = Color(
    0xFF198754,
  );

  static const Color _greenLight = Color(
    0xFFDDF1E4,
  );

  static const Color _greenBorder = Color(
    0xFFA9D2B5,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _mutedLight = Color(
    0xFF8A918C,
  );

  // ============================================================
  // CONTROLLER
  // ============================================================

  late final TextEditingController _controller;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialValue,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _save() {
    Navigator.of(
      context,
    ).pop(
      _controller.text.trim(),
    );
  }

  // ============================================================
  // CLOSE
  // ============================================================

  void _close() {
    Navigator.of(
      context,
    ).pop();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final int minLines =
        widget.maxLines >=
            3
        ? 3
        : widget.maxLines;

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(
              24,
            ),
            border: Border.all(
              color: _border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x24000000,
                ),
                blurRadius: 32,
                offset: Offset(
                  0,
                  14,
                ),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              24,
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                22,
                24,
                22 +
                    MediaQuery.viewInsetsOf(
                      context,
                    ).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================
                  _header(),

                  const SizedBox(
                    height: 22,
                  ),

                  // ==================================================
                  // CAMPO
                  // ==================================================
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    minLines: minLines,
                    maxLines: widget.maxLines,
                    textInputAction:
                        widget.maxLines ==
                            1
                        ? TextInputAction.done
                        : TextInputAction.newline,
                    onSubmitted:
                        widget.maxLines ==
                            1
                        ? (
                            _,
                          ) {
                            _save();
                          }
                        : null,
                    style: const TextStyle(
                      color: _text,
                      fontSize: 14,
                      height: 1.45,
                    ),
                    cursorColor: _green,
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: const TextStyle(
                        color: _mutedLight,
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: _surface,
                      contentPadding: const EdgeInsets.all(
                        17,
                      ),
                      enabledBorder: _borderStyle(
                        _border,
                      ),
                      focusedBorder: _borderStyle(
                        _green,
                        width: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  // ==================================================
                  // ACTIONS
                  // ==================================================
                  _actions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================================
        // ÍCONE
        // ======================================================
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _greenLight,
            borderRadius: BorderRadius.circular(
              13,
            ),
            border: Border.all(
              color: _greenBorder,
            ),
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            color: _green,
            size: 22,
          ),
        ),

        const SizedBox(
          width: 13,
        ),

        // ======================================================
        // TEXTOS
        // ======================================================
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: _text,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              const Text(
                'Registre com clareza. Você poderá editar depois.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // ======================================================
        // FECHAR
        // ======================================================
        IconButton(
          tooltip: 'Fechar',
          onPressed: _close,
          style: IconButton.styleFrom(
            foregroundColor: _muted,
            backgroundColor: _surfaceDark,
          ),
          icon: const Icon(
            Icons.close_rounded,
            size: 20,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _actions() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'ESC para fechar',
            style: TextStyle(
              color: _mutedLight,
              fontSize: 11,
            ),
          ),
        ),

        // ======================================================
        // CANCELAR
        // ======================================================
        TextButton(
          onPressed: _close,
          style: TextButton.styleFrom(
            foregroundColor: _muted,
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 13,
            ),
          ),
          child: const Text(
            'Cancelar',
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        // ======================================================
        // SALVAR
        // ======================================================
        FilledButton.icon(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: _green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
          ),
          icon: const Icon(
            Icons.check_rounded,
            size: 18,
          ),
          label: const Text(
            'Salvar',
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BORDER
  // ============================================================

  OutlineInputBorder _borderStyle(
    Color color, {
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        15,
      ),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }
}
