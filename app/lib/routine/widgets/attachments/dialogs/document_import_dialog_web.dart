import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../controllers/attachments/board_attachment_controller.dart';
import '../../../models/attachments/board_attachment.dart';

class DocumentImportDialog extends StatefulWidget {
  const DocumentImportDialog({
    super.key,
    required this.controller,
    required this.boardId,
    required this.blockId,
  });

  final BoardAttachmentController controller;
  final String boardId;
  final String blockId;

  static Future<BoardAttachment?> show(
    BuildContext context, {
    required BoardAttachmentController controller,
    required String boardId,
    required String blockId,
  }) {
    return showDialog<BoardAttachment>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return DocumentImportDialog(
          controller: controller,
          boardId: boardId,
          blockId: blockId,
        );
      },
    );
  }

  @override
  State<DocumentImportDialog> createState() {
    return _DocumentImportDialogState();
  }
}

class _DocumentImportDialogState extends State<DocumentImportDialog> {
  Uint8List? _bytes;

  String? _name;

  String? _error;

  bool _busy = false;

  // ============================================================
  // PICK FILE
  // ============================================================

  Future<void> _pick() async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // file_picker 12.x:
      //
      // Não existe mais:
      //
      //   FilePicker.platform.pickFiles(...)
      //
      // A API nova usa FilePicker.pickFile().
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const <String>['md', 'markdown', 'txt'],
      );

      if (!mounted) {
        return;
      }

      if (file == null) {
        setState(() {
          _busy = false;
        });

        return;
      }

      // file_picker 12.x também não depende mais de withData.
      //
      // Lemos os bytes diretamente do PlatformFile.
      final bytes = await file.readAsBytes();

      if (!mounted) {
        return;
      }

      if (bytes.isEmpty) {
        setState(() {
          _busy = false;
          _error = 'O arquivo selecionado está vazio.';
        });

        return;
      }

      setState(() {
        _bytes = bytes;
        _name = file.name;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _busy = false;
        _error = 'Erro ao selecionar arquivo: $error';
      });
    }
  }

  // ============================================================
  // IMPORT
  // ============================================================

  Future<void> _import() async {
    final bytes = _bytes;

    final name = _name;

    if (bytes == null || name == null || name.trim().isEmpty || _busy) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final attachment = await widget.controller.importAttachmentBytes(
        boardId: widget.boardId,
        blockId: widget.blockId,
        fileName: name,
        bytes: bytes,
      );

      if (!mounted) {
        return;
      }

      if (attachment == null) {
        setState(() {
          _busy = false;

          _error =
              widget.controller.errorMessage ??
              'Não foi possível importar o documento.';
        });

        return;
      }

      Navigator.of(context).pop(attachment);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _busy = false;
        _error = 'Erro ao importar documento: $error';
      });
    }
  }

  // ============================================================
  // UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final selectedName = _name?.trim();

    return AlertDialog(
      title: const Text('Importar documento'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Selecione um documento Markdown ou TXT. '
              'No Web, o arquivo será enviado para o '
              'armazenamento da sua conta EVRYLUX.',
            ),

            const SizedBox(height: 18),

            OutlinedButton.icon(
              onPressed: _busy ? null : _pick,
              icon: const Icon(Icons.upload_file_outlined),
              label: Text(
                selectedName == null || selectedName.isEmpty
                    ? 'Selecionar arquivo'
                    : selectedName,
              ),
            ),

            if (selectedName != null && selectedName.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),

              Row(
                children: <Widget>[
                  const Icon(Icons.description_outlined, size: 18),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      selectedName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            if (_error != null) ...<Widget>[
              const SizedBox(height: 14),

              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _busy
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: _busy || _bytes == null ? null : _import,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Importar'),
        ),
      ],
    );
  }
}
