enum BrainGeneratedReviewQuestionKind {
  recall,
  explanation,
  application,
}

/// Questão gerada a partir de um conhecimento marcado para revisão.
///
/// Nesta fase ela ainda é um rascunho de geração e não substitui
/// [BrainReviewItem]. Isso mantém Perguntas manuais e Revisões automáticas
/// como conceitos separados.
class BrainGeneratedReviewQuestion {
  const BrainGeneratedReviewQuestion({
    required this.id,
    required this.sourceConceptId,
    required this.kind,
    required this.question,
    required this.answer,
  });

  final String id;
  final String sourceConceptId;
  final BrainGeneratedReviewQuestionKind kind;
  final String question;
  final String answer;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'sourceConceptId': sourceConceptId,
    'kind': kind.name,
    'question': question,
    'answer': answer,
  };
}
