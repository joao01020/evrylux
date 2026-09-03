import 'brain_concept.dart';
import 'brain_source.dart';

// ============================================================
// BRAIN FILE
// ============================================================
//
// Representa uma anotação salva no Cérebro.
//
// createdAt:
// - data original de criação;
// - usada para posicionar a anotação no calendário.
//
// updatedAt:
// - última edição da anotação.
//
// sources:
// - fontes associadas ao conhecimento;
// - opcional;
// - notas antigas continuam funcionando com lista vazia.
//
// Compatibilidade:
//
// createdAt é opcional no construtor.
// Se não for informado, usamos updatedAt.
//
// sources é opcional no construtor.
// Se não for informado, usamos lista vazia.
//
// ============================================================

class BrainFile {
  const BrainFile({
    required this.topic,
    required this.title,
    required this.path,
    required this.content,
    required this.concepts,
    this.sources = const <BrainSource>[],
    DateTime? createdAt,
    required this.updatedAt,
  }) : createdAt = createdAt ?? updatedAt;

  // ============================================================
  // DATA
  // ============================================================

  final String topic;

  final String title;

  final String path;

  final String content;

  /// Conhecimentos extraídos desta anotação.
  final List<BrainConcept> concepts;

  /// Fontes associadas a esta anotação.
  ///
  /// FASE 13 — FONTES DO CONHECIMENTO
  ///
  /// A fonte é opcional e apenas preserva a origem/contexto
  /// do conhecimento.
  final List<BrainSource> sources;

  /// Data original de criação.
  ///
  /// Essa é a data usada pelo calendário.
  final DateTime createdAt;

  /// Última atualização da anotação.
  final DateTime updatedAt;

  // ============================================================
  // COPY
  // ============================================================

