import '../../models/brain_concept.dart';

// ============================================================
// BRAIN SEARCH SORT
// ============================================================
//
// Define como os resultados devem ser ordenados.
//
// relevance:
//   prioridade para o score calculado pelo BrainSearchEngine.
//
// newest:
//   resultados mais recentes primeiro.
//
// oldest:
//   resultados mais antigos primeiro.
//
// ============================================================

enum BrainSearchSort { relevance, newest, oldest }

// ============================================================
// BRAIN SEARCH INTENT
// ============================================================
//
// Define a intenção principal detectada na linguagem natural.
//
// search:
//   busca normal.
//
// knowledgeOverview:
//   consulta do tipo:
//
//   "o que eu já sei sobre filas?"
//
//   A Fase 12 pode usar essa intenção para montar uma resposta
//   estruturada por conceitos, perguntas, exemplos e atenções.
//
// ============================================================

enum BrainSearchIntent { search, knowledgeOverview }

// ============================================================
// BRAIN SEARCH QUERY
// ============================================================
//
// Representa uma consulta já interpretada pelo parser.
//
// A busca natural entra como texto livre:
//
// "me mostra perguntas de ontem sobre ponteiros"
//
// e sai estruturada como:
//
// - originalQuery;
// - normalizedQuery;
// - terms;
// - type;
// - startDate;
// - endDate;
// - sort;
// - limit;
// - intent.
//
// Exemplos:
//
// "o que estudei recentemente sobre C++"
//
// terms  = ["c++"]
// sort   = newest
// limit  = 5
//
// "me mostre 5 perguntas sobre C++"
//
// terms  = ["c++"]
// type   = question
// limit  = 5
// sort   = relevance
//
// "quais foram os 3 últimos exemplos sobre Flutter?"
//
// terms  = ["flutter"]
// type   = example
// limit  = 3
// sort   = newest
//
// "o que eu já sei sobre filas?"
//
// terms  = ["filas"]
// intent = knowledgeOverview
//
// IMPORTANTE:
//
// startDate é inclusivo.
// endDate é exclusivo.
//
// Exemplo:
//
// ontem = [00:00 de ontem, 00:00 de hoje)
//
// ============================================================

class BrainSearchQuery {
  const BrainSearchQuery({
    required this.originalQuery,
    required this.normalizedQuery,
    required this.terms,
    this.type,
    this.startDate,
    this.endDate,
    this.sort = BrainSearchSort.relevance,
    this.limit,
    this.intent = BrainSearchIntent.search,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final String originalQuery;

  final String normalizedQuery;

  final List<String> terms;

  final BrainConceptType? type;

  final DateTime? startDate;

  final DateTime? endDate;

  final BrainSearchSort sort;

  final int? limit;

  final BrainSearchIntent intent;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get hasTerms {
    return terms.isNotEmpty;
  }

  bool get hasTypeFilter {
    return type != null;
  }

  bool get hasDateFilter {
    return startDate != null || endDate != null;
  }

  bool get hasLimit {
    final value = limit;

    return value != null && value > 0;
  }

  bool get isEmpty {
    return normalizedQuery.trim().isEmpty;
  }

  bool get isRelevanceSort {
    return sort == BrainSearchSort.relevance;
  }

  bool get isNewestSort {
    return sort == BrainSearchSort.newest;
  }

  bool get isOldestSort {
    return sort == BrainSearchSort.oldest;
  }

  bool get isKnowledgeOverview {
    return intent == BrainSearchIntent.knowledgeOverview;
  }

  String get searchText {
    return terms.join(' ');
  }

  // ============================================================
  // EFFECTIVE LIMIT
  // ============================================================
  //
  // Retorna null quando não existe limite válido.
  //
  // ============================================================

  int? get effectiveLimit {
    final value = limit;

    if (value == null || value <= 0) {
      return null;
    }

    return value;
  }

  // ============================================================
  // DATE MATCH
  // ============================================================

  bool matchesDate(DateTime value) {
    final local = value.toLocal();

    final start = startDate;

    if (start != null && local.isBefore(start)) {
      return false;
    }

    final end = endDate;

    if (end != null && !local.isBefore(end)) {
      return false;
    }

    return true;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  BrainSearchQuery copyWith({
    String? originalQuery,
    String? normalizedQuery,
    List<String>? terms,
    BrainConceptType? type,
    bool clearType = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    BrainSearchSort? sort,
    int? limit,
    bool clearLimit = false,
    BrainSearchIntent? intent,
  }) {
    return BrainSearchQuery(
      originalQuery: originalQuery ?? this.originalQuery,
      normalizedQuery: normalizedQuery ?? this.normalizedQuery,
      terms: terms ?? this.terms,
      type: clearType ? null : type ?? this.type,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      sort: sort ?? this.sort,
      limit: clearLimit ? null : limit ?? this.limit,
      intent: intent ?? this.intent,
    );
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'BrainSearchQuery('
        'originalQuery: $originalQuery, '
        'normalizedQuery: $normalizedQuery, '
        'terms: $terms, '
        'type: $type, '
        'startDate: $startDate, '
        'endDate: $endDate, '
        'sort: $sort, '
        'limit: $limit, '
        'intent: $intent'
        ')';
  }
}
