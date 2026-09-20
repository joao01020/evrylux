part of '../brain_screen.dart';

// Core orchestration da UI.
//
// A lógica de primeira experiência foi extraída para:
//
// BrainExperienceController
//        ↓
// BrainInitializationService
//
// Esta extensão apenas traduz o estado da experiência para a UI:
// - prepara o BrainVisualController;
// - abre o modal Local / Cloud quando solicitado;
// - mantém navegação e mensagens pertencentes à Screen.
extension _BrainScreenCore
    on
        _BrainScreenState {
  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<
    void
  >
  _initialize() async {
    await _experienceController.initialize();

    if (!mounted) {
      return;
    }

    // O listener normalmente já executou estes passos durante as
    // transições de fase. Chamamos novamente como reconciliação
    // idempotente para cobrir qualquer conclusão sem mudança visual.
    _prepareBrainVisualFromExperience();

    _scheduleDataModeChoiceIfNeeded();

    _showExperienceErrorIfNeeded();

    _mutateState(
      () {},
    );
  }

  // ============================================================
  // PREPARAR CÉREBRO VISUAL
  // ============================================================

  void _prepareBrainVisualFromExperience() {
    final initialization = _experienceController.initialization;

    if (initialization ==
        null) {
      return;
    }

    final knowledgeCount = initialization.knowledgeCount;

    final visualController = _brainVisualController;

    if (visualController !=
        null) {
      visualController.setKnowledgeCount(
        knowledgeCount,
      );

      return;
    }

    _brainVisualController = BrainVisualController(
      knowledgeCount: knowledgeCount,
      introSeen: initialization.introSeen,
    );

    _brainVisualReady = true;

    // Mantém o comportamento anterior:
    // ao entrar no Brain preparamos um rascunho limpo.
    _controller.createNewNote();

    _showControllerMessage();
  }

  // ============================================================
  // NASCIMENTO DO BRAIN
  // ============================================================

  Future<
    void
  >
  _completeBrainBirth() async {
    // O evento vem diretamente de EvolvingBrain.onBirthCompleted.
    //
    // O ExperienceController:
    // 1. libera o Future interno;
    // 2. persiste introSeen através do InitializationService;
    // 3. somente depois avança para Local / Cloud.
    //
    // Não existe timer para sincronizar esse fluxo.
    await _experienceController.completeBirth();
  }

  // ============================================================
  // AGENDAR MODAL LOCAL / CLOUD
  // ============================================================

  void _scheduleDataModeChoiceIfNeeded() {
    if (!mounted ||
        !_experienceController.needsDataModeChoice ||
        _dataModeDialogRunning ||
        _dataModeDialogScheduled) {
      return;
    }

    _dataModeDialogScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        _dataModeDialogScheduled = false;

        if (!mounted ||
            !_experienceController.needsDataModeChoice ||
            _dataModeDialogRunning) {
          return;
        }

        unawaited(
          _ensureFirstBrainDataModeChoice(),
        );
      },
    );
  }

  // ============================================================
  // PRIMEIRA ESCOLHA — LOCAL / CLOUD
  // ============================================================

  Future<
    void
  >
  _ensureFirstBrainDataModeChoice() async {
    if (!mounted ||
        !_experienceController.needsDataModeChoice ||
        _dataModeDialogRunning) {
      return;
    }

    _dataModeDialogRunning = true;

    try {
      final selectedMode =
          await showDialog<
            BrainDataMode
          >(
            context: context,
            barrierDismissible: false,
            builder:
                (
                  dialogContext,
                ) {
                  final scheme = Theme.of(
                    dialogContext,
                  ).colorScheme;

                  return PopScope(
                    canPop: false,
                    child: AlertDialog(
                      title: const Text(
                        'Como você quer proteger seus dados?',
                      ),
                      content: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 560,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: scheme.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(
                                  16,
                                ),
                                border: Border.all(
                                  color: scheme.primary.withValues(
                                    alpha: 0.28,
                                  ),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.cloud_done_outlined,
                                      ),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Cloud  •  Recomendado',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Seus dados continuam neste dispositivo e uma '
                                    'cópia criptografada é mantida automaticamente '
                                    'na nuvem. Se trocar ou perder o computador, '
                                    'você poderá recuperar o seu Cérebro.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Container(
                              padding: const EdgeInsets.all(
                                16,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  16,
                                ),
                                border: Border.all(
                                  color: Theme.of(
                                    dialogContext,
                                  ).dividerColor,
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.laptop_rounded,
                                      ),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      Expanded(
                                        child: Text(
                                          'Somente local',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    'Seus dados ficam somente neste dispositivo. '
                                    'Nada novo do Cérebro é enviado para a nuvem '
                                    'e você será responsável por manter seus '
                                    'próprios backups.',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            const Text(
                              'Você poderá mudar isso depois em '
                              'Perfil e configurações → Cérebro.',
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(
                              dialogContext,
                            ).pop(
                              BrainDataMode.local,
                            );
                          },
                          child: const Text(
                            'Somente local',
                          ),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            Navigator.of(
                              dialogContext,
                            ).pop(
                              BrainDataMode.cloud,
                            );
                          },
                          icon: const Icon(
                            Icons.cloud_done_outlined,
                          ),
                          label: const Text(
                            'Usar Cloud',
                          ),
                        ),
                      ],
                    ),
                  );
                },
          );

      if (!mounted ||
          selectedMode ==
              null) {
        return;
      }

      if (selectedMode ==
          BrainDataMode.local) {
        await dependencies.brainDataModeTransitionService.activateLocal();

        if (!mounted) {
          return;
        }

        _experienceController.dataModeChoiceCompleted(
          BrainDataMode.local,
        );

        _showMessage(
          'Modo Local ativado. Seus dados ficarão somente neste dispositivo.',
        );

        return;
      }

      _showMessage(
        'Ativando a proteção automática na nuvem...',
      );

      final result = await dependencies.brainDataModeTransitionService.activateCloud();

      if (!mounted) {
        return;
      }

      _experienceController.dataModeChoiceCompleted(
        BrainDataMode.cloud,
      );

      if (result.isPending) {
        _showMessage(
          'Cloud ativado. Este dispositivo ainda precisa ser autorizado '
          'para concluir a proteção na nuvem.',
        );
      } else if (result.deviceRegistrationError !=
          null) {
        _showMessage(
          'Cloud ativado. A proteção será concluída automaticamente '
          'quando houver conexão.',
        );
      } else {
        _showMessage(
          'Cloud ativado. Seus dados continuam locais e uma cópia '
          'criptografada será mantida na nuvem.',
        );
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[BRAIN DATA MODE] Primeira escolha falhou: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Não foi possível concluir essa escolha agora. Tente novamente.',
      );
    } finally {
      _dataModeDialogRunning = false;
    }
  }

  // ============================================================
  // ERRO DA EXPERIÊNCIA
  // ============================================================

  void _showExperienceErrorIfNeeded() {
    if (!mounted ||
        !_experienceController.hasFailed ||
        _experienceErrorShown) {
      return;
    }

    _experienceErrorShown = true;

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _showMessage(
          'Não foi possível inicializar o Cérebro agora.',
        );
      },
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

    if (!mounted) {
      return;
    }

    // As telas especializadas podem alterar conteúdo.
    // Ao voltar, reconciliamos o estado visual com a fonte local.
    await _controller.loadNotes();

    if (!mounted) {
      return;
    }

    await _syncBrainVisualKnowledge(
      animateGrowth: true,
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
    if (!mounted) {
      return;
    }

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
}
