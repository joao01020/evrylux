import 'dart:async';

import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart' as dependencies;

import '../controllers/brain_controller.dart';

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
  // PESQUISA
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // ============================================================
  // PESQUISA REMOTA / SUPABASE
  // ============================================================

  Timer? _searchDebounce;

  int _searchRequestVersion = 0;

  bool _isSearchingRemote = false;

  String? _remoteSearchError;

  List<
    BrainFile
  >
  _remoteNotes = [];

  final Set<
    String
  >
  _remoteNoteIds =
      <
        String
      >{};

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

    _searchDebounce?.cancel();

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
    await _controller.initialize();

    if (!mounted) {
      return;
    }

    _controller.createNewNote();

    _showControllerMessage();
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
      firstReviewAt: DateTime.now(),
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
  // PESQUISA
  // ============================================================

  List<
    BrainFile
  >
  get _filteredNotes {
    final query = _normalizeSearch(
      _searchQuery,
    );

    if (query.isEmpty) {
      return const <
        BrainFile
      >[];
    }

    final tokens = query
        .split(
          RegExp(
            r'\s+',
          ),
        )
        .where(
          (
            token,
          ) {
            return token.trim().isNotEmpty;
          },
        )
        .toList();

    if (tokens.isEmpty) {
      return const <
        BrainFile
      >[];
    }

    // ========================================================
    // LOCAL + SUPABASE
    // ========================================================
    //
    // O local continua sendo a primeira fonte.
    //
    // Depois adicionamos resultados remotos que ainda não estão
    // disponíveis no dispositivo.
    //
    // A chave de conteúdo impede a mesma anotação aparecer duas
    // vezes quando já existe localmente e também no Supabase.
    //
    // ========================================================

    final merged =
        <
          String,
          BrainFile
        >{};

    for (final note in _controller.notes) {
      merged[_noteContentKey(
            note,
          )] =
          note;
    }

    for (final note in _remoteNotes) {
      final key = _noteContentKey(
        note,
      );

      merged.putIfAbsent(
        key,
        () {
          return note;
        },
      );
    }

    final scored =
        <
          MapEntry<
            BrainFile,
            int
          >
        >[];

    for (final note in merged.values) {
      final score = _searchScore(
        note: note,
        query: query,
        tokens: tokens,
      );

      if (score <=
          0) {
        continue;
      }

      scored.add(
        MapEntry(
          note,
          score,
        ),
      );
    }

    scored.sort(
      (
        first,
        second,
      ) {
        final scoreComparison = second.value.compareTo(
          first.value,
        );

        if (scoreComparison !=
            0) {
          return scoreComparison;
        }

        return second.key.updatedAt.compareTo(
          first.key.updatedAt,
        );
      },
    );

    return scored.map(
      (
        entry,
      ) {
        return entry.key;
      },
    ).toList();
  }

  // ============================================================
  // PESQUISAR NO SUPABASE
  // ============================================================
  //
  // A pesquisa local responde imediatamente.
  //
  // Após um pequeno debounce buscamos as notas do usuário no
  // Supabase e aplicamos exatamente a mesma regra de relevância.
  //
  // Se estiver offline, os resultados locais continuam funcionando.
  //
  // ============================================================

  void _scheduleRemoteSearch(
    String rawQuery,
  ) {
    _searchDebounce?.cancel();

    final query = _normalizeSearch(
      rawQuery,
    );

    if (query.isEmpty) {
      _searchRequestVersion++;

      if (mounted) {
        setState(
          () {
            _remoteNotes = [];
            _remoteNoteIds.clear();
            _isSearchingRemote = false;
            _remoteSearchError = null;
          },
        );
      }

      return;
    }

    final requestVersion = ++_searchRequestVersion;

    _searchDebounce = Timer(
      const Duration(
        milliseconds: 350,
      ),
      () {
        _loadRemoteSearch(
          query: query,
          requestVersion: requestVersion,
        );
      },
    );
  }

  Future<
    void
  >
  _loadRemoteSearch({
    required String query,
    required int requestVersion,
  }) async {
    if (!mounted ||
        requestVersion !=
            _searchRequestVersion) {
      return;
    }

    setState(
      () {
        _isSearchingRemote = true;
        _remoteSearchError = null;
      },
    );

    try {
      final rows = await dependencies.supabaseBrainService.loadNotes();

      if (!mounted ||
          requestVersion !=
              _searchRequestVersion) {
        return;
      }

      final notes =
          <
            BrainFile
          >[];

      final ids =
          <
            String
          >{};

      for (final row in rows) {
        final note = _brainFileFromRemoteRow(
          row,
        );

        if (note ==
            null) {
          continue;
        }

        final normalizedQuery = _normalizeSearch(
          query,
        );

        final tokens = normalizedQuery
            .split(
              RegExp(
                r'\s+',
              ),
            )
            .where(
              (
                token,
              ) {
                return token.trim().isNotEmpty;
              },
            )
            .toList();

        if (_searchScore(
              note: note,
              query: normalizedQuery,
              tokens: tokens,
            ) <=
            0) {
          continue;
        }

        notes.add(
          note,
        );

        if (note.path.trim().isNotEmpty) {
          ids.add(
            note.path.trim(),
          );
        }
      }

      setState(
        () {
          _remoteNotes = notes;
          _remoteNoteIds
            ..clear()
            ..addAll(
              ids,
            );
          _isSearchingRemote = false;
          _remoteSearchError = null;
        },
      );
    } catch (
      error
    ) {
      if (!mounted ||
          requestVersion !=
              _searchRequestVersion) {
        return;
      }

      setState(
        () {
          _isSearchingRemote = false;
          _remoteSearchError = 'Sem acesso à nuvem. Mostrando resultados locais.';
        },
      );
    }
  }

  // ============================================================
  // REMOTE ROW -> BRAIN FILE
  // ============================================================

  BrainFile? _brainFileFromRemoteRow(
    Map<
      String,
      dynamic
    >
    row,
  ) {
    final id =
        row['id']?.toString().trim() ??
        '';

    final topic =
        row['topic']?.toString().trim() ??
        '';

    final title =
        row['title']?.toString().trim() ??
        '';

    final content =
        row['content']?.toString() ??
        '';

    if (id.isEmpty ||
        title.isEmpty ||
        content.trim().isEmpty) {
      return null;
    }

    final updatedAt =
        _parseRemoteDate(
          row['updated_at'],
        ) ??
        DateTime.now();

    final createdAt =
        _parseRemoteDate(
          row['created_at'],
        ) ??
        updatedAt;

    return BrainFile(
      topic: topic.isEmpty
          ? 'Sem tema'
          : topic,
      title: title,
      path: id,
      content: content,
      concepts:
          const <
            BrainConcept
          >[],
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  DateTime? _parseRemoteDate(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(
      text,
    )?.toLocal();
  }

  // ============================================================
  // SCORE DA PESQUISA
  // ============================================================
  //
  // Todos os termos digitados precisam existir na anotação.
  //
  // Isso evita exibir arquivos sem relação real com a busca.
  //
  // Prioridade:
  //
  // título > tema > conceitos > conteúdo > data
  //
  // ============================================================

  int _searchScore({
    required BrainFile note,
    required String query,
    required List<
      String
    >
    tokens,
  }) {
    final title = _normalizeSearch(
      note.title,
    );

    final topic = _normalizeSearch(
      note.topic,
    );

    final content = _normalizeSearch(
      note.content,
    );

    final conceptTitles =
        <
          String
        >[];

    final conceptDescriptions =
        <
          String
        >[];

    final conceptLabels =
        <
          String
        >[];

    for (final concept in note.concepts) {
      conceptTitles.add(
        _normalizeSearch(
          concept.title,
        ),
      );

      conceptDescriptions.add(
        _normalizeSearch(
          concept.description,
        ),
      );

      conceptLabels.add(
        _normalizeSearch(
          concept.label,
        ),
      );
    }

    final dates =
        <
          String
        >[
          _normalizeSearch(
            _formatSearchDate(
              note.createdAt,
            ),
          ),
          _normalizeSearch(
            _formatSearchDate(
              note.updatedAt,
            ),
          ),
          _normalizeSearch(
            _formatIsoDate(
              note.createdAt,
            ),
          ),
          _normalizeSearch(
            _formatIsoDate(
              note.updatedAt,
            ),
          ),
          note.createdAt.year.toString(),
          note.updatedAt.year.toString(),
        ];

    final allowDateSearch =
        RegExp(
          r'\d',
        ).hasMatch(
          query,
        );

    var score = 0;

    if (title ==
        query) {
      score += 1000;
    } else if (title.startsWith(
      query,
    )) {
      score += 700;
    } else if (query.length >=
            3 &&
        title.contains(
          query,
        )) {
      score += 500;
    }

    if (topic ==
        query) {
      score += 600;
    } else if (topic.startsWith(
      query,
    )) {
      score += 400;
    } else if (query.length >=
            3 &&
        topic.contains(
          query,
        )) {
      score += 280;
    }

    for (final value in conceptTitles) {
      if (value ==
          query) {
        score += 450;
      } else if (value.startsWith(
        query,
      )) {
        score += 320;
      } else if (query.length >=
              3 &&
          value.contains(
            query,
          )) {
        score += 220;
      }
    }

    if (query.length >=
            4 &&
        content.contains(
          query,
        )) {
      score += 120;
    }

    if (allowDateSearch &&
        dates.any(
          (
            value,
          ) {
            return value.contains(
              query,
            );
          },
        )) {
      score += 300;
    }

    for (final token in tokens) {
      var tokenScore = 0;

      tokenScore = _maxSearchScore(
        tokenScore,
        _scoreSearchField(
          value: title,
          token: token,
          exact: 180,
          prefix: 130,
          contains: 90,
        ),
      );

      tokenScore = _maxSearchScore(
        tokenScore,
        _scoreSearchField(
          value: topic,
          token: token,
          exact: 140,
          prefix: 100,
          contains: 70,
        ),
      );

      for (final value in conceptTitles) {
        tokenScore = _maxSearchScore(
          tokenScore,
          _scoreSearchField(
            value: value,
            token: token,
            exact: 120,
            prefix: 90,
            contains: 60,
          ),
        );
      }

      for (final value in conceptLabels) {
        tokenScore = _maxSearchScore(
          tokenScore,
          _scoreSearchField(
            value: value,
            token: token,
            exact: 100,
            prefix: 75,
            contains: 50,
          ),
        );
      }

      for (final value in conceptDescriptions) {
        tokenScore = _maxSearchScore(
          tokenScore,
          _scoreSearchField(
            value: value,
            token: token,
            exact: 80,
            prefix: 60,
            contains: 40,
          ),
        );
      }

      tokenScore = _maxSearchScore(
        tokenScore,
        _scoreSearchField(
          value: content,
          token: token,
          exact: 70,
          prefix: 50,
          contains: 30,
        ),
      );

      if (allowDateSearch) {
        for (final value in dates) {
          tokenScore = _maxSearchScore(
            tokenScore,
            _scoreSearchField(
              value: value,
              token: token,
              exact: 90,
              prefix: 70,
              contains: 50,
              allowShortContains: true,
            ),
          );
        }
      }

      if (tokenScore <=
          0) {
        return 0;
      }

      score += tokenScore;
    }

    return score;
  }

  int _scoreSearchField({
    required String value,
    required String token,
    required int exact,
    required int prefix,
    required int contains,
    bool allowShortContains = false,
  }) {
    if (value.isEmpty ||
        token.isEmpty) {
      return 0;
    }

    if (value ==
        token) {
      return exact;
    }

    if (value.startsWith(
      token,
    )) {
      return prefix;
    }

    final canUseContains =
        allowShortContains ||
        token.length >=
            3;

    if (canUseContains &&
        value.contains(
          token,
        )) {
      return contains;
    }

    return 0;
  }

  int _maxSearchScore(
    int first,
    int second,
  ) {
    return first >
            second
        ? first
        : second;
  }

  String _noteContentKey(
    BrainFile note,
  ) {
    return '${_normalizeSearch(note.topic)}|'
        '${_normalizeSearch(note.title)}|'
        '${_normalizeSearch(note.content)}';
  }

  // ============================================================
  // NORMALIZAR PESQUISA
  // ============================================================

  String _normalizeSearch(
    String value,
  ) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(
          RegExp(
            r'[áàãâä]',
          ),
          'a',
        )
        .replaceAll(
          RegExp(
            r'[éèêë]',
          ),
          'e',
        )
        .replaceAll(
          RegExp(
            r'[íìîï]',
          ),
          'i',
        )
        .replaceAll(
          RegExp(
            r'[óòõôö]',
          ),
          'o',
        )
        .replaceAll(
          RegExp(
            r'[úùûü]',
          ),
          'u',
        )
        .replaceAll(
          'ç',
          'c',
        );
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
  // DATA ISO
  // ============================================================

  String _formatIsoDate(
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

    return '${local.year}-'
        '${two(local.month)}-'
        '${two(local.day)}';
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
  // Qualquer anotação existente, local ou vinda do Supabase,
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
    var noteToOpen = note;

    // ========================================================
    // RESULTADO REMOTO
    // ========================================================
    //
    // Se a anotação existe somente no Supabase, criamos primeiro
    // a cópia local. Depois abrimos uma PÁGINA exclusiva para o
    // arquivo, em vez de reutilizar o modal de criação.
    //
    // ========================================================

    final isRemoteOnly =
        _remoteNoteIds.contains(
          note.path.trim(),
        ) &&
        !_controller.notes.any(
          (
            local,
          ) {
            return _noteContentKey(
                  local,
                ) ==
                _noteContentKey(
                  note,
                );
          },
        );

    if (isRemoteOnly) {
      try {
        final localCopy = await dependencies.brainStorage.saveNote(
          topic: note.topic,
          title: note.title,
          content: note.content,
          concepts:
              const <
                BrainConcept
              >[],
        );

        await _controller.loadNotes();

        noteToOpen = localCopy;
      } catch (
        _
      ) {
        if (!mounted) {
          return;
        }

        _showMessage(
          'A anotação foi encontrada no Supabase, mas não foi possível criar a cópia local.',
        );

        return;
      }
    }

    if (!mounted) {
      return;
    }

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
            true ||
        isRemoteOnly) {
      await _controller.loadNotes();
    }

    if (!mounted) {
      return;
    }

    setState(
      () {},
    );
  }

  // ============================================================
  // CAMPO DE PESQUISA
  // ============================================================

  Widget _buildSearchField(
    BuildContext context,
  ) {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onChanged:
          (
            value,
          ) {
            setState(
              () {
                _searchQuery = value;
              },
            );

            _scheduleRemoteSearch(
              value,
            );
          },
      decoration: InputDecoration(
        hintText: 'Pesquisar por tema, título, conteúdo ou data...',
        prefixIcon: const Icon(
          Icons.search_rounded,
        ),
        suffixIcon: _searchQuery.trim().isEmpty
            ? null
            : IconButton(
                tooltip: 'Limpar pesquisa',
                onPressed: () {
                  _searchDebounce?.cancel();

                  _searchRequestVersion++;

                  _searchController.clear();

                  setState(
                    () {
                      _searchQuery = '';
                      _remoteNotes = [];
                      _remoteNoteIds.clear();
                      _isSearchingRemote = false;
                      _remoteSearchError = null;
                    },
                  );
                },
                icon: const Icon(
                  Icons.close_rounded,
                ),
              ),
        filled: true,
        fillColor:
            Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(
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
            color: Theme.of(
              context,
            ).colorScheme.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RESULTADOS DA PESQUISA
  // ============================================================

  Widget _buildSearchResults(
    BuildContext context,
  ) {
    final notes = _filteredNotes;

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
                    notes.isEmpty
                        ? 'Nenhum resultado'
                        : '${notes.length} resultado${notes.length == 1 ? '' : 's'}',
                    style:
                        Theme.of(
                          context,
                        ).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                if (_isSearchingRemote)
                  const Padding(
                    padding: EdgeInsets.only(
                      right: 8,
                    ),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),

                Text(
                  _isSearchingRemote
                      ? 'Consultando nuvem...'
                      : _remoteSearchError ??
                            'Local + Supabase',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall,
                ),
              ],
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

          if (notes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(
                18,
              ),
              child: Text(
                'Nenhuma anotação corresponde à pesquisa.',
              ),
            )
          else
            for (
              var index = 0;
              index <
                  notes.length;
              index++
            ) ...[
              _buildSearchResultCard(
                context,
                notes[index],
              ),
              if (index !=
                  notes.length -
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
          padding: const EdgeInsets.all(
            16,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
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
                          icon: Icons.folder_outlined,
                          text: note.topic,
                        ),
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
                        maxLines: 3,
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
  // MODAL EXCLUSIVO PARA CRIAR ANOTAÇÃO
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Este modal é usado SOMENTE pelo botão "+ Nova anotação".
  //
  // Arquivos já existentes nunca passam por este modal.
  // Eles são abertos exclusivamente em:
  //
  // lib/study/brain/screen/note/brain_note_screen.dart
  //
  // ============================================================

  Future<
    void
  >
  _showCreateNoteDialog() async {
    if (_controller.isSaving) {
      return;
    }

    _controller.createNewNote();

    await _showCreateNoteEditorDialog();
  }

  Future<
    void
  >
  _showCreateNoteEditorDialog() async {
    if (!mounted) {
      return;
    }

    await showDialog<
      void
    >(
      context: context,
      barrierDismissible: !_controller.isSaving,
      builder:
          (
            dialogContext,
          ) {
            return Dialog(
              clipBehavior: Clip.antiAlias,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 820,
                  maxHeight: 760,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        16,
                        12,
                        12,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.edit_note_rounded,
                            size: 22,
                          ),

                          const SizedBox(
                            width: 10,
                          ),

                          Expanded(
                            child: Text(
                              _controller.selectedNote ==
                                      null
                                  ? 'Nova anotação'
                                  : 'Editar anotação',
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

                    // ==================================================
                    // EDITOR
                    // ==================================================
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(
                          20,
                        ),
                        child: BrainEditorSection(
                          selectedNote: _controller.selectedNote,
                          topicController: _controller.topicController,
                          titleController: _controller.titleController,
                          contentController: _controller.contentController,
                          contentFocusNode: _controller.contentFocusNode,
                          isSaving: _controller.isSaving,
                          onSave: _saveNote,
                          onDelete:
                              (
                                note,
                              ) async {
                                await _deleteNote(
                                  note,
                                );

                                if (!dialogContext.mounted) {
                                  return;
                                }

                                Navigator.of(
                                  dialogContext,
                                ).pop();
                              },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
                    -0.22,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 760,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
