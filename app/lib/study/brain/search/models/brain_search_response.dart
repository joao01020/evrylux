import '../../models/brain_concept.dart';
import '../../models/brain_file.dart';
import '../../models/brain_source.dart';

// ============================================================
// BRAIN SEARCH RESPONSE
// ============================================================
//
// FASE 12/13 — RESPOSTAS ESTRUTURADAS + FONTES
//
// Representa a resposta organizada da busca.
//
// Objetivos:
//
// - evitar exibir dezenas de cards grandes de uma vez;
// - destacar apenas os resultados mais relevantes;
// - manter acesso à lista completa;
// - agrupar resultados por tipo;
// - agregar fontes relacionadas sem duplicação;
// - destacar fontes mais recorrentes;
// - preparar a UI para seções expansíveis;
// - continuar 100% determinístico e offline;
// - preparar a futura camada de IA sem acoplar IA agora.
//
// Fluxo:
//
// BrainSearchEngine
//      ↓
// List<BrainFile>
//      ↓
// BrainSearchResponse
//      ├── total
//      ├── topResults
//      ├── concepts
//      ├── questions
//      ├── examples
//      ├── warnings
//      ├── relatedSources
//      ├── mostFrequentSources
//      └── allResults
//
// REGRA DAS FONTES:
//
// - uma mesma fonte usada em várias notas aparece apenas uma vez em
//   relatedSources;
// - a deduplicação usa BrainSource.contentKey;
// - mostFrequentSources ordena pela quantidade de notas em que a
//   mesma fonte aparece;
// - em empate, preservamos a ordem de relevância dos resultados.
//
// ============================================================

class BrainSearchResponse {
  const BrainSearchResponse({
    required this.allResults,
    required this.topResults,
    required this.concepts,
    required this.questions,
    required this.examples,
    required this.warnings,
    required this.relatedSources,
    required this.mostFrequentSources,
    required this.sourceOccurrences,
  });

  // ============================================================
  // FACTORY
  // ============================================================

  factory BrainSearchResponse.fromResults(
    Iterable<BrainFile> results, {
    int topLimit = 3,
  }) {
    final normalizedTopLimit = topLimit < 0 ? 0 : topLimit;

    final all = List<BrainFile>.unmodifiable(results);

    final concepts = <BrainFile>[];
    final questions = <BrainFile>[];
    final examples = <BrainFile>[];
    final warnings = <BrainFile>[];

    // ==========================================================
    // FONTES
    // ==========================================================
    //
    // O primeiro BrainSource encontrado para cada contentKey é
    // preservado como representação canônica na resposta.
    //
    // Como "all" já chega ordenado pelo BrainSearchEngine, essa
    // estratégia também preserva a relevância do resultado que
    // apresentou a fonte primeiro.
    //
    // ==========================================================

    final sourcesByKey = <String, BrainSource>{};

    final sourceOccurrences = <String, int>{};

    final firstSeenOrder = <String, int>{};

    var sourceOrder = 0;

    for (final note in all) {
      if (_containsType(note, BrainConceptType.concept)) {
        concepts.add(note);
      }

      if (_containsType(note, BrainConceptType.question)) {
        questions.add(note);
      }

      if (_containsType(note, BrainConceptType.example)) {
        examples.add(note);
      }

      if (_containsType(note, BrainConceptType.warning)) {
        warnings.add(note);
      }

      // ========================================================
      // FONTES DA NOTA
      // ========================================================
      //
      // Cada source conta no máximo uma vez por nota.
      //
      // Isso evita inflar a recorrência caso uma mesma nota tenha,
      // por alguma inconsistência histórica, duas fontes com o mesmo
      // contentKey.
      //
      // ========================================================

      final seenInThisNote = <String>{};

      for (final source in note.sources) {
        if (!source.isValid) {
          continue;
        }

        final key = source.contentKey.trim();

        if (key.isEmpty) {
          continue;
        }

        sourcesByKey.putIfAbsent(key, () {
          firstSeenOrder[key] = sourceOrder++;

          return source;
        });

        if (!seenInThisNote.add(key)) {
          continue;
        }

        sourceOccurrences[key] = (sourceOccurrences[key] ?? 0) + 1;
      }
    }

    final relatedSources = sourcesByKey.values.toList(growable: false);

    final mostFrequentSources = relatedSources.toList(growable: true)
      ..sort((first, second) {
        final firstCount = sourceOccurrences[first.contentKey] ?? 0;

        final secondCount = sourceOccurrences[second.contentKey] ?? 0;

        final frequencyComparison = secondCount.compareTo(firstCount);

        if (frequencyComparison != 0) {
          return frequencyComparison;
        }

        final firstOrder = firstSeenOrder[first.contentKey] ?? 0;

        final secondOrder = firstSeenOrder[second.contentKey] ?? 0;

        return firstOrder.compareTo(secondOrder);
      });

    final topCount = normalizedTopLimit > all.length
        ? all.length
        : normalizedTopLimit;

    return BrainSearchResponse(
      allResults: all,
      topResults: List<BrainFile>.unmodifiable(all.take(topCount)),
      concepts: List<BrainFile>.unmodifiable(concepts),
      questions: List<BrainFile>.unmodifiable(questions),
      examples: List<BrainFile>.unmodifiable(examples),
      warnings: List<BrainFile>.unmodifiable(warnings),
      relatedSources: List<BrainSource>.unmodifiable(relatedSources),
      mostFrequentSources: List<BrainSource>.unmodifiable(mostFrequentSources),
      sourceOccurrences: Map<String, int>.unmodifiable(sourceOccurrences),
    );
  }

