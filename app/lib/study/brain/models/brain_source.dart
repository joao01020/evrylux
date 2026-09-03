// ============================================================
// BRAIN SOURCE TYPE
// ============================================================
//
// Tipos de fonte suportados inicialmente pela Fase 13.
//
// A fonte é apenas contexto de origem do conhecimento.
//
// Ela NÃO:
// - organiza o conhecimento;
// - substitui a anotação;
// - é obrigatória.
//
// ============================================================

enum BrainSourceType { url, book, pdf, file, video, lesson, other }

// ============================================================
// BRAIN SOURCE TYPE EXTENSION
// ============================================================

extension BrainSourceTypeX on BrainSourceType {
  // ============================================================
  // LABEL
  // ============================================================

  String get label {
    switch (this) {
      case BrainSourceType.url:
        return 'URL';

      case BrainSourceType.book:
        return 'Livro';

      case BrainSourceType.pdf:
        return 'PDF';

      case BrainSourceType.file:
        return 'Arquivo';

      case BrainSourceType.video:
        return 'Vídeo';

      case BrainSourceType.lesson:
        return 'Aula';

      case BrainSourceType.other:
        return 'Outro';
    }
  }

  // ============================================================
  // VALUE
  // ============================================================

  String get value {
    return name;
  }

  // ============================================================
  // FROM VALUE
  // ============================================================

  static BrainSourceType fromValue(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';

    for (final type in BrainSourceType.values) {
      if (type.name == normalized) {
        return type;
      }
    }

    return BrainSourceType.other;
  }
}

// ============================================================
// BRAIN SOURCE
// ============================================================
//
// Representa uma fonte associada a um conhecimento.
//
// Exemplos:
//
// URL:
// BrainSource(
//   id: '...',
//   type: BrainSourceType.url,
//   title: 'cppreference - Pointers',
//   reference: 'https://...',
// )
//
// Livro:
// BrainSource(
//   id: '...',
//   type: BrainSourceType.book,
//   title: 'Effective C++',
//   reference: 'Capítulo 3',
//   author: 'Scott Meyers',
// )
//
// PDF:
// BrainSource(
//   id: '...',
//   type: BrainSourceType.pdf,
//   title: 'Arquitetura de Software',
//   reference: 'arquitetura_software.pdf',
// )
//
// ============================================================

class BrainSource {
  const BrainSource({
    required this.id,
    required this.type,
    required this.title,
    required this.reference,
    this.author,
    this.publishedAt,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  // ============================================================
  // DATA
  // ============================================================

  final String id;

  final BrainSourceType type;

  final String title;

  final String reference;

  final String? author;

  final DateTime? publishedAt;

  final String? note;

  final DateTime createdAt;

  final DateTime updatedAt;

  // ============================================================
  // FACTORY
  // ============================================================

  factory BrainSource.create({
    required BrainSourceType type,
    required String title,
    required String reference,
    String? author,
    DateTime? publishedAt,
    String? note,
    DateTime? now,
    String? id,
  }) {
    final timestamp = (now ?? DateTime.now()).toLocal();

    return BrainSource(
      id: id ?? timestamp.microsecondsSinceEpoch.toString(),
      type: type,
      title: title.trim(),
      reference: reference.trim(),
      author: _normalizeNullableText(author),
      publishedAt: publishedAt?.toLocal(),
      note: _normalizeNullableText(note),
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  // ============================================================
  // GETTERS
  // ============================================================

  bool get hasAuthor {
    return author?.trim().isNotEmpty ?? false;
  }

  bool get hasPublishedAt {
    return publishedAt != null;
  }

  bool get hasNote {
    return note?.trim().isNotEmpty ?? false;
  }

  bool get isUrl {
    return type == BrainSourceType.url;
  }

  bool get isBook {
    return type == BrainSourceType.book;
  }

  bool get isPdf {
    return type == BrainSourceType.pdf;
  }

  bool get isFile {
    return type == BrainSourceType.file;
  }

  bool get isVideo {
    return type == BrainSourceType.video;
  }

  bool get isLesson {
    return type == BrainSourceType.lesson;
  }

  bool get isOther {
    return type == BrainSourceType.other;
  }

  String get normalizedTitle {
    return title.trim();
  }

  String get normalizedReference {
    return reference.trim();
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool get isValid {
    return id.trim().isNotEmpty &&
        title.trim().isNotEmpty &&
        reference.trim().isNotEmpty;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  BrainSource copyWith({
    String? id,
    BrainSourceType? type,
    String? title,
    String? reference,
    String? author,
    bool clearAuthor = false,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    String? note,
    bool clearNote = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrainSource(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      reference: reference ?? this.reference,
      author: clearAuthor ? null : author ?? this.author,
      publishedAt: clearPublishedAt ? null : publishedAt ?? this.publishedAt,
      note: clearNote ? null : note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // TOUCH
  // ============================================================

  BrainSource touch({DateTime? now}) {
    return copyWith(updatedAt: (now ?? DateTime.now()).toLocal());
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'reference': reference,
      'author': author,
      'published_at': publishedAt?.toUtc().toIso8601String(),
      'note': note,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // FROM MAP
  // ============================================================

  factory BrainSource.fromMap(Map<String, dynamic> map) {
    final now = DateTime.now().toLocal();

    final createdAt = _parseDate(map['created_at']) ?? now;

    final updatedAt = _parseDate(map['updated_at']) ?? createdAt;

    return BrainSource(
      id: map['id']?.toString().trim() ?? '',
      type: BrainSourceTypeX.fromValue(map['type']?.toString()),
      title: map['title']?.toString().trim() ?? '',
      reference: map['reference']?.toString().trim() ?? '',
      author: _normalizeNullableText(map['author']?.toString()),
      publishedAt: _parseDate(map['published_at']),
      note: _normalizeNullableText(map['note']?.toString()),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return toMap();
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory BrainSource.fromJson(Map<String, dynamic> json) {
    return BrainSource.fromMap(json);
  }

  // ============================================================
  // EQUALITY KEY
  // ============================================================
  //
  // Útil para evitar duplicação visual da mesma fonte.
  //
  // Não substitui o id.
  //
  // ============================================================

  String get contentKey {
    return '${type.value}|'
        '${title.trim().toLowerCase()}|'
        '${reference.trim().toLowerCase()}';
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static String? _normalizeNullableText(String? value) {
    final normalized = value?.trim();

    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is DateTime) {
      return value.toLocal();
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return DateTime.tryParse(text)?.toLocal();
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return 'BrainSource('
        'id: $id, '
        'type: $type, '
        'title: $title, '
        'reference: $reference, '
        'author: $author, '
        'publishedAt: $publishedAt, '
        'note: $note, '
        'createdAt: $createdAt, '
        'updatedAt: $updatedAt'
        ')';
  }
}
