import '../../models/brain_concept.dart';
import '../models/brain_search_query.dart';
import '../utils/brain_search_normalizer.dart';

// ============================================================
// BRAIN SEARCH PARSER
// ============================================================
//
// FASE 11/13 — BUSCA NATURAL + FONTES DO CONHECIMENTO
//
// Interpreta frases naturais sem IA.
//
// Responsabilidades:
//
// - interpretar linguagem natural;
// - identificar tipo de conhecimento;
// - identificar datas e períodos;
// - identificar recência;
// - identificar quantidade;
// - identificar intenção;
// - remover linguagem estrutural;
// - preservar somente os termos realmente pesquisáveis;
// - entender frases relacionadas à origem do conhecimento;
// - manter busca determinística;
// - funcionar offline;
// - não depender de IA.
//
// Exemplos:
//
// "onde eu aprendi sobre ponteiros?"
// -> terms = ["ponteiros"]
//
// "qual fonte eu usei para estudar filas?"
// -> terms = ["filas"]
//
// "anotações que vieram do cppreference"
// -> terms = ["cppreference"]
//
// "o que eu aprendi no livro Clean Code?"
// -> terms = ["clean", "code"]
//
// "me mostra perguntas de ontem sobre ponteiros"
// -> type = question
// -> data = ontem
// -> terms = ["ponteiros"]
//
// "exemplos da semana passada sobre fila"
// -> type = example
// -> período = semana passada
// -> terms = ["fila"]
//
// "o que eu fiz no dia 01/09/2026"
// -> período = 01/09/2026
// -> terms = []
//
// "o que estudei recentemente sobre C++"
// -> sort = newest
// -> limit = 5
// -> terms = ["c++"]
//
// "me mostre 5 perguntas sobre C++"
// -> type = question
// -> limit = 5
// -> sort = relevance
// -> terms = ["c++"]
//
// "quais foram os 3 últimos exemplos sobre Flutter?"
// -> type = example
// -> limit = 3
// -> sort = newest
// -> terms = ["flutter"]
//
// "aquele conteúdo sobre stack"
// -> terms = ["stack"]
//
// "onde eu falei de redis?"
// -> terms = ["redis"]
//
// "quando eu falei de esp?"
// -> terms = ["esp"]
//
// "quando eu falei sobre esp32?"
// -> terms = ["esp32"]
//
// "o que eu estudei de manhã?"
// -> hoje, 06:00–12:00
//
// "o que anotei ontem à noite?"
// -> ontem, 18:00–24:00
//
// "o que eu já sei sobre filas?"
// -> intent = knowledgeOverview
// -> terms = ["filas"]
//
// O parser não pesquisa nada.
// Ele apenas transforma texto livre em BrainSearchQuery.
//
// ============================================================

class BrainSearchParser {
  const BrainSearchParser();

  // ============================================================
  // CONFIG
  // ============================================================

  static const int _defaultRecentLimit = 5;

  static const int _maximumRequestedLimit = 100;

  // ============================================================
  // STOP WORDS
  // ============================================================
  //
  // Palavras estruturais da frase.
  //
  // Elas ajudam o usuário a escrever naturalmente, mas não
  // representam necessariamente o assunto procurado.
  //
  // Exemplo:
  //
  // "quando eu falei de esp"
  //
  // quando -> estrutura
  // eu      -> estrutura
  // falei   -> intenção
  // de      -> estrutura
  // esp     -> termo pesquisável
  //
  // ============================================================

