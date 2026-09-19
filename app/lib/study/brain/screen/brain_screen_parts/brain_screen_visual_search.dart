part of '../brain_screen.dart';

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

    _brainVisualKnowledgeCount = currentCount;

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
  // BUSCA NATURAL — PREFIXOS
  // ============================================================
  //
  // Estes prefixos fazem parte da linguagem da interface.
  //
  // Eles NÃO representam o assunto que deve ser procurado.
  //
  // Exemplo:
  //
  // "onde eu falei de FL Studio"
  //
  // prefixo:
  // "onde eu falei de"
  //
  // assunto:
  // "FL Studio"
  //
  // ============================================================

  static const List<
    String
  >
  _brainSearchSubjectPrefixes = [
    // ============================================================
    // BUSCA SIMPLES
    // ============================================================
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

    // ============================================================
    // TIPOS
    // ============================================================
    'conceitos sobre',
    'perguntas sobre',
    'exemplos sobre',
    'atenções sobre',

    // ============================================================
    // RECÊNCIA
    // ============================================================
    'o que estudei recentemente sobre',
    'minhas últimas anotações sobre',
    'o que eu vi por último sobre',

    // ============================================================
    // CONHECIMENTO ACUMULADO
    // ============================================================
    'o que eu já sei sobre',
    'o que eu já aprendi sobre',
    'o que eu já anotei sobre',
  ];

  // ============================================================
  // NORMALIZAÇÃO LEVE
  // ============================================================

  String _normalizeBrainSearchStructure(
    String value,
  ) {
    return value.trim().toLowerCase().replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
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
    // 1. PREFIXO COMPLETO
    // ==========================================================

    for (final prefix in _brainSearchSubjectPrefixes) {
      final normalizedPrefix = _normalizeBrainSearchStructure(
        prefix,
      );

      if (normalized ==
          normalizedPrefix) {
        return _BrainSearchInputState.waitingSubject(
          prefix: prefix,
        );
      }

      // ========================================================
      // PREFIXO + ASSUNTO
      // ========================================================

      final prefixWithSpace = '$normalizedPrefix ';

      if (normalized.startsWith(
        prefixWithSpace,
      )) {
        final prefixWordCount = normalizedPrefix
            .split(
              ' ',
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
    // 2. PREFIXO AINDA SENDO DIGITADO
    // ==========================================================

    for (final prefix in _brainSearchSubjectPrefixes) {
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
    // 3. BUSCA LIVRE — VALIDAR CRITÉRIO PESQUISÁVEL
    // ==========================================================
    //
    // REGRA DE NEGÓCIO:
    //
    // Uma consulta livre só pode ser executada quando, depois
    // de interpretada pelo BrainSearchParser, existir pelo menos:
    //
    // - um termo pesquisável;
    // - um filtro de tipo;
    // - um filtro de data/período.
    //
    // Isso impede frases estruturalmente incompletas de mostrar
    // todos os conhecimentos.
    //
    // Exemplos:
    //
    // "o que eu fiz"
    // -> nenhum termo/tipo/data
    // -> aguarda assunto
    //
    // "o que eu fiz ontem"
    // -> possui filtro de data
    // -> pode pesquisar
    //
    // "perguntas"
    // -> possui filtro de tipo
    // -> pode pesquisar
    //
    // "ESP32"
    // -> possui termo
    // -> pode pesquisar
    //
    // ==========================================================

    final parsedFreeQuery = _BrainScreenState._searchParser.parse(
      original,
    );

    final hasSearchCriteria =
        parsedFreeQuery.hasTerms ||
        parsedFreeQuery.hasTypeFilter ||
        parsedFreeQuery.hasDateFilter;

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
  //
  // Temos agora dois estados diferentes:
  //
  // _searchQuery
  //     texto que o usuário está digitando.
  //
  // _committedSearchQuery
  //     texto que realmente pode ser pesquisado.
  //
  // Toda nova tecla cancela o timer anterior.
  //
  // Somente depois de 500 ms sem digitação a consulta é
  // confirmada.
  //
  // ============================================================

  void _scheduleSearchCommit(
    String rawQuery,
  ) {
    _searchDebounceTimer?.cancel();

    final query = rawQuery.trim();

    // ==========================================================
    // CAMPO VAZIO
    // ==========================================================

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
    // VERIFICAR ESTRUTURA DA FRASE
    // ==========================================================
    //
    // Frases incompletas não precisam esperar o debounce para
    // sabermos que ainda não podem ser pesquisadas.
    //
    // Exemplo:
    //
    // onde eu falei d
    //
    // ou:
    //
    // onde eu falei de
    //
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

        // ======================================================
        // GARANTIR QUE A CONSULTA NÃO MUDOU
        // ======================================================

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

        // ======================================================
        // CONFIRMAR A CONSULTA
        // ======================================================

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
  //
  // Usado quando:
  //
  // - usuário pressiona Enter;
  // - usuário escolhe uma sugestão do modal de ajuda.
  //
  // Nesses casos não precisamos esperar os 500 ms.
  //
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

    _mutateState(
      () {
        _searchQuery = rawQuery;
        _committedSearchQuery = rawQuery;
        _showAllSearchResults = false;
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

        // ======================================================
        // IMPORTANTE
        // ======================================================
        //
        // Agora comparamos com a consulta CONFIRMADA.
        //
        // Não usamos mais somente _searchQuery, porque o usuário
        // pode estar digitando uma nova consulta enquanto uma
        // pesquisa anterior ainda estava animando.
        //
        // ======================================================

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
            'Nenhum resultado para "${currentState.effectiveQuery}".',
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
  // IMPORTANTE:
  //
  // Este getter NÃO usa mais _searchQuery.
  //
  // _searchQuery é apenas a digitação atual.
  //
  // O mecanismo de pesquisa recebe exclusivamente:
  //
  // _committedSearchQuery
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

    // ==========================================================
    // NÃO PESQUISAR FRASES INCOMPLETAS
    // ==========================================================

    if (!inputState.canSearch) {
      return BrainSearchResponse.fromResults(
        const <
          BrainFile
        >[],
      );
    }

    // ==========================================================
    // PARSER RECEBE SOMENTE A CONSULTA EFETIVA
    // ==========================================================
    //
    // onde eu falei de FL Studio
    //
    // vira:
    //
    // FL Studio
    //
    // ==========================================================

    final parsedQuery = _BrainScreenState._searchParser.parse(
      inputState.effectiveQuery,
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

  String _normalizeSearchHighlightText(
    String value,
  ) {
    var normalized = value.toLowerCase().trim();

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

    return normalized.replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
    );
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
      inputState.effectiveQuery,
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

    for (final term in terms) {
      final normalizedTerm = _normalizeSearchHighlightText(
        term,
      );

      if (normalizedTerm.isEmpty) {
        continue;
      }

      final expression = RegExp(
        RegExp.escape(
          term,
        ),
        caseSensitive: false,
      );

      for (final match in expression.allMatches(
        text,
      )) {
        matches.add(
          _BrainSearchHighlightMatch(
            start: match.start,
            end: match.end,
          ),
        );
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
            // SUGESTÃO ESCOLHIDA PELO USUÁRIO
            // ======================================================
            //
            // Como houve uma ação explícita no botão "Usar", podemos
            // confirmar imediatamente a consulta.
            //
            // Não precisamos esperar 500 ms.
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
            //
            // Aqui NÃO pesquisamos mais imediatamente.
            //
            // 1. atualizamos o texto visual;
            // 2. apagamos a consulta confirmada;
            // 3. escondemos resultados anteriores;
            // 4. iniciamos/reiniciamos o debounce.
            //
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

                      // =================================================
                      // MUITO IMPORTANTE
                      // =================================================
                      //
                      // Enquanto existe uma nova digitação, a pesquisa
                      // anterior deixa de representar o que está no campo.
                      //
                      // Por isso limpamos a consulta confirmada.
                      //
                      // Isso impede resultados antigos de permanecerem
                      // visíveis enquanto o usuário formula outra busca.
                      //
                      // =================================================

                      _committedSearchQuery = '';

                      _showAllSearchResults = false;
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
            //
            // Aqui a intenção do usuário é explícita.
            //
            // Portanto confirmamos imediatamente.
            //
            // ==================================================
            onSubmitted:
                (
                  value,
                ) {
                  _commitSearchImmediately(
                    value,
                    activityHold: const Duration(
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
                        // ===========================================
                        // CANCELAR QUALQUER PESQUISA PENDENTE
                        // ===========================================

                        _searchDebounceTimer?.cancel();

                        _brainSearchPulseStopTimer?.cancel();

                        _searchController.clear();

                        _mutateState(
                          () {
                            _searchQuery = '';
                            _committedSearchQuery = '';
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

  Widget _buildSearchResults(
    BuildContext context,
  ) {
    // ==========================================================
    // PRIMEIRO ANALISAMOS O TEXTO QUE ESTÁ NO CAMPO
    // ==========================================================
    //
    // Isso é diferente da consulta confirmada.
    //
    // Precisamos do texto atual para saber se:
    //
    // - a frase está incompleta;
    // - falta o assunto;
    // - o usuário ainda está digitando.
    //
    // ==========================================================

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
    // FRASE AINDA SENDO FORMULADA
    // ==========================================================
    //
    // Exemplo:
    //
    // onde eu falei d
    //
    // ==========================================================

    if (inputState.isIncomplete) {
      return _buildSearchWaitingCard(
        context: context,
        icon: Icons.edit_rounded,
        title: 'Continue digitando',
        message: 'Complete a frase para iniciar a pesquisa.',
      );
    }

    // ==========================================================
    // MODELO COMPLETO, MAS SEM ASSUNTO
    // ==========================================================
    //
    // Exemplo:
    //
    // onde eu falei de
    //
    // ==========================================================

    if (inputState.isWaitingSubject) {
      return _buildSearchWaitingCard(
        context: context,
        icon: Icons.search_rounded,
        title: 'Qual assunto você procura?',
        message: 'Complete com o assunto que deseja pesquisar.',
      );
    }

    // ==========================================================
    // USUÁRIO AINDA ESTÁ DIGITANDO
    // ==========================================================
    //
    // Este é o comportamento principal da correção.
    //
    // Exemplo:
    //
    // m
    // me
    // mem
    // memó
    // memória
    //
    // Enquanto o debounce ainda não terminou:
    //
    // NÃO mostramos:
    //
    // - resultados antigos;
    // - "Nenhum resultado";
    // - resultados parciais.
    //
    // A interface fica limpa.
    //
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
    // EXECUTAR / MOSTRAR RESULTADO CONFIRMADO
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
