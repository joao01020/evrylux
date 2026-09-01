import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart' as dependencies;

import '../controllers/brain_controller.dart';
import '../controllers/review_controller.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';

import '../sections/brain_editor_section.dart';

// ============================================================
// SCREENS
// ============================================================

import 'concept/concept_screen.dart';
import 'question/question_screen.dart';
import 'example/example_screen.dart';
import 'warning/warning_screen.dart';

// ============================================================
// BRAIN SCREEN
// ============================================================
//
// Esta tela NÃO cria nem destrói o BrainController.
//
// Exclusões usam o fluxo offline-first real e removem o arquivo
// Markdown local antes da sincronização remota.
//
// O controller é compartilhado pelo container global de
// dependências para manter a mesma SyncQueue e o mesmo
// SyncService utilizados pelo restante do aplicativo.
//
// ============================================================

class BrainScreen
    extends
        StatefulWidget {
  const BrainScreen({
    super.key,
  });

  @override
  State<
    BrainScreen
  >
  createState() {
    return _BrainScreenState();
  }
}

class _BrainScreenState
    extends
        State<
          BrainScreen
        > {
  late final BrainController _controller;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ========================================================
    // CONTROLLER GLOBAL OFFLINE-FIRST
    // ========================================================
    //
    // Usa exatamente a instância configurada em:
    //
    // app_dependencies.dart
    //
    // Assim o fluxo permanece:
    //
    // BrainController
    //      ↓
    // BrainRepository
    //      ↓
    // BrainStorage
    //      ↓
    // SyncQueue
    //      ↓
    // SyncService
    //      ↓
    // Supabase
    //
    // Não criamos BrainController() localmente nesta tela.
    //
    // ========================================================

    _controller = dependencies.brainController;

    _controller.addListener(
      _onControllerChanged,
    );

    _initialize();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    // ========================================================
    // NÃO FAZER DISPOSE
    // ========================================================
    //
    // O BrainController pertence ao container global de
    // dependências da aplicação.
    //
    // Esta tela apenas remove seu listener.
    //
    // Fazer _controller.dispose() aqui inutilizaria a mesma
    // instância quando o usuário abrisse o Cérebro novamente.
    //
    // ========================================================

    super.dispose();
  }

  // ============================================================
  // CONTROLLER
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
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  _initialize() async {
    await _controller.initialize();

    if (!mounted) {
      return;
    }

    _controller.createNewNote();

    _showControllerMessage();
  }

  // ============================================================
  // NOVA ANOTAÇÃO
  // ============================================================

  void _createNewNote() {
    _controller.createNewNote();
  }

  // ============================================================
  // EXCLUIR ANOTAÇÃO
  // ============================================================
  //
  // O BrainEditorSection já pede confirmação ao usuário.
  //
  // Aqui executamos a exclusão REAL:
  //
  // BrainController
  //      ↓
  // BrainRepository
  //      ↓
  // BrainStorage apaga o .md local
  //      ↓
  // SyncQueue recebe DELETE
  //      ↓
  // SyncService envia ao Supabase quando houver conexão
  //
  // Como o calendário lê os arquivos locais, ao voltar para
  // StudyScreen a data é recalculada por loadCreatedDates().
  //
  // ============================================================

  Future<
    void
  >
  _deleteNote(
    BrainFile note,
  ) async {
    final deleted = await _controller.deleteNote(
      note,
    );

    if (!mounted) {
      return;
    }

    if (!deleted) {
      _showControllerMessage();

      return;
    }

    // ========================================================
    // FORMULÁRIO LIMPO APÓS EXCLUSÃO REAL
    // ========================================================

    _controller.createNewNote();

    _showControllerMessage();
  }

  // ============================================================
  // SALVAR
  // ============================================================

  Future<
    void
  >
  _saveNote() async {
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
        'Digite o conteúdo da anotação antes de salvar.',
      );

      return;
    }

    // ==========================================================
    // ESCOLHER TIPO
    // ==========================================================

    final type = await _showSaveTypeDialog();

    if (!mounted ||
        type ==
            null) {
      return;
    }

    // ==========================================================
    // PROCURAR CONHECIMENTO EXISTENTE
    // ==========================================================

    BrainConcept? existingConcept;

    for (final item in _controller.concepts) {
      if (item.type ==
              type &&
          item.title.trim() ==
              title &&
          item.description.trim() ==
              content) {
        existingConcept = item;

        break;
      }
    }

    // ==========================================================
    // CRIAR CONHECIMENTO
    // ==========================================================

    final concept =
        existingConcept ??
        BrainConcept(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title,
          description: content,
          type: type,
        );

    // ==========================================================
    // ADICIONAR AO ARQUIVO
    // ==========================================================

    if (existingConcept ==
        null) {
      await _controller.addConcept(
        concept,
      );

      if (!mounted) {
        return;
      }
    }

    // ==========================================================
    // SALVAR OFFLINE-FIRST
    // ==========================================================
    //
    // O controller chama o BrainRepository configurado
    // globalmente.
    //
    // O repository:
    //
    // 1. salva o Markdown local;
    // 2. adiciona a alteração na SyncQueue;
    // 3. solicita o SyncService;
    // 4. sincroniza com Supabase quando houver conexão.
    //
    // ==========================================================

    final saved = await _controller.saveNote();

    if (!mounted) {
      return;
    }

    if (!saved) {
      _showControllerMessage();

      return;
    }

    // ==========================================================
    // PERGUNTA → SISTEMA DE REVISÃO
    // ==========================================================

    if (type ==
        BrainConceptType.question) {
      final sourceNotePath =
          _controller.selectedNote?.path.trim() ??
          '';

      if (sourceNotePath.isEmpty) {
        _showMessage(
          'A anotação foi salva, mas não foi possível identificar o arquivo local para criar a revisão.',
        );

        return;
      }

      await _createQuestionReview(
        concept: concept,
        answer: content,
        title: title,
        sourceNotePath: sourceNotePath,
      );

      if (!mounted) {
        return;
      }
    }

    _showControllerMessage();

    if (!mounted) {
      return;
    }

    // ==========================================================
    // ABRIR DESTINO
    // ==========================================================

    await _openTypeScreen(
      type,
    );

    if (!mounted) {
      return;
    }

    // ==========================================================
    // NOVO FORMULÁRIO AO VOLTAR
    // ==========================================================

    _controller.createNewNote();
  }

  // ============================================================
  // REVIEW
  // ============================================================

  Future<
    void
  >
  _createQuestionReview({
    required BrainConcept concept,
    required String answer,
    required String title,
    required String sourceNotePath,
  }) async {
    final reviewController = ReviewController();

    try {
      await reviewController.initialize();

      final existing = reviewController.findByConceptId(
        concept.id,
      );

      if (existing !=
          null) {
        return;
      }

      await reviewController.createFromConcept(
        concept: concept,
        answer: answer,
        sourceNotePath: sourceNotePath,
        sourceNoteTitle: title,
        firstReviewAt: DateTime.now(),
      );
    } finally {
      reviewController.dispose();
    }
  }

  // ============================================================
  // SELECIONAR TIPO PARA SALVAR
  // ============================================================

  Future<
    BrainConceptType?
  >
  _showSaveTypeDialog() {
    return showDialog<
      BrainConceptType
    >(
      context: context,
      barrierDismissible: true,
      builder:
          (
            dialogContext,
          ) {
            return Dialog(
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 540,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    dialogContext,
                                  ).colorScheme.primary.withValues(
                                    alpha: 0.10,
                                  ),
                              borderRadius: BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome_outlined,
                              color: Theme.of(
                                dialogContext,
                              ).colorScheme.primary,
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
                                  'Salvar conhecimento',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(
                                  height: 2,
                                ),
                                Text(
                                  'Escolha como esta anotação será utilizada.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 24,
                      ),

                      _buildSaveTypeOption(
                        dialogContext: dialogContext,
                        type: BrainConceptType.concept,
                        subtitle: 'Definição ou conhecimento para consultar quando precisar.',
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      _buildSaveTypeOption(
                        dialogContext: dialogContext,
                        type: BrainConceptType.question,
                        subtitle: 'Transforma o conteúdo em revisão ativa para você aprender.',
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      _buildSaveTypeOption(
                        dialogContext: dialogContext,
                        type: BrainConceptType.example,
                        subtitle: 'Código, aplicação prática, demonstração ou referência.',
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      _buildSaveTypeOption(
                        dialogContext: dialogContext,
                        type: BrainConceptType.warning,
                        subtitle: 'Erro, cuidado ou detalhe importante que merece atenção.',
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                            );
                          },
                          child: const Text(
                            'Cancelar',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // OPÇÃO DE TIPO
  // ============================================================

  Widget _buildSaveTypeOption({
    required BuildContext dialogContext,
    required BrainConceptType type,
    required String subtitle,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          16,
        ),
        onTap: () {
          Navigator.pop(
            dialogContext,
            type,
          );
        },
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(
            14,
          ),
          decoration: BoxDecoration(
            color: type.color.withValues(
              alpha: 0.055,
            ),
            borderRadius: BorderRadius.circular(
              16,
            ),
            border: Border.all(
              color: type.color.withValues(
                alpha: 0.20,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: type.color.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(
                    13,
                  ),
                ),
                child: Icon(
                  type.icon,
                  color: type.color,
                  size: 23,
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          type.emoji,
                          style: const TextStyle(
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        Text(
                          type.label,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(
                        dialogContext,
                      ).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                width: 8,
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: type.color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MODAL DE INFORMAÇÕES
  // ============================================================

  Future<
    void
  >
  _showKnowledgeInfoDialog() async {
    await showDialog<
      void
    >(
      context: context,
      barrierDismissible: true,
      builder:
          (
            dialogContext,
          ) {
            return Dialog(
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 620,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(
                    24,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ==================================================
                        // HEADER
                        // ==================================================
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      dialogContext,
                                    ).colorScheme.primary.withValues(
                                      alpha: 0.10,
                                    ),
                                borderRadius: BorderRadius.circular(
                                  13,
                                ),
                              ),
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: Theme.of(
                                  dialogContext,
                                ).colorScheme.primary,
                              ),
                            ),

                            const SizedBox(
                              width: 13,
                            ),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Como funciona o Cérebro?',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 4,
                                  ),
                                  Text(
                                    'Cada anotação pode ter uma função diferente dentro do seu conhecimento.',
                                  ),
                                ],
                              ),
                            ),

                            IconButton(
                              tooltip: 'Fechar',
                              onPressed: () {
                                Navigator.pop(
                                  dialogContext,
                                );
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        // ==================================================
                        // CONCEITO
                        // ==================================================
                        _buildInfoTypeCard(
                          context: dialogContext,
                          type: BrainConceptType.concept,
                          title: 'Conceito',
                          description: 'Use para salvar uma definição, ideia ou conhecimento que você queira consultar novamente.',
                          example: 'Exemplo: "O que é um ponteiro em C?"',
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        // ==================================================
                        // PERGUNTA
                        // ==================================================
                        _buildInfoTypeCard(
                          context: dialogContext,
                          type: BrainConceptType.question,
                          title: 'Pergunta',
                          description: 'Use quando quiser aprender algo por revisão. A pergunta entra no sistema de revisão e volta a aparecer até você dominar.',
                          example: 'Título: "O que é um ponteiro?"\nConteúdo: a resposta que você deseja aprender.',
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        // ==================================================
                        // EXEMPLO
                        // ==================================================
                        _buildInfoTypeCard(
                          context: dialogContext,
                          type: BrainConceptType.example,
                          title: 'Exemplo',
                          description: 'Use para guardar demonstrações, trechos de código, aplicações práticas ou formas de aplicar um conceito.',
                          example: 'Exemplo: um código usando ponteiros ou uma situação prática.',
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        // ==================================================
                        // ATENÇÃO
                        // ==================================================
                        _buildInfoTypeCard(
                          context: dialogContext,
                          type: BrainConceptType.warning,
                          title: 'Atenção',
                          description: 'Use para registrar erros comuns, cuidados, detalhes importantes e coisas que você não quer esquecer.',
                          example: 'Exemplo: "Nunca acessar um ponteiro nulo."',
                        ),

                        const SizedBox(
                          height: 22,
                        ),

                        // ==================================================
                        // COMO SALVAR
                        // ==================================================
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(
                            16,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(
                                  dialogContext,
                                ).colorScheme.surfaceContainerHighest.withValues(
                                  alpha: 0.45,
                                ),
                            borderRadius: BorderRadius.circular(
                              16,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.save_outlined,
                                    size: 20,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ),
                                  Text(
                                    'Como salvar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              _buildInfoStep(
                                number: '1',
                                text: 'Preencha o tema, o título e o conteúdo da anotação.',
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              _buildInfoStep(
                                number: '2',
                                text: 'Clique em "Salvar em .md". O arquivo é salvo primeiro neste dispositivo.',
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              _buildInfoStep(
                                number: '3',
                                text: 'Escolha Conceito, Pergunta, Exemplo ou Atenção.',
                              ),

                              const SizedBox(
                                height: 8,
                              ),

                              _buildInfoStep(
                                number: '4',
                                text: 'O conteúdo fica disponível imediatamente e será sincronizado automaticamente com a nuvem quando houver conexão.',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.pop(
                                dialogContext,
                              );
                            },
                            child: const Text(
                              'Entendi',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
    );
  }

  // ============================================================
  // CARD DO MODAL DE INFORMAÇÕES
  // ============================================================

  Widget _buildInfoTypeCard({
    required BuildContext context,
    required BrainConceptType type,
    required String title,
    required String description,
    required String example,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: type.color.withValues(
          alpha: 0.055,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: type.color.withValues(
            alpha: 0.18,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: type.color.withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              type.icon,
              color: type.color,
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
                Row(
                  children: [
                    Text(
                      type.emoji,
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(
                      width: 6,
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 5,
                ),

                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium,
                ),

                const SizedBox(
                  height: 7,
                ),

                Text(
                  example,
                  style:
                      Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PASSO DO MODAL
  // ============================================================

  Widget _buildInfoStep({
    required String number,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 23,
          height: 23,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                Theme.of(
                  context,
                ).colorScheme.primary.withValues(
                  alpha: 0.10,
                ),
            borderRadius: BorderRadius.circular(
              7,
            ),
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Theme.of(
                context,
              ).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(
          width: 9,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(
              top: 2,
            ),
            child: Text(
              text,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NAVEGAÇÃO
  // ============================================================

  Future<
    void
  >
  _openTypeScreen(
    BrainConceptType type,
  ) async {
    final Widget screen;

    switch (type) {
      case BrainConceptType.concept:
        screen = const ConceptScreen();
        break;

      case BrainConceptType.question:
        screen = const QuestionScreen();
        break;

      case BrainConceptType.example:
        screen = const ExampleScreen();
        break;

      case BrainConceptType.warning:
        screen = const WarningScreen();
        break;
    }

    await Navigator.of(
      context,
    ).push(
      MaterialPageRoute(
        builder:
            (
              _,
            ) {
              return screen;
            },
      ),
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
  // CATEGORY BUTTON
  // ============================================================

  Widget _buildTypeButton({
    required BrainConceptType type,
  }) {
    return Tooltip(
      message: type.label,
      child: IconButton(
        onPressed: _controller.isSaving
            ? null
            : () {
                _openTypeScreen(
                  type,
                );
              },
        icon: Icon(
          type.icon,
          size: 20,
          color: type.color,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: _buildAppBar(
        context,
      ),
      body: _controller.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildBody(
              context,
            ),
    );
  }

  // ============================================================
  // APP BAR
  // ============================================================

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
  ) {
    return AppBar(
      toolbarHeight: 58,
      titleSpacing: 18,
      title: const Row(
        children: [
          Icon(
            Icons.psychology_alt_outlined,
            size: 22,
          ),
          SizedBox(
            width: 9,
          ),
          Text(
            'Cérebro',
          ),
        ],
      ),
      actions: [
        Tooltip(
          message: 'Nova anotação',
          child: IconButton(
            onPressed: _controller.isSaving
                ? null
                : _createNewNote,
            icon: const Icon(
              Icons.add_rounded,
            ),
          ),
        ),

        Container(
          width: 1,
          height: 22,
          margin: const EdgeInsets.symmetric(
            horizontal: 7,
            vertical: 18,
          ),
          color:
              Theme.of(
                context,
              ).dividerColor.withValues(
                alpha: 0.40,
              ),
        ),

        _buildTypeButton(
          type: BrainConceptType.concept,
        ),

        _buildTypeButton(
          type: BrainConceptType.question,
        ),

        _buildTypeButton(
          type: BrainConceptType.example,
        ),

        _buildTypeButton(
          type: BrainConceptType.warning,
        ),

        const SizedBox(
          width: 10,
        ),
      ],
    );
  }

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(
    BuildContext context,
  ) {
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
            maxWidth: 1040,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(
                context,
              ),

              const SizedBox(
                height: 22,
              ),

              _buildEditorCard(
                context,
              ),

              const SizedBox(
                height: 18,
              ),

              _buildKnowledgeHint(
                context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _controller.selectedNote ==
                        null
                    ? 'Nova anotação'
                    : 'Editando anotação',
                style:
                    Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(
                height: 5,
              ),
              Text(
                'Capture uma ideia e defina depois como ela será usada.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        const SizedBox(
          width: 16,
        ),

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
                  alpha: 0.08,
                ),
            borderRadius: BorderRadius.circular(
              999,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 17,
                color: Theme.of(
                  context,
                ).colorScheme.primary,
              ),
              const SizedBox(
                width: 6,
              ),
              const Text(
                'Capturar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EDITOR CARD
  // ============================================================

  Widget _buildEditorCard(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        20,
      ),
      decoration: BoxDecoration(
        color:
            Theme.of(
              context,
            ).colorScheme.surface.withValues(
              alpha: 0.35,
            ),
        borderRadius: BorderRadius.circular(
          20,
        ),
        border: Border.all(
          color:
              Theme.of(
                context,
              ).dividerColor.withValues(
                alpha: 0.55,
              ),
        ),
      ),
      child: AnimatedSize(
        duration: const Duration(
          milliseconds: 180,
        ),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: BrainEditorSection(
          selectedNote: _controller.selectedNote,
          topicController: _controller.topicController,
          titleController: _controller.titleController,
          contentController: _controller.contentController,
          contentFocusNode: _controller.contentFocusNode,
          isSaving: _controller.isSaving,
          onSave: _saveNote,
          onDelete: _deleteNote,
        ),
      ),
    );
  }

  // ============================================================
  // HINT CLICÁVEL
  // ============================================================

  Widget _buildKnowledgeHint(
    BuildContext context,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(
          16,
        ),
        onTap: _showKnowledgeInfoDialog,
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
              16,
            ),
            color:
                Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
          ),
          child: Row(
            children: [
              Tooltip(
                message: 'Saiba como funciona',
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(
                          alpha: 0.08,
                        ),
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 19,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary,
                  ),
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              const Expanded(
                child: Text(
                  'Ao salvar, escolha entre Conceito, Pergunta, Exemplo ou Atenção.',
                ),
              ),

              const SizedBox(
                width: 14,
              ),

              Wrap(
                spacing: 8,
                children: [
                  _miniTypeIcon(
                    BrainConceptType.concept,
                  ),
                  _miniTypeIcon(
                    BrainConceptType.question,
                  ),
                  _miniTypeIcon(
                    BrainConceptType.example,
                  ),
                  _miniTypeIcon(
                    BrainConceptType.warning,
                  ),
                ],
              ),

              const SizedBox(
                width: 8,
              ),

              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MINI ICON
  // ============================================================

  Widget _miniTypeIcon(
    BrainConceptType type,
  ) {
    return Tooltip(
      message: type.label,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: type.color.withValues(
            alpha: 0.10,
          ),
          borderRadius: BorderRadius.circular(
            9,
          ),
        ),
        child: Icon(
          type.icon,
          size: 16,
          color: type.color,
        ),
      ),
    );
  }
}