  static const Set<
    String
  >
  _stopWords = {
    'a',
    'ao',
    'aos',
    'aquela',
    'aquele',
    'aquilo',
    'as',
    'ate',
    'com',
    'como',
    'conteudo',
    'coisa',
    'coisas',
    'da',
    'das',
    'data',
    'de',
    'definicao',
    'dia',
    'do',
    'dos',
    'e',
    'em',
    'essa',
    'esse',
    'esta',
    'este',
    'eu',
    'foi',
    'isso',
    'me',
    'meu',
    'meus',
    'minha',
    'minhas',
    'na',
    'nas',
    'no',
    'nos',
    'o',
    'onde',
    'os',
    'para',
    'por',
    'qual',
    'quais',

    // ==========================================================
    // CORREÇÃO — QUANDO
    // ==========================================================
    //
    // "quando" descreve a intenção/estrutura da consulta.
    //
    // Não deve virar termo pesquisável.
    //
    // "quando eu falei de esp"
    //
    // deve produzir:
    //
    // ["esp"]
    //
    // e nunca:
    //
    // ["quando", "esp"]
    //
    // ==========================================================
    'quando',

    'que',
    'se',
    'sobre',
    'um',
    'uma',
    'umas',
    'uns',

    // ==========================================================
    // VERBOS / EXPRESSÕES DE INTENÇÃO
    // ==========================================================
    'anotei',
    'anotacao',
    'anotacoes',
    'aprendi',
    'estudei',
    'falei',
    'falava',
    'fiz',
    'guardei',
    'lembro',
    'lembrava',
    'mostra',
    'mostrar',
    'mostre',
    'pesquisa',
    'pesquisar',
    'procura',
    'procurar',
    'quero',
    'sei',
    'tinha',
    'vi',
    'ja',

    // ==========================================================
    // FONTES DO CONHECIMENTO
    // ==========================================================
    //
    // Estas palavras representam a intenção de procurar a origem
    // do conhecimento, não o conteúdo principal procurado.
    //
    // ==========================================================
    'fonte',
    'fontes',
    'origem',
    'origens',
    'referencia',
    'referencias',
    'autor',
    'autores',
    'livro',
    'livros',
    'usei',
    'usar',
    'usado',
    'usada',
    'vieram',
    'veio',
    'vindo',
    'vinda',

    // ==========================================================
    // ORDENAÇÃO / QUANTIDADE
    // ==========================================================
    'recente',
    'recentes',
    'recentemente',
    'ultima',
    'ultimas',
    'ultimo',
    'ultimos',
    'mais',
    'so',
    'somente',

    // ==========================================================
    // PERÍODO DO DIA
    // ==========================================================
    'manha',
    'tarde',
    'noite',
  };

  // ============================================================
  // TYPE TOKENS
  // ============================================================

  static const Map<
    String,
    BrainConceptType
  >
  _typeTokens = {
    'conceito': BrainConceptType.concept,
    'conceitos': BrainConceptType.concept,
    'definicao': BrainConceptType.concept,
    'definicoes': BrainConceptType.concept,

    'pergunta': BrainConceptType.question,
    'perguntas': BrainConceptType.question,
    'questao': BrainConceptType.question,
    'questoes': BrainConceptType.question,
    'revisao': BrainConceptType.question,
    'revisoes': BrainConceptType.question,

    // Mantidos por compatibilidade com dados antigos.
    'exemplo': BrainConceptType.example,
    'exemplos': BrainConceptType.example,
    'pratica': BrainConceptType.example,
    'praticas': BrainConceptType.example,

    'atencao': BrainConceptType.warning,
    'atencoes': BrainConceptType.warning,
    'aviso': BrainConceptType.warning,
    'avisos': BrainConceptType.warning,
    'alerta': BrainConceptType.warning,
    'alertas': BrainConceptType.warning,
    'cuidado': BrainConceptType.warning,
    'cuidados': BrainConceptType.warning,
    'erro': BrainConceptType.warning,
    'erros': BrainConceptType.warning,
  };

  // ============================================================
  // DATE VOCABULARY
  // ============================================================

  static const Set<
    String
  >
  _dateVocabulary = {
    'hoje',
    'ontem',
    'anteontem',
    'semana',
    'passada',
    'passado',
    'mes',
    'ano',
    'ultimos',
    'ultimas',
    'dias',
    'dia',
    'data',
    'manha',
    'tarde',
    'noite',
  };

  // ============================================================
  // NATURAL SEARCH PHRASES
  // ============================================================
  //
  // Frases que descrevem COMO o usuário está procurando.
  //
  // Elas não fazem parte do assunto.
  //
  // Isso complementa as stop words e torna o parser mais
  // previsível para os modelos ensinados no modal de ajuda.
  //
  // Exemplo:
  //
  // "quando eu falei de esp"
  //
  // remove:
  //
  // "quando eu falei de"
  //
  // preserva:
  //
  // "esp"
  //
  // ============================================================