  // ============================================================
  // DATA
  // ============================================================

  final List<BrainFile> allResults;

  final List<BrainFile> topResults;

  final List<BrainFile> concepts;

  final List<BrainFile> questions;

  final List<BrainFile> examples;

  final List<BrainFile> warnings;

  // ============================================================
  // FONTES DO CONHECIMENTO
  // ============================================================

  final List<BrainSource> relatedSources;

  final List<BrainSource> mostFrequentSources;

  // Quantidade de notas, dentro da resposta, que referenciam cada
  // BrainSource.contentKey.
  final Map<String, int> sourceOccurrences;

  // ============================================================
  // COUNTS
  // ============================================================

  int get total {
    return allResults.length;
  }

  int get topCount {
    return topResults.length;
  }

  int get conceptCount {
    return concepts.length;
  }

  int get questionCount {
    return questions.length;
  }

  int get exampleCount {
    return examples.length;
  }

  int get warningCount {
    return warnings.length;
  }

  int get sourceCount {
    return relatedSources.length;
  }

  // ============================================================
  // STATES
  // ============================================================

  bool get isEmpty {
    return allResults.isEmpty;
  }

  bool get isNotEmpty {
    return allResults.isNotEmpty;
  }

  bool get hasMoreResults {
    return total > topCount;
  }

  bool get hasConcepts {
    return concepts.isNotEmpty;
  }

  bool get hasQuestions {
    return questions.isNotEmpty;
  }

  bool get hasExamples {
    return examples.isNotEmpty;
  }

  bool get hasWarnings {
    return warnings.isNotEmpty;
  }

  bool get hasSources {
    return relatedSources.isNotEmpty;
  }

  bool get hasFrequentSources {
    return mostFrequentSources.isNotEmpty;
  }

  // ============================================================
  // SOURCE HELPERS
  // ============================================================

  int occurrenceCountForSource(BrainSource source) {
    return sourceOccurrences[source.contentKey] ?? 0;
  }

  int occurrenceCountForSourceKey(String contentKey) {
    return sourceOccurrences[contentKey.trim()] ?? 0;
  }

  bool isRecurringSource(BrainSource source) {
    return occurrenceCountForSource(source) > 1;
  }

