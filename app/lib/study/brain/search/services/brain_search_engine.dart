import '../../models/brain_file.dart';
import '../models/brain_search_query.dart';
import '../models/brain_search_response.dart';
import '../utils/brain_search_normalizer.dart';

// ============================================================
// BRAIN SEARCH ENGINE
// ============================================================
//
// Motor determinístico, offline e Vault-first de busca/ranking.
//
// Responsabilidades:
//
// - receber BrainFile já carregados;
// - aplicar filtros estruturados da BrainSearchQuery;
// - calcular relevância;
// - evitar correspondências fracas;
// - tratar consultas curtas com segurança;
// - preservar buscas legítimas como C, R, Go, IA, C#, ESP;
// - pesquisar título, conteúdo, conceitos, fontes e datas;
// - ordenar resultados;
// - respeitar limit;
// - estruturar BrainSearchResponse;
// - manter compatibilidade com topic legado;
// - não depender de Supabase;
// - não depender de IA.
//
// Fluxo:
//
// texto livre
//    ↓
// BrainSearchParser
//    ↓
// BrainSearchQuery
//    ↓
// BrainSearchEngine
//    ↓
// BrainSearchResponse
//
// ============================================================

class BrainSearchEngine {
  const BrainSearchEngine();

  // ============================================================
  // CONFIG
  // ============================================================

  static const int defaultTopLimit = 3;

  // ============================================================
  // TAMANHO DE TOKEN
  // ============================================================
  //
  // Tokens com até 3 caracteres precisam de tratamento
  // especial.
  //
  // Exemplos legítimos:
  //
  // C
  // R
  // Go
  // IA
  // C#
  // ESP
  //
  // Eles não podem simplesmente usar contains em qualquer
  // texto porque isso gera falsos positivos.
  //
  // ============================================================

  static const int _minimumContainsLength = 3;

  // ============================================================
  // SEARCH — RESPOSTA ESTRUTURADA
  // ============================================================

  BrainSearchResponse search({
    required Iterable<
      BrainFile
    >
    notes,
    required BrainSearchQuery query,
    int topLimit = defaultTopLimit,
  }) {
    if (query.isEmpty) {
      return BrainSearchResponse.fromResults(
        const <
          BrainFile
        >[],
        topLimit: topLimit,
      );
    }

    final ranked = _rank(
      notes: notes,
      query: query,
    );

    return BrainSearchResponse.fromResults(
      ranked,
      topLimit: topLimit,
    );
  }

  // ============================================================
  // SEARCH FILES — COMPATIBILIDADE
  // ============================================================

  List<
    BrainFile
  >
  searchFiles({
    required Iterable<
      BrainFile
    >
    notes,
    required BrainSearchQuery query,
  }) {
    return _rank(
      notes: notes,
      query: query,
    );
  }

  // ============================================================
  // RANK
  // ============================================================