  static const Set<
    String
  >
  _naturalSearchPhrases = {
    // ----------------------------------------------------------
    // FALAR
    // ----------------------------------------------------------
    'onde eu falei de',
    'onde falei de',
    'quando eu falei de',
    'quando falei de',

    'onde eu falei sobre',
    'onde falei sobre',
    'quando eu falei sobre',
    'quando falei sobre',

    // ----------------------------------------------------------
    // ANOTAR
    // ----------------------------------------------------------
    'onde eu anotei sobre',
    'onde anotei sobre',
    'quando eu anotei sobre',
    'quando anotei sobre',

    'onde eu anotei',
    'onde anotei',
    'quando eu anotei',
    'quando anotei',

    // ----------------------------------------------------------
    // ESCREVER / GUARDAR
    // ----------------------------------------------------------
    'onde eu escrevi sobre',
    'onde escrevi sobre',
    'quando eu escrevi sobre',
    'quando escrevi sobre',

    'onde eu guardei',
    'onde guardei',
    'quando eu guardei',
    'quando guardei',

    // ----------------------------------------------------------
    // AÇÕES / HISTÓRICO
    // ----------------------------------------------------------
    'o que eu fiz sobre',
    'o que fiz sobre',
    'o que eu fiz',
    'o que fiz',

    // ----------------------------------------------------------
    // CONTEÚDO
    // ----------------------------------------------------------
    'algo sobre',
    'aquele conteudo sobre',
    'aquela anotacao sobre',
    'a anotacao que falava de',
    'a anotacao que falava sobre',

    // ----------------------------------------------------------
    // BUSCA DIRETA
    // ----------------------------------------------------------
    'procure por',
    'procurar por',
    'pesquise por',
    'pesquisar por',
    'buscar por',
    'busque por',
  };

  // ============================================================
  // SOURCE INTENT PHRASES
  // ============================================================
  //
  // FASE 13 — FONTES DO CONHECIMENTO
  //
  // Não criamos um novo BrainSearchIntent ainda.
  //
  // O objetivo desta etapa é transformar frases de origem em
  // termos limpos que o BrainSearchEngine já consegue procurar em:
  //
  // - source.title;
  // - source.author;
  // - source.reference.
  //
  // ============================================================

  static const Set<
    String
  >
  _sourceIntentPhrases = {
    'onde eu aprendi sobre',
    'onde aprendi sobre',
    'de onde eu aprendi sobre',
    'de onde aprendi sobre',

    'qual fonte eu usei para estudar',
    'qual fonte usei para estudar',
    'quais fontes eu usei para estudar',
    'quais fontes usei para estudar',

    'qual fonte eu usei para aprender',
    'qual fonte usei para aprender',
    'quais fontes eu usei para aprender',
    'quais fontes usei para aprender',

    'qual foi a fonte de',
    'quais foram as fontes de',

    'anotacoes que vieram do',
    'anotacoes que vieram da',
    'anotacao que veio do',
    'anotacao que veio da',

    'conteudos que vieram do',
    'conteudos que vieram da',
    'conteudo que veio do',
    'conteudo que veio da',

    'o que eu aprendi no livro',
    'o que aprendi no livro',

    'o que eu aprendi na aula',
    'o que aprendi na aula',

    'o que eu aprendi pelo',
    'o que aprendi pelo',

    'o que eu aprendi pela',
    'o que aprendi pela',

    'onde vi',
    'onde eu vi',
  };

  // ============================================================
  // PARSE
  // ============================================================

