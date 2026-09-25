part of '../brain_screen.dart';

// ============================================================
// IA — HISTÓRICO DE SUGESTÕES DA SESSÃO
// ============================================================
//
// Objetivo:
//
// evitar que uma mesma consulta para um mesmo assunto mostre sempre
// os mesmos "Próximos caminhos".
//
// Regras:
//
// - histórico somente em memória;
// - separado por assunto;
// - máximo de 12 títulos recentes por assunto;
// - não altera nem salva conhecimento do usuário;
// - ao reiniciar o aplicativo, o histórico recomeça.
//
// ============================================================

const int
_brainAiRecentSuggestionHistoryLimit = 12;

final Map<
  String,
  List<
    String
  >
>
_brainAiRecentSuggestionHistory =
    <
      String,
      List<
        String
      >
    >{};

// Visual lifecycle + local/Vault-first search experience.
extension _BrainScreenVisualSearch
    on
        _BrainScreenState {
  // ============================================================
  // CÉREBRO VISUAL — CONTAGEM
  // ============================================================

  int _currentBrainKnowledgeCount() {
    return _controller.notes.length;
  }

  // ============================================================
  // CÉREBRO VISUAL — NASCIMENTO
  // ============================================================

  Future<
    void
  >
  _onBrainBirthCompleted() async {
    await _completeBrainBirth();
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

    if (animateGrowth &&
        currentCount >
            previousVisualCount) {
      visualController.animateKnowledgeTarget(
        currentCount,
      );

      return true;
    }

    visualController.setKnowledgeCount(
      currentCount,
    );

    return false;
  }

  // ============================================================
  // BUSCA NATURAL — ESTRUTURAS QUE EXIGEM COMPLEMENTO
  // ============================================================
  //
  // REGRA CENTRAL:
  //
  // Estas frases são MODELOS DE PESQUISA.
  //
  // Elas descrevem COMO pesquisar.
  //
  // Elas não representam, sozinhas, o conteúdo procurado.
  //
  // Exemplos:
  //
  // "perguntas sobre"
  //
  // -> incompleto
  // -> não pesquisar
  //
  // "perguntas sobre eletrônica"
  //
  // -> estrutura = perguntas sobre
  // -> assunto   = eletrônica
  // -> pesquisar
  //
  // ------------------------------------------------------------
  //
  // "o que eu fiz no dia"
  //
  // -> incompleto
  // -> falta uma data
  //
  // "o que eu fiz no dia 16"
  //
  // -> estrutura = o que eu fiz no dia
  // -> data      = 16
  // -> pesquisar
  //
  // ------------------------------------------------------------
  //
  // IMPORTANTE:
  //
  // Não colocamos aqui consultas que já são completas:
  //
  // - o que estudei ontem
  // - o que anotei essa semana
  // - o que vi no mês passado
  // - o que eu estudei de manhã
  // - o que fiz hoje à tarde
  // - o que anotei ontem à noite
  // - mostre só 10 resultados
  //
  // Essas consultas podem ser executadas diretamente.
  //
  // ============================================================

  static const List<
    String
  >
  _brainSearchRequiredCompletionPrefixes = [
    // ==========================================================
    // BUSCA SIMPLES
    // ==========================================================
    'algo sobre',

    'onde eu falei de',
    'quando eu falei de',

    'onde eu falei sobre',
    'quando eu falei sobre',

    'onde eu anotei sobre',
    'quando eu anotei sobre',

    'onde eu escrevi sobre',
    'quando eu escrevi sobre',

    'aquele conteúdo sobre',
    'a anotação que falava de',

    // ==========================================================
    // TIPOS DE CONHECIMENTO
    // ==========================================================
    'conceitos sobre',
    'perguntas sobre',
    'exemplos sobre',
    'atenções sobre',

    // ==========================================================
    // DATA QUE AINDA PRECISA SER INFORMADA
    // ==========================================================
    'o que eu fiz no dia',
    'o que anotei na manhã de',

    // ==========================================================
    // RECÊNCIA + ASSUNTO
    // ==========================================================
    'o que estudei recentemente sobre',
    'minhas últimas anotações sobre',
    'o que eu vi por último sobre',

    // ==========================================================
    // CONHECIMENTO ACUMULADO + ASSUNTO
    // ==========================================================
    'o que eu já sei sobre',
    'o que eu já aprendi sobre',
    'o que eu já anotei sobre',

    // ==========================================================
    // IA — LACUNAS DE ESTUDO
    // ==========================================================
    'o que falta eu aprender sobre',

    // ==========================================================
    // IA — REVISÃO
    // ==========================================================
    'o que eu deveria revisar sobre',

    // ==========================================================
    // IA — CONHECIMENTOS RELACIONADOS
    // ==========================================================
    'quais conhecimentos estão relacionados a',

    // ==========================================================
    // IA — PERGUNTAS EM ABERTO
    // ==========================================================
    'quais perguntas eu ainda tenho sobre',
  ];

  // ============================================================
  // QUANTIDADE + ASSUNTO
  // ============================================================
  //
  // Em vez de cadastrar:
  //
  // me mostre 3 perguntas sobre
  // me mostre 5 perguntas sobre
  // me mostre 10 perguntas sobre
  //
  // separadamente, tratamos qualquer quantidade.
  //
  // Isso evita redundância.
  //
  // Exemplos:
  //
  // me mostre 5 resultados sobre
  // me mostre 3 perguntas sobre
  // mostre 8 conceitos sobre
  // mostre 4 exemplos sobre
  //
  // Todos exigem algo DEPOIS de "sobre".
  //
  // ============================================================

  RegExp get _brainSearchQuantitySubjectPattern {
    return RegExp(
      r'^(?:me\s+)?'
      r'(?:mostre|mostra|mostrar)\s+'
      r'\d{1,3}\s+'
      r'(?:'
      r'resultado|resultados|'
      r'pergunta|perguntas|'
      r'conceito|conceitos|'
      r'exemplo|exemplos|'
      r'atencao|atencoes'
      r')\s+'
      r'sobre'
      r'(?:\s+(.+))?$',
    );
  }

  // ============================================================
  // NORMALIZAÇÃO DA ESTRUTURA
  // ============================================================
  //
  // Esta normalização é apenas para reconhecer os modelos.
  //
  // Também removemos acentos para que:
  //
  // atenção
  // atencao
  //
  // sejam entendidos da mesma forma.
  //
  // ============================================================

  String _normalizeBrainSearchStructure(
    String value,
  ) {
    var normalized = value.trim().toLowerCase();

    const replacements =
        <
          String,
          String
        >{
          'á': 'a',
          'à': 'a',
          'â': 'a',
          'ã': 'a',
          'ä': 'a',
          'é': 'e',
          'è': 'e',
          'ê': 'e',
          'ë': 'e',
          'í': 'i',
          'ì': 'i',
          'î': 'i',
          'ï': 'i',
          'ó': 'o',
          'ò': 'o',
          'ô': 'o',
          'õ': 'o',
          'ö': 'o',
          'ú': 'u',
          'ù': 'u',
          'û': 'u',
          'ü': 'u',
          'ç': 'c',
        };

    replacements.forEach(
      (
        source,
        target,
      ) {
        normalized = normalized.replaceAll(
          source,
          target,
        );
      },
    );

    return normalized
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        )
        .trim();
  }

  // ============================================================
  // PREFIXO NORMALIZADO MAIS ESPECÍFICO
  // ============================================================
  //
  // Ordenamos pelo maior primeiro.
  //
  // Isso evita que uma estrutura menor capture uma maior.
  //
  // ============================================================

  List<
    String
  >
  get _orderedRequiredSearchPrefixes {
    final result =
        <
          String
        >[
          ..._brainSearchRequiredCompletionPrefixes,
        ];

    result.sort(
      (
        first,
        second,
      ) {
        return second.length.compareTo(
          first.length,
        );
      },
    );

    return result;
  }

  // ============================================================
  // QUANTIDADE + ASSUNTO — ANALISAR
  // ============================================================

  _BrainSearchInputState? _brainQuantitySearchInputState({
    required String original,
    required String normalized,
  }) {
    final match = _brainSearchQuantitySubjectPattern.firstMatch(
      normalized,
    );

    if (match ==
        null) {
      return null;
    }

    final subject =
        (match.group(
                  1,
                ) ??
                '')
            .trim();

    final matchedWithoutSubject = subject.isEmpty
        ? normalized
        : normalized
              .substring(
                0,
                normalized.length -
                    subject.length,
              )
              .trim();

    if (subject.isEmpty) {
      return _BrainSearchInputState.waitingSubject(
        prefix: matchedWithoutSubject,
      );
    }

    return _BrainSearchInputState.ready(
      originalQuery: original,
      effectiveQuery: subject,
      recognizedPrefix: matchedWithoutSubject,
    );
  }

  // ============================================================
  // ESTADO DA CONSULTA
  // ============================================================

  _BrainSearchInputState _brainSearchInputState(
    String rawQuery,
  ) {
    final original = rawQuery.trim();

    if (original.isEmpty) {
      return const _BrainSearchInputState.empty();
    }

    final normalized = _normalizeBrainSearchStructure(
      original,
    );

    // ==========================================================
    // 1. QUANTIDADE + ASSUNTO
    // ==========================================================
    //
    // Exemplo:
    //
    // me mostre 3 perguntas sobre
    //
    // não pode pesquisar.
    //
    // me mostre 3 perguntas sobre eletrônica
    //
    // pode pesquisar.
    //
    // ==========================================================

    final quantityState = _brainQuantitySearchInputState(
      original: original,
      normalized: normalized,
    );

    if (quantityState !=
        null) {
      return quantityState;
    }

    // ==========================================================
    // 2. PREFIXOS QUE EXIGEM COMPLEMENTO
    // ==========================================================

    for (final prefix in _orderedRequiredSearchPrefixes) {
      final normalizedPrefix = _normalizeBrainSearchStructure(
        prefix,
      );

      // ========================================================
      // PREFIXO EXATO, SEM COMPLEMENTO
      // ========================================================

      if (normalized ==
          normalizedPrefix) {
        return _BrainSearchInputState.waitingSubject(
          prefix: prefix,
        );
      }

      // ========================================================
      // PREFIXO + COMPLEMENTO
      // ========================================================

      final prefixWithSpace = '$normalizedPrefix ';

      if (normalized.startsWith(
        prefixWithSpace,
      )) {
        final normalizedSubject = normalized
            .substring(
              prefixWithSpace.length,
            )
            .trim();

        if (normalizedSubject.isEmpty) {
          return _BrainSearchInputState.waitingSubject(
            prefix: prefix,
          );
        }

        // ======================================================
        // EXTRAIR O COMPLEMENTO DO TEXTO ORIGINAL
        // ======================================================
        //
        // Fazemos por quantidade de palavras.
        //
        // Isso preserva:
        //
        // - maiúsculas;
        // - acentos;
        // - símbolos;
        // - nomes técnicos.
        //
        // ======================================================

        final prefixWordCount = normalizedPrefix
            .split(
              ' ',
            )
            .where(
              (
                word,
              ) => word.trim().isNotEmpty,
            )
            .length;

        final originalWords = original
            .split(
              RegExp(
                r'\s+',
              ),
            )
            .where(
              (
                word,
              ) => word.trim().isNotEmpty,
            )
            .toList();

        if (originalWords.length <=
            prefixWordCount) {
          return _BrainSearchInputState.waitingSubject(
            prefix: prefix,
          );
        }

        final subject = originalWords
            .skip(
              prefixWordCount,
            )
            .join(
              ' ',
            )
            .trim();

        if (subject.isEmpty) {
          return _BrainSearchInputState.waitingSubject(
            prefix: prefix,
          );
        }

        return _BrainSearchInputState.ready(
          originalQuery: original,
          effectiveQuery: subject,
          recognizedPrefix: prefix,
        );
      }
    }

    // ==========================================================
    // 3. PREFIXO AINDA SENDO DIGITADO
    // ==========================================================
    //
    // Exemplo:
    //
    // "perguntas sob"
    //
    // ainda não deve pesquisar.
    //
    // ==========================================================

    for (final prefix in _orderedRequiredSearchPrefixes) {
      final normalizedPrefix = _normalizeBrainSearchStructure(
        prefix,
      );

      if (normalizedPrefix.startsWith(
        normalized,
      )) {
        return _BrainSearchInputState.incomplete(
          expectedPrefix: prefix,
        );
      }
    }

    // ==========================================================
    // 4. QUANTIDADE SENDO DIGITADA
    // ==========================================================
    //
    // Evita que:
    //
    // me mostre 3 perguntas sobr
    //
    // seja interpretado como uma busca textual.
    //
    // ==========================================================

    final looksLikeIncompleteQuantity =
        RegExp(
          r'^(?:me\s+)?'
          r'(?:mostre|mostra|mostrar)'
          r'(?:\s+\d{0,3})?'
          r'(?:\s+(?:'
          r'resultado|resultados|'
          r'pergunta|perguntas|'
          r'conceito|conceitos|'
          r'exemplo|exemplos|'
          r'atencao|atencoes'
          r'))?'
          r'(?:\s+sob(?:r(?:e)?)?)?$',
        ).hasMatch(
          normalized,
        );

    if (looksLikeIncompleteQuantity) {
      return _BrainSearchInputState.incomplete(
        expectedPrefix: 'me mostre uma quantidade sobre',
      );
    }

    // ==========================================================
    // 5. BUSCA LIVRE — VALIDAR CRITÉRIOS
    // ==========================================================
    //
    // Uma pesquisa pode existir por:
    //
    // - texto;
    // - tipo;
    // - data;
    // - quantidade;
    // - recência;
    // - intenção de conhecimento acumulado.
    //
    // Exemplos válidos:
    //
    // ESP32
    //
    // perguntas
    //
    // o que estudei ontem
    //
    // mostre só 10 resultados
    //
    // ==========================================================

    final parsedFreeQuery = _BrainScreenState._searchParser.parse(
      original,
    );

    final hasSearchCriteria =
        parsedFreeQuery.hasTerms ||
        parsedFreeQuery.hasTypeFilter ||
        parsedFreeQuery.hasDateFilter ||
        parsedFreeQuery.hasLimit ||
        parsedFreeQuery.isNewestSort ||
        parsedFreeQuery.isOldestSort ||
        parsedFreeQuery.isKnowledgeOverview;

    if (!hasSearchCriteria) {
      return _BrainSearchInputState.waitingSubject(
        prefix: original,
      );
    }

    return _BrainSearchInputState.ready(
      originalQuery: original,
      effectiveQuery: original,
    );
  }

  // ============================================================
  // DEBOUNCE — PESQUISA
  // ============================================================

  void _scheduleSearchCommit(
    String rawQuery,
  ) {
    _searchDebounceTimer?.cancel();

    final query = rawQuery.trim();

    if (query.isEmpty) {
      _mutateState(
        () {
          _committedSearchQuery = '';
          _showAllSearchResults = false;
        },
      );

      _setBrainSearchActivity(
        '',
      );

      return;
    }

    // ==========================================================
    // NÃO AGENDAR UMA ESTRUTURA INCOMPLETA
    // ==========================================================

    final inputState = _brainSearchInputState(
      rawQuery,
    );

    if (!inputState.canSearch) {
      _mutateState(
        () {
          _committedSearchQuery = '';
          _showAllSearchResults = false;
        },
      );

      _setBrainSearchActivity(
        '',
      );

      return;
    }

    // ==========================================================
    // AGUARDAR O USUÁRIO PARAR DE DIGITAR
    // ==========================================================

    _searchDebounceTimer = Timer(
      _BrainScreenState._searchDebounceDuration,
      () {
        if (!mounted) {
          return;
        }

        if (_searchQuery.trim() !=
            query) {
          return;
        }

        final currentState = _brainSearchInputState(
          _searchQuery,
        );

        if (!currentState.canSearch) {
          _mutateState(
            () {
              _committedSearchQuery = '';
              _showAllSearchResults = false;
            },
          );

          _setBrainSearchActivity(
            '',
          );

          return;
        }

        _mutateState(
          () {
            _committedSearchQuery = _searchQuery;

            _showAllSearchResults = false;
          },
        );

        _scheduleRemoteSearch(
          _committedSearchQuery,
        );

        _setBrainSearchActivity(
          _committedSearchQuery,
        );
      },
    );
  }

  // ============================================================
  // CONFIRMAR PESQUISA IMEDIATAMENTE
  // ============================================================

  void _commitSearchImmediately(
    String rawQuery, {
    Duration activityHold = const Duration(
      milliseconds: 1600,
    ),
  }) {
    _searchDebounceTimer?.cancel();

    final query = rawQuery.trim();

    if (query.isEmpty) {
      _mutateState(
        () {
          _committedSearchQuery = '';
          _showAllSearchResults = false;
          _brainAiLoading = false;
          _brainAiResponse = null;
          _brainAiError = null;
        },
      );

      _setBrainSearchActivity(
        '',
      );

      return;
    }

    final inputState = _brainSearchInputState(
      rawQuery,
    );

    // ==========================================================
    // MODELO INCOMPLETO
    // ==========================================================
    //
    // Inclusive quando o usuário clica em "Usar".
    //
    // O modelo será colocado no campo, mas a pesquisa NÃO será
    // executada até ele completar o que falta.
    //
    // ==========================================================

    if (!inputState.canSearch) {
      _mutateState(
        () {
          _searchQuery = rawQuery;
          _committedSearchQuery = '';
          _showAllSearchResults = false;
          _brainAiLoading = false;
          _brainAiResponse = null;
          _brainAiError = null;
        },
      );

      _setBrainSearchActivity(
        '',
      );

      return;
    }

    _mutateState(
      () {
        _searchQuery = rawQuery;
        _committedSearchQuery = rawQuery;
        _showAllSearchResults = false;

        // A resposta anterior não pertence à nova consulta.
        _brainAiResponse = null;
        _brainAiError = null;
      },
    );

    _scheduleRemoteSearch(
      rawQuery,
    );

    _setBrainSearchActivity(
      rawQuery,
      hold: activityHold,
    );
  }

  // ============================================================
  // SABER SE O USUÁRIO AINDA ESTÁ DIGITANDO
  // ============================================================

  bool get _isSearchWaitingForDebounce {
    final current = _searchQuery.trim();
    final committed = _committedSearchQuery.trim();

    if (current.isEmpty) {
      return false;
    }

    final inputState = _brainSearchInputState(
      current,
    );

    if (!inputState.canSearch) {
      return false;
    }

    return current !=
        committed;
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

    final inputState = _brainSearchInputState(
      rawQuery,
    );

    if (!inputState.canSearch) {
      visualController.setSearching(
        false,
      );

      visualController.clearSearchMatch();

      return;
    }

    visualController.clearSearchMatch();

    visualController.setSearching(
      true,
    );

    _brainSearchPulseStopTimer = Timer(
      hold,
      () {
        if (!mounted) {
          return;
        }

        if (_committedSearchQuery.trim() !=
            normalizedQuery) {
          return;
        }

        final currentState = _brainSearchInputState(
          _committedSearchQuery,
        );

        if (!currentState.canSearch) {
          visualController.setSearching(
            false,
          );

          visualController.clearSearchMatch();

          return;
        }

        final response = _searchResponse;
        final results = response.allResults;

        if (results.isEmpty) {
          debugPrint(
            '[BRAIN SEARCH VISUAL] '
            'Nenhum resultado para '
            '"${currentState.originalQuery}".',
          );

          visualController.setSearching(
            false,
          );

          visualController.clearSearchMatch();

          return;
        }

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

    return const _BrainSearchVisualTarget();
  }

  int _indexOfBrainNote(
    BrainFile note,
  ) {
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
  // PESQUISA
  // ============================================================
  //
  // CORREÇÃO IMPORTANTE:
  //
  // Antes, quando uma estrutura era reconhecida, o parser recebia
  // somente o assunto.
  //
  // Exemplo:
  //
  // perguntas sobre eletrônica
  //
  // virava:
  //
  // eletrônica
  //
  // Isso fazia o parser perder o filtro "perguntas".
  //
  // Agora:
  //
  // - effectiveQuery é usado para VALIDAR se existe complemento;
  // - originalQuery é enviado ao BrainSearchParser.
  //
  // Assim:
  //
  // perguntas sobre eletrônica
  //
  // produz:
  //
  // type  = question
  // terms = eletrônica
  //
  // O mesmo vale para:
  //
  // - quantidade;
  // - datas;
  // - recência;
  // - conhecimento acumulado.
  //
  // ============================================================

  BrainSearchResponse get _searchResponse {
    final committedQuery = _committedSearchQuery.trim();

    if (committedQuery.isEmpty) {
      return BrainSearchResponse.fromResults(
        const <
          BrainFile
        >[],
      );
    }

    final inputState = _brainSearchInputState(
      committedQuery,
    );

    if (!inputState.canSearch) {
      return BrainSearchResponse.fromResults(
        const <
          BrainFile
        >[],
      );
    }

    // ==========================================================
    // PARSER RECEBE A FRASE COMPLETA
    // ==========================================================

    final parsedQuery = _BrainScreenState._searchParser.parse(
      inputState.originalQuery,
    );

    if (parsedQuery.isEmpty) {
      return BrainSearchResponse.fromResults(
        const <
          BrainFile
        >[],
      );
    }

    return _BrainScreenState._searchEngine.search(
      notes: _controller.notes,
      query: parsedQuery,
      topLimit: 3,
    );
  }

  // ============================================================
  // PESQUISA LOCAL / VAULT-FIRST
  // ============================================================

  void _scheduleRemoteSearch(
    String rawQuery,
  ) {
    if (rawQuery.trim().isEmpty) {
      return;
    }
  }

  // ============================================================
  // BRAIN AI — CONSULTA INTELIGENTE
  // ============================================================
  //
  // A IA NÃO é chamada durante a digitação.
  //
  // Fluxo:
  //
  // usuário confirma a consulta
  //      ↓
  // detector identifica se a intenção exige IA
  //      ↓
  // busca local já confirmada fornece os resultados relevantes
  //      ↓
  // BrainAiContextBuilder compacta o contexto
  //      ↓
  // BrainAiSupabaseClient chama a Edge Function
  //      ↓
  // Groq responde em JSON estruturado
  //
  // Busca normal continua 100% local.
  //
  // ============================================================

  // ============================================================
  // BRAIN AI — HISTÓRICO DE PRÓXIMOS CAMINHOS
  // ============================================================

  String _brainAiSuggestionHistoryKey({
    required String query,
    String? topic,
  }) {
    final cleanTopic =
        topic?.trim() ??
        '';

    final source = cleanTopic.isNotEmpty
        ? cleanTopic
        : query.trim();

    return _normalizeBrainSearchStructure(
      source,
    );
  }

  List<
    String
  >
  _brainAiRecentSuggestionsFor(
    String historyKey,
  ) {
    final items = _brainAiRecentSuggestionHistory[historyKey];

    if (items ==
            null ||
        items.isEmpty) {
      return const <
        String
      >[];
    }

    return List<
      String
    >.unmodifiable(
      items,
    );
  }

  void _rememberBrainAiSuggestions({
    required String historyKey,
    required BrainAiResponse response,
  }) {
    if (historyKey.trim().isEmpty ||
        response.suggestions.isEmpty) {
      return;
    }

    final history = _brainAiRecentSuggestionHistory.putIfAbsent(
      historyKey,
      () =>
          <
            String
          >[],
    );

    for (final suggestion in response.suggestions) {
      final title = suggestion.title.trim();

      if (title.isEmpty) {
        continue;
      }

      final normalizedTitle = _normalizeBrainSearchStructure(
        title,
      );

      history.removeWhere(
        (
          existing,
        ) =>
            _normalizeBrainSearchStructure(
              existing,
            ) ==
            normalizedTitle,
      );

      history.add(
        title,
      );
    }

    while (history.length >
        _brainAiRecentSuggestionHistoryLimit) {
      history.removeAt(
        0,
      );
    }

    debugPrint(
      '[BRAIN AI] Histórico de sugestões atualizado. '
      'tema="$historyKey" '
      'itens=${history.length}',
    );
  }

  // ============================================================
  // BRAIN AI — BUSCA LOCAL DO CONTEXTO
  // ============================================================
  //
  // PROBLEMA QUE ESTA FUNÇÃO RESOLVE:
  //
  // A frase:
  //
  // "o que falta eu aprender sobre ESP32"
  //
  // NÃO deve ser usada literalmente para procurar anotações.
  //
  // Para recuperar o conhecimento que será enviado à IA, usamos:
  //
  // "ESP32"
  //
  // Assim a busca local encontra os conhecimentos reais do assunto
  // e somente depois a IA interpreta a intenção da pergunta.
  //
  // ============================================================

  BrainSearchResponse _brainAiSearchResponseForTopic(
    String rawTopic,
  ) {
    final topic = rawTopic.trim();

    if (topic.isEmpty) {
      return BrainSearchResponse.fromResults(
        const <
          BrainFile
        >[],
      );
    }

    final parsedTopic = _BrainScreenState._searchParser.parse(
      topic,
    );

    if (parsedTopic.isEmpty) {
      return BrainSearchResponse.fromResults(
        const <
          BrainFile
        >[],
      );
    }

    return _BrainScreenState._searchEngine.search(
      notes: _controller.notes,
      query: parsedTopic,
      topLimit: 8,
    );
  }

  // ============================================================
  // BRAIN AI — CONSULTA INTELIGENTE
  // ============================================================
  //
  // Fluxo corrigido:
  //
  // usuário confirma com Enter
  //      ↓
  // detector identifica intenção + assunto
  //      ↓
  // busca local procura SOMENTE o assunto
  //      ↓
  // resultados relevantes viram contexto compacto
  //      ↓
  // Supabase Edge Function
  //      ↓
  // Groq
  //      ↓
  // resposta estruturada
  //
  // A frase original continua sendo enviada para a IA para que ela
  // saiba O QUE o usuário perguntou.
  //
  // O contexto, porém, vem da pesquisa local pelo ASSUNTO.
  //
  // ============================================================

  Future<
    void
  >
  _runBrainSmartQuery(
    String rawQuery,
  ) async {
    final query = rawQuery.trim();

    if (query.isEmpty) {
      _clearBrainAiState();
      return;
    }

    final inputState = _brainSearchInputState(
      query,
    );

    if (!inputState.canSearch) {
      _clearBrainAiState();
      return;
    }

    final intent = _BrainScreenState._brainAiIntentDetector.detect(
      query,
    );

    // ==========================================================
    // BUSCA NORMAL
    // ==========================================================
    //
    // Uma pesquisa como:
    //
    // ESP32
    // Flutter
    // criptografia
    //
    // continua 100% local.
    //
    // ==========================================================

    if (!intent.usesAi) {
      _clearBrainAiState();
      return;
    }

    final requestQuery = query;

    // O detector é a fonte principal do assunto.
    //
    // O effectiveQuery é um fallback seguro para as estruturas que
    // a própria tela já reconhece e das quais já extrai o complemento.
    final detectedTopic =
        intent.topic?.trim() ??
        '';

    final topic = detectedTopic.isNotEmpty
        ? detectedTopic
        : inputState.effectiveQuery.trim();

    final suggestionHistoryKey = _brainAiSuggestionHistoryKey(
      query: requestQuery,
      topic: topic,
    );

    final avoidSuggestions = _brainAiRecentSuggestionsFor(
      suggestionHistoryKey,
    );

    final aiSearchResponse = _brainAiSearchResponseForTopic(
      topic,
    );

    _mutateState(
      () {
        _brainAiLoading = true;
        _brainAiResponse = null;
        _brainAiError = null;
      },
    );

    debugPrint(
      '[BRAIN AI] Consulta inteligente iniciada. '
      'intent=${intent.wireName} '
      'topic="$topic" '
      'resultados=${aiSearchResponse.allResults.length} '
      'evitarSugestoes=${avoidSuggestions.length}',
    );

    try {
      final response = await _brainAiOrchestrator.run(
        rawQuery: requestQuery,
        notes: _controller.notes,
        searchResponse: aiSearchResponse,
        avoidSuggestions: avoidSuggestions,
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // DESCARTAR RESPOSTA ANTIGA
      // ========================================================
      //
      // Se o usuário mudou o texto enquanto a Groq respondia,
      // a resposta anterior não deve aparecer para a nova consulta.
      //
      // ========================================================

      if (_searchQuery.trim() !=
              requestQuery ||
          _committedSearchQuery.trim() !=
              requestQuery) {
        debugPrint(
          '[BRAIN AI] Resposta descartada porque a consulta mudou.',
        );

        return;
      }

      _rememberBrainAiSuggestions(
        historyKey: suggestionHistoryKey,
        response: response,
      );

      _mutateState(
        () {
          _brainAiLoading = false;
          _brainAiResponse = response;
          _brainAiError = null;
        },
      );

      debugPrint(
        '[BRAIN AI] Consulta inteligente concluída. '
        'contexto=${aiSearchResponse.allResults.length} '
        'sugestoes=${response.suggestions.length}',
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[BRAIN AI] Falha na consulta: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      // Não mostrar erro de uma consulta que já deixou de ser atual.
      if (_searchQuery.trim() !=
          requestQuery) {
        return;
      }

      _mutateState(
        () {
          _brainAiLoading = false;
          _brainAiResponse = null;
          _brainAiError = 'Não foi possível analisar seu Cérebro agora. Tente novamente.';
        },
      );
    }
  }

  // ============================================================
  // BRAIN AI — LIMPAR ESTADO
  // ============================================================

  void _clearBrainAiState() {
    if (!_brainAiLoading &&
        _brainAiResponse ==
            null &&
        _brainAiError ==
            null) {
      return;
    }

    _mutateState(
      () {
        _brainAiLoading = false;
        _brainAiResponse = null;
        _brainAiError = null;
      },
    );
  }

  // ============================================================
  // BRAIN AI — ERRO
  // ============================================================

  Widget _buildBrainAiErrorCard(
    BuildContext context,
  ) {
    final message = _brainAiError;

    if (message ==
            null ||
        message.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(
          alpha: 0.32,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: colorScheme.error.withValues(
            alpha: 0.30,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: colorScheme.error,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
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
  // PREVIEW — NORMALIZAÇÃO
  // ============================================================

  String _normalizeSearchHighlightText(
    String value,
  ) {
    // IMPORTANTE:
    //
    // Esta normalização precisa preservar exatamente o mesmo número
    // de caracteres do texto original, porque os índices encontrados
    // aqui são reutilizados para recortar o texto original no destaque.
    //
    // Por isso NÃO usamos trim() e NÃO compactamos espaços com \s+.
    //
    // Exemplo:
    //
    // original   = "tensão"
    // normalizado = "tensao"
    //
    // Ambos continuam com o mesmo comprimento, então o intervalo
    // encontrado em "tensao" também aponta corretamente para "tensão".
    var normalized = value.toLowerCase();

    const replacements =
        <
          String,
          String
        >{
          'á': 'a',
          'à': 'a',
          'â': 'a',
          'ã': 'a',
          'ä': 'a',
          'é': 'e',
          'è': 'e',
          'ê': 'e',
          'ë': 'e',
          'í': 'i',
          'ì': 'i',
          'î': 'i',
          'ï': 'i',
          'ó': 'o',
          'ò': 'o',
          'ô': 'o',
          'õ': 'o',
          'ö': 'o',
          'ú': 'u',
          'ù': 'u',
          'û': 'u',
          'ü': 'u',
          'ç': 'c',
        };

    replacements.forEach(
      (
        source,
        target,
      ) {
        normalized = normalized.replaceAll(
          source,
          target,
        );
      },
    );

    return normalized;
  }

  String _cleanSearchPreviewText(
    String value,
  ) {
    return value
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        )
        .trim();
  }

  // ============================================================
  // TERMOS PARA DESTAQUE
  // ============================================================
  //
  // Assim como _searchResponse, o parser recebe a frase completa.
  //
  // O próprio BrainSearchParser remove:
  //
  // - "perguntas sobre";
  // - "me mostre 3";
  // - "recentemente";
  // - datas;
  // - demais estruturas.
  //
  // Portanto somente o assunto real será destacado.
  //
  // ============================================================

  List<
    String
  >
  _currentSearchHighlightTerms() {
    final committed = _committedSearchQuery.trim();

    if (committed.isEmpty) {
      return const <
        String
      >[];
    }

    final inputState = _brainSearchInputState(
      committed,
    );

    if (!inputState.canSearch) {
      return const <
        String
      >[];
    }

    final parsed = _BrainScreenState._searchParser.parse(
      inputState.originalQuery,
    );

    final uniqueTerms =
        <
          String
        >[];
    final normalizedTerms =
        <
          String
        >{};

    for (final term in parsed.terms) {
      final clean = term.trim();

      if (clean.isEmpty) {
        continue;
      }

      final normalized = _normalizeSearchHighlightText(
        clean,
      );

      if (normalized.isEmpty ||
          normalizedTerms.contains(
            normalized,
          )) {
        continue;
      }

      normalizedTerms.add(
        normalized,
      );

      uniqueTerms.add(
        clean,
      );
    }

    uniqueTerms.sort(
      (
        a,
        b,
      ) => b.length.compareTo(
        a.length,
      ),
    );

    return uniqueTerms;
  }

  // ============================================================
  // PREVIEW DO CONTEÚDO
  // ============================================================

  String _previewContentForSearch(
    String content, {
    int maxLength = 210,
  }) {
    final clean = _cleanSearchPreviewText(
      content,
    );

    if (clean.isEmpty) {
      return '';
    }

    final terms = _currentSearchHighlightTerms();

    if (terms.isEmpty) {
      return _truncateSearchPreview(
        clean,
        maxLength: maxLength,
      );
    }

    final normalizedContent = _normalizeSearchHighlightText(
      clean,
    );

    int? bestStart;
    int? bestEnd;

    for (final term in terms) {
      final normalizedTerm = _normalizeSearchHighlightText(
        term,
      );

      if (normalizedTerm.isEmpty) {
        continue;
      }

      final index = normalizedContent.indexOf(
        normalizedTerm,
      );

      if (index <
          0) {
        continue;
      }

      if (bestStart ==
              null ||
          index <
              bestStart) {
        bestStart = index;
        bestEnd =
            index +
            normalizedTerm.length;
      }
    }

    if (bestStart ==
        null) {
      return _truncateSearchPreview(
        clean,
        maxLength: maxLength,
      );
    }

    final safeMatchStart = bestStart.clamp(
      0,
      clean.length,
    );

    final safeMatchEnd =
        (bestEnd ??
                bestStart)
            .clamp(
              safeMatchStart,
              clean.length,
            );

    final beforeBudget =
        (maxLength *
                0.38)
            .round();

    var start =
        safeMatchStart -
        beforeBudget;

    if (start <
        0) {
      start = 0;
    }

    var end =
        start +
        maxLength;

    if (end <
        safeMatchEnd) {
      end = safeMatchEnd;
    }

    if (end >
        clean.length) {
      end = clean.length;

      start =
          end -
          maxLength;

      if (start <
          0) {
        start = 0;
      }
    }

    start = _moveSearchPreviewStartToWord(
      clean,
      start,
    );

    end = _moveSearchPreviewEndToWord(
      clean,
      end,
    );

    final snippet = clean
        .substring(
          start,
          end,
        )
        .trim();

    final prefix =
        start >
            0
        ? '...'
        : '';

    final suffix =
        end <
            clean.length
        ? '...'
        : '';

    return '$prefix$snippet$suffix';
  }

  String _truncateSearchPreview(
    String clean, {
    required int maxLength,
  }) {
    if (clean.length <=
        maxLength) {
      return clean;
    }

    var end = maxLength;

    end = _moveSearchPreviewEndToWord(
      clean,
      end,
    );

    return '${clean.substring(0, end).trim()}...';
  }

  int _moveSearchPreviewStartToWord(
    String text,
    int start,
  ) {
    if (start <=
            0 ||
        start >=
            text.length) {
      return start.clamp(
        0,
        text.length,
      );
    }

    var index = start;

    while (index <
            text.length &&
        !_isSearchPreviewBoundary(
          text[index],
        )) {
      index++;
    }

    while (index <
            text.length &&
        _isSearchPreviewBoundary(
          text[index],
        )) {
      index++;
    }

    return index.clamp(
      0,
      text.length,
    );
  }

  int _moveSearchPreviewEndToWord(
    String text,
    int end,
  ) {
    if (end <=
        0) {
      return 0;
    }

    if (end >=
        text.length) {
      return text.length;
    }

    var index = end;

    while (index >
            0 &&
        !_isSearchPreviewBoundary(
          text[index -
              1],
        )) {
      index--;
    }

    if (index <=
        0) {
      return end.clamp(
        0,
        text.length,
      );
    }

    return index.clamp(
      0,
      text.length,
    );
  }

  bool _isSearchPreviewBoundary(
    String character,
  ) {
    return RegExp(
      r'\s',
    ).hasMatch(
      character,
    );
  }

  // ============================================================
  // TEXTO DESTACADO
  // ============================================================

  Widget _buildHighlightedSearchText({
    required BuildContext context,
    required String text,
    TextStyle? style,
    int? maxLines,
    TextOverflow overflow = TextOverflow.clip,
  }) {
    final terms = _currentSearchHighlightTerms();

    if (text.isEmpty ||
        terms.isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: overflow,
        style: style,
      );
    }

    final spans = _buildSearchHighlightSpans(
      context: context,
      text: text,
      terms: terms,
      baseStyle: style,
    );

    return Text.rich(
      TextSpan(
        style: style,
        children: spans,
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  List<
    InlineSpan
  >
  _buildSearchHighlightSpans({
    required BuildContext context,
    required String text,
    required List<
      String
    >
    terms,
    TextStyle? baseStyle,
  }) {
    final matches =
        <
          _BrainSearchHighlightMatch
        >[];

    // Normalizamos o texto uma única vez.
    //
    // A busca visual passa a obedecer a mesma regra da pesquisa:
    //
    // - ignora maiúsculas/minúsculas;
    // - ignora acentos;
    // - preserva os índices do texto original.
    //
    // Assim:
    //
    // "tensao" encontra "tensão"
    // "tensão" encontra "tensao"
    // "eletronica" encontra "eletrônica"
    // "ESP32" encontra "esp32"
    final normalizedText = _normalizeSearchHighlightText(
      text,
    );

    for (final term in terms) {
      final normalizedTerm = _normalizeSearchHighlightText(
        term.trim(),
      );

      if (normalizedTerm.isEmpty) {
        continue;
      }

      var searchStart = 0;

      while (searchStart <=
          normalizedText.length -
              normalizedTerm.length) {
        final index = normalizedText.indexOf(
          normalizedTerm,
          searchStart,
        );

        if (index <
            0) {
          break;
        }

        final end =
            index +
            normalizedTerm.length;

        matches.add(
          _BrainSearchHighlightMatch(
            start: index,
            end: end,
          ),
        );

        // Avança até o final da ocorrência atual.
        //
        // Isso evita loop infinito e continua encontrando todas as
        // demais ocorrências da palavra no mesmo título/preview.
        searchStart = end;
      }
    }

    if (matches.isEmpty) {
      return <
        InlineSpan
      >[
        TextSpan(
          text: text,
          style: baseStyle,
        ),
      ];
    }

    matches.sort(
      (
        a,
        b,
      ) {
        final byStart = a.start.compareTo(
          b.start,
        );

        if (byStart !=
            0) {
          return byStart;
        }

        return b.end.compareTo(
          a.end,
        );
      },
    );

    final merged =
        <
          _BrainSearchHighlightMatch
        >[];

    for (final match in matches) {
      if (merged.isEmpty) {
        merged.add(
          match,
        );

        continue;
      }

      final previous = merged.last;

      if (match.start <
          previous.end) {
        if (match.end >
            previous.end) {
          merged[merged.length -
              1] = _BrainSearchHighlightMatch(
            start: previous.start,
            end: match.end,
          );
        }

        continue;
      }

      merged.add(
        match,
      );
    }

    final colorScheme = Theme.of(
      context,
    ).colorScheme;

    final highlightStyle =
        baseStyle?.copyWith(
          backgroundColor: colorScheme.primaryContainer,
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ) ??
        TextStyle(
          backgroundColor: colorScheme.primaryContainer,
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        );

    final spans =
        <
          InlineSpan
        >[];

    var cursor = 0;

    for (final match in merged) {
      if (match.start >
          cursor) {
        spans.add(
          TextSpan(
            text: text.substring(
              cursor,
              match.start,
            ),
            style: baseStyle,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(
            match.start,
            match.end,
          ),
          style: highlightStyle,
        ),
      );

      cursor = match.end;
    }

    if (cursor <
        text.length) {
      spans.add(
        TextSpan(
          text: text.substring(
            cursor,
          ),
          style: baseStyle,
        ),
      );
    }

    return spans;
  }

  // ============================================================
  // ABRIR RESULTADO EM PÁGINA
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
                    initialSearchTerms: _currentSearchHighlightTerms(),
                  );
                },
          ),
        );

    if (!mounted) {
      return;
    }

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

    _mutateState(
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

            // ======================================================
            // MODELO ESCOLHIDO
            // ======================================================
            //
            // Se o modelo estiver incompleto:
            //
            // perguntas sobre
            //
            // ele será colocado no campo, mas NÃO pesquisará.
            //
            // O usuário deverá escrever:
            //
            // perguntas sobre eletrônica
            //
            // Se o modelo já for uma consulta completa:
            //
            // o que estudei ontem
            //
            // ele pode pesquisar imediatamente.
            //
            // ======================================================

            _commitSearchImmediately(
              example,
              activityHold: const Duration(
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

            // ==================================================
            // DIGITAÇÃO
            // ==================================================
            onChanged:
                (
                  value,
                ) {
                  _searchDebounceTimer?.cancel();

                  _brainSearchPulseStopTimer?.cancel();

                  _mutateState(
                    () {
                      _searchQuery = value;

                      // Enquanto existe uma nova digitação,
                      // resultados anteriores deixam de representar
                      // o conteúdo atual do campo.

                      _committedSearchQuery = '';

                      _showAllSearchResults = false;

                      // Uma nova digitação invalida qualquer resposta
                      // inteligente pertencente à consulta anterior.
                      _brainAiLoading = false;
                      _brainAiResponse = null;
                      _brainAiError = null;
                    },
                  );

                  final visualController = _brainVisualController;

                  visualController?.setSearching(
                    false,
                  );

                  visualController?.clearSearchMatch();

                  _scheduleSearchCommit(
                    value,
                  );
                },

            // ==================================================
            // ENTER / SEARCH DO TECLADO
            // ==================================================
            onSubmitted:
                (
                  value,
                ) async {
                  // Primeiro confirma a pesquisa local.
                  //
                  // Isso garante que _searchResponse já represente
                  // exatamente a consulta que será usada para montar
                  // o contexto compacto enviado à IA.
                  _commitSearchImmediately(
                    value,
                    activityHold: const Duration(
                      milliseconds: 1600,
                    ),
                  );

                  await _runBrainSmartQuery(
                    value,
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
                        _searchDebounceTimer?.cancel();

                        _brainSearchPulseStopTimer?.cancel();

                        _searchController.clear();

                        _mutateState(
                          () {
                            _searchQuery = '';

                            _committedSearchQuery = '';

                            _showAllSearchResults = false;

                            _brainAiLoading = false;
                            _brainAiResponse = null;
                            _brainAiError = null;
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

  Widget _buildSearchResults(
    BuildContext context,
  ) {
    final inputState = _brainSearchInputState(
      _searchQuery,
    );

    // ==========================================================
    // CAMPO VAZIO
    // ==========================================================

    if (_searchQuery.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // MODELO AINDA SENDO DIGITADO
    // ==========================================================

    if (inputState.isIncomplete) {
      return _buildSearchWaitingCard(
        context: context,
        icon: Icons.edit_rounded,
        title: 'Continue digitando',
        message: 'Complete a estrutura para iniciar a pesquisa.',
      );
    }

    // ==========================================================
    // MODELO COMPLETO, MAS FALTA COMPLEMENTO
    // ==========================================================
    //
    // Usamos uma mensagem genérica para não precisar repetir:
    //
    // "digite um assunto"
    //
    // ou:
    //
    // "digite uma data"
    //
    // em cada tipo de estrutura.
    //
    // ==========================================================

    if (inputState.isWaitingSubject) {
      return _buildSearchWaitingCard(
        context: context,
        icon: Icons.search_rounded,
        title: 'Complete a pesquisa',
        message: 'Adicione o que falta depois da estrutura para pesquisar.',
      );
    }

    // ==========================================================
    // USUÁRIO AINDA ESTÁ DIGITANDO
    // ==========================================================

    if (_isSearchWaitingForDebounce) {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // AINDA NÃO EXISTE CONSULTA CONFIRMADA
    // ==========================================================

    if (_committedSearchQuery.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // ==========================================================
    // BRAIN AI — ESTADO DA CONSULTA INTELIGENTE
    // ==========================================================
    //
    // Quando uma intenção inteligente foi confirmada, a mesma área
    // que normalmente mostra resultados locais passa a mostrar:
    //
    // loading
    //    ↓
    // resposta da IA
    //    ↓
    // ou erro recuperável
    //
    // Uma busca normal ignora este bloco e continua abaixo.
    //
    // ==========================================================

    if (_brainAiLoading) {
      return const BrainAiLoadingCard();
    }

    final aiResponse = _brainAiResponse;

    if (aiResponse !=
        null) {
      return BrainAiResultCard(
        response: aiResponse,
      );
    }

    if (_brainAiError !=
        null) {
      return _buildBrainAiErrorCard(
        context,
      );
    }

    // ==========================================================
    // RESULTADO LOCAL CONFIRMADO
    // ==========================================================

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
          // ====================================================
          // HEADER
          // ====================================================
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

          // ====================================================
          // RESUMO POR TIPO
          // ====================================================
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

          // ====================================================
          // EMPTY
          // ====================================================
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
            // ==================================================
            // TOP RESULTS / ALL RESULTS
            // ==================================================
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

            // ==================================================
            // EXPAND / COLLAPSE
            // ==================================================
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
                      _mutateState(
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
  // AGUARDANDO CONSULTA
  // ============================================================

  Widget _buildSearchWaitingCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Theme.of(
      context,
    );

    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(
          alpha: 0.30,
        ),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: theme.dividerColor.withValues(
            alpha: 0.45,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: colorScheme.onSurfaceVariant,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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
                    _buildHighlightedSearchText(
                      context: context,
                      text: note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

                      _buildHighlightedSearchText(
                        context: context,
                        text: _previewContentForSearch(
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
}

// ============================================================
// MATCH DE DESTAQUE DA PESQUISA
// ============================================================

class _BrainSearchHighlightMatch {
  const _BrainSearchHighlightMatch({
    required this.start,
    required this.end,
  });

  final int start;
  final int end;
}

// ============================================================
// SEARCH INPUT STATE
// ============================================================
//
// Representa o estado da frase antes de enviá-la ao parser.
//
// effectiveQuery:
//
//   conteúdo que veio depois de uma estrutura obrigatória.
//
// originalQuery:
//
//   frase completa.
//
// IMPORTANTE:
//
// O effectiveQuery serve para saber se a estrutura foi completada.
//
// O parser recebe originalQuery para não perder:
//
// - tipo;
// - data;
// - quantidade;
// - recência;
// - intenção.
//
// ============================================================

class _BrainSearchInputState {
  const _BrainSearchInputState._({
    required this.originalQuery,
    required this.effectiveQuery,
    required this.canSearch,
    required this.isIncomplete,
    required this.isWaitingSubject,
    this.recognizedPrefix,
    this.expectedPrefix,
  });

  const _BrainSearchInputState.empty()
    : this._(
        originalQuery: '',
        effectiveQuery: '',
        canSearch: false,
        isIncomplete: false,
        isWaitingSubject: false,
      );

  factory _BrainSearchInputState.incomplete({
    required String expectedPrefix,
  }) {
    return _BrainSearchInputState._(
      originalQuery: '',
      effectiveQuery: '',
      canSearch: false,
      isIncomplete: true,
      isWaitingSubject: false,
      expectedPrefix: expectedPrefix,
    );
  }

  factory _BrainSearchInputState.waitingSubject({
    required String prefix,
  }) {
    return _BrainSearchInputState._(
      originalQuery: prefix,
      effectiveQuery: '',
      canSearch: false,
      isIncomplete: false,
      isWaitingSubject: true,
      recognizedPrefix: prefix,
    );
  }

  factory _BrainSearchInputState.ready({
    required String originalQuery,
    required String effectiveQuery,
    String? recognizedPrefix,
  }) {
    return _BrainSearchInputState._(
      originalQuery: originalQuery,
      effectiveQuery: effectiveQuery,
      canSearch: effectiveQuery.trim().isNotEmpty,
      isIncomplete: false,
      isWaitingSubject: false,
      recognizedPrefix: recognizedPrefix,
    );
  }

  final String originalQuery;

  final String effectiveQuery;

  final bool canSearch;

  final bool isIncomplete;

  final bool isWaitingSubject;

  final String? recognizedPrefix;

  final String? expectedPrefix;
}
