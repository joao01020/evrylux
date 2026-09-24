enum BrainAiIntentType {
  normalSearch,
  knowledgeSummary,
  studyGaps,
  relatedKnowledge,
  reviewSuggestions,
  openQuestions,
}

class BrainAiIntent {
  const BrainAiIntent({
    required this.type,
    required this.rawQuery,
    this.topic,
  });

  final BrainAiIntentType type;
  final String rawQuery;
  final String? topic;

  bool get usesAi => type != BrainAiIntentType.normalSearch;

  String get wireName {
    switch (type) {
      case BrainAiIntentType.normalSearch:
        return 'normal_search';
      case BrainAiIntentType.knowledgeSummary:
        return 'knowledge_summary';
      case BrainAiIntentType.studyGaps:
        return 'study_gaps';
      case BrainAiIntentType.relatedKnowledge:
        return 'related_knowledge';
      case BrainAiIntentType.reviewSuggestions:
        return 'review_suggestions';
      case BrainAiIntentType.openQuestions:
        return 'open_questions';
    }
  }
}
