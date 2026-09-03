import '../controllers/review_controller.dart';
import '../models/brain_review_item.dart';
import '../repositories/brain_repository.dart';

// ============================================================
// BRAIN REVIEW DELETION SERVICE
// ============================================================
//
// FASE 10 — REVISÃO CONSOLIDADA
//
// Responsabilidade única:
//
// excluir uma revisão e, quando existir, também remover a origem
// correspondente no Cérebro.
//
// Fluxo:
//
// BrainReviewDeletionService
//        │
//        ├── BrainRepository
//        │     ├── remove conceitos da nota
//        │     └── remove a nota
//        │
//        └── ReviewController
//              └── remove a revisão
//
// A UI apenas confirma a ação e chama este serviço.
//
// ============================================================

class BrainReviewDeletionService {
  const BrainReviewDeletionService({
    required BrainRepository brainRepository,
    required ReviewController reviewController,
  }) : _brainRepository = brainRepository,
       _reviewController = reviewController;

  final BrainRepository _brainRepository;

  final ReviewController _reviewController;

  // ============================================================
  // DELETE REVIEW + SOURCE
  // ============================================================

  Future<void> deleteReviewAndSource(BrainReviewItem review) async {
    final sourceNotePath = review.sourceNotePath.trim();

    final conceptId = review.conceptId.trim();

    // ==========================================================
    // 1. REMOVER ORIGEM DO CÉREBRO
    // ==========================================================

    if (sourceNotePath.isNotEmpty) {
      await _brainRepository.deleteConceptsByNoteId(sourceNotePath);

      await _brainRepository.deleteNote(sourceNotePath);
    } else if (conceptId.isNotEmpty) {
      // Compatibilidade com revisões antigas que não possuem
      // sourceNotePath.
      await _brainRepository.deleteConceptAndSourceNote(conceptId);
    }

    // ==========================================================
    // 2. REMOVER REVISÃO
    // ==========================================================

    await _reviewController.deleteReview(review);

    final error = _reviewController.errorMessage;

    if (error != null) {
      throw StateError(error);
    }
  }
}
