import '../../models/brain_file.dart';
import '../models/brain_search_query.dart';
import '../models/brain_search_response.dart';
import '../utils/brain_search_normalizer.dart';

// ============================================================
// BRAIN SEARCH ENGINE
// ============================================================
//
// FASE 12/13 — RESPOSTAS ESTRUTURADAS + FONTES
//
// Motor determinístico e offline de busca/ranking.
//
// FASE 13:
//
// - fontes entram na busca com peso menor que conteúdo principal;
// - título, autor e referência da fonte participam do ranking;
// - sort/limit da BrainSearchQuery passam a ser respeitados.
//
// Responsabilidades:
//
// - receber BrainFile já carregados;
// - aplicar filtros estruturados da BrainSearchQuery;
// - manter compatibilidade com a busca textual antiga;
// - calcular relevância por título, conteúdo, conceitos e datas;
// - ordenar resultados pelo score;
// - estruturar os resultados em BrainSearchResponse;
// - destacar os resultados mais relevantes;
// - agrupar resultados por tipo;
// - usar topic apenas como compatibilidade silenciosa;
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
//    ├── topResults
//    ├── concepts
//    ├── questions
//    ├── examples
//    ├── warnings
//    └── allResults
//
// ============================================================

class BrainSearchEngine {
  const BrainSearchEngine();

  // ============================================================
  // CONFIG
  // ============================================================

  static const int defaultTopLimit = 3;

  // ============================================================
  // SEARCH — RESPOSTA ESTRUTURADA
  // ============================================================

  BrainSearchResponse search({
    required Iterable<BrainFile> notes,
    required BrainSearchQuery query,
    int topLimit = defaultTopLimit,
  }) {
    if (query.isEmpty) {
      return BrainSearchResponse.fromResults(
        const <BrainFile>[],
        topLimit: topLimit,
      );
    }

    final ranked = _rank(notes: notes, query: query);

    return BrainSearchResponse.fromResults(ranked, topLimit: topLimit);
  }

  // ============================================================
  // SEARCH FILES — COMPATIBILIDADE TEMPORÁRIA
  // ============================================================
  //
  // Enquanto BrainScreen ainda estiver migrando para a Fase 12,
  // este método permite obter apenas a lista ordenada.
  //
  // Quando a UI estiver totalmente usando BrainSearchResponse,
  // este método poderá ser removido.
  //
  // ============================================================

  List<BrainFile> searchFiles({
    required Iterable<BrainFile> notes,
    required BrainSearchQuery query,
  }) {
    return _rank(notes: notes, query: query);
  }

  // ============================================================
  // RANK
  // ============================================================

  List<BrainFile> _rank({
    required Iterable<BrainFile> notes,
    required BrainSearchQuery query,
  }) {
    if (query.isEmpty) {
      return const <BrainFile>[];
    }

    final scored = <_BrainSearchScoredNote>[];

    for (final note in notes) {
      if (!_matchesStructuredFilters(note: note, query: query)) {
        continue;
      }

      final noteScore = score(note: note, query: query);

      if (noteScore <= 0 && query.hasTerms) {
        continue;
      }

      scored.add(_BrainSearchScoredNote(note: note, score: noteScore));
    }

    scored.sort((first, second) {
      switch (query.sort) {
        case BrainSearchSort.newest:
          final updatedComparison = second.note.updatedAt.compareTo(
            first.note.updatedAt,
          );

          if (updatedComparison != 0) {
            return updatedComparison;
          }

          final createdComparison = second.note.createdAt.compareTo(
            first.note.createdAt,
          );

          if (createdComparison != 0) {
            return createdComparison;
          }

          return second.score.compareTo(first.score);

        case BrainSearchSort.oldest:
          final createdComparison = first.note.createdAt.compareTo(
            second.note.createdAt,
          );

          if (createdComparison != 0) {
            return createdComparison;
          }

          final updatedComparison = first.note.updatedAt.compareTo(
            second.note.updatedAt,
          );

          if (updatedComparison != 0) {
            return updatedComparison;
          }

          return second.score.compareTo(first.score);

        case BrainSearchSort.relevance:
          final scoreComparison = second.score.compareTo(first.score);

          if (scoreComparison != 0) {
            return scoreComparison;
          }

          final updatedComparison = second.note.updatedAt.compareTo(
            first.note.updatedAt,
          );

          if (updatedComparison != 0) {
            return updatedComparison;
          }

          return second.note.createdAt.compareTo(first.note.createdAt);
      }
    });

    final ordered = scored
        .map((item) {
          return item.note;
        })
        .toList(growable: false);

    final limit = query.effectiveLimit;

    if (limit == null) {
      return List<BrainFile>.unmodifiable(ordered);
    }

    if (limit <= 0) {
      return const <BrainFile>[];
    }

    if (ordered.length <= limit) {
      return List<BrainFile>.unmodifiable(ordered);
    }

    return List<BrainFile>.unmodifiable(ordered.take(limit));
  }

