import 'package:flutter/material.dart';

import '../../../../app/dependencies/app_dependencies.dart' as dependencies;

import '../../controllers/brain_controller.dart';
import '../../models/brain_concept.dart';
import '../../models/brain_file.dart';
import '../../sections/brain_editor_section.dart';

// ============================================================
// BRAIN NOTE SCREEN
// ============================================================
//
// Página dedicada para ABRIR uma anotação já existente.
//
// Fluxo:
//
// BrainScreen
//      ↓
// BrainNoteScreen
//      ↓
// BrainController global
//      ↓
// BrainRepository
//      ↓
// local + SyncQueue + Supabase
//
// Esta página NÃO cria BrainController próprio.
// Também NÃO faz dispose() no controller global.
//
// ============================================================

class BrainNoteScreen
    extends
        StatefulWidget {
  const BrainNoteScreen({
    super.key,
    required this.note,
  });

  final BrainFile note;

  @override
  State<
    BrainNoteScreen
  >
  createState() {
    return _BrainNoteScreenState();
  }
}

class _BrainNoteScreenState
    extends
        State<
          BrainNoteScreen
        > {
  late final BrainController _controller;

  bool _isOpening = true;

  bool _isEditing = false;

  bool _isDeleting = false;

  String? _openError;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _controller = dependencies.brainController;

    _controller.addListener(
      _onControllerChanged,
    );

    _openNote();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    // Controller global:
    // não fazer _controller.dispose() aqui.

    super.dispose();
  }

  // ============================================================
  // CONTROLLER CHANGED
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // OPEN
  // ============================================================

  Future<
    void
  >
  _openNote() async {
    setState(
      () {
        _isOpening = true;
        _openError = null;
      },
    );

    final opened = await _controller.openNote(
      widget.note,
    );

    if (!mounted) {
      return;
    }

    if (!opened) {
      setState(
        () {
          _isOpening = false;
          _openError =
              _controller.errorMessage ??
              'Não foi possível abrir a anotação.';
        },
      );

      _controller.clearMessages();

      return;
    }

    setState(
      () {
        _isOpening = false;
      },
    );
  }

  // ============================================================
  // CURRENT NOTE
  // ============================================================

  BrainFile get _currentNote {
    return _controller.selectedNote ??
        widget.note;
  }

  // ============================================================
  // EDIT
  // ============================================================

  void _startEditing() {
    if (_controller.isSaving ||
        _isDeleting) {
      return;
    }

    setState(
      () {
        _isEditing = true;
      },
    );
  }

  void _cancelEditing() {
    if (_controller.isSaving) {
      return;
    }

    setState(
      () {
        _isEditing = false;
      },
    );
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<
    void
  >
  _save() async {
    final title = _controller.titleController.text.trim();

    final content = _controller.contentController.text.trim();

    if (title.isEmpty) {
      _showMessage(
        'Digite um título antes de salvar.',
      );

      return;
    }

    if (content.isEmpty) {
      _showMessage(
        'Digite o conteúdo antes de salvar.',
      );

      return;
    }

    final saved = await _controller.saveNote();

    if (!mounted) {
      return;
    }

    if (!saved) {
      _showControllerMessage();

      return;
    }

    setState(
      () {
        _isEditing = false;
      },
    );

    _showControllerMessage();
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  _delete(
    BrainFile note,
  ) async {
    if (_isDeleting ||
        _controller.isSaving) {
      return;
    }

    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  title: const Text(
                    'Excluir anotação?',
                  ),
                  content: Text(
                    'Deseja excluir permanentemente "${note.title}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(
                          dialogContext,
                          true,
                        );
                      },
                      child: const Text(
                        'Excluir',
                      ),
                    ),
                  ],
                );
              },
        );

    if (!mounted ||
        confirmed !=
            true) {
      return;
    }

    setState(
      () {
        _isDeleting = true;
      },
    );

    final deleted = await _controller.deleteNote(
      note,
    );

    if (!mounted) {
      return;
    }

    if (!deleted) {
      setState(
        () {
          _isDeleting = false;
        },
      );

      _showControllerMessage();

      return;
    }

    Navigator.of(
      context,
    ).pop(
      true,
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showControllerMessage() {
    final error = _controller.errorMessage;

    final success = _controller.successMessage;

    if (error !=
        null) {
      _showMessage(
        error,
      );

      _controller.clearMessages();

      return;
    }

    if (success !=
        null) {
      _showMessage(
        success,
      );

      _controller.clearMessages();
    }
  }

  void _showMessage(
    String message,
  ) {
    final messenger = ScaffoldMessenger.of(
      context,
    );

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
      ),
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
    DateTime date,
  ) {
    final local = date.toLocal();

    String two(
      int value,
    ) {
      return value.toString().padLeft(
        2,
        '0',
      );
    }

    return '${two(local.day)}/'
        '${two(local.month)}/'
        '${local.year} '
        '${two(local.hour)}:'
        '${two(local.minute)}';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing
              ? 'Editar anotação'
              : 'Anotação',
        ),
        actions: [
          if (!_isOpening &&
              _openError ==
                  null &&
              !_isEditing)
            IconButton(
              tooltip: 'Editar',
              onPressed:
                  _controller.isSaving ||
                      _isDeleting
                  ? null
                  : _startEditing,
              icon: const Icon(
                Icons.edit_outlined,
              ),
            ),

          if (_isEditing)
            TextButton(
              onPressed: _controller.isSaving
                  ? null
                  : _cancelEditing,
              child: const Text(
                'Cancelar',
              ),
            ),

          if (!_isEditing &&
              !_isOpening &&
              _openError ==
                  null)
            IconButton(
              tooltip: 'Excluir',
              onPressed: _isDeleting
                  ? null
                  : () {
                      _delete(
                        _currentNote,
                      );
                    },
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
            ),

          const SizedBox(
            width: 8,
          ),
        ],
      ),
      body: _buildBody(
        context,
      ),
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(
    BuildContext context,
  ) {
    if (_isOpening) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_openError !=
        null) {
      return _buildError();
    }

    if (_isEditing) {
      return _buildEditor();
    }

    return _buildViewer(
      context,
    );
  }

  // ============================================================
  // VIEWER
  // ============================================================

  Widget _buildViewer(
    BuildContext context,
  ) {
    final note = _currentNote;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        24,
        24,
        24,
        40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 900,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // TOPIC
              // ==================================================
              if (note.topic.trim().isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(
                          alpha: 0.10,
                        ),
                    borderRadius: BorderRadius.circular(
                      999,
                    ),
                  ),
                  child: Text(
                    note.topic,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary,
                    ),
                  ),
                ),

              const SizedBox(
                height: 18,
              ),

              // ==================================================
              // TITLE
              // ==================================================
              SelectableText(
                note.title,
                style:
                    Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),

              const SizedBox(
                height: 12,
              ),

              // ==================================================
              // DATES
              // ==================================================
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _meta(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    text: 'Criado em ${_formatDate(note.createdAt)}',
                  ),
                  _meta(
                    context: context,
                    icon: Icons.update_rounded,
                    text: 'Atualizado em ${_formatDate(note.updatedAt)}',
                  ),
                ],
              ),

              const SizedBox(
                height: 24,
              ),

              Divider(
                color:
                    Theme.of(
                      context,
                    ).dividerColor.withValues(
                      alpha: 0.55,
                    ),
              ),

              const SizedBox(
                height: 24,
              ),

              // ==================================================
              // CONTENT
              // ==================================================
              SelectableText(
                note.content,
                style:
                    Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      height: 1.65,
                    ),
              ),

              if (note.concepts.isNotEmpty) ...[
                const SizedBox(
                  height: 30,
                ),

                Divider(
                  color:
                      Theme.of(
                        context,
                      ).dividerColor.withValues(
                        alpha: 0.55,
                      ),
                ),

                const SizedBox(
                  height: 18,
                ),

                Text(
                  'Classificações',
                  style:
                      Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final concept in note.concepts)
                      Chip(
                        avatar: Icon(
                          _conceptIcon(
                            concept.type,
                          ),
                          size: 16,
                          color: _conceptColor(
                            concept.type,
                          ),
                        ),
                        label: Text(
                          _conceptLabel(
                            concept.type,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EDITOR
  // ============================================================

  Widget _buildEditor() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(
        24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 900,
          ),
          child: BrainEditorSection(
            selectedNote: _controller.selectedNote,
            topicController: _controller.topicController,
            titleController: _controller.titleController,
            contentController: _controller.contentController,
            contentFocusNode: _controller.contentFocusNode,
            isSaving: _controller.isSaving,
            onSave: _save,
            onDelete: _delete,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CLASSIFICAÇÃO
  // ============================================================
  //
  // BrainConceptType é um enum de domínio e não possui getters
  // visuais como icon, color ou label.
  //
  // Por isso esta tela resolve a apresentação localmente.
  //
  // ============================================================

  IconData _conceptIcon(
    BrainConceptType type,
  ) {
    switch (type) {
      case BrainConceptType.concept:
        return Icons.lightbulb_outline_rounded;

      case BrainConceptType.question:
        return Icons.help_outline_rounded;

      case BrainConceptType.example:
        return Icons.code_rounded;

      case BrainConceptType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  Color _conceptColor(
    BrainConceptType type,
  ) {
    switch (type) {
      case BrainConceptType.concept:
        return const Color(
          0xFF3B6939,
        );

      case BrainConceptType.question:
        return const Color(
          0xFF3859FF,
        );

      case BrainConceptType.example:
        return const Color(
          0xFF6D4AFF,
        );

      case BrainConceptType.warning:
        return const Color(
          0xFFB26A00,
        );
    }
  }

  String _conceptLabel(
    BrainConceptType type,
  ) {
    switch (type) {
      case BrainConceptType.concept:
        return 'Conceito';

      case BrainConceptType.question:
        return 'Pergunta';

      case BrainConceptType.example:
        return 'Exemplo';

      case BrainConceptType.warning:
        return 'Atenção';
    }
  }

  // ============================================================
  // META
  // ============================================================

  Widget _meta({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 15,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(
          width: 5,
        ),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall,
        ),
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              _openError ??
                  'Não foi possível abrir a anotação.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 16,
            ),
            FilledButton.icon(
              onPressed: _openNote,
              icon: const Icon(
                Icons.refresh_rounded,
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
