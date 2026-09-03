import 'package:flutter/material.dart';

import '../../models/brain_source.dart';

// ============================================================
// BRAIN SOURCE DIALOG
// ============================================================
//
// FASE 13 — FONTES DO CONHECIMENTO
//
// Modal para:
//
// - criar uma nova fonte;
// - editar uma fonte existente.
//
// A persistência é responsabilidade do BrainController.
//
// ============================================================

class BrainSourceDialog extends StatefulWidget {
  const BrainSourceDialog({super.key, this.initialSource});

  final BrainSource? initialSource;

  static Future<BrainSource?> show({
    required BuildContext context,
    BrainSource? initialSource,
  }) {
    return showDialog<BrainSource>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BrainSourceDialog(initialSource: initialSource);
      },
    );
  }

  @override
  State<BrainSourceDialog> createState() {
    return _BrainSourceDialogState();
  }
}

class _BrainSourceDialogState extends State<BrainSourceDialog> {
  late BrainSourceType _type;

  late final TextEditingController _titleController;

  late final TextEditingController _referenceController;

  late final TextEditingController _authorController;

  late final TextEditingController _noteController;

  DateTime? _publishedAt;

  String? _errorMessage;

  bool get _isEditing {
    return widget.initialSource != null;
  }

  @override
  void initState() {
    super.initState();

    final source = widget.initialSource;

    _type = source?.type ?? BrainSourceType.url;

    _titleController = TextEditingController(text: source?.title ?? '');

    _referenceController = TextEditingController(text: source?.reference ?? '');

    _authorController = TextEditingController(text: source?.author ?? '');

    _noteController = TextEditingController(text: source?.note ?? '');

    _publishedAt = source?.publishedAt?.toLocal();
  }

  @override
  void dispose() {
    _titleController.dispose();

    _referenceController.dispose();

    _authorController.dispose();

    _noteController.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _save() {
    final title = _titleController.text.trim();

    final reference = _referenceController.text.trim();

    if (title.isEmpty) {
      setState(() {
        _errorMessage = 'Informe o título da fonte.';
      });

      return;
    }

    if (reference.isEmpty) {
      setState(() {
        _errorMessage = 'Informe a referência da fonte.';
      });

      return;
    }

    final initial = widget.initialSource;

    final source = initial == null
        ? BrainSource.create(
            type: _type,
            title: title,
            reference: reference,
            author: _authorController.text,
            publishedAt: _publishedAt,
            note: _noteController.text,
          )
        : initial.copyWith(
            type: _type,
            title: title,
            reference: reference,
            author: _authorController.text.trim().isEmpty
                ? null
                : _authorController.text.trim(),
            clearAuthor: _authorController.text.trim().isEmpty,
            publishedAt: _publishedAt,
            clearPublishedAt: _publishedAt == null,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            clearNote: _noteController.text.trim().isEmpty,
            updatedAt: DateTime.now().toLocal(),
          );

    Navigator.of(context).pop(source);
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<void> _choosePublishedDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _publishedAt ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 10),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _publishedAt = picked;
    });
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();

    String two(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${two(local.day)}/${two(local.month)}/${local.year}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Editar fonte' : 'Adicionar fonte'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<BrainSourceType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: BrainSourceType.values.map((type) {
                  return DropdownMenuItem<BrainSourceType>(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _type = value;
                  });
                },
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ex.: cppreference - Pointers',
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _referenceController,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Referência',
                  hintText: 'URL, capítulo, nome do arquivo, aula...',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 14),

              TextField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: 'Autor',
                  hintText: 'Opcional',
                ),
              ),

              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: _choosePublishedDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _publishedAt == null
                        ? 'Adicionar data'
                        : _formatDate(_publishedAt!),
                  ),
                ),
              ),

              if (_publishedAt != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _publishedAt = null;
                      });
                    },
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Remover data'),
                  ),
                ),

              const SizedBox(height: 8),

              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  hintText: 'Opcional',
                  alignLabelWithHint: true,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),

                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),

        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Salvar alterações' : 'Adicionar'),
        ),
      ],
    );
  }
}