  BrainSearchQuery parse(
    String rawQuery, {
    DateTime? now,
  }) {
    final normalized = BrainSearchNormalizer.normalize(
      rawQuery,
    );

    if (normalized.isEmpty) {
      return BrainSearchQuery(
        originalQuery: rawQuery,
        normalizedQuery: '',
        terms:
            const <
              String
            >[],
      );
    }

    final reference =
        (now ??
                DateTime.now())
            .toLocal();

    // ==========================================================
    // INTENT
    // ==========================================================

    final intent = _parseIntent(
      normalized,
    );

    // ==========================================================
    // RECENCY
    // ==========================================================

    final recency = _parseRecency(
      normalized,
    );

    // ==========================================================
    // LIMIT
    // ==========================================================

    final limitResult = _parseLimit(
      normalized,
    );

    // ==========================================================
    // DATE
    // ==========================================================

    final dateFilter = _parseDateFilter(
      rawQuery: rawQuery,
      normalized: normalized,
      now: reference,
    );

    // ==========================================================
    // TYPE
    // ==========================================================

    final type = _parseType(
      normalized,
    );

    // ==========================================================
    // FRASES A REMOVER
    // ==========================================================
    //
    // Agora também removemos explicitamente as frases naturais
    // de busca.
    //
    // Isso torna:
    //
    // quando eu falei de esp
    //
    // em:
    //
    // esp
    //
    // antes da tokenização.
    //
    // ==========================================================

    final phrasesToRemove =
        <
          String
        >{
          ...dateFilter.consumedPhrases,
          ...recency.consumedPhrases,
          ...limitResult.consumedPhrases,
          ..._intentPhrases(
            intent,
          ),
          ..._matchedSourceIntentPhrases(
            normalized,
          ),
          ..._matchedNaturalSearchPhrases(
            normalized,
          ),
        };

    final cleaned = _removeKnownPhrases(
      normalized,
      phrasesToRemove,
    );

    // ==========================================================
    // TOKENIZAÇÃO
    // ==========================================================

    final tokens = BrainSearchNormalizer.tokenize(
      cleaned,
    );

    final terms =
        <
          String
        >[];

    for (final token in tokens) {
      // ========================================================
      // STOP WORD
      // ========================================================

      if (_stopWords.contains(
        token,
      )) {
        continue;
      }

      // ========================================================
      // TYPE
      // ========================================================

      if (_typeTokens.containsKey(
        token,
      )) {
        continue;
      }

      // ========================================================
      // DATE
      // ========================================================

      if (_dateVocabulary.contains(
        token,
      )) {
        continue;
      }

      // ========================================================
      // LIMIT
      // ========================================================

      if (_looksLikeStandaloneLimitNumber(
        token: token,
        normalized: normalized,
        limit: limitResult.limit,
      )) {
        continue;
      }

      // ========================================================
      // TERM
      // ========================================================

      if (!terms.contains(
        token,
      )) {
        terms.add(
          token,
        );
      }
    }

    final resolvedSort = recency.sort;

    final resolvedLimit =
        limitResult.limit ??
        recency.limit;

    return BrainSearchQuery(
      originalQuery: rawQuery,
      normalizedQuery: normalized,
      terms:
          List<
            String
          >.unmodifiable(
            terms,
          ),
      type: type,
      startDate: dateFilter.startDate,
      endDate: dateFilter.endDate,
      sort: resolvedSort,
      limit: resolvedLimit,
      intent: intent,
    );
  }

  // ============================================================
  // INTENT
  // ============================================================

  BrainSearchIntent _parseIntent(
    String normalized,
  ) {
    const knowledgePatterns =
        <
          String
        >[
          'o que eu ja sei sobre',
          'o que ja sei sobre',
          'o que eu sei sobre',
          'o que sei sobre',
          'o que eu ja aprendi sobre',
          'o que ja aprendi sobre',
          'meu conhecimento sobre',
          'meus conhecimentos sobre',
        ];

    for (final pattern in knowledgePatterns) {
      if (_containsPhrase(
        normalized,
        pattern,
      )) {
        return BrainSearchIntent.knowledgeOverview;
      }
    }

    return BrainSearchIntent.search;
  }

  Set<
    String
  >
  _intentPhrases(
    BrainSearchIntent intent,
  ) {
    switch (intent) {
      case BrainSearchIntent.search:
        return const <
          String
        >{};

      case BrainSearchIntent.knowledgeOverview:
        return const <
          String
        >{
          'o que eu ja sei sobre',
          'o que ja sei sobre',
          'o que eu sei sobre',
          'o que sei sobre',
          'o que eu ja aprendi sobre',
          'o que ja aprendi sobre',
          'meu conhecimento sobre',
          'meus conhecimentos sobre',
        };
    }
  }

  // ============================================================
  // TYPE
  // ============================================================

  BrainConceptType? _parseType(
    String normalized,
  ) {
    final tokens = normalized.split(
      RegExp(
        r'\s+',
      ),
    );

    for (final token in tokens) {
      final type = _typeTokens[token];

      if (type !=
          null) {
        return type;
      }
    }

    return null;
  }

  // ============================================================
  // RECENCY / SORT
  // ============================================================

