part of '../brain_screen.dart';

// Knowledge creation flow: save, review, type selection, source editing and question batches.
extension _BrainScreenCreation
    on
        _BrainScreenState {
  // ============================================================
  // SALVAR CONHECIMENTO
  // ============================================================
  //
  // O tipo agora é escolhido ANTES de abrir o formulário.
  //
  // Conceito / Exemplo / Atenção:
  //
  //   seletor de tipo
  //        ↓
  //   modal de anotação
  //
  // Pergunta:
  //
  //   seletor de tipo
  //        ↓
  //   modal exclusivo de pergunta + revisão
  //
  // ============================================================

  Future<
    bool
  >
  _saveKnowledge({
    required BrainConceptType type,
    DateTime? firstReviewAt,
    bool reviewEnabled = false,
    List<
          BrainSource
        >
        sources =
        const <
          BrainSource
        >[],
  }) async {
    final title = _controller.titleController.text.trim();

    final content = _controller.contentController.text.trim();

    // ==========================================================
    // FASE 09 — CAPTURA SEM TEMA
    // ==========================================================
    //
    // Tema não faz mais parte da experiência de criação.
    //
    // O valor abaixo existe APENAS como compatibilidade temporária
    // com BrainController / BrainRepository / BrainStorage legados,
    // que ainda serão migrados nos próximos blocos da Fase 09.
    //
    // Nenhum campo "Tema" é exibido ao usuário.
    //
    // ==========================================================

    if (_controller.topicController.text.trim().isEmpty) {
      _controller.topicController.text = 'Sem tema';
    }

    if (title.isEmpty) {
      _showMessage(
        type ==
                BrainConceptType.question
            ? 'Digite a pergunta antes de salvar.'
            : 'Digite um título antes de salvar.',
      );

      return false;
    }

    if (content.isEmpty) {
      _showMessage(
        type ==
                BrainConceptType.question
            ? 'Digite a resposta antes de salvar.'
            : 'Digite o conteúdo da anotação antes de salvar.',
      );

      return false;
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
          reviewEnabled: reviewEnabled,
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
        return false;
      }
    }

    // ==========================================================
    // SALVAR OFFLINE-FIRST
    // ==========================================================

    final saved = await _controller.saveNote();

    if (!mounted) {
      return false;
    }

    if (!saved) {
      _showControllerMessage();

      return false;
    }

    // ==========================================================
    // FASE 13 — FONTES DO CONHECIMENTO
    // ==========================================================
    //
    // A nota precisa existir antes de uma fonte ser persistida,
    // pois BrainController.addSource() trabalha sobre a nota já
    // salva no Vault.
    //
    // As fontes escolhidas durante o modal ficam apenas em memória
    // até este ponto. Depois do primeiro save, são anexadas uma a
    // uma ao BrainFile criptografado.
    //
    // ==========================================================

    for (final source in sources) {
      final sourceSaved = await _controller.addSource(
        source,
      );

      if (!mounted) {
        return false;
      }

      if (!sourceSaved) {
        _showControllerMessage();

        return false;
      }
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
          'A pergunta foi salva, mas não foi possível identificar o arquivo local para criar a revisão.',
        );

        return false;
      }

      await _createQuestionReview(
        concept: concept,
        answer: content,
        title: title,
        sourceNotePath: sourceNotePath,
        firstReviewAt:
            firstReviewAt ??
            DateTime.now(),
      );

      if (!mounted) {
        return false;
      }
    }


    // ==========================================================
    // CONCEITO MARCADO → REVISÕES AUTOMÁTICAS LOCAIS
    // ==========================================================
    //
    // O usuário só marca "Usar este conhecimento para revisão".
    // O motor local separa o conteúdo, encontra afirmações revisáveis,
    // gera perguntas abertas e persiste cada uma como BrainReviewItem.
    // ==========================================================

    if (type == BrainConceptType.concept && reviewEnabled) {
      final sourceNotePath = _controller.selectedNote?.path.trim() ?? '';
      final sourceNoteTitle = _controller.selectedNote?.title.trim() ?? title;

      if (sourceNotePath.isEmpty) {
        _showMessage(
          'O conhecimento foi salvo, mas não foi possível identificar a anotação para gerar as revisões.',
        );
        return false;
      }

      final reviewController = dependencies.reviewController;
      await reviewController.generateAndSaveReviewsForConcept(
        concept: concept,
        sourceNotePath: sourceNotePath,
        sourceNoteTitle: sourceNoteTitle,
        firstReviewAt: firstReviewAt ?? DateTime.now(),
      );

      if (!mounted) {
        return false;
      }

      final reviewError = reviewController.errorMessage;
      if (reviewError != null) {
        _showMessage(
          'O conhecimento foi salvo, mas as perguntas de revisão não puderam ser geradas: $reviewError',
        );
        reviewController.clearMessages();
        return false;
      }
    }

    _showControllerMessage();

    if (!mounted) {
      return false;
    }

    return true;
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
    required DateTime firstReviewAt,
  }) async {
    // ========================================================
    // REVIEW CONTROLLER GLOBAL OFFLINE-FIRST
    // ========================================================
    //
    // Usa a mesma instância criada em app_dependencies.dart:
    //
    // ReviewController
    //      ↓
    // ReviewRepository
    //      ↓
    // ReviewStorage
    //      ↓
    // SyncQueue
    //      ↓
    // SyncService
    //      ↓
    // SupabaseReviewService
    //      ↓
    // brain_reviews
    //
    // Não criamos ReviewController() localmente e também não
    // fazemos dispose(), porque essa instância pertence ao
    // container global da aplicação.
    //
    // ========================================================

    final reviewController = dependencies.reviewController;

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
      firstReviewAt: firstReviewAt,
    );

    if (!mounted) {
      return;
    }

    final error = reviewController.errorMessage;

    if (error !=
        null) {
      _showMessage(
        error,
      );

      reviewController.clearMessages();
    }
  }

  // ============================================================
  // SELECIONAR TIPO PARA SALVAR
  // ============================================================
  //
  // Tipos principais visíveis:
  //
  // - Conceito
  // - Pergunta
  //
  // BrainConceptType.example e BrainConceptType.warning continuam
  // existindo para compatibilidade e podem ser adicionados como
  // detalhes opcionais dentro de um conceito.
  //
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
                                  'Escolha o que deseja criar.',
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
                        subtitle: 'Registre algo que você aprendeu e queira consultar depois.',
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      _buildSaveTypeOption(
                        dialogContext: dialogContext,
                        type: BrainConceptType.question,
                        subtitle: 'Crie uma pergunta para transformar o conhecimento em revisão ativa.',
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
              // ==================================================
              // ÍCONE PRINCIPAL
              // ==================================================
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
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

              // ==================================================
              // TEXTO
              // ==================================================
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // O type.emoji foi removido daqui.
                    // Agora existe somente o ícone principal acima.
                    Text(
                      type.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
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

              // ==================================================
              // SETA
              // ==================================================
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
  // NOVO CONHECIMENTO
  // ============================================================

  Future<
    void
  >
  _showCreateNoteDialog() async {
    if (_controller.isSaving ||
        !mounted) {
      return;
    }

    final type = await _showSaveTypeDialog();

    if (!mounted ||
        type ==
            null) {
      return;
    }

    _controller.createNewNote();

    if (type ==
        BrainConceptType.question) {
      await _showCreateQuestionDialog();

      return;
    }

    // O seletor principal expõe somente Conceito e Pergunta.
    // Example/Warning continuam válidos no modelo, mas são usados
    // apenas como detalhes opcionais dentro do conceito.
    await _showCreateNoteEditorDialog(
      BrainConceptType.concept,
    );
  }

  // ============================================================
  // MODAL DE CONCEITO
  // ============================================================

  Future<
    void
  >
  _showCreateNoteEditorDialog(
    BrainConceptType type,
  ) async {
    if (!mounted) {
      return;
    }

    final sources =
        <
          BrainSource
        >[];

    final exampleController = TextEditingController();

    final warningController = TextEditingController();

    var showDetailOptions = false;
    var showExample = false;
    var showWarning = false;
    var showSources = false;

    // Fase inicial da revisão automática:
    // por enquanto esta escolha pertence ao modal. A persistência em
    // BrainConcept/BrainFile e a geração automática de questões serão
    // conectadas na próxima etapa.
    var useKnowledgeForReview = false;

    var saving = false;

    try {
      await showDialog<
        void
      >(
        context: context,
        barrierDismissible: false,
        builder:
            (
              dialogContext,
            ) {
              return StatefulBuilder(
                builder:
                    (
                      dialogContext,
                      setDialogState,
                    ) {
                      Future<
                        void
                      >
                      addSource() async {
                        if (saving ||
                            _controller.isSaving) {
                          return;
                        }

                        final source = await BrainSourceDialog.show(
                          context: dialogContext,
                        );

                        if (source ==
                                null ||
                            !dialogContext.mounted) {
                          return;
                        }

                        final duplicate = sources.any(
                          (
                            item,
                          ) =>
                              item.id ==
                                  source.id ||
                              item.contentKey ==
                                  source.contentKey,
                        );

                        if (duplicate) {
                          _showMessage(
                            'Essa fonte já foi adicionada.',
                          );

                          return;
                        }

                        setDialogState(
                          () {
                            sources.add(
                              source,
                            );
                            showSources = true;
                          },
                        );
                      }

                      Future<
                        void
                      >
                      editSource(
                        int index,
                      ) async {
                        if (saving ||
                            index <
                                0 ||
                            index >=
                                sources.length) {
                          return;
                        }

                        final updated = await BrainSourceDialog.show(
                          context: dialogContext,
                          initialSource: sources[index],
                        );

                        if (updated ==
                                null ||
                            !dialogContext.mounted) {
                          return;
                        }

                        setDialogState(
                          () {
                            sources[index] = updated;
                          },
                        );
                      }

                      void removeSource(
                        int index,
                      ) {
                        if (saving ||
                            index <
                                0 ||
                            index >=
                                sources.length) {
                          return;
                        }

                        setDialogState(
                          () {
                            sources.removeAt(
                              index,
                            );
                          },
                        );
                      }

                      Future<
                        void
                      >
                      saveConcept() async {
                        if (saving ||
                            _controller.isSaving) {
                          return;
                        }

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
                            'Escreva o que você aprendeu antes de salvar.',
                          );

                          return;
                        }

                        setDialogState(
                          () {
                            saving = true;
                          },
                        );

                        try {
                          // ============================================
                          // DETALHES OPCIONAIS
                          // ============================================
                          //
                          // Não criamos nenhum modelo novo.
                          //
                          // Exemplo:
                          //   BrainConceptType.example
                          //
                          // Ponto de atenção:
                          //   BrainConceptType.warning
                          //
                          // Ambos pertencem ao mesmo BrainFile do conceito.
                          //
                          // ============================================

                          final example = exampleController.text.trim();

                          final warning = warningController.text.trim();

                          if (example.isNotEmpty) {
                            await _controller.addConcept(
                              BrainConcept(
                                id: '${DateTime.now().microsecondsSinceEpoch}-example',
                                title: '$title — Exemplo',
                                description: example,
                                type: BrainConceptType.example,
                              ),
                            );

                            if (!mounted ||
                                !dialogContext.mounted) {
                              return;
                            }
                          }

                          if (warning.isNotEmpty) {
                            await _controller.addConcept(
                              BrainConcept(
                                id: '${DateTime.now().microsecondsSinceEpoch}-warning',
                                title: '$title — Ponto de atenção',
                                description: warning,
                                type: BrainConceptType.warning,
                              ),
                            );

                            if (!mounted ||
                                !dialogContext.mounted) {
                              return;
                            }
                          }

                          // _saveKnowledge adiciona o BrainConcept principal
                          // e então BrainController.saveNote() persiste o
                          // BrainFile com todos os concepts acumulados.
                          final saved = await _saveKnowledge(
                            type: BrainConceptType.concept,
                            reviewEnabled: useKnowledgeForReview,
                            sources:
                                List<
                                  BrainSource
                                >.unmodifiable(
                                  sources,
                                ),
                          );

                          if (!mounted ||
                              !dialogContext.mounted ||
                              !saved) {
                            return;
                          }

                          Navigator.of(
                            dialogContext,
                          ).pop();

                          final grew = await _syncBrainVisualKnowledge(
                            animateGrowth: true,
                            reloadLocal: true,
                          );

                          if (grew) {
                            await Future<
                              void
                            >.delayed(
                              _BrainScreenState._brainGrowthPreviewDuration,
                            );
                          }

                          if (!mounted) {
                            return;
                          }

                          _controller.createNewNote();

                          _mutateState(
                            () {},
                          );
                        } finally {
                          if (dialogContext.mounted) {
                            setDialogState(
                              () {
                                saving = false;
                              },
                            );
                          }
                        }
                      }

                      final conceptColor = BrainConceptType.concept.color;

                      return Dialog(
                        clipBehavior: Clip.antiAlias,
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 650,
                            maxHeight: 820,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ========================================
                              // HEADER
                              // ========================================
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  12,
                                  12,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: conceptColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                      child: Icon(
                                        BrainConceptType.concept.icon,
                                        color: conceptColor,
                                      ),
                                    ),

                                    const SizedBox(
                                      width: 11,
                                    ),

                                    const Expanded(
                                      child: Text(
                                        'Novo conceito',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),

                                    IconButton(
                                      tooltip: 'Fechar',
                                      onPressed:
                                          saving ||
                                              _controller.isSaving
                                          ? null
                                          : () {
                                              Navigator.of(
                                                dialogContext,
                                              ).pop();
                                            },
                                      icon: const Icon(
                                        Icons.close_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Divider(
                                height: 1,
                                color:
                                    Theme.of(
                                      dialogContext,
                                    ).dividerColor.withValues(
                                      alpha: 0.45,
                                    ),
                              ),

                              Flexible(
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.all(
                                    20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      // ==============================
                                      // TÍTULO
                                      // ==============================
                                      const Text(
                                        'Título',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 7,
                                      ),

                                      TextField(
                                        controller: _controller.titleController,
                                        enabled:
                                            !saving &&
                                            !_controller.isSaving,
                                        textInputAction: TextInputAction.next,
                                        onSubmitted:
                                            (
                                              _,
                                            ) {
                                              _controller.contentFocusNode.requestFocus();
                                            },
                                        decoration: const InputDecoration(
                                          hintText: 'Dê um nome para este conceito',
                                          border: OutlineInputBorder(),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 18,
                                      ),

                                      // ==============================
                                      // CONTEÚDO
                                      // ==============================
                                      const Text(
                                        'O que você aprendeu?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 7,
                                      ),

                                      TextField(
                                        controller: _controller.contentController,
                                        focusNode: _controller.contentFocusNode,
                                        enabled:
                                            !saving &&
                                            !_controller.isSaving,
                                        minLines: 5,
                                        maxLines: 12,
                                        keyboardType: TextInputType.multiline,
                                        textInputAction: TextInputAction.newline,
                                        decoration: const InputDecoration(
                                          hintText: 'Explique com suas próprias palavras...',
                                          alignLabelWithHint: true,
                                          border: OutlineInputBorder(),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 14,
                                      ),

                                      // ==============================
                                      // ADICIONAR DETALHES
                                      // ==============================
                                      if (!showDetailOptions)
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: TextButton.icon(
                                            onPressed:
                                                saving ||
                                                    _controller.isSaving
                                                ? null
                                                : () {
                                                    setDialogState(
                                                      () {
                                                        showDetailOptions = true;
                                                      },
                                                    );
                                                  },
                                            icon: const Icon(
                                              Icons.add_rounded,
                                            ),
                                            label: const Text(
                                              'Adicionar detalhes',
                                            ),
                                          ),
                                        )
                                      else ...[
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(
                                            12,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(
                                                  dialogContext,
                                                ).colorScheme.surfaceContainerLow.withValues(
                                                  alpha: 0.55,
                                                ),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color:
                                                  Theme.of(
                                                    dialogContext,
                                                  ).dividerColor.withValues(
                                                    alpha: 0.35,
                                                  ),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Detalhes opcionais',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),

                                              const SizedBox(
                                                height: 10,
                                              ),

                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 8,
                                                children: [
                                                  if (!showExample)
                                                    OutlinedButton.icon(
                                                      onPressed: saving
                                                          ? null
                                                          : () {
                                                              setDialogState(
                                                                () {
                                                                  showExample = true;
                                                                },
                                                              );
                                                            },
                                                      icon: const Icon(
                                                        Icons.add_rounded,
                                                        size: 18,
                                                      ),
                                                      label: const Text(
                                                        'Exemplo',
                                                      ),
                                                    ),

                                                  if (!showWarning)
                                                    OutlinedButton.icon(
                                                      onPressed: saving
                                                          ? null
                                                          : () {
                                                              setDialogState(
                                                                () {
                                                                  showWarning = true;
                                                                },
                                                              );
                                                            },
                                                      icon: const Icon(
                                                        Icons.add_rounded,
                                                        size: 18,
                                                      ),
                                                      label: const Text(
                                                        'Ponto de atenção',
                                                      ),
                                                    ),

                                                  if (!showSources)
                                                    OutlinedButton.icon(
                                                      onPressed: saving
                                                          ? null
                                                          : () async {
                                                              setDialogState(
                                                                () {
                                                                  showSources = true;
                                                                },
                                                              );

                                                              await addSource();
                                                            },
                                                      icon: const Icon(
                                                        Icons.add_rounded,
                                                        size: 18,
                                                      ),
                                                      label: const Text(
                                                        'Fonte',
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // ============================
                                        // EXEMPLO
                                        // ============================
                                        if (showExample) ...[
                                          const SizedBox(
                                            height: 14,
                                          ),

                                          TextField(
                                            controller: exampleController,
                                            enabled:
                                                !saving &&
                                                !_controller.isSaving,
                                            minLines: 2,
                                            maxLines: 6,
                                            decoration: InputDecoration(
                                              labelText: 'Exemplo',
                                              hintText: 'Adicione uma aplicação, situação prática ou código...',
                                              alignLabelWithHint: true,
                                              prefixIcon: Icon(
                                                BrainConceptType.example.icon,
                                                color: BrainConceptType.example.color,
                                              ),
                                              suffixIcon: IconButton(
                                                tooltip: 'Remover exemplo',
                                                onPressed: saving
                                                    ? null
                                                    : () {
                                                        setDialogState(
                                                          () {
                                                            showExample = false;
                                                            exampleController.clear();
                                                          },
                                                        );
                                                      },
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                ),
                                              ),
                                              border: const OutlineInputBorder(),
                                            ),
                                          ),
                                        ],

                                        // ============================
                                        // PONTO DE ATENÇÃO
                                        // ============================
                                        if (showWarning) ...[
                                          const SizedBox(
                                            height: 14,
                                          ),

                                          TextField(
                                            controller: warningController,
                                            enabled:
                                                !saving &&
                                                !_controller.isSaving,
                                            minLines: 2,
                                            maxLines: 6,
                                            decoration: InputDecoration(
                                              labelText: 'Ponto de atenção',
                                              hintText: 'Registre um cuidado, exceção ou erro importante...',
                                              alignLabelWithHint: true,
                                              prefixIcon: Icon(
                                                BrainConceptType.warning.icon,
                                                color: BrainConceptType.warning.color,
                                              ),
                                              suffixIcon: IconButton(
                                                tooltip: 'Remover ponto de atenção',
                                                onPressed: saving
                                                    ? null
                                                    : () {
                                                        setDialogState(
                                                          () {
                                                            showWarning = false;
                                                            warningController.clear();
                                                          },
                                                        );
                                                      },
                                                icon: const Icon(
                                                  Icons.close_rounded,
                                                ),
                                              ),
                                              border: const OutlineInputBorder(),
                                            ),
                                          ),
                                        ],

                                        // ============================
                                        // FONTES
                                        // ============================
                                        if (showSources) ...[
                                          const SizedBox(
                                            height: 14,
                                          ),

                                          _buildPendingSourcesEditor(
                                            context: dialogContext,
                                            sources: sources,
                                            enabled:
                                                !saving &&
                                                !_controller.isSaving,
                                            onAdd: addSource,
                                            onEdit: editSource,
                                            onRemove: removeSource,
                                          ),
                                        ],
                                      ],

                                      const SizedBox(
                                        height: 20,
                                      ),

                                      // ==============================
                                      // USAR PARA REVISÃO
                                      // ==============================
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(
                                          14,
                                          10,
                                          12,
                                          10,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(
                                                dialogContext,
                                              ).colorScheme.surfaceContainerLow.withValues(
                                                alpha: 0.58,
                                              ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color:
                                                Theme.of(
                                                  dialogContext,
                                                ).dividerColor.withValues(
                                                  alpha: 0.34,
                                                ),
                                          ),
                                        ),
                                        child: CheckboxListTile(
                                          value: useKnowledgeForReview,
                                          onChanged:
                                              saving ||
                                                  _controller.isSaving
                                              ? null
                                              : (
                                                  value,
                                                ) {
                                                  setDialogState(
                                                    () {
                                                      useKnowledgeForReview =
                                                          value ??
                                                          false;
                                                    },
                                                  );
                                                },
                                          controlAffinity: ListTileControlAffinity.leading,
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                          title: const Text(
                                            'Usar este conhecimento para revisão',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          subtitle: const Padding(
                                            padding: EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              'Podemos criar perguntas a partir deste conteúdo para ajudar você a revisar o que aprendeu. Deixe desmarcado se não quer revisar',
                                              style: TextStyle(
                                                fontSize: 11,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      if (useKnowledgeForReview) ...[
                                        const SizedBox(
                                          height: 8,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Marcado para revisão. A geração automática das perguntas será conectada ao sistema de revisão na próxima etapa.',
                                                  style: Theme.of(
                                                    dialogContext,
                                                  ).textTheme.bodySmall,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const SizedBox(
                                        height: 22,
                                      ),

                                      // ==============================
                                      // ACTIONS
                                      // ==============================
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed:
                                                saving ||
                                                    _controller.isSaving
                                                ? null
                                                : () {
                                                    Navigator.of(
                                                      dialogContext,
                                                    ).pop();
                                                  },
                                            child: const Text(
                                              'Cancelar',
                                            ),
                                          ),

                                          const SizedBox(
                                            width: 8,
                                          ),

                                          FilledButton(
                                            onPressed:
                                                saving ||
                                                    _controller.isSaving
                                                ? null
                                                : saveConcept,
                                            child:
                                                saving ||
                                                    _controller.isSaving
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Text(
                                                    'Salvar',
                                                  ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
              );
            },
      );

      // Evita descartar controllers enquanto o Dialog ainda
      // termina sua animação de saída.
      await Future<
        void
      >.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );
    } finally {
      exampleController.dispose();
      warningController.dispose();
    }
  }
  // ============================================================
  // FONTES PENDENTES — CAPTURA
  // ============================================================
  //
  // Fontes ainda não persistidas. Elas ficam em memória no modal
  // e são anexadas ao BrainFile somente depois que a nota existe.
  //
  // ============================================================

  Widget _buildPendingSourcesEditor({
    required BuildContext context,
    required List<
      BrainSource
    >
    sources,
    required bool enabled,
    required Future<
      void
    >
    Function()
    onAdd,
    required Future<
      void
    >
    Function(
      int index,
    )
    onEdit,
    required void Function(
      int index,
    )
    onRemove,
  }) {
    final theme = Theme.of(
      context,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        14,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow.withValues(
          alpha: 0.62,
        ),
        borderRadius: BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color: theme.dividerColor.withValues(
            alpha: 0.38,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.link_rounded,
                size: 18,
              ),

              const SizedBox(
                width: 8,
              ),

              const Expanded(
                child: Text(
                  'Fontes',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              if (sources.isNotEmpty)
                Text(
                  '${sources.length}',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),

          const SizedBox(
            height: 6,
          ),

          Text(
            'Opcional. Preserve de onde este conhecimento veio.',
            style: theme.textTheme.bodySmall,
          ),

          if (sources.isNotEmpty) ...[
            const SizedBox(
              height: 10,
            ),

            for (
              var index = 0;
              index <
                  sources.length;
              index++
            ) ...[
              _buildPendingSourceTile(
                context: context,
                source: sources[index],
                enabled: enabled,
                onEdit: () {
                  onEdit(
                    index,
                  );
                },
                onRemove: () {
                  onRemove(
                    index,
                  );
                },
              ),

              if (index <
                  sources.length -
                      1)
                const SizedBox(
                  height: 7,
                ),
            ],
          ],

          const SizedBox(
            height: 10,
          ),

          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: enabled
                  ? () {
                      onAdd();
                    }
                  : null,
              icon: const Icon(
                Icons.add_link_rounded,
                size: 18,
              ),
              label: const Text(
                'Adicionar fonte',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingSourceTile({
    required BuildContext context,
    required BrainSource source,
    required bool enabled,
    required VoidCallback onEdit,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        11,
        8,
        6,
        8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surface,
        borderRadius: BorderRadius.circular(
          11,
        ),
        border: Border.all(
          color:
              Theme.of(
                context,
              ).dividerColor.withValues(
                alpha: 0.30,
              ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link_outlined,
            size: 17,
            color: Theme.of(
              context,
            ).colorScheme.primary,
          ),

          const SizedBox(
            width: 9,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  source.type.label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall,
                ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Editar fonte',
            onPressed: enabled
                ? onEdit
                : null,
            icon: const Icon(
              Icons.edit_outlined,
              size: 18,
            ),
          ),

          IconButton(
            tooltip: 'Remover fonte',
            onPressed: enabled
                ? onRemove
                : null,
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MODAL EXCLUSIVO DE PERGUNTAS
  // ============================================================
  //
  // Agora o usuário pode criar VÁRIAS perguntas no mesmo modal
  // sem escolher tema.
  //
  // Cada pergunta é uma captura independente.
  //
  // Pergunta 1:
  //   Qual é a ideia principal deste conteúdo?
  //
  // Pergunta 2:
  //   Como eu explicaria isso com minhas próprias palavras?
  //
  // Cada pergunta possui:
  //
  // - sua própria resposta;
  // - sua própria primeira revisão;
  // - seu próprio BrainConcept;
  // - seu próprio BrainReviewItem;
  //
  // Todas continuam sendo revisões independentes e não dependem
  // de uma categoria/tema prévio para serem capturadas.
  //
  // ============================================================

  Future<
    void
  >
  _showCreateQuestionDialog() async {
    if (!mounted) {
      return;
    }

    // ==========================================================
    // CONTROLLERS LOCAIS DO MODAL
    // ==========================================================
    //
    // Não utilizamos diretamente titleController/contentController
    // do BrainController enquanto o usuário monta a lista.
    //
    // Isso é importante porque _controller.createNewNote() limpa
    // os controllers globais entre uma pergunta e outra durante o
    // salvamento em lote.
    //
    // ==========================================================

    final questions =
        <
          _QuestionDraft
        >[
          _QuestionDraft(),
        ];

    var saving = false;

    var savedCount = 0;

    int? createdCount;

    try {
      createdCount =
          await showDialog<
            int
          >(
            context: context,
            barrierDismissible: false,
            builder:
                (
                  dialogContext,
                ) {
                  return StatefulBuilder(
                    builder:
                        (
                          dialogContext,
                          setDialogState,
                        ) {
                          final colorScheme = Theme.of(
                            dialogContext,
                          ).colorScheme;

                          // ==========================================
                          // ADD QUESTION
                          // ==========================================

                          void addQuestion() {
                            if (saving) {
                              return;
                            }

                            setDialogState(
                              () {
                                questions.add(
                                  _QuestionDraft(),
                                );
                              },
                            );
                          }

                          // ==========================================
                          // REMOVE QUESTION
                          // ==========================================

                          void removeQuestion(
                            int index,
                          ) {
                            if (saving ||
                                questions.length <=
                                    1) {
                              return;
                            }

                            late final _QuestionDraft removed;

                            setDialogState(
                              () {
                                removed = questions.removeAt(
                                  index,
                                );
                              },
                            );

                            // ========================================
                            // DISPOSE APÓS O FRAME
                            // ========================================
                            //
                            // O card removido ainda pode estar sendo
                            // desmontado neste frame. Descartar os
                            // TextEditingControllers antes disso pode
                            // fazer um TextField tentar reutilizar um
                            // controller já disposed.
                            //
                            // ========================================

                            WidgetsBinding.instance.addPostFrameCallback(
                              (
                                _,
                              ) {
                                removed.dispose();
                              },
                            );
                          }

                          // ==========================================
                          // VALIDATE
                          // ==========================================

                          bool validateQuestions() {
                            for (
                              var index = 0;
                              index <
                                  questions.length;
                              index++
                            ) {
                              final draft = questions[index];

                              final question = draft.questionController.text.trim();

                              final answer = draft.answerController.text.trim();

                              if (question.isEmpty) {
                                _showMessage(
                                  'Digite a pergunta ${index + 1}.',
                                );

                                return false;
                              }

                              if (answer.isEmpty) {
                                _showMessage(
                                  'Digite a resposta da pergunta ${index + 1}.',
                                );

                                return false;
                              }
                            }

                            return true;
                          }

                          // ==========================================
                          // SAVE ALL
                          // ==========================================

                          Future<
                            void
                          >
                          saveQuestions() async {
                            if (saving ||
                                _controller.isSaving) {
                              return;
                            }

                            if (!validateQuestions()) {
                              return;
                            }

                            setDialogState(
                              () {
                                saving = true;

                                savedCount = 0;
                              },
                            );

                            var allSaved = true;

                            try {
                              for (
                                var index = 0;
                                index <
                                    questions.length;
                                index++
                              ) {
                                final draft = questions[index];

                                // ====================================
                                // NOVA NOTA PARA CADA PERGUNTA
                                // ====================================
                                //
                                // Isso garante que uma pergunta não
                                // sobrescreva a anterior.
                                //
                                // ====================================

                                _controller.createNewNote();

                                // FASE 09:
                                // "Sem tema" é apenas compatibilidade interna
                                // enquanto as camadas legadas são migradas.
                                _controller.topicController.text = 'Sem tema';

                                _controller.titleController.text = draft.questionController.text.trim();

                                _controller.contentController.text = draft.answerController.text.trim();

                                final firstReviewAt = DateTime.now().add(
                                  draft.delay.duration,
                                );

                                final saved = await _saveKnowledge(
                                  type: BrainConceptType.question,
                                  firstReviewAt: firstReviewAt,
                                  sources:
                                      List<
                                        BrainSource
                                      >.unmodifiable(
                                        draft.sources,
                                      ),
                                );

                                if (!mounted ||
                                    !dialogContext.mounted) {
                                  return;
                                }

                                if (!saved) {
                                  allSaved = false;

                                  break;
                                }

                                savedCount++;

                                setDialogState(
                                  () {},
                                );
                              }

                              if (!allSaved) {
                                _showMessage(
                                  savedCount ==
                                          0
                                      ? 'Não foi possível criar as perguntas.'
                                      : '$savedCount pergunta${savedCount == 1 ? '' : 's'} foram salvas antes de ocorrer um erro.',
                                );

                                return;
                              }

                              // ====================================
                              // SUCESSO
                              // ====================================

                              if (!dialogContext.mounted) {
                                return;
                              }

                              // ====================================
                              // FECHAR O MODAL COM RESULTADO
                              // ====================================
                              //
                              // Não navegamos para QuestionScreen daqui.
                              //
                              // Primeiro deixamos o Dialog terminar todo
                              // o ciclo de remoção da árvore. Só depois,
                              // fora do builder, descartamos os
                              // controllers locais e abrimos a tela de
                              // perguntas.
                              //
                              // Isso evita:
                              //
                              // TextEditingController was used after
                              // being disposed.
                              //
                              // ====================================

                              Navigator.of(
                                dialogContext,
                              ).pop(
                                savedCount,
                              );

                              return;
                            } finally {
                              if (dialogContext.mounted) {
                                setDialogState(
                                  () {
                                    saving = false;
                                  },
                                );
                              }
                            }
                          }

                          // ==========================================
                          // BUILD DIALOG
                          // ==========================================

                          return Dialog(
                            clipBehavior: Clip.antiAlias,
                            insetPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 780,
                                maxHeight: 860,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ==================================
                                  // HEADER
                                  // ==================================
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      22,
                                      18,
                                      12,
                                      14,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: BrainConceptType.question.color.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            BrainConceptType.question.icon,
                                            color: BrainConceptType.question.color,
                                          ),
                                        ),

                                        const SizedBox(
                                          width: 12,
                                        ),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                questions.length ==
                                                        1
                                                    ? 'Nova pergunta'
                                                    : 'Novas perguntas',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),

                                              const SizedBox(
                                                height: 3,
                                              ),

                                              Text(
                                                questions.length ==
                                                        1
                                                    ? 'Crie uma revisão ativa. Você pode adicionar outras perguntas no mesmo fluxo.'
                                                    : '${questions.length} perguntas serão salvas como revisões independentes.',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        IconButton(
                                          tooltip: 'Fechar',
                                          onPressed:
                                              saving ||
                                                  _controller.isSaving
                                              ? null
                                              : () {
                                                  Navigator.of(
                                                    dialogContext,
                                                  ).pop();
                                                },
                                          icon: const Icon(
                                            Icons.close_rounded,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  Divider(
                                    height: 1,
                                    color:
                                        Theme.of(
                                          dialogContext,
                                        ).dividerColor.withValues(
                                          alpha: 0.45,
                                        ),
                                  ),

                                  // ==================================
                                  // CONTENT
                                  // ==================================
                                  Flexible(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(
                                        22,
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // ==========================
                                          // PERGUNTAS
                                          // ==========================
                                          for (
                                            var index = 0;
                                            index <
                                                questions.length;
                                            index++
                                          ) ...[
                                            _buildQuestionDraftCard(
                                              context: dialogContext,
                                              index: index,
                                              draft: questions[index],
                                              canRemove:
                                                  questions.length >
                                                  1,
                                              saving: saving,
                                              onRemove: () {
                                                removeQuestion(
                                                  index,
                                                );
                                              },
                                              onDelayChanged:
                                                  (
                                                    value,
                                                  ) {
                                                    setDialogState(
                                                      () {
                                                        questions[index].delay = value;
                                                      },
                                                    );
                                                  },
                                              onAddSource: () async {
                                                final source = await BrainSourceDialog.show(
                                                  context: dialogContext,
                                                );

                                                if (source ==
                                                        null ||
                                                    !dialogContext.mounted) {
                                                  return;
                                                }

                                                final duplicate = questions[index].sources.any(
                                                  (
                                                    item,
                                                  ) =>
                                                      item.id ==
                                                          source.id ||
                                                      item.contentKey ==
                                                          source.contentKey,
                                                );

                                                if (duplicate) {
                                                  _showMessage(
                                                    'Essa fonte já foi adicionada à pergunta ${index + 1}.',
                                                  );

                                                  return;
                                                }

                                                setDialogState(
                                                  () {
                                                    questions[index].sources.add(
                                                      source,
                                                    );
                                                  },
                                                );
                                              },
                                              onEditSource:
                                                  (
                                                    sourceIndex,
                                                  ) async {
                                                    if (sourceIndex <
                                                            0 ||
                                                        sourceIndex >=
                                                            questions[index].sources.length) {
                                                      return;
                                                    }

                                                    final updated = await BrainSourceDialog.show(
                                                      context: dialogContext,
                                                      initialSource: questions[index].sources[sourceIndex],
                                                    );

                                                    if (updated ==
                                                            null ||
                                                        !dialogContext.mounted) {
                                                      return;
                                                    }

                                                    setDialogState(
                                                      () {
                                                        questions[index].sources[sourceIndex] = updated;
                                                      },
                                                    );
                                                  },
                                              onRemoveSource:
                                                  (
                                                    sourceIndex,
                                                  ) {
                                                    if (sourceIndex <
                                                            0 ||
                                                        sourceIndex >=
                                                            questions[index].sources.length) {
                                                      return;
                                                    }

                                                    setDialogState(
                                                      () {
                                                        questions[index].sources.removeAt(
                                                          sourceIndex,
                                                        );
                                                      },
                                                    );
                                                  },
                                            ),

                                            if (index <
                                                questions.length -
                                                    1)
                                              const SizedBox(
                                                height: 10,
                                              ),
                                          ],

                                          const SizedBox(
                                            height: 16,
                                          ),

                                          // ==========================
                                          // ADD
                                          // ==========================
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: saving
                                                  ? null
                                                  : addQuestion,
                                              icon: const Icon(
                                                Icons.add_rounded,
                                              ),
                                              label: const Text(
                                                'Adicionar outra pergunta',
                                              ),
                                            ),
                                          ),

                                          const SizedBox(
                                            height: 20,
                                          ),

                                          // ==========================
                                          // EXPLICAÇÃO
                                          // ==========================
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(
                                              13,
                                            ),
                                            decoration: BoxDecoration(
                                              color: colorScheme.primaryContainer.withValues(
                                                alpha: 0.25,
                                              ),
                                              borderRadius: BorderRadius.circular(
                                                13,
                                              ),
                                              border: Border.all(
                                                color: colorScheme.primary.withValues(
                                                  alpha: 0.12,
                                                ),
                                              ),
                                            ),
                                            child: const Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.psychology_alt_outlined,
                                                  size: 18,
                                                ),

                                                SizedBox(
                                                  width: 8,
                                                ),

                                                Expanded(
                                                  child: Text(
                                                    'Cada pergunta terá sua própria revisão. Depois da primeira revisão, o Cérebro ajustará os próximos intervalos conforme você marcar Errei, Difícil, Acertei ou Fácil.',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      height: 1.45,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(
                                            height: 18,
                                          ),

                                          // ==========================
                                          // SAVE ALL
                                          // ==========================
                                          SizedBox(
                                            width: double.infinity,
                                            child: FilledButton.icon(
                                              onPressed:
                                                  saving ||
                                                      _controller.isSaving
                                                  ? null
                                                  : saveQuestions,
                                              icon:
                                                  saving ||
                                                      _controller.isSaving
                                                  ? const SizedBox(
                                                      width: 17,
                                                      height: 17,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.school_outlined,
                                                    ),
                                              label: Text(
                                                saving
                                                    ? savedCount >
                                                              0
                                                          ? 'Criando ${savedCount + 1} de ${questions.length}...'
                                                          : 'Criando perguntas...'
                                                    : questions.length ==
                                                          1
                                                    ? 'Criar pergunta'
                                                    : 'Criar ${questions.length} perguntas',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                  );
                },
          );

      // ========================================================
      // AGUARDAR O DIÁLOGO SAIR DA ÁRVORE
      // ========================================================
      //
      // O Future retornado por Navigator.pop pode concluir antes
      // de todos os últimos frames da transição do Dialog terem
      // terminado.
      //
      // Damos tempo para o route terminar o teardown antes de
      // destruir TextEditingControllers usados pelos TextFields.
      //
      // ========================================================

      await Future<
        void
      >.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );
    } finally {
      // ========================================================
      // DISPOSE DOS CONTROLLERS LOCAIS
      // ========================================================
      //
      // Neste ponto o Dialog já terminou sua saída visual.
      //
      // ========================================================

      for (final draft in questions) {
        draft.dispose();
      }
    }

    // ==========================================================
    // CANCELADO / FECHADO SEM SALVAR
    // ==========================================================

    if (!mounted ||
        createdCount ==
            null ||
        createdCount <=
            0) {
      return;
    }

    // ==========================================================
    // FEEDBACK
    // ==========================================================

    _showMessage(
      createdCount ==
              1
          ? 'Pergunta criada e adicionada às revisões.'
          : '$createdCount perguntas criadas e adicionadas às revisões.',
    );

    // ==========================================================
    // CÉREBRO VISUAL — NOVAS RAMIFICAÇÕES
    // ==========================================================

    final grew = await _syncBrainVisualKnowledge(
      animateGrowth: true,
      reloadLocal: true,
    );

    if (grew) {
      await Future<
        void
      >.delayed(
        _BrainScreenState._brainGrowthPreviewDuration,
      );
    }

    if (!mounted) {
      return;
    }

    // ==========================================================
    // PERMANECER NO CÉREBRO
    // ==========================================================
    //
    // Depois de salvar perguntas, não navegamos automaticamente
    // para QuestionScreen. O usuário permanece na BrainScreen e
    // pode assistir às novas ramificações sendo desenhadas.
    //
    // ==========================================================

    _controller.createNewNote();

    _mutateState(
      () {},
    );
  }

  // ============================================================
  // CARD DE PERGUNTA
  // ============================================================

  Widget _buildQuestionDraftCard({
    required BuildContext context,
    required int index,
    required _QuestionDraft draft,
    required bool canRemove,
    required bool saving,
    required VoidCallback onRemove,
    required ValueChanged<
      _QuestionReviewDelay
    >
    onDelayChanged,
    required Future<
      void
    >
    Function()
    onAddSource,
    required Future<
      void
    >
    Function(
      int index,
    )
    onEditSource,
    required void Function(
      int index,
    )
    onRemoveSource,
  }) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Container(
      key: ObjectKey(
        draft,
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(
        16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow.withValues(
          alpha: 0.72,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: 0.75,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ====================================================
          // HEADER
          // ====================================================
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: BrainConceptType.question.color.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: BorderRadius.circular(
                    9,
                  ),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: BrainConceptType.question.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  'Pergunta ${index + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              IconButton(
                tooltip: canRemove
                    ? 'Remover pergunta'
                    : 'Mantenha pelo menos uma pergunta',
                onPressed:
                    !saving &&
                        canRemove
                    ? onRemove
                    : null,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 19,
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // QUESTION
          // ====================================================
          TextField(
            controller: draft.questionController,
            enabled: !saving,
            textInputAction: TextInputAction.next,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Pergunta',
              hintText: 'Ex.: Qual é a ideia principal deste conteúdo?',
              prefixIcon: Icon(
                Icons.help_outline_rounded,
              ),
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ====================================================
          // ANSWER
          // ====================================================
          TextField(
            controller: draft.answerController,
            enabled: !saving,
            minLines: 3,
            maxLines: 7,
            decoration: const InputDecoration(
              labelText: 'Resposta',
              hintText: 'Escreva a resposta que deverá ser lembrada...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          // ====================================================
          // FIRST REVIEW
          // ====================================================
          DropdownButtonFormField<
            _QuestionReviewDelay
          >(
            initialValue: draft.delay,
            decoration: const InputDecoration(
              labelText: 'Primeira revisão',
              prefixIcon: Icon(
                Icons.schedule_rounded,
              ),
              border: OutlineInputBorder(),
            ),
            items: _QuestionReviewDelay.values
                .map(
                  (
                    delay,
                  ) {
                    return DropdownMenuItem<
                      _QuestionReviewDelay
                    >(
                      value: delay,
                      child: Text(
                        delay.label,
                      ),
                    );
                  },
                )
                .toList(
                  growable: false,
                ),
            onChanged: saving
                ? null
                : (
                    value,
                  ) {
                    if (value ==
                        null) {
                      return;
                    }

                    onDelayChanged(
                      value,
                    );
                  },
          ),

          const SizedBox(
            height: 14,
          ),

          _buildPendingSourcesEditor(
            context: context,
            sources: draft.sources,
            enabled: !saving,
            onAdd: onAddSource,
            onEdit: onEditSource,
            onRemove: onRemoveSource,
          ),
        ],
      ),
    );
  }
}
