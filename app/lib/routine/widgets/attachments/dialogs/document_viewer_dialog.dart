import 'package:flutter/material.dart';

import '../../../controllers/attachments/board_attachment_controller.dart';
import '../../../models/attachments/board_attachment.dart';
import '../../../models/attachments/board_attachment_type.dart';
import '../viewers/markdown_document_viewer.dart';
import '../viewers/text_document_viewer.dart';

class DocumentViewerDialog
    extends
        StatefulWidget {
  const DocumentViewerDialog({
    super.key,
    required this.attachment,
    required this.controller,
  });

  final BoardAttachment attachment;

  final BoardAttachmentController controller;

  static Future<
    BoardAttachment?
  >
  show(
    BuildContext context, {
    required BoardAttachment attachment,
    required BoardAttachmentController controller,
  }) {
    return showDialog<
      BoardAttachment
    >(
      context: context,
      barrierDismissible: false,
      builder:
          (
            context,
          ) {
            return DocumentViewerDialog(
              attachment: attachment,
              controller: controller,
            );
          },
    );
  }

  @override
  State<
    DocumentViewerDialog
  >
  createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState
    extends
        State<
          DocumentViewerDialog
        > {
  static const Color _background = Color(
    0xFFF7FBF1,
  );

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

  late BoardAttachment _attachment;

  late TextEditingController _editorController;

  bool _loading = true;

  bool _editing = false;

  bool _saving = false;

  String? _content;

  String? _error;

  @override
  void initState() {
    super.initState();

    _attachment = widget.attachment;

    _editorController = TextEditingController();

    _load();
  }

  @override
  void dispose() {
    _editorController.dispose();

    super.dispose();
  }

  Future<
    void
  >
  _load() async {
    setState(
      () {
        _loading = true;

        _error = null;
      },
    );

    final content = await widget.controller.readText(
      _attachment,
    );

    if (!mounted) {
      return;
    }

    if (content ==
        null) {
      setState(
        () {
          _loading = false;

          _error =
              widget.controller.errorMessage ??
              'Não foi possível abrir o documento.';
        },
      );

      return;
    }

    _editorController.text = content;

    setState(
      () {
        _loading = false;

        _content = content;
      },
    );
  }

  Future<
    void
  >
  _save() async {
    if (_saving) {
      return;
    }

    setState(
      () {
        _saving = true;

        _error = null;
      },
    );

    final updated = await widget.controller.saveText(
      attachment: _attachment,
      content: _editorController.text,
    );

    if (!mounted) {
      return;
    }

    if (updated ==
        null) {
      setState(
        () {
          _saving = false;

          _error =
              widget.controller.errorMessage ??
              'Não foi possível salvar o documento.';
        },
      );

      return;
    }

    setState(
      () {
        _attachment = updated;

        _content = _editorController.text;

        _editing = false;

        _saving = false;
      },
    );
  }

  void _cancelEdit() {
    _editorController.text =
        _content ??
        '';

    setState(
      () {
        _editing = false;
      },
    );
  }

  void _close() {
    Navigator.of(
      context,
    ).pop(
      _attachment,
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 980,
          maxHeight: 800,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(
              20,
            ),
            border: Border.all(
              color: _border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x1A000000,
                ),
                blurRadius: 28,
                offset: Offset(
                  0,
                  14,
                ),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),

              const Divider(
                height: 1,
                color: _border,
              ),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _error !=
                              null &&
                          _content ==
                              null
                    ? _buildError()
                    : _editing
                    ? _buildEditor()
                    : _buildViewer(),
              ),

              if (_error !=
                      null &&
                  _content !=
                      null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 9,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(
                      0xFFFFF2F0,
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Color(
                          0xFFFFC9C3,
                        ),
                      ),
                    ),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        14,
        12,
        14,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
              _attachment.type ==
                      BoardAttachmentType.markdown
                  ? Icons.description_outlined
                  : Icons.notes_rounded,
              color: _primary,
              size: 21,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _attachment.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  _attachment.type.label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (!_loading &&
              _content !=
                  null) ...[
            if (_editing) ...[
              TextButton(
                onPressed: _saving
                    ? null
                    : _cancelEdit,
                child: const Text(
                  'Cancelar',
                ),
              ),

              const SizedBox(
                width: 6,
              ),

              FilledButton.icon(
                onPressed: _saving
                    ? null
                    : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 13,
                        height: 13,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.save_outlined,
                        size: 17,
                      ),
                label: Text(
                  _saving
                      ? 'Salvando...'
                      : 'Salvar',
                ),
              ),
            ] else
              OutlinedButton.icon(
                onPressed: () {
                  setState(
                    () {
                      _editing = true;
                    },
                  );
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 16,
                ),
                label: const Text(
                  'Editar',
                ),
              ),
          ],

          const SizedBox(
            width: 6,
          ),

          IconButton(
            tooltip: 'Fechar',
            onPressed: _saving
                ? null
                : _close,
            icon: const Icon(
              Icons.close_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewer() {
    final content =
        _content ??
        '';

    switch (_attachment.type) {
      case BoardAttachmentType.markdown:
        return MarkdownDocumentViewer(
          content: content,
        );

      case BoardAttachmentType.text:
        return TextDocumentViewer(
          content: content,
        );

      case BoardAttachmentType.unknown:
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(
              28,
            ),
            child: Text(
              'Este tipo de documento ainda não possui visualizador interno.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 12,
              ),
            ),
          ),
        );
    }
  }

  Widget _buildEditor() {
    return Container(
      color: _surface,
      padding: const EdgeInsets.all(
        16,
      ),
      child: TextField(
        controller: _editorController,
        expands: true,
        minLines: null,
        maxLines: null,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(
          color: _text,
          fontSize: 13,
          height: 1.5,
          fontFamily: 'monospace',
        ),
        decoration: InputDecoration(
          hintText: 'Edite o conteúdo do documento...',
          filled: true,
          fillColor: _soft,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
            borderSide: const BorderSide(
              color: _border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
            borderSide: const BorderSide(
              color: _border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
              12,
            ),
            borderSide: const BorderSide(
              color: _primary,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 38,
              color: Theme.of(
                context,
              ).colorScheme.error,
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              _error ??
                  'Não foi possível abrir o documento.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(
              height: 14,
            ),

            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 17,
              ),
              label: const Text(
                'Tentar novamente',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