  // ============================================================
  // SCORE
  // ============================================================

  int score({required BrainFile note, required BrainSearchQuery query}) {
    final terms = query.terms;

    final searchText = BrainSearchNormalizer.normalize(query.searchText);

    final title = BrainSearchNormalizer.normalize(note.title);

    // ==========================================================
    // TOPIC LEGADO
    // ==========================================================
    //
    // Continua entrando silenciosamente no ranking apenas para
    // manter dados antigos encontráveis.
    //
    // ==========================================================

    final topic = BrainSearchNormalizer.normalize(note.topic);

    final content = BrainSearchNormalizer.normalize(note.content);

    final conceptTitles = <String>[];
    final conceptDescriptions = <String>[];
    final conceptLabels = <String>[];

    final sourceTitles = <String>[];
    final sourceAuthors = <String>[];
    final sourceReferences = <String>[];

    for (final concept in note.concepts) {
      conceptTitles.add(BrainSearchNormalizer.normalize(concept.title));

      conceptDescriptions.add(
        BrainSearchNormalizer.normalize(concept.description),
      );

      conceptLabels.add(BrainSearchNormalizer.normalize(concept.label));
    }

    for (final source in note.sources) {
      sourceTitles.add(BrainSearchNormalizer.normalize(source.title));

      final author = source.author?.trim();

      if (author != null && author.isNotEmpty) {
        sourceAuthors.add(BrainSearchNormalizer.normalize(author));
      }

      sourceReferences.add(BrainSearchNormalizer.normalize(source.reference));
    }

    final dates = <String>[
      BrainSearchNormalizer.normalize(_formatSearchDate(note.createdAt)),
      BrainSearchNormalizer.normalize(_formatSearchDate(note.updatedAt)),
      BrainSearchNormalizer.normalize(_formatIsoDate(note.createdAt)),
      BrainSearchNormalizer.normalize(_formatIsoDate(note.updatedAt)),
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
    // QUERY ÚTIL COMPLETA
    // ==========================================================

    if (searchText.isNotEmpty) {
      if (title == searchText) {
        total += 1000;
      } else if (title.startsWith(searchText)) {
        total += 700;
      } else if (searchText.length >= 3 && title.contains(searchText)) {
        total += 500;
      }

      if (topic == searchText) {
        total += 600;
      } else if (topic.startsWith(searchText)) {
        total += 400;
      } else if (searchText.length >= 3 && topic.contains(searchText)) {
        total += 280;
      }

      for (final value in conceptTitles) {
        if (value == searchText) {
          total += 450;
        } else if (value.startsWith(searchText)) {
          total += 320;
        } else if (searchText.length >= 3 && value.contains(searchText)) {
          total += 220;
        }
      }

      for (final value in sourceTitles) {
        if (value == searchText) {
          total += 180;
        } else if (value.startsWith(searchText)) {
          total += 130;
        } else if (searchText.length >= 3 && value.contains(searchText)) {
          total += 90;
        }
      }

      for (final value in sourceAuthors) {
        if (value == searchText) {
          total += 140;
        } else if (value.startsWith(searchText)) {
          total += 100;
        } else if (searchText.length >= 3 && value.contains(searchText)) {
          total += 70;
        }
      }

      for (final value in sourceReferences) {
        if (value == searchText) {
          total += 110;
        } else if (value.startsWith(searchText)) {
          total += 80;
        } else if (searchText.length >= 3 && value.contains(searchText)) {
          total += 55;
        }
      }

      if (searchText.length >= 4 && content.contains(searchText)) {
        total += 120;
      }
    }

    // ==========================================================
    // BUSCA NUMÉRICA / DATA DIGITADA
    // ==========================================================
    //
    // Mantém compatibilidade com consultas como:
    //
    // 03/09/2026
    // 2026-09-03
    // 2026
    //
    // ==========================================================

    final allowDateTextSearch = RegExp(r'\d').hasMatch(query.normalizedQuery);

    if (allowDateTextSearch &&
        dates.any((value) {
          return value.contains(query.normalizedQuery);
        })) {
      total += 300;
    }

    // ==========================================================
    // TOKENS
    // ==========================================================

    for (final rawToken in terms) {
      final token = BrainSearchNormalizer.normalize(rawToken);

      if (token.isEmpty) {
        continue;
      }

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

      for (final value in sourceTitles) {
        tokenScore = _maxSearchScore(
          tokenScore,
          _scoreSearchField(
            value: value,
            token: token,
            exact: 65,
            prefix: 48,
            contains: 32,
          ),
        );
      }

      for (final value in sourceAuthors) {
        tokenScore = _maxSearchScore(
          tokenScore,
          _scoreSearchField(
            value: value,
            token: token,
            exact: 55,
            prefix: 40,
            contains: 28,
          ),
        );
      }

      for (final value in sourceReferences) {
        tokenScore = _maxSearchScore(
          tokenScore,
          _scoreSearchField(
            value: value,
            token: token,
            exact: 45,
            prefix: 34,
            contains: 24,
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
      //
      // Se um termo útil não aparece em nenhum campo, a nota
      // deixa de ser um resultado válido.
      //
      // ========================================================

      if (tokenScore <= 0) {
        return 0;
      }

      total += tokenScore;
    }

    // ==========================================================
    // QUERY SOMENTE COM FILTROS
    // ==========================================================
    //
    // Exemplos:
    //
    // "perguntas de ontem"
    // "exemplos da semana passada"
    //
    // ==========================================================

    if (!query.hasTerms && (query.hasTypeFilter || query.hasDateFilter)) {
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
    if (!_matchesTypeFilter(note: note, query: query)) {
      return false;
    }

    if (!_matchesDateFilter(note: note, query: query)) {
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

    if (type == null) {
      return true;
    }

    // Linhas remotas/legadas podem chegar sem conceitos
    // materializados.
    //
    // Não rejeitamos só pela ausência desse metadado para manter
    // compatibilidade temporária com o fluxo remoto atual.
    if (note.concepts.isEmpty) {
      return true;
    }

    return note.concepts.any((concept) {
      return concept.type == type;
    });
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

    // Uma nota entra se foi criada OU atualizada no período.
    return query.matchesDate(note.createdAt) ||
        query.matchesDate(note.updatedAt);
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
  }) {
    if (value.isEmpty || token.isEmpty) {
      return 0;
    }

    if (value == token) {
      return exact;
    }

    if (value.startsWith(token)) {
      return prefix;
    }

    final canUseContains = allowShortContains || token.length >= 3;

    if (canUseContains && value.contains(token)) {
      return contains;
    }

    return 0;
  }

  // ============================================================
  // MAX SCORE
  // ============================================================

  int _maxSearchScore(int first, int second) {
    return first > second ? first : second;
  }

  // ============================================================
  // NOTE CONTENT KEY
  // ============================================================
  //
  // Usado para merge/deduplicação entre local e remoto.
  //
  // ============================================================

  String contentKey(BrainFile note) {
    return '${BrainSearchNormalizer.normalize(note.topic)}|'
        '${BrainSearchNormalizer.normalize(note.title)}|'
        '${BrainSearchNormalizer.normalize(note.content)}';
  }

  // ============================================================
  // DATE FORMAT
  // ============================================================

  String _formatSearchDate(DateTime date) {
    final local = date.toLocal();

    String two(int value) {
      return value.toString().padLeft(2, '0');
    }

    return '${two(local.day)}/'
        '${two(local.month)}/'
        '${local.year}';
  }

  String _formatIsoDate(DateTime date) {
    final local = date.toLocal();

    String two(int value) {
      return value.toString().padLeft(2, '0');
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
  const _BrainSearchScoredNote({required this.note, required this.score});

  final BrainFile note;

  final int score;
}
