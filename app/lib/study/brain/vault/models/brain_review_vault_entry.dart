import '../../models/brain_review_item.dart';

// ============================================================
// BRAIN REVIEW VAULT ENTRY
// ============================================================
//
// Representa a relação entre:
//
// objeto físico do Vault
//
// objectId
//
// e
//
// modelo lógico da aplicação
//
// BrainReviewItem
//
// ============================================================
//
// IMPORTANTE:
//
// BrainReviewItem.id
//
// NÃO é o mesmo que:
//
// BrainVaultObject.header.objectId
//
// O primeiro é o ID lógico da revisão.
//
// O segundo é o ID físico/estável do objeto dentro do Vault.
//
// ============================================================

class BrainReviewVaultEntry {
  const BrainReviewVaultEntry({
    required this.objectId,
    required this.review,
  });

  // ============================================================
  // VAULT OBJECT ID
  // ============================================================

  final String objectId;

  // ============================================================
  // REVIEW
  // ============================================================

  final BrainReviewItem review;

  // ============================================================
  // VALIDATION
  // ============================================================

  bool get isValid {
    return objectId.trim().isNotEmpty &&
        review.id.trim().isNotEmpty;
  }

  // ============================================================
  // STRING
  // ============================================================

  @override
  String toString() {
    return 'BrainReviewVaultEntry('
        'objectId: $objectId, '
        'reviewId: ${review.id}'
        ')';
  }
}
