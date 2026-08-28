class BrainReviewItem {
  // ============================================================
  // IDENTIFICAÇÃO
  // ============================================================

  final String id;

  /// ID do BrainConcept original.
  final String conceptId;

  // ============================================================
  // CONTEÚDO
  // ============================================================

  final String question;

  final String answer;

  // ============================================================
  // ORIGEM
  // ============================================================

  final String sourceNotePath;

  final String sourceNoteTitle;

  // ============================================================
  // DATAS
  // ============================================================

  final DateTime createdAt;

  final DateTime nextReviewAt;

  final DateTime? lastReviewedAt;

  final DateTime? archivedAt;

  // ============================================================
  // ESTATÍSTICAS
  // ============================================================

  final int reviewCount;

  final int correctCount;

  final int wrongCount;

  /// Quantidade de acertos consecutivos.
  final int streak;

  // ============================================================
  // STATUS
  // ============================================================

  final bool archived;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const BrainReviewItem({
    required this.id,
    required this.conceptId,
    required this.question,
    required this.answer,
    required this.sourceNotePath,
    required this.sourceNoteTitle,
    required this.createdAt,
    required this.nextReviewAt,
    required this.reviewCount,
    required this.correctCount,
    required this.wrongCount,
    required this.streak,
    required this.archived,
    required this.archivedAt,
    required this.lastReviewedAt,
  });

  // ============================================================
  // COPY WITH
  // ============================================================

  BrainReviewItem copyWith({
    String? id,
    String? conceptId,
    String? question,
    String? answer,
    String? sourceNotePath,
    String? sourceNoteTitle,
    DateTime? createdAt,
    DateTime? nextReviewAt,
    int? reviewCount,
    int? correctCount,
    int? wrongCount,
    int? streak,
    bool? archived,
    DateTime? archivedAt,
    DateTime? lastReviewedAt,
    bool clearArchivedAt = false,
    bool clearLastReviewedAt = false,
  }) {
    return BrainReviewItem(
      id:
          id ??
          this.id,

      conceptId:
          conceptId ??
          this.conceptId,

      question:
          question ??
          this.question,

      answer:
          answer ??
          this.answer,

      sourceNotePath:
          sourceNotePath ??
          this.sourceNotePath,

      sourceNoteTitle:
          sourceNoteTitle ??
          this.sourceNoteTitle,

      createdAt:
          createdAt ??
          this.createdAt,

      nextReviewAt:
          nextReviewAt ??
          this.nextReviewAt,

      reviewCount:
          reviewCount ??
          this.reviewCount,

      correctCount:
          correctCount ??
          this.correctCount,

      wrongCount:
          wrongCount ??
          this.wrongCount,

      streak:
          streak ??
          this.streak,

      archived:
          archived ??
          this.archived,

      archivedAt: clearArchivedAt
          ? null
          : archivedAt ??
                this.archivedAt,

      lastReviewedAt: clearLastReviewedAt
          ? null
          : lastReviewedAt ??
                this.lastReviewedAt,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isDue {
    if (archived) {
      return false;
    }

    return !nextReviewAt.isAfter(
      DateTime.now(),
    );
  }

  bool get isUpcoming {
    if (archived) {
      return false;
    }

    return nextReviewAt.isAfter(
      DateTime.now(),
    );
  }

  bool get hasBeenReviewed {
    return reviewCount >
        0;
  }

  bool get hasCorrectAnswers {
    return correctCount >
        0;
  }

  bool get hasWrongAnswers {
    return wrongCount >
        0;
  }

  double get successRate {
    if (reviewCount <=
        0) {
      return 0;
    }

    return correctCount /
        reviewCount;
  }

  int get successPercentage {
    return (successRate *
            100)
        .round();
  }

  Duration get timeUntilNextReview {
    final difference = nextReviewAt.difference(
      DateTime.now(),
    );

    if (difference.isNegative) {
      return Duration.zero;
    }

    return difference;
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return {
      'id': id,

      'conceptId': conceptId,

      'question': question,

      'answer': answer,

      'sourceNotePath': sourceNotePath,

      'sourceNoteTitle': sourceNoteTitle,

      'createdAt': createdAt.toIso8601String(),

      'nextReviewAt': nextReviewAt.toIso8601String(),

      'lastReviewedAt': lastReviewedAt?.toIso8601String(),

      'archivedAt': archivedAt?.toIso8601String(),

      'reviewCount': reviewCount,

      'correctCount': correctCount,

      'wrongCount': wrongCount,

      'streak': streak,

      'archived': archived,
    };
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory BrainReviewItem.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return BrainReviewItem(
      id:
          json['id']?.toString().trim() ??
          '',

      conceptId:
          json['conceptId']?.toString().trim() ??
          '',

      question:
          json['question']?.toString().trim() ??
          '',

      answer:
          json['answer']?.toString().trim() ??
          '',

      sourceNotePath:
          json['sourceNotePath']?.toString().trim() ??
          '',

      sourceNoteTitle:
          json['sourceNoteTitle']?.toString().trim() ??
          '',

      createdAt:
          _parseDate(
            json['createdAt'],
          ) ??
          DateTime.now(),

      nextReviewAt:
          _parseDate(
            json['nextReviewAt'],
          ) ??
          DateTime.now(),

      lastReviewedAt: _parseDate(
        json['lastReviewedAt'],
      ),

      archivedAt: _parseDate(
        json['archivedAt'],
      ),

      reviewCount: _parseInt(
        json['reviewCount'],
      ),

      correctCount: _parseInt(
        json['correctCount'],
      ),

      wrongCount: _parseInt(
        json['wrongCount'],
      ),

      streak: _parseInt(
        json['streak'],
      ),

      archived: _parseBool(
        json['archived'],
      ),
    );
  }

  // ============================================================
  // PARSE DATE
  // ============================================================

  static DateTime? _parseDate(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() ==
            'null') {
      return null;
    }

    return DateTime.tryParse(
      text,
    );
  }

  // ============================================================
  // PARSE INT
  // ============================================================

  static int _parseInt(
    dynamic value,
  ) {
    if (value
        is int) {
      return value;
    }

    return int.tryParse(
          value?.toString().trim() ??
              '',
        ) ??
        0;
  }

  // ============================================================
  // PARSE BOOL
  // ============================================================

  static bool _parseBool(
    dynamic value,
  ) {
    if (value
        is bool) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase();

    return normalized ==
            'true' ||
        normalized ==
            '1';
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is BrainReviewItem &&
        other.id ==
            id &&
        other.conceptId ==
            conceptId &&
        other.question ==
            question &&
        other.answer ==
            answer &&
        other.sourceNotePath ==
            sourceNotePath &&
        other.sourceNoteTitle ==
            sourceNoteTitle &&
        other.createdAt ==
            createdAt &&
        other.nextReviewAt ==
            nextReviewAt &&
        other.lastReviewedAt ==
            lastReviewedAt &&
        other.archivedAt ==
            archivedAt &&
        other.reviewCount ==
            reviewCount &&
        other.correctCount ==
            correctCount &&
        other.wrongCount ==
            wrongCount &&
        other.streak ==
            streak &&
        other.archived ==
            archived;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      conceptId,
      question,
      answer,
      sourceNotePath,
      sourceNoteTitle,
      createdAt,
      nextReviewAt,
      lastReviewedAt,
      archivedAt,
      reviewCount,
      correctCount,
      wrongCount,
      streak,
      archived,
    );
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return 'BrainReviewItem('
        'id: $id, '
        'conceptId: $conceptId, '
        'question: $question, '
        'nextReviewAt: $nextReviewAt, '
        'reviewCount: $reviewCount, '
        'correctCount: $correctCount, '
        'wrongCount: $wrongCount, '
        'streak: $streak, '
        'archived: $archived'
        ')';
  }
}
