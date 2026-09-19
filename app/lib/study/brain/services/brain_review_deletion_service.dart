import '../controllers/review_controller.dart';
import '../models/brain_review_item.dart';
import '../repositories/brain_repository.dart';

// ============================================================
// BRAIN REVIEW DELETION SERVICE
// ============================================================
//
// Regra atual:
//
// - excluir uma pergunta/revisão NÃO apaga o conhecimento de origem;
// - excluir o conhecimento pelo módulo Brain pode remover as revisões
//   vinculadas a ele.
//
// O método deleteReviewAndSource foi mantido apenas por compatibilidade
// com chamadas antigas que realmente desejem apagar a origem.
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
  // DELETE REVIEW ONLY
  // ============================================================

  Future<void> deleteReviewOnly(BrainReviewItem review) async {
    await _reviewController.deleteReview(review);

    final error = _reviewController.errorMessage;

    if (error != null) {
      throw StateError(error);
    }
  }

  // ============================================================
  // DELETE MANY REVIEWS ONLY
  // ============================================================

  Future<void> deleteReviewsOnly(Iterable<BrainReviewItem> reviews) async {
    for (final review in reviews) {
      await deleteReviewOnly(review);
    }
  }

  // ============================================================
  // DELETE REVIEW + SOURCE
  // ============================================================
  //
  // Compatibilidade com fluxos antigos. NÃO usar na tela Revisar
  // quando o usuário estiver apenas excluindo uma pergunta.
  //
  // ============================================================

  Future<void> deleteReviewAndSource(BrainReviewItem review) async {
    final sourceNotePath = review.sourceNotePath.trim();
    final conceptId = review.conceptId.trim();

    if (sourceNotePath.isNotEmpty) {
      await _brainRepository.deleteConceptsByNoteId(sourceNotePath);
      await _brainRepository.deleteNote(sourceNotePath);
    } else if (conceptId.isNotEmpty) {
      await _brainRepository.deleteConceptAndSourceNote(conceptId);
    }

    await _reviewController.deleteReview(review);

    final error = _reviewController.errorMessage;

    if (error != null) {
      throw StateError(error);
    }
  }
}
