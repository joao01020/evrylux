import 'package:flutter/foundation.dart';

import 'brain_migration_coordinator.dart';

// ============================================================
// BRAIN REVIEW STARTUP MIGRATION SERVICE
// ============================================================
//
// Responsabilidade:
//
// executar no startup a migração de revisões legadas:
//
// ghost_brain/_reviews/reviews.json
//
// para:
//
// Brain Vault criptografado.
//
// ============================================================
//
// IMPORTANTE:
//
// Este serviço NÃO implementa a migração novamente.
//
// A regra real continua pertencendo a:
//
// BrainMigrationCoordinator
//      ↓
// BrainLegacyMigrationService
//      ↓
// BrainReviewVaultMapper
//      ↓
// BrainVaultService
//
// ============================================================
//
// Por que existe esta classe?
//
// Para separar:
//
// "quando executar"
//
// de:
//
// "como migrar".
//
// O Coordinator já sabe COMO migrar.
// Esta classe apenas dispara a migração no startup.
//
// ============================================================
//
// SEGURANÇA:
//
// - não apaga reviews.json;
// - não grava plaintext novo;
// - não acessa Supabase;
// - não depende de login;
// - pode ser executada mais de uma vez;
// - idempotência continua sendo responsabilidade da
//   infraestrutura de migração já existente.
//
// ============================================================

class BrainReviewStartupMigrationService {
  BrainReviewStartupMigrationService({
    required BrainMigrationCoordinator coordinator,
  }) : _coordinator = coordinator;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final BrainMigrationCoordinator _coordinator;

  // ============================================================
  // STATE
  // ============================================================
  //
  // Evita executar duas vezes simultaneamente dentro da mesma
  // instância durante o mesmo processo.
  //
  // Isso NÃO substitui a idempotência persistente do Coordinator.
  //
  // ============================================================

  bool _running = false;

  bool _completedInCurrentProcess = false;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get isRunning {
    return _running;
  }

  bool get completedInCurrentProcess {
    return _completedInCurrentProcess;
  }

  // ============================================================
  // RUN
  // ============================================================

  Future<
    void
  >
  run() async {
    // ==========================================================
    // JÁ CONCLUÍDO NESTA INSTÂNCIA
    // ==========================================================

    if (_completedInCurrentProcess) {
      return;
    }

    // ==========================================================
    // JÁ EXECUTANDO
    // ==========================================================

    if (_running) {
      return;
    }

    _running = true;

    try {
      debugPrint(
        '[BRAIN MIGRATION] '
        'Verificando revisões legadas...',
      );

      // ========================================================
      // MIGRAR APENAS REVIEWS
      // ========================================================
      //
      // O próprio BrainMigrationCoordinator:
      //
      // - carrega ReviewStorage legado;
      // - verifica registros já migrados;
      // - cria objetos no Vault;
      // - valida a migração;
      // - mantém o arquivo legado;
      // - impede duplicação através do registry.
      //
      // ========================================================

      await _coordinator.runReviewsOnly();

      _completedInCurrentProcess = true;

      debugPrint(
        '[BRAIN MIGRATION] '
        'Verificação de revisões legadas concluída.',
      );
    } catch (
      error,
      stackTrace
    ) {
      // ========================================================
      // FAIL CLOSED
      // ========================================================
      //
      // Não marcamos como concluído se algo falhar.
      //
      // Também não apagamos nem alteramos o legado.
      //
      // O erro sobe para o caller decidir se o startup deve
      // continuar, registrar telemetria ou apresentar mensagem.
      //
      // ========================================================

      debugPrint(
        '[BRAIN MIGRATION] '
        'Erro ao migrar revisões legadas: '
        '$error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      rethrow;
    } finally {
      _running = false;
    }
  }
}