  BrainFile copyWith({
    String? topic,
    String? title,
    String? path,
    String? content,
    List<BrainConcept>? concepts,
    List<BrainSource>? sources,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrainFile(
      topic: topic ?? this.topic,
      title: title ?? this.title,
      path: path ?? this.path,
      content: content ?? this.content,
      concepts: concepts ?? this.concepts,
      sources: sources ?? this.sources,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // BASIC INFO
  // ============================================================

  bool get hasConcepts {
    return concepts.isNotEmpty;
  }

  int get conceptsCount {
    return concepts.length;
  }

  bool get hasSources {
    return sources.isNotEmpty;
  }

  int get sourcesCount {
    return sources.length;
  }

  bool get hasTopic {
    return topic.trim().isNotEmpty;
  }

  bool get hasTitle {
    return title.trim().isNotEmpty;
  }

  bool get hasContent {
    return content.trim().isNotEmpty;
  }

  // ============================================================
  // DATE HELPERS
  // ============================================================

  bool wasCreatedOn(DateTime date) {
    final created = createdAt.toLocal();

    final target = date.toLocal();

    return created.year == target.year &&
        created.month == target.month &&
        created.day == target.day;
  }

  bool wasUpdatedOn(DateTime date) {
    final updated = updatedAt.toLocal();

    final target = date.toLocal();

    return updated.year == target.year &&
        updated.month == target.month &&
        updated.day == target.day;
  }

  // ============================================================
  // CONCEITOS
  // ============================================================

  List<BrainConcept> get conceptItems {
    return concepts.where((concept) {
      return concept.type == BrainConceptType.concept;
    }).toList();
  }

  int get conceptCount {
    return conceptItems.length;
  }

  // ============================================================
  // PERGUNTAS
  // ============================================================

  List<BrainConcept> get questionItems {
    return concepts.where((concept) {
      return concept.type == BrainConceptType.question;
    }).toList();
  }

  int get questionCount {
    return questionItems.length;
  }

  // ============================================================
  // EXEMPLOS
  // ============================================================

  List<BrainConcept> get exampleItems {
    return concepts.where((concept) {
      return concept.type == BrainConceptType.example;
    }).toList();
  }

  int get exampleCount {
    return exampleItems.length;
  }

  // ============================================================
  // ATENÇÕES
  // ============================================================

  List<BrainConcept> get warningItems {
    return concepts.where((concept) {
      return concept.type == BrainConceptType.warning;
    }).toList();
  }

  int get warningCount {
    return warningItems.length;
  }

  // ============================================================
  // FILTER BY TYPE
  // ============================================================

  List<BrainConcept> conceptsByType(BrainConceptType type) {
    return concepts.where((concept) {
      return concept.type == type;
    }).toList();
  }

  // ============================================================
  // HAS TYPE
  // ============================================================

  bool hasConceptType(BrainConceptType type) {
    return concepts.any((concept) {
      return concept.type == type;
    });
  }

  // ============================================================
  // TOTAL BY TYPE
  // ============================================================

  int countByType(BrainConceptType type) {
    return concepts.where((concept) {
      return concept.type == type;
    }).length;
  }

  // ============================================================
  // SOURCES BY TYPE
  // ============================================================

  List<BrainSource> sourcesByType(BrainSourceType type) {
    return sources.where((source) {
      return source.type == type;
    }).toList();
  }

  // ============================================================
  // HAS SOURCE TYPE
  // ============================================================

  bool hasSourceType(BrainSourceType type) {
    return sources.any((source) {
      return source.type == type;
    });
  }

  // ============================================================
  // SOURCE BY ID
  // ============================================================

  BrainSource? sourceById(String id) {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return null;
    }

    for (final source in sources) {
      if (source.id.trim() == normalizedId) {
        return source;
      }
    }

    return null;
  }

  // ============================================================
  // HAS SOURCE ID
  // ============================================================

  bool hasSourceId(String id) {
    return sourceById(id) != null;
  }

  // ============================================================
  // ADD SOURCE
  // ============================================================
  //
  // Retorna uma nova instância de BrainFile.
  //
  // A fonte não é adicionada novamente se já existir outra com
  // o mesmo id ou contentKey.
  //
  // ============================================================

  BrainFile addSource(BrainSource source, {DateTime? now}) {
    final duplicated = sources.any((item) {
      return item.id == source.id || item.contentKey == source.contentKey;
    });

    if (duplicated) {
      return this;
    }

    return copyWith(
      sources: [...sources, source],
      updatedAt: (now ?? DateTime.now()).toLocal(),
    );
  }

  // ============================================================
  // UPDATE SOURCE
  // ============================================================

  BrainFile updateSource(BrainSource source, {DateTime? now}) {
    final index = sources.indexWhere((item) {
      return item.id == source.id;
    });

    if (index < 0) {
      return this;
    }

    final updatedSources = [...sources];

    updatedSources[index] = source;

    return copyWith(
      sources: updatedSources,
      updatedAt: (now ?? DateTime.now()).toLocal(),
    );
  }

  // ============================================================
  // REMOVE SOURCE
  // ============================================================

  BrainFile removeSourceById(String id, {DateTime? now}) {
    final normalizedId = id.trim();

    if (normalizedId.isEmpty) {
      return this;
    }

    final updatedSources = sources.where((source) {
      return source.id.trim() != normalizedId;
    }).toList();

    if (updatedSources.length == sources.length) {
      return this;
    }

    return copyWith(
      sources: updatedSources,
      updatedAt: (now ?? DateTime.now()).toLocal(),
    );
  }

  // ============================================================
  // CLEAR SOURCES
  // ============================================================

  BrainFile clearSources({DateTime? now}) {
    if (sources.isEmpty) {
      return this;
    }

    return copyWith(
      sources: const <BrainSource>[],
      updatedAt: (now ?? DateTime.now()).toLocal(),
    );
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return 'BrainFile('
        'topic: $topic, '
        'title: $title, '
        'path: $path, '
        'concepts: ${concepts.length}, '
        'sources: ${sources.length}, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
