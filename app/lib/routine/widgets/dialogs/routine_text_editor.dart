import 'package:flutter/material.dart';

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
    final safeMaxLines =
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
        alpha: .72,
      ),
      transitionDuration: const Duration(
        milliseconds: 240,
      ),
      transitionBuilder:
          (
            _,
            animation,
            __,
            child,
          ) {
            final curved = CurvedAnimation(
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
                          begin: .96,
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
            __,
            ___,
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
  createState() => _RoutineTextEditorState();
}

class _RoutineTextEditorState
    extends
        State<
          RoutineTextEditor
        > {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      _controller.text.trim(),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final minLines =
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
            color: const Color(
              0xFF141720,
            ),
            borderRadius: BorderRadius.circular(
              24,
            ),
            border: Border.all(
              color: const Color(
                0xFF2B3040,
              ),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x66000000,
                ),
                blurRadius: 42,
                offset: Offset(
                  0,
                  20,
                ),
              ),
              BoxShadow(
                color: Color(
                  0x207C5CFF,
                ),
                blurRadius: 38,
                spreadRadius: -12,
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
                  _header(),
                  const SizedBox(
                    height: 22,
                  ),
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
                          ) => _save()
                        : null,
                    style: const TextStyle(
                      color: Color(
                        0xFFF5F7FA,
                      ),
                      fontSize: 14,
                      height: 1.45,
                    ),
                    cursorColor: const Color(
                      0xFFA996FF,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
                      hintStyle: const TextStyle(
                        color: Color(
                          0xFF6F7584,
                        ),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(
                        0xFF0E1016,
                      ),
                      contentPadding: const EdgeInsets.all(
                        17,
                      ),
                      enabledBorder: _border(
                        const Color(
                          0xFF292E3A,
                        ),
                      ),
                      focusedBorder: _border(
                        const Color(
                          0xFF8D73FF,
                        ),
                        width: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 18,
                  ),
                  _actions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color:
                const Color(
                  0xFF7C5CFF,
                ).withValues(
                  alpha: .14,
                ),
            borderRadius: BorderRadius.circular(
              13,
            ),
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            color: Color(
              0xFFA996FF,
            ),
            size: 22,
          ),
        ),
        const SizedBox(
          width: 13,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Color(
                    0xFFF5F7FA,
                  ),
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
                  color: Color(
                    0xFF9298A6,
                  ),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Fechar',
          onPressed: () => Navigator.pop(
            context,
          ),
          icon: const Icon(
            Icons.close_rounded,
            color: Color(
              0xFF9298A6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'ESC para fechar',
            style: TextStyle(
              color: Color(
                0xFF666C79,
              ),
              fontSize: 11,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(
            context,
          ),
          child: const Text(
            'Cancelar',
          ),
        ),
        const SizedBox(
          width: 8,
        ),
        FilledButton.icon(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(
              0xFF7C5CFF,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 15,
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

  OutlineInputBorder _border(
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