  _BrainSearchRecencyResult _parseRecency(
    String normalized,
  ) {
    // ==========================================================
    // "ÚLTIMOS N DIAS" É PERÍODO, NÃO LIMIT
    // ==========================================================

    final lastDaysPattern = RegExp(
      r'\bultim(?:os|as)\s+\d{1,3}\s+dias\b',
    );

    if (lastDaysPattern.hasMatch(
      normalized,
    )) {
      return const _BrainSearchRecencyResult(
        sort: BrainSearchSort.relevance,
      );
    }

    const explicitRecentPhrases =
        <
          String
        >{
          'recentemente',
          'mais recente',
          'mais recentes',
          'por ultimo',
          'por ultima',
          'ultimas anotacoes',
          'ultimos conteudos',
          'ultimos conhecimentos',
        };

    for (final phrase in explicitRecentPhrases) {
      if (_containsPhrase(
        normalized,
        phrase,
      )) {
        return _BrainSearchRecencyResult(
          sort: BrainSearchSort.newest,
          limit: _defaultRecentLimit,
          consumedPhrases: {
            phrase,
          },
        );
      }
    }

    final numberedNewest =
        RegExp(
          r'\b(\d{1,3})\s+ultim(?:os|as)\b',
        ).firstMatch(
          normalized,
        );

    if (numberedNewest !=
        null) {
      final parsed = _parseSafeLimit(
        numberedNewest.group(
          1,
        ),
      );

      return _BrainSearchRecencyResult(
        sort: BrainSearchSort.newest,
        limit: parsed,
        consumedPhrases: {
          numberedNewest.group(
                0,
              ) ??
              '',
        },
      );
    }

    if (_containsWord(
          normalized,
          'ultimo',
        ) ||
        _containsWord(
          normalized,
          'ultima',
        ) ||
        _containsWord(
          normalized,
          'ultimos',
        ) ||
        _containsWord(
          normalized,
          'ultimas',
        )) {
      return const _BrainSearchRecencyResult(
        sort: BrainSearchSort.newest,
        limit: _defaultRecentLimit,
      );
    }

    return const _BrainSearchRecencyResult(
      sort: BrainSearchSort.relevance,
    );
  }

  // ============================================================
  // LIMIT
  // ============================================================

  _BrainSearchLimitResult _parseLimit(
    String normalized,
  ) {
    final patterns =
        <
          RegExp
        >[
          RegExp(
            r'\b(?:mostre|mostra|mostrar)\s+(?:so\s+|somente\s+)?(\d{1,3})\b',
          ),
          RegExp(
            r'\b(?:so|somente)\s+(\d{1,3})\s+(?:resultado|resultados)\b',
          ),
          RegExp(
            r'\b(\d{1,3})\s+(?:resultado|resultados)\b',
          ),
          RegExp(
            r'\b(\d{1,3})\s+ultim(?:os|as)\b',
          ),
        ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(
        normalized,
      );

      if (match ==
          null) {
        continue;
      }

      final parsed = _parseSafeLimit(
        match.group(
          1,
        ),
      );

      if (parsed ==
          null) {
        continue;
      }

      return _BrainSearchLimitResult(
        limit: parsed,
        consumedPhrases: {
          match.group(
                0,
              ) ??
              '',
        },
      );
    }

    return const _BrainSearchLimitResult();
  }

  int? _parseSafeLimit(
    String? raw,
  ) {
    final parsed = int.tryParse(
      raw ??
          '',
    );

    if (parsed ==
            null ||
        parsed <=
            0) {
      return null;
    }

    if (parsed >
        _maximumRequestedLimit) {
      return _maximumRequestedLimit;
    }

    return parsed;
  }

  bool _looksLikeStandaloneLimitNumber({
    required String token,
    required String normalized,
    required int? limit,
  }) {
    final parsed = int.tryParse(
      token,
    );

    if (parsed ==
            null ||
        limit ==
            null ||
        parsed !=
            limit) {
      return false;
    }

    return normalized.contains(
      token,
    );
  }

  // ============================================================
  // DATE
  // ============================================================

