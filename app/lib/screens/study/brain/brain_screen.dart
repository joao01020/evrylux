import 'package:flutter/material.dart';

import 'controllers/brain_controller.dart';

import 'dialogs/brain_concept_dialog.dart';
import 'dialogs/delete_note_dialog.dart';

import 'models/brain_concept.dart';
import 'models/brain_file.dart';

import 'sections/brain_concepts_section.dart';
import 'sections/brain_editor_section.dart';
import 'sections/brain_notes_section.dart';

import 'widgets/brain_sidebar.dart';

class BrainScreen extends StatefulWidget {
  const BrainScreen({super.key});

  @override
  State<BrainScreen> createState() {
    return _BrainScreenState();
  }
}

class _BrainScreenState extends State<BrainScreen> {
  late final BrainController _controller;

  // =========================================================
  // CICLO DE VIDA
  // =========================================================

  @override
  void initState() {
    super.initState();

    _controller = BrainController();

    _controller.addListener(_onControllerChanged);

    _initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);

    _controller.dispose();

    super.dispose();
  }

  // =========================================================
  // ATUALIZAÇÃO DA INTERFACE
  // =========================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // =========================================================
  // INICIALIZAÇÃO
  // =========================================================

  Future<void> _initialize() async {
    await _controller.initialize();

    if (!mounted) {
      return;
    }

    _showControllerMessage();
  }

  // =========================================================
  // NOVA NOTA
  // =========================================================

  void _createNewNote() {
    _controller.createNewNote();
  }

  // =========================================================
  // ABRIR NOTA
  // =========================================================

  Future<void> _openNote(BrainFile note) async {
    await _controller.openNote(note);

    if (!mounted) {
      return;
    }

    _showControllerMessage();
  }

  // =========================================================
  // SALVAR NOTA
  // =========================================================

  Future<void> _saveNote() async {
    await _controller.saveNote();

    if (!mounted) {
      return;
    }

    _showControllerMessage();
  }

  // =========================================================
  // EXCLUIR NOTA
  // =========================================================

  Future<void> _deleteNote(BrainFile note) async {
    final confirmed = await DeleteNoteDialog.show(context: context, note: note);

    if (!mounted) {
      return;
    }

    if (!confirmed) {
      return;
    }

    await _controller.deleteNote(note);

    if (!mounted) {
      return;
    }

    _showControllerMessage();
  }

  // =========================================================
  // CONVERTER CATEGORIA PARA TIPO
  // =========================================================

  BrainConceptType _convertCategoryToType(BrainConceptCategory category) {
    return BrainConceptType.values.firstWhere(
      (type) {
        return type.name == category.name;
      },
      orElse: () {
        return BrainConceptType.values.first;
      },
    );
  }

  // =========================================================
  // ADICIONAR CONCEITO
  // =========================================================

  Future<void> _addConcept() async {
    final result = await BrainConceptDialog.show(context: context);

    if (!mounted) {
      return;
    }

    if (result == null) {
      return;
    }

    final concept = BrainConcept(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: result.title,
      description: result.description,
      type: _convertCategoryToType(result.category),
    );

    _controller.addConcept(concept);

    _showControllerMessage();
  }

  // =========================================================
  // REMOVER CONCEITO
  // =========================================================

  void _removeConcept(int index) {
    _controller.removeConcept(index);

    _showControllerMessage();
  }

  // =========================================================
  // MENSAGENS DO CONTROLLER
  // =========================================================

  void _showControllerMessage() {
    final errorMessage = _controller.errorMessage;

    final successMessage = _controller.successMessage;

    if (errorMessage != null) {
      _showMessage(errorMessage);

      _controller.clearMessages();

      return;
    }

    if (successMessage != null) {
      _showMessage(successMessage);

      _controller.clearMessages();
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  // =========================================================
  // TELA
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cérebro 🧠'),
        actions: [
          IconButton(
            tooltip: 'Nova anotação',
            onPressed: _controller.isSaving ? null : _createNewNote,
            icon: const Icon(Icons.note_add_outlined),
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;

                if (isWide) {
                  return _buildWideLayout();
                }

                return _buildCompactLayout();
              },
            ),
    );
  }

  // =========================================================
  // LAYOUT GRANDE
  // =========================================================

  Widget _buildWideLayout() {
    return Row(
      children: [
        SizedBox(
          width: 310,
          child: BrainSidebar(
            notes: _controller.notes,
            selectedNote: _controller.selectedNote,
            onCreateNote: _createNewNote,
            onOpenNote: _openNote,
            onDeleteNote: _deleteNote,
          ),
        ),

        const VerticalDivider(width: 1),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEditorSection(),

                const SizedBox(height: 32),

                _buildConceptsSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // LAYOUT PEQUENO
  // =========================================================

  Widget _buildCompactLayout() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildEditorSection(),

        const SizedBox(height: 32),

        _buildConceptsSection(),

        const SizedBox(height: 32),

        _buildNotesSection(),
      ],
    );
  }

  // =========================================================
  // SEÇÃO DO EDITOR
  // =========================================================

  Widget _buildEditorSection() {
    return BrainEditorSection(
      selectedNote: _controller.selectedNote,
      topicController: _controller.topicController,
      titleController: _controller.titleController,
      contentController: _controller.contentController,
      contentFocusNode: _controller.contentFocusNode,
      isSaving: _controller.isSaving,
      onSave: _saveNote,
      onDelete: _deleteNote,
    );
  }

  // =========================================================
  // SEÇÃO DE NOTAS
  // =========================================================

  Widget _buildNotesSection() {
    return BrainNotesSection(
      notes: _controller.notes,
      selectedNote: _controller.selectedNote,
      onOpenNote: _openNote,
      onDeleteNote: _deleteNote,
    );
  }

  // =========================================================
  // SEÇÃO DE CONCEITOS
  // =========================================================

  Widget _buildConceptsSection() {
    return BrainConceptsSection(
      concepts: _controller.concepts,
      onAddConcept: _addConcept,
      itemBuilder: (context, concept, index) {
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.lightbulb_outline),
            title: Text(concept.title),
            subtitle: Text(concept.description),
            trailing: IconButton(
              tooltip: 'Remover conceito',
              onPressed: () {
                _removeConcept(index);
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        );
      },
    );
  }
}
