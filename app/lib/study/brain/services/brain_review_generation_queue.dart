import '../models/brain_concept.dart';
import '../models/brain_review_item.dart';

/// Candidato determinístico para geração futura de exercícios de revisão.
///
/// A fila não precisa ser persistida separadamente: ela é reconstruída a partir
/// de `BrainConcept.reviewEnabled` (persistente) e das revisões já existentes.
class BrainReviewGenerationCandidate {
  const BrainReviewGenerationCandidate({required this.concept});

  final BrainConcept concept;

  String get conceptId => concept.id;
  String get title => concept.title;
  String get knowledge => concept.description;
}

class BrainReviewGenerationQueue {
  const BrainReviewGenerationQueue();

  List<BrainReviewGenerationCandidate> build({
    required Iterable<BrainConcept> concepts,
    required Iterable<BrainReviewItem> reviews,
  }) {
    final conceptIdsWithActiveReview = reviews
        .where((review) => !review.archived)
        .map((review) => review.conceptId)
        .toSet();

    final seenConceptIds = <String>{};
    final result = <BrainReviewGenerationCandidate>[];

    for (final concept in concepts) {
      if (!_isEligible(concept)) {
        continue;
      }

      if (!seenConceptIds.add(concept.id)) {
        continue;
      }

      if (conceptIdsWithActiveReview.contains(concept.id)) {
        continue;
      }

      result.add(BrainReviewGenerationCandidate(concept: concept));
    }

    return List<BrainReviewGenerationCandidate>.unmodifiable(result);
  }

  bool _isEligible(BrainConcept concept) {
    if (concept.type != BrainConceptType.concept) {
      return false;
    }

    if (!concept.reviewEnabled) {
      return false;
    }

    if (concept.title.trim().isEmpty || concept.description.trim().isEmpty) {
      return false;
    }

    return true;
  }
}