  _BrainSearchDateFilter _parseDateFilter({
    required String rawQuery,
    required String normalized,
    required DateTime now,
  }) {
    final today = _startOfDay(
      now,
    );

    // ==========================================================
    // DATA ABSOLUTA
    // ==========================================================

    final absoluteDate = _parseAbsoluteDate(
      rawQuery,
    );

    if (absoluteDate !=
        null) {
      final baseStart = _startOfDay(
        absoluteDate.date,
      );

      final dayPart = _parseDayPart(
        normalized,
      );

      final range = _applyDayPart(
        dayStart: baseStart,
        dayPart: dayPart,
      );

      final consumed =
          <
            String
          >{
            BrainSearchNormalizer.normalize(
              absoluteDate.matchedText,
            ),
            ...dayPart.consumedPhrases,
          };

      return _BrainSearchDateFilter(
        startDate: range.startDate,
        endDate: range.endDate,
        consumedPhrases: consumed,
      );
    }

    // ==========================================================
    // ANTEONTEM
    // ==========================================================

    if (_containsPhrase(
      normalized,
      'anteontem',
    )) {
      final baseStart = today.subtract(
        const Duration(
          days: 2,
        ),
      );

      return _dateFilterWithDayPart(
        dayStart: baseStart,
        normalized: normalized,
        basePhrase: 'anteontem',
      );
    }

    // ==========================================================
    // ONTEM
    // ==========================================================

    if (_containsPhrase(
      normalized,
      'ontem',
    )) {
      final baseStart = today.subtract(
        const Duration(
          days: 1,
        ),
      );

      return _dateFilterWithDayPart(
        dayStart: baseStart,
        normalized: normalized,
        basePhrase: 'ontem',
      );
    }

    // ==========================================================
    // HOJE
    // ==========================================================

    if (_containsPhrase(
      normalized,
      'hoje',
    )) {
      return _dateFilterWithDayPart(
        dayStart: today,
        normalized: normalized,
        basePhrase: 'hoje',
      );
    }

    // ==========================================================
    // PERÍODO DO DIA SEM DATA EXPLÍCITA
    // ==========================================================
    //
    // "o que estudei de manhã?"
    //
    // assume hoje.
    //
    // ==========================================================

    final standaloneDayPart = _parseDayPart(
      normalized,
    );

    if (standaloneDayPart.value !=
        _BrainSearchDayPart.none) {
      final range = _applyDayPart(
        dayStart: today,
        dayPart: standaloneDayPart,
      );

      return _BrainSearchDateFilter(
        startDate: range.startDate,
        endDate: range.endDate,
        consumedPhrases: standaloneDayPart.consumedPhrases,
      );
    }

    // ==========================================================
    // SEMANA PASSADA
    // ==========================================================

    if (_containsPhrase(
      normalized,
      'semana passada',
    )) {
      final currentWeekStart = _startOfWeek(
        today,
      );

      final previousWeekStart = currentWeekStart.subtract(
        const Duration(
          days: 7,
        ),
      );

      return _BrainSearchDateFilter(
        startDate: previousWeekStart,
        endDate: currentWeekStart,
        consumedPhrases: const {
          'semana passada',
        },
      );
    }

    // ==========================================================
    // ESTA SEMANA
    // ==========================================================

    if (_containsPhrase(
          normalized,
          'esta semana',
        ) ||
        _containsPhrase(
          normalized,
          'essa semana',
        )) {
      final weekStart = _startOfWeek(
        today,
      );

      return _BrainSearchDateFilter(
        startDate: weekStart,
        endDate: weekStart.add(
          const Duration(
            days: 7,
          ),
        ),
        consumedPhrases: const {
          'esta semana',
          'essa semana',
        },
      );
    }

    // ==========================================================
    // MÊS PASSADO
    // ==========================================================

    if (_containsPhrase(
      normalized,
      'mes passado',
    )) {
      final currentMonthStart = DateTime(
        today.year,
        today.month,
      );

      final previousMonthStart = DateTime(
        today.year,
        today.month -
            1,
      );

      return _BrainSearchDateFilter(
        startDate: previousMonthStart,
        endDate: currentMonthStart,
        consumedPhrases: const {
          'mes passado',
        },
      );
    }

    // ==========================================================
    // ESTE MÊS
    // ==========================================================

    if (_containsPhrase(
          normalized,
          'este mes',
        ) ||
        _containsPhrase(
          normalized,
          'esse mes',
        )) {
      final monthStart = DateTime(
        today.year,
        today.month,
      );

      final nextMonthStart = DateTime(
        today.year,
        today.month +
            1,
      );

      return _BrainSearchDateFilter(
        startDate: monthStart,
        endDate: nextMonthStart,
        consumedPhrases: const {
          'este mes',
          'esse mes',
        },
      );
    }

    // ==========================================================
    // ÚLTIMOS N DIAS
    // ==========================================================

    final lastDays =
        RegExp(
          r'\bultim(?:os|as)\s+(\d{1,3})\s+dias\b',
        ).firstMatch(
          normalized,
        );

    if (lastDays !=
        null) {
      final parsed = int.tryParse(
        lastDays.group(
              1,
            ) ??
            '',
      );

      if (parsed !=
              null &&
          parsed >
              0) {
        final start = today.subtract(
          Duration(
            days:
                parsed -
                1,
          ),
        );

        return _BrainSearchDateFilter(
          startDate: start,
          endDate: today.add(
            const Duration(
              days: 1,
            ),
          ),
          consumedPhrases: {
            lastDays.group(
                  0,
                ) ??
                '',
          },
        );
      }
    }

    return const _BrainSearchDateFilter();
  }

  // ============================================================
  // DAY PART
  // ============================================================

