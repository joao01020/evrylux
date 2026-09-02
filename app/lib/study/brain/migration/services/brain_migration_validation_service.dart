import 'dart:convert';

import '../../models/brain_file.dart';
import '../../models/brain_review_item.dart';

import '../../vault/mappers/brain_file_vault_mapper.dart';
import '../../vault/mappers/brain_review_vault_mapper.dart';
import '../../vault/models/brain_vault_object_type.dart';
import '../../vault/services/brain_vault_service.dart';

// ============================================================
// BRAIN MIGRATION VALIDATION RESULT
// ============================================================

class BrainMigrationValidationResult {
  const BrainMigrationValidationResult({
    required this.valid,
    this.reason,
  });

  final bool valid;

  final String? reason;

  factory BrainMigrationValidationResult.success() {
    return const BrainMigrationValidationResult(
      valid: true,
    );
  }

  factory BrainMigrationValidationResult.failure(
    String reason,
  ) {
    return BrainMigrationValidationResult(
      valid: false,
      reason: reason,
    );
  }
}

// ============================================================
// BRAIN MIGRATION VALIDATION SERVICE
// ============================================================
//
// Depois de migrar:
//
// legado
//   ↓
// Vault
//
// nós lemos novamente o objeto criptografado e verificamos se
// ele representa exatamente os dados esperados.
//
// NÃO apagamos o legado.
//
// ============================================================

class BrainMigrationValidationService {
  const BrainMigrationValidationService({
    required BrainVaultService vaultService,
    BrainFileVaultMapper brainFileMapper = const BrainFileVaultMapper(),
    BrainReviewVaultMapper brainReviewMapper = const BrainReviewVaultMapper(),
  }) : _vaultService = vaultService,
       _brainFileMapper = brainFileMapper,
       _brainReviewMapper = brainReviewMapper;

  final BrainVaultService _vaultService;

  final BrainFileVaultMapper _brainFileMapper;

  final BrainReviewVaultMapper _brainReviewMapper;

  // ============================================================
  // VALIDATE BRAIN FILE
  // ============================================================

  Future<
    BrainMigrationValidationResult
  >
  validateBrainFile({
    required String objectId,
    required BrainFile source,
  }) async {
    try {
      final decoded = await _vaultService.readObject(
        objectId,
      );

      if (decoded ==
          null) {
        return BrainMigrationValidationResult.failure(
          'Objeto não encontrado ou tombstone.',
        );
      }

      if (decoded.type !=
          BrainVaultObjectType.note) {
        return BrainMigrationValidationResult.failure(
          'Tipo inesperado no Vault: ${decoded.type.value}',
        );
      }

      final expected = _brainFileMapper.toVaultData(
        source,
      );

      if (!_deepEquals(
        decoded.data,
        expected,
      )) {
        return BrainMigrationValidationResult.failure(
          'BrainFile recuperado do Vault difere da origem.',
        );
      }

      return BrainMigrationValidationResult.success();
    } catch (
      error
    ) {
      return BrainMigrationValidationResult.failure(
        error.toString(),
      );
    }
  }

  // ============================================================
  // VALIDATE REVIEW
  // ============================================================

  Future<
    BrainMigrationValidationResult
  >
  validateBrainReview({
    required String objectId,
    required BrainReviewItem source,
  }) async {
    try {
      final decoded = await _vaultService.readObject(
        objectId,
      );

      if (decoded ==
          null) {
        return BrainMigrationValidationResult.failure(
          'Objeto não encontrado ou tombstone.',
        );
      }

      if (decoded.type !=
          BrainVaultObjectType.review) {
        return BrainMigrationValidationResult.failure(
          'Tipo inesperado no Vault: ${decoded.type.value}',
        );
      }

      final expected = _brainReviewMapper.toVaultData(
        source,
      );

      if (!_deepEquals(
        decoded.data,
        expected,
      )) {
        return BrainMigrationValidationResult.failure(
          'BrainReviewItem recuperado do Vault difere da origem.',
        );
      }

      return BrainMigrationValidationResult.success();
    } catch (
      error
    ) {
      return BrainMigrationValidationResult.failure(
        error.toString(),
      );
    }
  }

  // ============================================================
  // DEEP EQUALS
  // ============================================================
  //
  // Os mappers geram estruturas JSON-safe.
  //
  // jsonEncode fornece uma comparação determinística suficiente
  // aqui porque ambos os lados usam a mesma estrutura lógica.
  //
  // ============================================================

  bool _deepEquals(
    Map<
      String,
      dynamic
    >
    left,
    Map<
      String,
      dynamic
    >
    right,
  ) {
    try {
      return jsonEncode(
            left,
          ) ==
          jsonEncode(
            right,
          );
    } catch (
      _
    ) {
      return false;
    }
  }
}