  List<BrainSource> frequentSources({int minimumOccurrences = 2, int? limit}) {
    final minimum = minimumOccurrences < 1 ? 1 : minimumOccurrences;

    final filtered = mostFrequentSources.where((source) {
      return occurrenceCountForSource(source) >= minimum;
    });

    if (limit == null) {
      return List<BrainSource>.unmodifiable(filtered);
    }

    final normalizedLimit = limit < 0 ? 0 : limit;

    return List<BrainSource>.unmodifiable(filtered.take(normalizedLimit));
  }

  // ============================================================
  // SUMMARY
  // ============================================================
  //
  // Texto simples e determinístico para a UI.
  //
  // Exemplos:
  //
  // "1 resultado encontrado"
  // "12 resultados encontrados"
  //
  // ============================================================

  String get resultLabel {
    if (total == 1) {
      return '1 resultado encontrado';
    }

    return '$total resultados encontrados';
  }

  String get sourceLabel {
    if (sourceCount == 1) {
      return '1 fonte relacionada';
    }

    return '$sourceCount fontes relacionadas';
  }

  // ============================================================
  // GROUP SUMMARY
  // ============================================================
  //
  // Produz somente grupos que realmente possuem resultados.
  //
  // Exemplo:
  //
  // [
  //   "5 conceitos",
  //   "3 perguntas",
  //   "2 exemplos",
  //   "4 fontes",
  // ]
  //
  // ============================================================

  List<String> get groupSummary {
    final items = <String>[];

    if (conceptCount > 0) {
      items.add(
        _countLabel(conceptCount, singular: 'conceito', plural: 'conceitos'),
      );
    }

    if (questionCount > 0) {
      items.add(
        _countLabel(questionCount, singular: 'pergunta', plural: 'perguntas'),
      );
    }

    if (exampleCount > 0) {
      items.add(
        _countLabel(exampleCount, singular: 'exemplo', plural: 'exemplos'),
      );
    }

    if (warningCount > 0) {
      items.add(
        _countLabel(warningCount, singular: 'atenção', plural: 'atenções'),
      );
    }

    if (sourceCount > 0) {
      items.add(_countLabel(sourceCount, singular: 'fonte', plural: 'fontes'));
    }

    return List<String>.unmodifiable(items);
  }

  // ============================================================
  // GROUP ACCESS
  // ============================================================

  List<BrainFile> resultsByType(BrainConceptType type) {
    switch (type) {
      case BrainConceptType.concept:
        return concepts;

      case BrainConceptType.question:
        return questions;

      case BrainConceptType.example:
        return examples;

      case BrainConceptType.warning:
        return warnings;
    }
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  BrainSearchResponse copyWith({
    List<BrainFile>? allResults,
    List<BrainFile>? topResults,
    List<BrainFile>? concepts,
    List<BrainFile>? questions,
    List<BrainFile>? examples,
    List<BrainFile>? warnings,
    List<BrainSource>? relatedSources,
    List<BrainSource>? mostFrequentSources,
    Map<String, int>? sourceOccurrences,
  }) {
    return BrainSearchResponse(
      allResults: allResults ?? this.allResults,
      topResults: topResults ?? this.topResults,
      concepts: concepts ?? this.concepts,
      questions: questions ?? this.questions,
      examples: examples ?? this.examples,
      warnings: warnings ?? this.warnings,
      relatedSources: relatedSources ?? this.relatedSources,
      mostFrequentSources: mostFrequentSources ?? this.mostFrequentSources,
      sourceOccurrences: sourceOccurrences ?? this.sourceOccurrences,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static bool _containsType(BrainFile note, BrainConceptType type) {
    return note.concepts.any((concept) {
      return concept.type == type;
    });
  }

  static String _countLabel(
    int value, {
    required String singular,
    required String plural,
  }) {
    if (value == 1) {
      return '1 $singular';
    }

    return '$value $plural';
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'BrainSearchResponse('
        'total: $total, '
        'topCount: $topCount, '
        'conceptCount: $conceptCount, '
        'questionCount: $questionCount, '
        'exampleCount: $exampleCount, '
        'warningCount: $warningCount, '
        'sourceCount: $sourceCount'
        ')';
  }
}
