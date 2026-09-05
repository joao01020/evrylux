import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart' as dependencies;
import '../../../brain/visualization/brain_visualization.dart';
import '../../../brain/visualization/painters/brain_paths.dart';

import '../controllers/brain_controller.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';
import '../models/brain_source.dart';
import '../settings/models/brain_data_mode.dart';

import '../search/models/brain_search_response.dart';
import '../search/services/brain_search_engine.dart';
import '../search/services/brain_search_parser.dart';
import '../search/widgets/brain_search_help_dialog.dart';
import '../source/widgets/brain_source_dialog.dart';

// ============================================================
// SCREENS
// ============================================================

import 'concept/concept_screen.dart';
import 'question/question_screen.dart';
import 'example/example_screen.dart';
import 'warning/warning_screen.dart';
import 'note/brain_note_screen.dart';

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
// FASE 13 — FONTES DO CONHECIMENTO:
//
// - Conceito / Exemplo / Atenção podem receber fontes na criação;
// - cada Pergunta pode receber suas próprias fontes;
// - fonte é opcional e fica recolhida na experiência principal;
// - a fonte só é persistida depois que a nota existe;
// - o BrainController envia a fonte ao Vault criptografado.
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
  // CÉREBRO VISUAL — EVRYLUX
  // ============================================================

  final BrainVisualStateStorage _brainVisualStateStorage = const BrainVisualStateStorage();

  BrainVisualController? _brainVisualController;

  Timer? _brainSearchPulseStopTimer;

  bool _brainVisualReady = false;

  int _brainVisualKnowledgeCount = 0;

  static const Duration _brainGrowthPreviewDuration = Duration(
    milliseconds: 2050,
  );

  // ============================================================
  // PESQUISA
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  static const BrainSearchParser _searchParser = BrainSearchParser();

  static const BrainSearchEngine _searchEngine = BrainSearchEngine();

  bool _showAllSearchResults = false;

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

    _brainSearchPulseStopTimer?.cancel();

    _brainVisualController?.dispose();

    _searchController.dispose();

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
    if (!_controller.isInitialized) {
      await _controller.initialize();
    }

    if (!mounted) {
      return;
    }

    // ========================================================
    // CÉREBRO VISUAL
    // ========================================================
    //
    // A animação inicial é um evento único.
    //
    // O estado visual não consulta Supabase. Ele usa apenas:
    //
    // - o conteúdo já carregado pelo BrainController;
    // - um pequeno estado local indicando se o nascimento já foi
    //   concluído neste perfil local.
    //
    // ========================================================

    final knowledgeCount = _currentBrainKnowledgeCount();

    final introSeen = await _brainVisualStateStorage.readIntroSeen();

    if (!mounted) {
      return;
    }

    _brainVisualKnowledgeCount = knowledgeCount;

    _brainVisualController = BrainVisualController(
      knowledgeCount: knowledgeCount,
      introSeen: introSeen,
    );

    _brainVisualReady = true;

    _controller.createNewNote();

    _showControllerMessage();

    if (mounted) {
      setState(
        () {},
      );
    }

    await _ensureFirstBrainDataModeChoice();
  }

  // ============================================================
  // PRIMEIRA ESCOLHA — LOCAL / CLOUD
  // ============================================================

  Future<
    void
  >
  _ensureFirstBrainDataModeChoice() async {
    // A leitura é feita diretamente do storage de preferência.
    // O service pode operar em Local como fail-safe antes da escolha,
    // mas isso não conta como uma decisão persistida do usuário.
    final storedMode = await dependencies.brainDataModeStorage.load();

    if (!mounted ||
        storedMode !=
            null) {
      return;
    }

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

    try {
      if (selectedMode ==
          BrainDataMode.local) {
        await dependencies.brainDataModeTransitionService.activateLocal();

        if (!mounted) {
          return;
        }

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
    }
  }

  // ============================================================
  // CÉREBRO VISUAL — CONTAGEM
  // ============================================================

  int _currentBrainKnowledgeCount() {
    // ========================================================
    // FONTE REAL DO PROGRESSO VISUAL
    // ========================================================
    //
    // Cada captura de conhecimento criada pela BrainScreen gera
    // uma BrainFile persistida localmente.
    //
    // Usar notes.length é mais confiável do que somar concepts,
    // pois o carregamento/migração de conceitos pode acontecer em
    // uma etapa diferente do carregamento da nota.
    //
    // Resultado:
    //
    // 0 notas salvas = cérebro vazio
    // 1 nota salva   = 1 ramificação
    // 2 notas salvas = 2 ramificações
    // ...
    //
    // ========================================================

    return _controller.notes.length;
  }

  // ============================================================
  // CÉREBRO VISUAL — NASCIMENTO
  // ============================================================

  Future<
    void
  >
  _onBrainBirthCompleted() async {
    await _brainVisualStateStorage.writeIntroSeen(
      true,
    );
  }

  // ============================================================
  // CÉREBRO VISUAL — SINCRONIZAR CONHECIMENTO
  // ============================================================

  Future<
    bool
  >
  _syncBrainVisualKnowledge({
    required bool animateGrowth,
    bool reloadLocal = false,
  }) async {
    final visualController = _brainVisualController;

    if (visualController ==
        null) {
      return false;
    }

    // ========================================================
    // RECARREGAR A FONTE REAL
    // ========================================================
    //
    // O crescimento só deve acontecer a partir do conteúdo que
    // realmente foi persistido no armazenamento local.
    //
    // ========================================================

    if (reloadLocal) {
      await _controller.loadNotes();

      if (!mounted) {
        return false;
      }
    }

    final currentCount = _currentBrainKnowledgeCount();

    final previousVisualCount = visualController.knowledgeCount;

    debugPrint(
      '[BRAIN VISUAL] '
      'salvos=$currentCount '
      'visual=$previousVisualCount '
      'animar=$animateGrowth',
    );

    _brainVisualKnowledgeCount = currentCount;

    // ========================================================
    // NOVO CONHECIMENTO
    // ========================================================

    if (animateGrowth &&
        currentCount >
            previousVisualCount) {
      visualController.animateKnowledgeTarget(
        currentCount,
      );

      return true;
    }

    // ========================================================
    // RECONCILIAÇÃO NORMAL
    // ========================================================

    visualController.setKnowledgeCount(
      currentCount,
    );

    return false;
  }

  // ============================================================
  // CÉREBRO VISUAL — ATIVIDADE DE PESQUISA
  // ============================================================

  void _setBrainSearchActivity(
    String rawQuery, {
    Duration hold = const Duration(
      milliseconds: 900,
    ),
  }) {
    final visualController = _brainVisualController;

    _brainSearchPulseStopTimer?.cancel();

    if (visualController ==
        null) {
      return;
    }

    final normalizedQuery = rawQuery.trim();

    if (normalizedQuery.isEmpty) {
      visualController.setSearching(
        false,
      );

      visualController.clearSearchMatch();

      return;
    }

    // Limpa qualquer brilho anterior antes de uma nova pesquisa.
    visualController.clearSearchMatch();

    // Mantém os pulsos distribuídos enquanto o usuário digita.
    visualController.setSearching(
      true,
    );

    // A busca local é síncrona. Consideramos que a pesquisa
    // "terminou" quando o usuário fica alguns milissegundos sem
    // alterar o texto. Nesse momento resolvemos o resultado e
    // disparamos o pulso final.
    _brainSearchPulseStopTimer = Timer(
      hold,
      () {
        if (!mounted) {
          return;
        }

        // Ignora timer de uma consulta antiga.
        if (_searchQuery.trim() !=
            normalizedQuery) {
          return;
        }

        final response = _searchResponse;

        final results = response.allResults;

        if (results.isEmpty) {
          debugPrint(
            '[BRAIN SEARCH VISUAL] Nenhum resultado para "$normalizedQuery".',
          );

          visualController.setSearching(
            false,
          );

          visualController.clearSearchMatch();

          return;
        }

        // topResults normalmente contém o primeiro resultado mais
        // relevante. O fallback para allResults garante que o efeito
        // não deixe de acontecer caso topResults esteja vazio.
        final topResult = response.topResults.isNotEmpty
            ? response.topResults.first
            : results.first;

        final target = _visualTargetForSearchResult(
          topResult,
        );

        debugPrint(
          '[BRAIN SEARCH VISUAL] '
          'Encontrado="${topResult.title}" '
          'ramo=${target.branchIndex} '
          'conexao=${target.connectionIndex}.',
        );

        visualController.resolveSearch(
          branchIndex: target.branchIndex,
          connectionIndex: target.connectionIndex,
        );
      },
    );
  }

  // ============================================================
  // ALVO VISUAL EXATO DO RESULTADO
  // ============================================================
  //
  // O BrainScreen atual ainda usa o crescimento visual legado:
  //
  //   1 BrainFile salvo
  //        ↓
  //   1 nova entrada de BrainPaths.connections
  //
  // Portanto o vínculo correto do arquivo com o desenho é a posição
  // dele em _controller.notes. Não usamos mais hash para escolher um
  // ramo durante a pesquisa.
  //
  // Se no futuro o crescimento semântico for realmente ativado e o
  // BrainFile passar a carregar uma semanticKey persistida, este método
  // poderá devolver branchIndex. Por enquanto preservamos a arquitetura
  // real que está desenhando o cérebro hoje.
  //
  // ============================================================

  _BrainSearchVisualTarget _visualTargetForSearchResult(
    BrainFile note,
  ) {
    final noteIndex = _indexOfBrainNote(
      note,
    );

    if (noteIndex >=
            0 &&
        noteIndex <
            BrainPaths.connections.length) {
      return _BrainSearchVisualTarget(
        connectionIndex: noteIndex,
      );
    }

    // Fail-safe: se por algum motivo o resultado não estiver mais na
    // lista local (por exemplo, exclusão/reload entre busca e animação),
    // não acendemos outro ramo aleatório.
    return const _BrainSearchVisualTarget();
  }

  int _indexOfBrainNote(
    BrainFile note,
  ) {
    // O crescimento legado nasce em ordem de criação: cada novo arquivo
    // aumenta knowledgeCount em 1 e revela a próxima conexão. A lista de
    // notas pode ser exibida em outra ordenação, então não usamos
    // _controller.notes.indexOf(note) como posição visual.
    final orderedNotes =
        <
            BrainFile
          >[
            ..._controller.notes,
          ]
          ..sort(
            (
              a,
              b,
            ) {
              final byCreatedAt = a.createdAt.compareTo(
                b.createdAt,
              );

              if (byCreatedAt !=
                  0) {
                return byCreatedAt;
              }

              return a.path.compareTo(
                b.path,
              );
            },
          );

    final notePath = note.path.trim();

    if (notePath.isNotEmpty) {
      final pathIndex = orderedNotes.indexWhere(
        (
          item,
        ) =>
            item.path.trim() ==
            notePath,
      );

      if (pathIndex >=
          0) {
        return pathIndex;
      }
    }

    final directIndex = orderedNotes.indexOf(
      note,
    );

    if (directIndex >=
        0) {
      return directIndex;
    }

    // Último fallback por identidade textual. Isso apenas reencontra o
    // mesmo arquivo na lista cronológica; nunca escolhe um caminho por hash.
    return orderedNotes.indexWhere(
      (
        item,
      ) =>
          item.title ==
              note.title &&
          item.content ==
              note.content &&
          item.createdAt ==
              note.createdAt,
    );
  }

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

    // ========================================================
    // RECARREGAR E ANIMAR NOVO CONHECIMENTO
    // ========================================================
    //
    // As telas de Conceito / Pergunta / Exemplo / Atenção também
    // podem alterar o conteúdo. Ao voltar, reconciliamos o estado
    // visual com a fonte local real.
    //
    // ========================================================

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
  // PESQUISA
  // ============================================================
  //
  // FASE 12 — RESPOSTAS ESTRUTURADAS
  //
  // A BrainScreen apenas:
  //
  // - consulta o conteúdo local já carregado;
  //   // - envia para BrainSearchEngine;
  // - renderiza BrainSearchResponse.
  //
  // O parser interpreta a linguagem natural.
  // O engine filtra e ranqueia.
  // A response organiza os resultados.
  //
  // ============================================================

  BrainSearchResponse get _searchResponse {
    final parsedQuery = _searchParser.parse(
      _searchQuery,
    );

    if (parsedQuery.isEmpty) {
      return BrainSearchResponse.fromResults(
        const <
          BrainFile
        >[],
      );
    }

    return _searchEngine.search(
      notes: _controller.notes,
      query: parsedQuery,
      topLimit: 3,
    );
  }

  // ============================================================
  // PESQUISA LOCAL / VAULT-FIRST
  // ============================================================
  //
  // A pesquisa não consulta o Supabase automaticamente.
  //
  // O parser e o engine trabalham somente sobre as notas que o
  // BrainController já carregou do armazenamento local/Vault.
  //
  // A nuvem permanece fora do caminho crítico e continua sendo
  // usada apenas pela sincronização E2EE.
  //
  // ============================================================

  void _scheduleRemoteSearch(
    String rawQuery,
  ) {
    // Mantido para preservar os callers existentes da interface.
    // A alteração de _searchQuery já dispara o rebuild e a busca
    // local. Nenhuma chamada de rede acontece aqui.
    if (rawQuery.trim().isEmpty) {
      return;
    }
  }

  // ============================================================
  // DATA BR
  // ============================================================

  String _formatSearchDate(
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
        '${local.year}';
  }

  // ============================================================
  // PREVIEW
  // ============================================================

  String _previewContent(
    String content,
  ) {
    final clean = content
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        )
        .trim();

    if (clean.length <=
        180) {
      return clean;
    }

    return '${clean.substring(0, 180)}...';
  }

  // ============================================================
  // ABRIR RESULTADO EM PÁGINA
  // ============================================================
  //
  // Qualquer anotação existente localmente,
  // é aberta exclusivamente pela BrainNoteScreen.
  //
  // NÃO reutilizar o modal de criação aqui.
  //
  // ============================================================

  Future<
    void
  >
  _openSearchResult(
    BrainFile note,
  ) async {
    if (!mounted) {
      return;
    }

    final noteToOpen = note;

    final changed =
        await Navigator.of(
          context,
        ).push<
          bool
        >(
          MaterialPageRoute(
            builder:
                (
                  _,
                ) {
                  return BrainNoteScreen(
                    note: noteToOpen,
                  );
                },
          ),
        );

    if (!mounted) {
      return;
    }

    // ========================================================
    // RECARREGAR AO VOLTAR
    // ========================================================
    //
    // Se a página editou ou excluiu a anotação, a lista local
    // e os resultados da pesquisa refletem a mudança.
    //
    // ========================================================

    if (changed ==
        true) {
      await _controller.loadNotes();

      if (!mounted) {
        return;
      }

      await _syncBrainVisualKnowledge(
        animateGrowth: false,
      );
    }

    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // AJUDA DA PESQUISA
  // ============================================================

  Future<
    void
  >
  _showSearchHelp() async {
    await BrainSearchHelpDialog.show(
      context: context,
      onUseExample:
          (
            example,
          ) {
            if (!mounted) {
              return;
            }

            _searchController.text = example;

            _searchController.selection = TextSelection.collapsed(
              offset: example.length,
            );

            setState(
              () {
                _searchQuery = example;

                _showAllSearchResults = false;
              },
            );

            _scheduleRemoteSearch(
              example,
            );

            _setBrainSearchActivity(
              example,
              hold: const Duration(
                milliseconds: 1500,
              ),
            );
          },
    );
  }

  // ============================================================
  // CAMPO DE PESQUISA
  // ============================================================

  Widget _buildSearchField(
    BuildContext context,
  ) {
    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Row(
      children: [
        Tooltip(
          message: 'Como pesquisar',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(
                14,
              ),
              onTap: _showSearchHelp,
              child: Ink(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color: colorScheme.primary.withValues(
                      alpha: 0.22,
                    ),
                  ),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 21,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(
          width: 10,
        ),

        Expanded(
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged:
                (
                  value,
                ) {
                  setState(
                    () {
                      _searchQuery = value;

                      _showAllSearchResults = false;
                    },
                  );

                  _scheduleRemoteSearch(
                    value,
                  );

                  _setBrainSearchActivity(
                    value,
                  );
                },
            onSubmitted:
                (
                  value,
                ) {
                  _setBrainSearchActivity(
                    value,
                    hold: const Duration(
                      milliseconds: 1600,
                    ),
                  );
                },
            decoration: InputDecoration(
              hintText: 'Pergunte ao que você já aprendeu...',
              prefixIcon: const Icon(
                Icons.search_rounded,
              ),
              suffixIcon: _searchQuery.trim().isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar pesquisa',
                      onPressed: () {
                        _searchController.clear();

                        setState(
                          () {
                            _searchQuery = '';

                            _showAllSearchResults = false;
                          },
                        );

                        _setBrainSearchActivity(
                          '',
                        );
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.28,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  16,
                ),
                borderSide: BorderSide(
                  color:
                      Theme.of(
                        context,
                      ).dividerColor.withValues(
                        alpha: 0.45,
                      ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  16,
                ),
                borderSide: BorderSide(
                  color:
                      Theme.of(
                        context,
                      ).dividerColor.withValues(
                        alpha: 0.45,
                      ),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  16,
                ),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RESULTADOS DA PESQUISA
  // ============================================================
  //
  // FASE 12:
  //
  // Mostramos inicialmente apenas os 3 resultados mais relevantes.
  //
  // Se houver mais:
  //
  // "Ver todos os X resultados"
  //
  // Assim a pesquisa não cresce indefinidamente na tela.
  //
  // ============================================================

  Widget _buildSearchResults(
    BuildContext context,
  ) {
    final response = _searchResponse;

    final visibleNotes = _showAllSearchResults
        ? response.allResults
        : response.topResults;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color:
            Theme.of(
              context,
            ).colorScheme.surface.withValues(
              alpha: 0.38,
            ),
        borderRadius: BorderRadius.circular(
          18,
        ),
        border: Border.all(
          color:
              Theme.of(
                context,
              ).dividerColor.withValues(
                alpha: 0.50,
              ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // HEADER
          // ==================================================
          Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              10,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.manage_search_rounded,
                  size: 20,
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child: Text(
                    response.isEmpty
                        ? 'Nenhum resultado'
                        : response.resultLabel,
                    style:
                        Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
          ),

          // ==================================================
          // RESUMO POR TIPO
          // ==================================================
          if (response.isNotEmpty &&
              response.groupSummary.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                0,
                16,
                12,
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: response.groupSummary.map(
                  (
                    item,
                  ) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.42,
                            ),
                        borderRadius: BorderRadius.circular(
                          999,
                        ),
                        border: Border.all(
                          color:
                              Theme.of(
                                context,
                              ).dividerColor.withValues(
                                alpha: 0.35,
                              ),
                        ),
                      ),
                      child: Text(
                        item,
                        style:
                            Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    );
                  },
                ).toList(),
              ),
            ),

          Divider(
            height: 1,
            color:
                Theme.of(
                  context,
                ).dividerColor.withValues(
                  alpha: 0.45,
                ),
          ),

          // ==================================================
          // EMPTY
          // ==================================================
          if (response.isEmpty)
            const Padding(
              padding: EdgeInsets.all(
                18,
              ),
              child: Text(
                'Nenhuma anotação corresponde à pesquisa.',
              ),
            )
          else ...[
            // ================================================
            // TOP RESULTS / ALL RESULTS
            // ================================================
            Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                13,
                16,
                5,
              ),
              child: Text(
                _showAllSearchResults
                    ? 'Todos os resultados'
                    : 'Mais relevantes',
                style:
                    Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),

            for (
              var index = 0;
              index <
                  visibleNotes.length;
              index++
            ) ...[
              _buildSearchResultCard(
                context,
                visibleNotes[index],
              ),

              if (index !=
                  visibleNotes.length -
                      1)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color:
                      Theme.of(
                        context,
                      ).dividerColor.withValues(
                        alpha: 0.35,
                      ),
                ),
            ],

            // ================================================
            // EXPAND / COLLAPSE
            // ================================================
            if (response.hasMoreResults)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  12,
                  4,
                  12,
                  12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(
                        () {
                          _showAllSearchResults = !_showAllSearchResults;
                        },
                      );
                    },
                    icon: Icon(
                      _showAllSearchResults
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                    ),
                    label: Text(
                      _showAllSearchResults
                          ? 'Mostrar apenas os principais'
                          : 'Ver todos os ${response.total} resultados',
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // CARD DE RESULTADO
  // ============================================================

  Widget _buildSearchResultCard(
    BuildContext context,
    BrainFile note,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _openSearchResult(
            note,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(
                        alpha: 0.10,
                      ),
                  borderRadius: BorderRadius.circular(
                    12,
                  ),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: Theme.of(
                    context,
                  ).colorScheme.primary,
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
                      note.title,
                      style:
                          Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        _buildSearchMeta(
                          context: context,
                          icon: Icons.calendar_today_outlined,
                          text: 'Criado em ${_formatSearchDate(note.createdAt)}',
                        ),
                        _buildSearchMeta(
                          context: context,
                          icon: Icons.update_rounded,
                          text: 'Atualizado em ${_formatSearchDate(note.updatedAt)}',
                        ),
                      ],
                    ),

                    if (note.content.trim().isNotEmpty) ...[
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        _previewContent(
                          note.content,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              const Padding(
                padding: EdgeInsets.only(
                  top: 8,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // META DO RESULTADO
  // ============================================================

  Widget _buildSearchMeta({
    required BuildContext context,
    required IconData icon,
    required String text,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(
          width: 4,
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
  // NOVO CONHECIMENTO
  // ============================================================
  //
  // NOVO FLUXO:
  //
  // 1. usuário clica em +
  // 2. escolhe o tipo
  // 3. abrimos o formulário correto
  //
  // ============================================================

  Future<
    void
  >
  _showCreateNoteDialog() async {
    if (_controller.isSaving) {
      return;
    }

    // ==========================================================
    // PRIMEIRO: ESCOLHER O TIPO
    // ==========================================================

    final type = await _showSaveTypeDialog();

    if (!mounted ||
        type ==
            null) {
      return;
    }

    // ==========================================================
    // NOVO FORMULÁRIO LIMPO
    // ==========================================================

    _controller.createNewNote();

    // ==========================================================
    // PERGUNTA POSSUI FORMULÁRIO PRÓPRIO
    // ==========================================================

    if (type ==
        BrainConceptType.question) {
      await _showCreateQuestionDialog();

      return;
    }

    // ==========================================================
    // CONCEITO / EXEMPLO / ATENÇÃO
    // ==========================================================

    await _showCreateNoteEditorDialog(
      type,
    );
  }

  // ============================================================
  // MODAL DE ANOTAÇÃO
  // ============================================================
  //
  // Utilizado somente por:
  //
  // - Conceito
  // - Exemplo
  // - Atenção
  //
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

    await showDialog<
      void
    >(
      context: context,
      barrierDismissible: !_controller.isSaving,
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
                        ) {
                          return item.id ==
                                  source.id ||
                              item.contentKey ==
                                  source.contentKey;
                        },
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
                        },
                      );
                    }

                    Future<
                      void
                    >
                    editSource(
                      int index,
                    ) async {
                      if (index <
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
                      if (index <
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

                    return Dialog(
                      clipBehavior: Clip.antiAlias,
                      insetPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 820,
                          maxHeight: 820,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ==========================================
                            // HEADER
                            // ==========================================
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                16,
                                12,
                                12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    type.icon,
                                    size: 22,
                                    color: type.color,
                                  ),

                                  const SizedBox(
                                    width: 10,
                                  ),

                                  Expanded(
                                    child: Text(
                                      'Novo ${type.label.toLowerCase()}',
                                      style:
                                          Theme.of(
                                            dialogContext,
                                          ).textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),

                                  IconButton(
                                    tooltip: 'Fechar',
                                    onPressed: _controller.isSaving
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

                            // ==========================================
                            // EDITOR
                            // ==========================================
                            Flexible(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(
                                  20,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    TextField(
                                      controller: _controller.titleController,
                                      enabled: !_controller.isSaving,
                                      textInputAction: TextInputAction.next,
                                      onSubmitted:
                                          (
                                            _,
                                          ) {
                                            _controller.contentFocusNode.requestFocus();
                                          },
                                      decoration: InputDecoration(
                                        labelText:
                                            type ==
                                                BrainConceptType.concept
                                            ? 'Título do conceito'
                                            : type ==
                                                  BrainConceptType.example
                                            ? 'Título do exemplo'
                                            : 'Título da atenção',
                                        hintText:
                                            type ==
                                                BrainConceptType.concept
                                            ? 'Ex.: Como funciona uma fila FIFO?'
                                            : type ==
                                                  BrainConceptType.example
                                            ? 'Ex.: Exemplo de uso na prática'
                                            : 'Ex.: Cuidado importante',
                                        prefixIcon: Icon(
                                          type.icon,
                                          color: type.color,
                                        ),
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 16,
                                    ),

                                    TextField(
                                      controller: _controller.contentController,
                                      focusNode: _controller.contentFocusNode,
                                      enabled: !_controller.isSaving,
                                      minLines: 7,
                                      maxLines: 14,
                                      keyboardType: TextInputType.multiline,
                                      textInputAction: TextInputAction.newline,
                                      decoration: InputDecoration(
                                        labelText:
                                            type ==
                                                BrainConceptType.concept
                                            ? 'Conteúdo'
                                            : type ==
                                                  BrainConceptType.example
                                            ? 'Descrição do exemplo'
                                            : 'Detalhes da atenção',
                                        hintText:
                                            type ==
                                                BrainConceptType.concept
                                            ? 'Explique este conhecimento com suas palavras.'
                                            : type ==
                                                  BrainConceptType.example
                                            ? 'Descreva o exemplo, código, aplicação ou situação prática.'
                                            : 'Registre o erro, cuidado ou detalhe importante.',
                                        alignLabelWithHint: true,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 18,
                                    ),

                                    // ====================================
                                    // FONTES
                                    // ====================================
                                    _buildPendingSourcesEditor(
                                      context: dialogContext,
                                      sources: sources,
                                      enabled: !_controller.isSaving,
                                      onAdd: addSource,
                                      onEdit: editSource,
                                      onRemove: removeSource,
                                    ),

                                    const SizedBox(
                                      height: 18,
                                    ),

                                    Container(
                                      padding: const EdgeInsets.all(
                                        12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: type.color.withValues(
                                          alpha: 0.055,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        border: Border.all(
                                          color: type.color.withValues(
                                            alpha: 0.16,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.auto_awesome_outlined,
                                            size: 17,
                                            color: type.color,
                                          ),

                                          const SizedBox(
                                            width: 8,
                                          ),

                                          Expanded(
                                            child: Text(
                                              'Você não precisa escolher um tema. '
                                              'Salve o conhecimento diretamente; '
                                              'o Cérebro cuidará da organização.',
                                              style: Theme.of(
                                                dialogContext,
                                              ).textTheme.bodySmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 18,
                                    ),

                                    SizedBox(
                                      width: double.infinity,
                                      child: FilledButton.icon(
                                        onPressed: _controller.isSaving
                                            ? null
                                            : () async {
                                                final saved = await _saveKnowledge(
                                                  type: type,
                                                  sources:
                                                      List<
                                                        BrainSource
                                                      >.unmodifiable(
                                                        sources,
                                                      ),
                                                );

                                                if (!dialogContext.mounted ||
                                                    !saved) {
                                                  return;
                                                }

                                                Navigator.of(
                                                  dialogContext,
                                                ).pop();

                                                if (!mounted) {
                                                  return;
                                                }

                                                // Deixa o usuário enxergar o novo
                                                // ramo surgindo antes da navegação.
                                                final grew = await _syncBrainVisualKnowledge(
                                                  animateGrowth: true,
                                                  reloadLocal: true,
                                                );

                                                if (grew) {
                                                  await Future<
                                                    void
                                                  >.delayed(
                                                    _brainGrowthPreviewDuration,
                                                  );
                                                }

                                                if (!mounted) {
                                                  return;
                                                }

                                                // ==================================================
                                                // PERMANECER NO CÉREBRO
                                                // ==================================================
                                                //
                                                // Depois de salvar, não abrimos mais a tela do tipo.
                                                // O usuário volta imediatamente para a BrainScreen e
                                                // consegue assistir à nova ramificação surgindo.
                                                //
                                                // ==================================================

                                                _controller.createNewNote();

                                                setState(
                                                  () {},
                                                );
                                              },
                                        icon: _controller.isSaving
                                            ? const SizedBox(
                                                width: 17,
                                                height: 17,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.save_outlined,
                                              ),
                                        label: Text(
                                          _controller.isSaving
                                              ? 'Salvando...'
                                              : 'Salvar ${type.label.toLowerCase()}',
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
        _brainGrowthPreviewDuration,
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

    setState(
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
          message: 'Novo conhecimento',
          child: IconButton(
            onPressed: _controller.isSaving
                ? null
                : _showCreateNoteDialog,
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
    return LayoutBuilder(
      builder:
          (
            context,
            constraints,
          ) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight -
                      48,
                ),
                child: Align(
                  alignment: const Alignment(
                    0,
                    -0.30,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 760,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_brainVisualReady &&
                            _brainVisualController !=
                                null) ...[
                          Center(
                            child: EvolvingBrain(
                              controller: _brainVisualController!,
                              size: 172,
                              config: const BrainVisualConfig(
                                birthDuration: Duration(
                                  milliseconds: 7200,
                                ),
                                branchGrowthDuration: Duration(
                                  milliseconds: 1900,
                                ),
                                branchSettleDuration: Duration(
                                  milliseconds: 380,
                                ),
                                searchPulseDuration: Duration(
                                  milliseconds: 2500,
                                ),
                              ),
                              onBirthCompleted: _onBrainBirthCompleted,
                            ),
                          ),

                          const SizedBox(
                            height: 14,
                          ),
                        ],

                        _buildSearchField(
                          context,
                        ),

                        if (_searchQuery.trim().isNotEmpty) ...[
                          const SizedBox(
                            height: 12,
                          ),

                          _buildSearchResults(
                            context,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
    );
  }
}

// ============================================================
// SEARCH VISUAL TARGET
// ============================================================

class _BrainSearchVisualTarget {
  const _BrainSearchVisualTarget({
    this.branchIndex,
    this.connectionIndex,
  });

  final int? branchIndex;
  final int? connectionIndex;
}

// ============================================================
// RASCUNHO DE PERGUNTA
// ============================================================
//
// FASE 09:
// perguntas não dependem mais de Tema; o texto e a captura usam
// apenas pergunta, resposta e primeira revisão.
//
//
// Usado somente pelo modal de criação em lote.
//
// Cada pergunta mantém controllers próprios para permitir que
// várias perguntas sejam preenchidas simultaneamente antes de
// enviarmos uma por uma para o BrainController.
//
// ============================================================

class _QuestionDraft {
  _QuestionDraft() : delay = _QuestionReviewDelay.oneDay;

  final TextEditingController questionController = TextEditingController();

  final TextEditingController answerController = TextEditingController();

  final List<
    BrainSource
  >
  sources =
      <
        BrainSource
      >[];

  _QuestionReviewDelay delay;

  void dispose() {
    questionController.dispose();

    answerController.dispose();
  }
}

// ============================================================
// PRIMEIRA REVISÃO DA PERGUNTA
// ============================================================
//
// Configuração individual escolhida ao criar cada pergunta.
//
// O ReviewController continua responsável pelos intervalos
// seguintes após o usuário responder à revisão.
//
// ============================================================

enum _QuestionReviewDelay {
  now,
  fifteenMinutes,
  oneHour,
  oneDay,
  threeDays,
  sevenDays,
  thirtyDays;

  String get label {
    switch (this) {
      case _QuestionReviewDelay.now:
        return 'Agora';

      case _QuestionReviewDelay.fifteenMinutes:
        return '15 minutos';

      case _QuestionReviewDelay.oneHour:
        return '1 hora';

      case _QuestionReviewDelay.oneDay:
        return '1 dia';

      case _QuestionReviewDelay.threeDays:
        return '3 dias';

      case _QuestionReviewDelay.sevenDays:
        return '7 dias';

      case _QuestionReviewDelay.thirtyDays:
        return '30 dias';
    }
  }

  Duration get duration {
    switch (this) {
      case _QuestionReviewDelay.now:
        return Duration.zero;

      case _QuestionReviewDelay.fifteenMinutes:
        return const Duration(
          minutes: 15,
        );

      case _QuestionReviewDelay.oneHour:
        return const Duration(
          hours: 1,
        );

      case _QuestionReviewDelay.oneDay:
        return const Duration(
          days: 1,
        );

      case _QuestionReviewDelay.threeDays:
        return const Duration(
          days: 3,
        );

      case _QuestionReviewDelay.sevenDays:
        return const Duration(
          days: 7,
        );

      case _QuestionReviewDelay.thirtyDays:
        return const Duration(
          days: 30,
        );
    }
  }
}
