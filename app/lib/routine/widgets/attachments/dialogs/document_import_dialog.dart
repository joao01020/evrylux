import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../controllers/attachments/board_attachment_controller.dart';
import '../../../models/attachments/board_attachment.dart';

class DocumentImportDialog
    extends
        StatefulWidget {
  const DocumentImportDialog({
    super.key,
    required this.controller,
    required this.boardId,
    required this.blockId,
  });

  // ============================================================
  // DEPENDÊNCIAS
  // ============================================================

  final BoardAttachmentController controller;

  // ============================================================
  // IDENTIDADE
  // ============================================================

  final String boardId;

  final String blockId;

  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    BoardAttachment?
  >
  show(
    BuildContext context, {
    required BoardAttachmentController controller,
    required String boardId,
    required String blockId,
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
            return DocumentImportDialog(
              controller: controller,
              boardId: boardId,
              blockId: blockId,
            );
          },
    );
  }

  @override
  State<
    DocumentImportDialog
  >
  createState() => _DocumentImportDialogState();
}

class _DocumentImportDialogState
    extends
        State<
          DocumentImportDialog
        > {
  // ============================================================
  // CORES
  // ============================================================

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

  // ============================================================
  // STATE
  // ============================================================

  String? _selectedPath;

  String? _selectedName;

  String? _error;

  bool _importing = false;

  // ============================================================
  // PICK FILE
  // ============================================================

  Future<
    void
  >
  _pickFile() async {
    if (_importing) {
      return;
    }

    setState(
      () {
        _error = null;
      },
    );

    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const [
          'md',
          'markdown',
          'txt',
        ],
      );

      if (!mounted) {
        return;
      }

      if (picked ==
          null) {
        return;
      }

      final path = picked.path;

      if (path ==
              null ||
          path.trim().isEmpty) {
        setState(
          () {
            _error = 'Não foi possível acessar o caminho local do arquivo.';
          },
        );

        return;
      }

      setState(
        () {
          _selectedPath = path.trim();

          _selectedName = picked.name.trim();

          _error = null;
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DOCUMENT IMPORT] '
        'Erro ao selecionar arquivo: '
        '$error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _error = 'Erro ao selecionar arquivo: $error';
        },
      );
    }
  }

  // ============================================================
  // IMPORT
  // ============================================================

  Future<
    void
  >
  _import() async {
    final path = _selectedPath;

    if (path ==
            null ||
        path.trim().isEmpty ||
        _importing) {
      return;
    }

    setState(
      () {
        _importing = true;

        _error = null;
      },
    );

    try {
      final attachment = await widget.controller.importAttachment(
        boardId: widget.boardId,
        blockId: widget.blockId,
        sourcePath: path,
      );

      if (!mounted) {
        return;
      }

      if (attachment ==
          null) {
        setState(
          () {
            _error =
                widget.controller.errorMessage ??
                'Não foi possível importar o documento.';
          },
        );

        return;
      }

      Navigator.of(
        context,
      ).pop(
        attachment,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[DOCUMENT IMPORT] '
        'Erro ao importar documento: '
        '$error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _error = 'Não foi possível importar o documento: $error';
        },
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _importing = false;
          },
        );
      }
    }
  }

  // ============================================================
  // CLOSE
  // ============================================================

  void _close() {
    if (_importing) {
      return;
    }

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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _surface,
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
                blurRadius: 26,
                offset: Offset(
                  0,
                  12,
                ),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ====================================
                // HEADER
                // ====================================
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _soft,
                        borderRadius: BorderRadius.circular(
                          12,
                        ),
                        border: Border.all(
                          color: _border,
                        ),
                      ),
                      child: const Icon(
                        Icons.upload_file_rounded,
                        color: _primary,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Adicionar documento',
                            style: TextStyle(
                              color: _text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),

                          SizedBox(
                            height: 3,
                          ),

                          Text(
                            'Importe um arquivo para esta lousa.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: _importing
                          ? null
                          : _close,
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // ====================================
                // FILE PICKER
                // ====================================
                InkWell(
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  onTap: _importing
                      ? null
                      : _pickFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: _soft,
                      borderRadius: BorderRadius.circular(
                        14,
                      ),
                      border: Border.all(
                        color: _border,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.description_outlined,
                          color: _primary,
                          size: 32,
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        Text(
                          _selectedName ??
                              'Selecionar arquivo',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        const Text(
                          '.md, .markdown ou .txt',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 10,
                          ),
                        ),

                        if (_selectedPath !=
                            null) ...[
                          const SizedBox(
                            height: 9,
                          ),

                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline_rounded,
                                size: 15,
                                color: _primary,
                              ),

                              SizedBox(
                                width: 5,
                              ),

                              Text(
                                'Arquivo selecionado',
                                style: TextStyle(
                                  color: _primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ====================================
                // ERROR
                // ====================================
                if (_error !=
                    null) ...[
                  const SizedBox(
                    height: 12,
                  ),

                  Container(
                    padding: const EdgeInsets.all(
                      10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFFFF2F0,
                      ),
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                      border: Border.all(
                        color: const Color(
                          0xFFFFC9C3,
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

                const SizedBox(
                  height: 20,
                ),

                // ====================================
                // ACTIONS
                // ====================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _importing
                          ? null
                          : _close,
                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    FilledButton.icon(
                      onPressed:
                          _selectedPath ==
                                  null ||
                              _importing
                          ? null
                          : _import,
                      icon: _importing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.add_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _importing
                            ? 'Importando...'
                            : 'Adicionar',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