  List<
    BrainFile
  >
  _rank({
    required Iterable<
      BrainFile
    >
    notes,
    required BrainSearchQuery query,
  }) {
    if (query.isEmpty) {
      return const <
        BrainFile
      >[];
    }

    final scored =
        <
          _BrainSearchScoredNote
        >[];

    for (final note in notes) {
      // ========================================================
      // FILTROS ESTRUTURADOS
      // ========================================================

      if (!_matchesStructuredFilters(
        note: note,
        query: query,
      )) {
        continue;
      }

      // ========================================================
      // SCORE
      // ========================================================

      final noteScore = score(
        note: note,
        query: query,
      );

      // ========================================================
      // CONSULTA TEXTUAL SEM CORRESPONDÊNCIA
      // ========================================================

      if (query.hasTerms &&
          noteScore <=
              0) {
        continue;
      }

      scored.add(
        _BrainSearchScoredNote(
          note: note,
          score: noteScore,
        ),
      );
    }

    // ==========================================================
    // ORDENAÇÃO
    // ==========================================================

    scored.sort(
      (
        first,
        second,
      ) {
        switch (query.sort) {
          case BrainSearchSort.newest:
            final updatedComparison = second.note.updatedAt.compareTo(
              first.note.updatedAt,
            );

            if (updatedComparison !=
                0) {
              return updatedComparison;
            }

            final createdComparison = second.note.createdAt.compareTo(
              first.note.createdAt,
            );

            if (createdComparison !=
                0) {
              return createdComparison;
            }

            return second.score.compareTo(
              first.score,
            );

          case BrainSearchSort.oldest:
            final createdComparison = first.note.createdAt.compareTo(
              second.note.createdAt,
            );

            if (createdComparison !=
                0) {
              return createdComparison;
            }

            final updatedComparison = first.note.updatedAt.compareTo(
              second.note.updatedAt,
            );

            if (updatedComparison !=
                0) {
              return updatedComparison;
            }

            return second.score.compareTo(
              first.score,
            );

          case BrainSearchSort.relevance:
            final scoreComparison = second.score.compareTo(
              first.score,
            );

            if (scoreComparison !=
                0) {
              return scoreComparison;
            }

            final updatedComparison = second.note.updatedAt.compareTo(
              first.note.updatedAt,
            );

            if (updatedComparison !=
                0) {
              return updatedComparison;
            }

            return second.note.createdAt.compareTo(
              first.note.createdAt,
            );
        }
      },
    );

    // ==========================================================
    // EXTRAIR NOTAS
    // ==========================================================

    final ordered = scored
        .map(
          (
            item,
          ) => item.note,
        )
        .toList(
          growable: false,
        );

    // ==========================================================
    // LIMIT
    // ==========================================================

    final limit = query.effectiveLimit;

    if (limit ==
        null) {
      return List<
        BrainFile
      >.unmodifiable(
        ordered,
      );
    }

    if (limit <=
        0) {
      return const <
        BrainFile
      >[];
    }

    if (ordered.length <=
        limit) {
      return List<
        BrainFile
      >.unmodifiable(
        ordered,
      );
    }

    return List<
      BrainFile
    >.unmodifiable(
      ordered.take(
        limit,
      ),
    );
  }

  // ============================================================
  // SCORE
  // ============================================================

  int score({
    required BrainFile note,
    required BrainSearchQuery query,
  }) {
    final terms = query.terms;

    final searchText = BrainSearchNormalizer.normalize(
      query.searchText,
    );

    final title = BrainSearchNormalizer.normalize(
      note.title,
    );

    // ==========================================================
    // TOPIC LEGADO
    // ==========================================================

    final topic = BrainSearchNormalizer.normalize(
      note.topic,
    );

    final content = BrainSearchNormalizer.normalize(
      note.content,
    );

    // ==========================================================
    // CONCEITOS
    // ==========================================================

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
        BrainSearchNormalizer.normalize(
          concept.title,
        ),
      );

      conceptDescriptions.add(
        BrainSearchNormalizer.normalize(
          concept.description,
        ),
      );

