import '../../models/brain_review_item.dart';

// ============================================================
// BRAIN REVIEW VAULT MAPPER
// ============================================================
//
// Faz a ponte entre:
//
// BrainReviewItem
//      ↓
// Map<String, dynamic>
//      ↓
// BrainVaultService
//
// e:
//
// BrainVaultDecodedPayload.data
//      ↓
// BrainReviewItem
//
// IMPORTANTE:
//
// question / answer / sourceNotePath / sourceNoteTitle ficam
// dentro do payload criptografado.
//
// Portanto não aparecem em plaintext no .evobj.
//
// ============================================================

class BrainReviewVaultMapper {
  const BrainReviewVaultMapper();

  // ============================================================
  // MODEL VERSION
  // ============================================================

  static const int modelVersion = 1;

  // ============================================================
  // TO VAULT DATA
  // ============================================================

  Map<
    String,
    dynamic
  >
  toVaultData(
    BrainReviewItem review,
  ) {
    return {
      'model': 'brain_review',
      'model_version': modelVersion,

      // ========================================================
      // IDS
      // ========================================================
      'id': review.id,

      'concept_id': review.conceptId,

      // ========================================================
      // SENSITIVE CONTENT
      // ========================================================
      //
      // Todos estes campos ficarão criptografados pelo Vault.
      //
      // ========================================================
      'question': review.question,

      'answer': review.answer,

      // ========================================================
      // LEGACY SOURCE RELATION
      // ========================================================
      //
      // sourceNotePath será substituído posteriormente por um
      // objectId estável.
      //
      // Por enquanto mantemos compatibilidade com o sistema
      // existente.
      //
      // ========================================================
      'source_note_path': review.sourceNotePath,

      'source_note_title': review.sourceNoteTitle,

      // ========================================================
      // DATES
      // ========================================================
      'created_at': review.createdAt.toUtc().toIso8601String(),

      'next_review_at': review.nextReviewAt.toUtc().toIso8601String(),

      'last_reviewed_at': review.lastReviewedAt?.toUtc().toIso8601String(),

      'archived_at': review.archivedAt?.toUtc().toIso8601String(),

      // ========================================================
      // REVIEW STATE
      // ========================================================
      'review_count': review.reviewCount,

      'correct_count': review.correctCount,

      'wrong_count': review.wrongCount,

      'streak': review.streak,

      'archived': review.archived,
    };
  }

  // ============================================================
  // FROM VAULT DATA
  // ============================================================

  BrainReviewItem fromVaultData(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    _validateModel(
      data,
    );

    final id = _parseRequiredString(
      data['id'],
      fieldName: 'id',
    );

    final conceptId = _parseRequiredString(
      data['concept_id'],
      fieldName: 'concept_id',
    );

    final question = _parseString(
      data['question'],
    );

    final answer = _parseString(
      data['answer'],
    );

    final sourceNotePath = _parseString(
      data['source_note_path'],
    );

    final sourceNoteTitle = _parseString(
      data['source_note_title'],
    );

    final createdAt = _parseRequiredDate(
      data['created_at'],
      fieldName: 'created_at',
    );

    final nextReviewAt = _parseRequiredDate(
      data['next_review_at'],
      fieldName: 'next_review_at',
    );

    final lastReviewedAt = _parseOptionalDate(
      data['last_reviewed_at'],
      fieldName: 'last_reviewed_at',
    );

    final archivedAt = _parseOptionalDate(
      data['archived_at'],
      fieldName: 'archived_at',
    );

    final reviewCount = _parseNonNegativeInt(
      data['review_count'],
      fieldName: 'review_count',
    );

    final correctCount = _parseNonNegativeInt(
      data['correct_count'],
      fieldName: 'correct_count',
    );

    final wrongCount = _parseNonNegativeInt(
      data['wrong_count'],
      fieldName: 'wrong_count',
    );

    final streak = _parseNonNegativeInt(
      data['streak'],
      fieldName: 'streak',
    );

    final archived = _parseBool(
      data['archived'],
    );

    return BrainReviewItem(
      id: id,

      conceptId: conceptId,

      question: question,

      answer: answer,

      sourceNotePath: sourceNotePath,

      sourceNoteTitle: sourceNoteTitle,

      createdAt: createdAt,

      nextReviewAt: nextReviewAt,

      lastReviewedAt: lastReviewedAt,

      archivedAt: archivedAt,

      reviewCount: reviewCount,

      correctCount: correctCount,

      wrongCount: wrongCount,

      streak: streak,

      archived: archived,
    );
  }

  // ============================================================
  // VALIDATE MODEL
  // ============================================================

  void _validateModel(
    Map<
      String,
      dynamic
    >
    data,
  ) {
    final model = _parseString(
      data['model'],
    );

    if (model !=
        'brain_review') {
      throw FormatException(
        'Payload não representa BrainReviewItem: $model',
      );
    }

    final version = _parseInt(
      data['model_version'],
      fieldName: 'model_version',
    );

    if (version !=
        modelVersion) {
      throw FormatException(
        'Versão de BrainReviewItem não suportada: $version',
      );
    }
  }

  // ============================================================
  // PARSE STRING
  // ============================================================

  String _parseString(
    dynamic value,
  ) {
    return value?.toString() ??
        '';
  }

  // ============================================================
  // REQUIRED STRING
  // ============================================================

  String _parseRequiredString(
    dynamic value, {
    required String fieldName,
  }) {
    final parsed =
        value?.toString().trim() ??
        '';

    if (parsed.isEmpty) {
      throw FormatException(
        '$fieldName não pode estar vazio no BrainReviewItem.',
      );
    }

    return parsed;
  }

  // ============================================================
  // PARSE INT
  // ============================================================

  int _parseInt(
    dynamic value, {
    required String fieldName,
  }) {
    if (value
        is int) {
      return value;
    }

    final parsed = int.tryParse(
      value?.toString().trim() ??
          '',
    );

    if (parsed ==
        null) {
      throw FormatException(
        '$fieldName inválido no BrainReviewItem.',
      );
    }

    return parsed;
  }

  // ============================================================
  // NON NEGATIVE INT
  // ============================================================

  int _parseNonNegativeInt(
    dynamic value, {
    required String fieldName,
  }) {
    final parsed = _parseInt(
      value,
      fieldName: fieldName,
    );

    if (parsed <
        0) {
      throw FormatException(
        '$fieldName não pode ser negativo no BrainReviewItem.',
      );
    }

    return parsed;
  }

  // ============================================================
  // BOOL
  // ============================================================

  bool _parseBool(
    dynamic value,
  ) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is int) {
      return value ==
          1;
    }

    final normalized = value?.toString().trim().toLowerCase();

    return normalized ==
            'true' ||
        normalized ==
            '1';
  }

  // ============================================================
  // REQUIRED DATE
  // ============================================================

  DateTime _parseRequiredDate(
    dynamic value, {
    required String fieldName,
  }) {
    final parsed = DateTime.tryParse(
      value?.toString().trim() ??
          '',
    );

    if (parsed ==
        null) {
      throw FormatException(
        '$fieldName inválido no BrainReviewItem.',
      );
    }

    return parsed.toLocal();
  }

  // ============================================================
  // OPTIONAL DATE
  // ============================================================

  DateTime? _parseOptionalDate(
    dynamic value, {
    required String fieldName,
  }) {
    if (value ==
        null) {
      return null;
    }

    final raw = value.toString().trim();

    if (raw.isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(
      raw,
    );

    if (parsed ==
        null) {
      throw FormatException(
        '$fieldName inválido no BrainReviewItem.',
      );
    }

    return parsed.toLocal();
  }
}