  _BrainSearchDayPartResult _parseDayPart(
    String normalized,
  ) {
    if (_containsWord(
      normalized,
      'manha',
    )) {
      return const _BrainSearchDayPartResult(
        value: _BrainSearchDayPart.morning,
        consumedPhrases: {
          'manha',
        },
      );
    }

    if (_containsWord(
      normalized,
      'tarde',
    )) {
      return const _BrainSearchDayPartResult(
        value: _BrainSearchDayPart.afternoon,
        consumedPhrases: {
          'tarde',
        },
      );
    }

    if (_containsWord(
      normalized,
      'noite',
    )) {
      return const _BrainSearchDayPartResult(
        value: _BrainSearchDayPart.night,
        consumedPhrases: {
          'noite',
        },
      );
    }

    return const _BrainSearchDayPartResult(
      value: _BrainSearchDayPart.none,
    );
  }

  _BrainSearchDateRange _applyDayPart({
    required DateTime dayStart,
    required _BrainSearchDayPartResult dayPart,
  }) {
    switch (dayPart.value) {
      case _BrainSearchDayPart.none:
        return _BrainSearchDateRange(
          startDate: dayStart,
          endDate: dayStart.add(
            const Duration(
              days: 1,
            ),
          ),
        );

      case _BrainSearchDayPart.morning:
        return _BrainSearchDateRange(
          startDate: dayStart.add(
            const Duration(
              hours: 6,
            ),
          ),
          endDate: dayStart.add(
            const Duration(
              hours: 12,
            ),
          ),
        );

      case _BrainSearchDayPart.afternoon:
        return _BrainSearchDateRange(
          startDate: dayStart.add(
            const Duration(
              hours: 12,
            ),
          ),
          endDate: dayStart.add(
            const Duration(
              hours: 18,
            ),
          ),
        );

      case _BrainSearchDayPart.night:
        return _BrainSearchDateRange(
          startDate: dayStart.add(
            const Duration(
              hours: 18,
            ),
          ),
          endDate: dayStart.add(
            const Duration(
              days: 1,
            ),
          ),
        );
    }
  }

  _BrainSearchDateFilter _dateFilterWithDayPart({
    required DateTime dayStart,
    required String normalized,
    required String basePhrase,
  }) {
    final dayPart = _parseDayPart(
      normalized,
    );

    final range = _applyDayPart(
      dayStart: dayStart,
      dayPart: dayPart,
    );

    return _BrainSearchDateFilter(
      startDate: range.startDate,
      endDate: range.endDate,
      consumedPhrases: {
        basePhrase,
        ...dayPart.consumedPhrases,
      },
    );
  }

  // ============================================================
  // ABSOLUTE DATE
  // ============================================================

  _BrainSearchAbsoluteDate? _parseAbsoluteDate(
    String rawQuery,
  ) {
    final brPattern = RegExp(
      r'(?<!\d)(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{4})(?!\d)',
    );

    final brMatch = brPattern.firstMatch(
      rawQuery,
    );

    if (brMatch !=
        null) {
      final day = int.tryParse(
        brMatch.group(
              1,
            ) ??
            '',
      );

      final month = int.tryParse(
        brMatch.group(
              2,
            ) ??
            '',
      );

      final year = int.tryParse(
        brMatch.group(
              3,
            ) ??
            '',
      );

      final date = _safeDate(
        year: year,
        month: month,
        day: day,
      );

      if (date !=
          null) {
        return _BrainSearchAbsoluteDate(
          date: date,
          matchedText:
              brMatch.group(
                0,
              ) ??
              '',
        );
      }
    }

    final isoPattern = RegExp(
      r'(?<!\d)(\d{4})-(\d{1,2})-(\d{1,2})(?!\d)',
    );

    final isoMatch = isoPattern.firstMatch(
      rawQuery,
    );

    if (isoMatch !=
        null) {
      final year = int.tryParse(
        isoMatch.group(
              1,
            ) ??
            '',
      );

      final month = int.tryParse(
        isoMatch.group(
              2,
            ) ??
            '',
      );

      final day = int.tryParse(
        isoMatch.group(
              3,
            ) ??
            '',
      );

      final date = _safeDate(
        year: year,
        month: month,
        day: day,
      );

      if (date !=
          null) {
        return _BrainSearchAbsoluteDate(
          date: date,
          matchedText:
              isoMatch.group(
                0,
              ) ??
              '',
        );
      }
    }

    return null;
  }

  DateTime? _safeDate({
    required int? year,
    required int? month,
    required int? day,
  }) {
    if (year ==
            null ||
        month ==
            null ||
        day ==
            null) {
      return null;
    }

    if (year <
            1 ||
        month <
            1 ||
        month >
            12 ||
        day <
            1 ||
        day >
            31) {
      return null;
    }

    final date = DateTime(
      year,
      month,
      day,
    );

    if (date.year !=
            year ||
        date.month !=
            month ||
        date.day !=
            day) {
      return null;
    }

    return date;
  }