      conceptLabels.add(
        BrainSearchNormalizer.normalize(
          concept.label,
        ),
      );
    }

    // ==========================================================
    // FONTES
    // ==========================================================

    final sourceTitles =
        <
          String
        >[];
    final sourceAuthors =
        <
          String
        >[];
    final sourceReferences =
        <
          String
        >[];

    for (final source in note.sources) {
      sourceTitles.add(
        BrainSearchNormalizer.normalize(
          source.title,
        ),
      );

      final author = source.author?.trim();

      if (author !=
              null &&
          author.isNotEmpty) {
        sourceAuthors.add(
          BrainSearchNormalizer.normalize(
            author,
          ),
        );
      }

      sourceReferences.add(
        BrainSearchNormalizer.normalize(
          source.reference,
        ),
      );
    }

    // ==========================================================
    // DATAS
    // ==========================================================

    final dates =
        <
          String
        >[
          BrainSearchNormalizer.normalize(
            _formatSearchDate(
              note.createdAt,
            ),
          ),
          BrainSearchNormalizer.normalize(
            _formatSearchDate(
              note.updatedAt,
            ),
          ),
          BrainSearchNormalizer.normalize(
            _formatIsoDate(
              note.createdAt,
            ),
          ),
          BrainSearchNormalizer.normalize(
            _formatIsoDate(
              note.updatedAt,
            ),
          ),
          note.createdAt.year.toString(),
          note.updatedAt.year.toString(),
        ];

    var total = 0;

    // ==========================================================
    // FILTROS NATURAIS
    // ==========================================================

    if (query.hasTypeFilter) {
      total += 180;
    }

    if (query.hasDateFilter) {
      total += 160;
    }

    // ==========================================================
    // QUERY COMPLETA
    // ==========================================================

    if (searchText.isNotEmpty) {
      final shortSearchText = _isShortSearchToken(
        searchText,
      );

      // ========================================================
      // TÍTULO
      // ========================================================

      if (shortSearchText) {
        if (_matchesShortToken(
          value: title,
          token: searchText,
        )) {
          total +=
              title ==
                  searchText
              ? 1000
              : 650;
        }
      } else {
        if (title ==
            searchText) {
          total += 1000;
        } else if (title.startsWith(
          searchText,
        )) {
          total += 700;
        } else if (title.contains(
          searchText,
        )) {
          total += 500;
        }
      }

      // ========================================================
      // TOPIC LEGADO
      // ========================================================

      if (shortSearchText) {
        if (_matchesShortToken(
          value: topic,
          token: searchText,
        )) {
          total +=
              topic ==
                  searchText
              ? 600
              : 380;
        }
      } else {
        if (topic ==
            searchText) {
          total += 600;
        } else if (topic.startsWith(
          searchText,
        )) {
          total += 400;
        } else if (topic.contains(
          searchText,
        )) {
          total += 280;
        }
      }

      // ========================================================
      // TÍTULOS DE CONCEITOS
      // ========================================================

      for (final value in conceptTitles) {
        if (shortSearchText) {
          if (_matchesShortToken(
            value: value,
            token: searchText,
          )) {
            total +=
                value ==
                    searchText
                ? 450
                : 300;
          }
        } else {
          if (value ==
              searchText) {
            total += 450;
          } else if (value.startsWith(
            searchText,
          )) {
            total += 320;
          } else if (value.contains(
            searchText,
          )) {
            total += 220;
          }
        }
      }

      // ========================================================
      // TÍTULOS DAS FONTES
      // ========================================================

      for (final value in sourceTitles) {
        if (shortSearchText) {
          if (_matchesShortToken(
            value: value,
            token: searchText,
          )) {
            total +=
                value ==
                    searchText
                ? 180
                : 115;
          }
        } else {
          if (value ==
              searchText) {
            total += 180;
          } else if (value.startsWith(
            searchText,
          )) {
            total += 130;
          } else if (value.contains(
            searchText,
          )) {
            total += 90;
          }
        }
      }

      // ========================================================
      // AUTORES
      // ========================================================

      for (final value in sourceAuthors) {
        if (shortSearchText) {
          if (_matchesShortToken(
            value: value,
            token: searchText,
          )) {
            total +=
                value ==
                    searchText
                ? 140
                : 90;
          }
        } else {
          if (value ==
              searchText) {
            total += 140;
          } else if (value.startsWith(
            searchText,
          )) {
            total += 100;
          } else if (value.contains(
            searchText,
          )) {
            total += 70;
          }
        }
      }

      // ========================================================
      // REFERÊNCIAS
      // ========================================================

      for (final value in sourceReferences) {
        if (shortSearchText) {
          if (_matchesShortToken(
            value: value,
            token: searchText,
          )) {
            total +=
                value ==
                    searchText
                ? 110
                : 70;
          }
        } else {
          if (value ==
              searchText) {
            total += 110;
          } else if (value.startsWith(
            searchText,
          )) {
            total += 80;
          } else if (value.contains(
            searchText,
          )) {
            total += 55;
          }
        }
      }

      // ========================================================
      // CONTEÚDO COMPLETO
      // ========================================================

      if (shortSearchText) {
        if (_matchesShortToken(
          value: content,
          token: searchText,
        )) {
          total += 100;
        }
      } else if (searchText.length >=
              4 &&
          content.contains(
            searchText,
          )) {
        total += 120;
      }
    }

    // ==========================================================
    // BUSCA NUMÉRICA / DATA DIGITADA
    // ==========================================================

    final allowDateTextSearch =
        RegExp(
          r'\d',
        ).hasMatch(
          query.normalizedQuery,
        );

    if (allowDateTextSearch &&
        dates.any(
          (
            value,
          ) => value.contains(
            query.normalizedQuery,
          ),
        )) {
      total += 300;
    }

    // ==========================================================
    // TOKENS
    // ==========================================================
    //
    // Todos os termos precisam aparecer.
    //
    // Tokens de até 3 caracteres recebem tratamento especial.
    //
    // Isso preserva:
    //
    // C
    // R
    // Go
    // IA
    // C#
    // ESP
    //
    // sem fazer "esp" encontrar "especial".
    //
    // ==========================================================

    for (final rawToken in terms) {
      final token = BrainSearchNormalizer.normalize(
        rawToken,
      );

      if (token.isEmpty) {
        continue;
      }

      final shortToken = _isShortSearchToken(
        token,
      );

      var tokenScore = 0;

      // ========================================================
      // TÍTULO
      // ========================================================

      tokenScore = _maxSearchScore(
        tokenScore,
        _scoreSearchField(
          value: title,
          token: token,
          exact: 180,
          prefix: 130,
          contains: 90,
          requireWholeToken: shortToken,
        ),
      );

      // ========================================================
      // TOPIC
      // ========================================================

      tokenScore = _maxSearchScore(
        tokenScore,
        _scoreSearchField(
          value: topic,
          token: token,
          exact: 140,
          prefix: 100,
          contains: 70,
          requireWholeToken: shortToken,
        ),
      );

      // ========================================================
      // TÍTULOS DE CONCEITOS
      // ========================================================

      for (final value in conceptTitles) {
        tokenScore = _maxSearchScore(
          tokenScore,
          _scoreSearchField(
            value: value,
            token: token,
            exact: 120,
            prefix: 90,
            contains: 60,
            requireWholeToken: shortToken,
          ),
        );
      }

      // ========================================================
      // LABELS DE CONCEITOS
      // ========================================================

      for (final value in conceptLabels) {
        tokenScore = _maxSearchScore(
          tokenScore,
          _scoreSearchField(
            value: value,
            token: token,
            exact: 100,
            prefix: 75,
            contains: 50,
            requireWholeToken: shortToken,
          ),
        );
      }

      // ========================================================
      // DESCRIÇÕES DE CONCEITOS
      // ========================================================

      for (final value in conceptDescriptions) {
        tokenScore = _maxSearchScore(
          tokenScore,
          _scoreSearchField(
            value: value,
            token: token,
            exact: 80,
            prefix: 60,
            contains: 40,
            requireWholeToken: shortToken,
          ),
        );
      }

      // ========================================================
      // TÍTULOS DAS FONTES
      // ========================================================

      for (final value in sourceTitles) {
        tokenScore = _maxSearchScore(
          tokenScore,
          _scoreSearchField(
            value: value,
            token: token,
            exact: 65,
            prefix: 48,
            contains: 32,
            requireWholeToken: shortToken,
          ),
        );
      }

      // ========================================================
      // AUTORES DAS FONTES
      // ========================================================

      for (final value in sourceAuthors) {
        tokenScore = _maxSearchScore(
          tokenScore,
          _scoreSearchField(
            value: value,
            token: token,
            exact: 55,
            prefix: 40,
            contains: 28,
            requireWholeToken: shortToken,
          ),
        );
      }

      // ========================================================
      // REFERÊNCIAS DAS FONTES
      // ========================================================

      for (final value in sourceReferences) {
        tokenScore = _maxSearchScore(
          tokenScore,
          _scoreSearchField(
            value: value,
            token: token,
            exact: 45,
            prefix: 34,
            contains: 24,
            requireWholeToken: shortToken,
          ),
        );
      }

      // ========================================================
      // CONTEÚDO
      // ========================================================

      tokenScore = _maxSearchScore(
        tokenScore,
        _scoreSearchField(
          value: content,
          token: token,
          exact: 70,
          prefix: 50,
          contains: 30,
          requireWholeToken: shortToken,
        ),
      );

      // ========================================================
      // DATAS
      // ========================================================

      if (allowDateTextSearch) {
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

      // ========================================================
      // TODOS OS TERMOS DEVEM SER ENCONTRADOS
      // ========================================================

      if (tokenScore <=
          0) {
        return 0;
      }

      total += tokenScore;
    }

    // ==========================================================
    // QUERY SOMENTE COM FILTROS
    // ==========================================================

    if (!query.hasTerms &&
        (query.hasTypeFilter ||
            query.hasDateFilter)) {
      total += 100;
    }

    return total;
  }

  // ============================================================
  // STRUCTURED FILTERS
  // ============================================================

  bool _matchesStructuredFilters({
    required BrainFile note,
    required BrainSearchQuery query,
  }) {
    if (!_matchesTypeFilter(
      note: note,
      query: query,
    )) {
      return false;
    }

    if (!_matchesDateFilter(
      note: note,
      query: query,
    )) {
      return false;
    }

    return true;
  }

  // ============================================================
  // TYPE FILTER
  // ============================================================

  bool _matchesTypeFilter({
    required BrainFile note,
    required BrainSearchQuery query,
  }) {
    final type = query.type;

    if (type ==
        null) {
      return true;
    }

    // ==========================================================
    // COMPATIBILIDADE COM DADOS LEGADOS
    // ==========================================================

    if (note.concepts.isEmpty) {
      return true;
    }

    return note.concepts.any(
      (
        concept,
      ) =>
          concept.type ==
          type,
    );
  }

  // ============================================================
  // DATE FILTER
  // ============================================================

  bool _matchesDateFilter({
    required BrainFile note,
    required BrainSearchQuery query,
  }) {
    if (!query.hasDateFilter) {
      return true;
    }

    return query.matchesDate(
          note.createdAt,
        ) ||
        query.matchesDate(
          note.updatedAt,
        );
  }

  // ============================================================
  // TOKEN CURTO
  // ============================================================
  //
  // IMPORTANTE:
  //
  // Agora usamos <= 3.
  //
  // Portanto:
  //
  // C   → curto
  // IA  → curto
  // Go  → curto
  // ESP → curto
  //
  // ============================================================

  bool _isShortSearchToken(
    String token,
  ) {
    return token.length <=
        _minimumContainsLength;
  }

  // ============================================================
  // MATCH DE TOKEN CURTO
  // ============================================================
  //
  // Existem dois comportamentos válidos:
  //
  // 1. termo completo:
  //
  // IA → "estudando IA generativa"
  // Go → "programação em Go"
  //
  // 2. família técnica alfanumérica:
  //
  // ESP → ESP32
  // ESP → ESP8266
  //
  // O segundo caso NÃO permite:
  //
  // ESP → especial
  // ESP → especificamente
  //
  // porque o caractere imediatamente depois do prefixo precisa
  // ser um número.
  //
  // ============================================================

  bool _matchesShortToken({
    required String value,
    required String token,
  }) {
    if (_containsWholeSearchToken(
      value: value,
      token: token,
    )) {
      return true;
    }

    return _containsTechnicalPrefix(
      value: value,
      token: token,
    );
  }

  // ============================================================
  // PREFIXO TÉCNICO
  // ============================================================
  //
  // Permite especificamente padrões como:
  //
  // ESP + 32
  // ESP + 8266
  //
  // Também funciona de forma genérica para siglas técnicas
  // curtas seguidas imediatamente por número.
  //
  // Não aceita prefixo seguido por letra.
  //
  // ============================================================

  bool _containsTechnicalPrefix({
    required String value,
    required String token,
  }) {
    if (value.isEmpty ||
        token.isEmpty) {
      return false;
    }

    final words = _tokenizeSearchValue(
      value,
    );

    for (final word in words) {
      if (!word.startsWith(
        token,
      )) {
        continue;
      }

      if (word.length <=
          token.length) {
        continue;
      }

      final nextCharacter = word.substring(
        token.length,
        token.length +
            1,
      );

      if (RegExp(
        r'[0-9]',
      ).hasMatch(
        nextCharacter,
      )) {
        return true;
      }
    }

    return false;
  }

  // ============================================================
  // PALAVRA / TERMO COMPLETO
  // ============================================================
  //
  // Exemplo:
  //
  // "me"
  //
  // NÃO encontra:
  //
  // memória
  // método
  // mercado
  //
  // Mas:
  //
  // IA
  //
  // encontra:
  //
  // "estudando IA generativa"
  //
  // ============================================================

  bool _containsWholeSearchToken({
    required String value,
    required String token,
  }) {
    if (value.isEmpty ||
        token.isEmpty) {
      return false;
    }

    if (value ==
        token) {
      return true;
    }

    final tokens = _tokenizeSearchValue(
      value,
    );

    return tokens.any(
      (
        item,
      ) =>
          item ==
          token,
    );
  }

  // ============================================================
  // TOKENIZAÇÃO
  // ============================================================
  //
  // Mantemos:
  //
  // +
  // #
  //
  // dentro do token para preservar:
  //
  // C++
  // C#
  //
  // ============================================================

  Iterable<
    String
  >
  _tokenizeSearchValue(
    String value,
  ) {
    return value
        .split(
          RegExp(
            r'[^a-z0-9+#]+',
            caseSensitive: false,
          ),
        )
        .where(
          (
            item,
          ) => item.isNotEmpty,
        );
  }

  // ============================================================
  // FIELD SCORE
  // ============================================================

  int _scoreSearchField({
    required String value,
    required String token,
    required int exact,
    required int prefix,
    required int contains,
    bool allowShortContains = false,
    bool requireWholeToken = false,
  }) {
    if (value.isEmpty ||
        token.isEmpty) {
      return 0;
    }

    // ==========================================================
    // EXACT
    // ==========================================================

    if (value ==
        token) {
      return exact;
    }

    // ==========================================================
    // TOKEN CURTO
    // ==========================================================
    //
    // Tokens de até 3 caracteres não podem usar contains
    // indiscriminadamente.
    //
    // Primeiro verificamos:
    //
    // - termo completo;
    // - prefixo técnico seguido por número.
    //
    // ==========================================================

    if (requireWholeToken) {
      if (_matchesShortToken(
        value: value,
        token: token,
      )) {
        return contains;
      }

      return 0;
    }

    // ==========================================================
    // PREFIX
    // ==========================================================

    if (value.startsWith(
      token,
    )) {
      return prefix;
    }

    // ==========================================================
    // CONTAINS
    // ==========================================================
    //
    // A mudança importante é:
    //
    // > 3
    //
    // e não:
    //
    // >= 3
    //
    // ==========================================================

    final canUseContains =
        allowShortContains ||
        token.length >
            _minimumContainsLength;

    if (canUseContains &&
        value.contains(
          token,
        )) {
      return contains;
    }

    return 0;
  }

  // ============================================================
  // MAX SCORE
  // ============================================================

  int _maxSearchScore(
    int first,
    int second,
  ) {
    return first >
            second
        ? first
        : second;
  }

  // ============================================================
  // NOTE CONTENT KEY
  // ============================================================

  String contentKey(
    BrainFile note,
  ) {
    return '${BrainSearchNormalizer.normalize(note.topic)}|'
        '${BrainSearchNormalizer.normalize(note.title)}|'
        '${BrainSearchNormalizer.normalize(note.content)}';
  }

  // ============================================================
  // DATE FORMAT
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
}

// ============================================================
// INTERNAL SCORED NOTE
// ============================================================

class _BrainSearchScoredNote {
  const _BrainSearchScoredNote({
    required this.note,
    required this.score,
  });

  final BrainFile note;

  final int score;
}