  // ============================================================
  // MATCHED NATURAL SEARCH PHRASES
  // ============================================================

  Set<
    String
  >
  _matchedNaturalSearchPhrases(
    String normalized,
  ) {
    final matched =
        <
          String
        >{};

    for (final phrase in _naturalSearchPhrases) {
      if (_containsPhrase(
        normalized,
        phrase,
      )) {
        matched.add(
          phrase,
        );
      }
    }

    return matched;
  }

  // ============================================================
  // MATCHED SOURCE INTENT PHRASES
  // ============================================================

  Set<
    String
  >
  _matchedSourceIntentPhrases(
    String normalized,
  ) {
    final matched =
        <
          String
        >{};

    for (final phrase in _sourceIntentPhrases) {
      if (_containsPhrase(
        normalized,
        phrase,
      )) {
        matched.add(
          phrase,
        );
      }
    }

    return matched;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  DateTime _startOfDay(
    DateTime value,
  ) {
    final local = value.toLocal();

    return DateTime(
      local.year,
      local.month,
      local.day,
    );
  }

  DateTime _startOfWeek(
    DateTime value,
  ) {
    final day = _startOfDay(
      value,
    );

    return day.subtract(
      Duration(
        days:
            day.weekday -
            DateTime.monday,
      ),
    );
  }

  bool _containsPhrase(
    String normalized,
    String phrase,
  ) {
    return normalized.contains(
      phrase,
    );
  }

  bool _containsWord(
    String normalized,
    String word,
  ) {
    return RegExp(
      r'(^|\s)' +
          RegExp.escape(
            word,
          ) +
          r'($|\s)',
    ).hasMatch(
      normalized,
    );
  }

  String _removeKnownPhrases(
    String normalized,
    Set<
      String
    >
    phrases,
  ) {
    var result = normalized;

    final ordered =
        phrases
            .where(
              (
                phrase,
              ) => phrase.trim().isNotEmpty,
            )
            .toList()
          ..sort(
            (
              first,
              second,
            ) {
              return second.length.compareTo(
                first.length,
              );
            },
          );

    for (final phrase in ordered) {
      result = result.replaceAll(
        phrase,
        ' ',
      );
    }

    return result
        .replaceAll(
          RegExp(
            r'\s+',
          ),
          ' ',
        )
        .trim();
  }
}

// ============================================================
// INTERNAL RECENCY RESULT
// ============================================================

class _BrainSearchRecencyResult {
  const _BrainSearchRecencyResult({
    required this.sort,
    this.limit,
    this.consumedPhrases =
        const <
          String
        >{},
  });

  final BrainSearchSort sort;

  final int? limit;

  final Set<
    String
  >
  consumedPhrases;
}

// ============================================================
// INTERNAL LIMIT RESULT
// ============================================================

class _BrainSearchLimitResult {
  const _BrainSearchLimitResult({
    this.limit,
    this.consumedPhrases =
        const <
          String
        >{},
  });

  final int? limit;

  final Set<
    String
  >
  consumedPhrases;
}

// ============================================================
// INTERNAL ABSOLUTE DATE
// ============================================================

class _BrainSearchAbsoluteDate {
  const _BrainSearchAbsoluteDate({
    required this.date,
    required this.matchedText,
  });

  final DateTime date;

  final String matchedText;
}

// ============================================================
// INTERNAL DAY PART
// ============================================================

enum _BrainSearchDayPart {
  none,
  morning,
  afternoon,
  night,
}

class _BrainSearchDayPartResult {
  const _BrainSearchDayPartResult({
    required this.value,
    this.consumedPhrases =
        const <
          String
        >{},
  });

  final _BrainSearchDayPart value;

  final Set<
    String
  >
  consumedPhrases;
}

// ============================================================
// INTERNAL DATE RANGE
// ============================================================

class _BrainSearchDateRange {
  const _BrainSearchDateRange({
    required this.startDate,
    required this.endDate,
  });

  final DateTime startDate;

  final DateTime endDate;
}

// ============================================================
// INTERNAL DATE FILTER
// ============================================================

class _BrainSearchDateFilter {
  const _BrainSearchDateFilter({
    this.startDate,
    this.endDate,
    this.consumedPhrases =
        const <
          String
        >{},
  });

  final DateTime? startDate;

  final DateTime? endDate;

  final Set<
    String
  >
  consumedPhrases;
}
