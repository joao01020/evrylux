import 'dart:io';

import '../../models/brain_file.dart';
import '../../models/brain_review_item.dart';
import '../../services/brain_storage.dart';

import '../models/brain_migration_result.dart';
import '../models/brain_migration_status.dart';

import 'brain_legacy_migration_service.dart';

// ============================================================
// LEGACY REVIEW LOADER
// ============================================================
//
// O carregamento das reviews continua desacoplado.
//
// Nesta fase, o Coordinator não conhece ainda:
//
// - ReviewRepository;
// - Supabase;
// - SyncQueue;
// - storage definitivo das reviews.
//
// Ele recebe apenas uma função capaz de devolver:
//
// List<BrainReviewItem>
//
// Isso mantém a migração isolada e testável.
//
// ============================================================

typedef BrainLegacyReviewLoader = Future<List<BrainReviewItem>> Function();

// ============================================================
// BRAIN MIGRATION COORDINATOR
// ============================================================
//
// Responsável por coordenar:
//
// BrainStorage legado
//        ↓
// loadNotes()
//
// Review loader legado
//        ↓
// List<BrainReviewItem>
//
//        ↓
//
// BrainLegacyMigrationService
//
//        ↓
//
// Vault criptografado
//
// ============================================================
//
// IMPORTANTE:
//
// O Coordinator continua sem:
// - apagar reviews legadas;
// - apagar backups;
// - alterar BrainRepository;
// - alterar ReviewRepository;
// - alterar SyncQueue;
// - enviar dados para Supabase.
//
// SEGURANÇA LOCAL:
//
// Após uma migração TOTALMENTE validada, os arquivos Markdown
// legados podem ser removidos automaticamente para que o conteúdo
// não permaneça em texto puro no disco.
//
// A remoção só acontece quando:
// - removeLegacyPlaintextAfterValidation == true;
// - não existe falha;
// - não existe item pendente;
// - result.allValidated == true.
//
// Se a validação não for concluída, nenhum .md é removido.
//
// Fluxo:
//
// 1. lê legado;
// 2. migra para o Vault criptografado;
// 3. valida o resultado;
// 4. remove somente os .md já protegidos, se habilitado.
//
// ============================================================

class BrainMigrationCoordinator {
  BrainMigrationCoordinator({
    required BrainStorage brainStorage,
    required BrainLegacyMigrationService migrationService,
    BrainLegacyReviewLoader? reviewLoader,
    DateTime Function()? now,
    bool removeLegacyPlaintextAfterValidation = true,
  }) : _brainStorage = brainStorage,
       _migrationService = migrationService,
       _reviewLoader = reviewLoader,
       _now = now ?? DateTime.now,
       _removeLegacyPlaintextAfterValidation =
           removeLegacyPlaintextAfterValidation;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final BrainStorage _brainStorage;

  final BrainLegacyMigrationService _migrationService;

  final BrainLegacyReviewLoader? _reviewLoader;

  final DateTime Function() _now;

  final bool _removeLegacyPlaintextAfterValidation;

  int _lastRemovedPlaintextFiles = 0;

  // ============================================================
  // STATE
  // ============================================================

  bool _running = false;

  // ============================================================
  // IS RUNNING
  // ============================================================

  bool get isRunning {
    return _running;
  }

  int get lastRemovedPlaintextFiles {
    return _lastRemovedPlaintextFiles;
  }

  // ============================================================
  // LOAD LEGACY FILES
  // ============================================================

  Future<List<BrainFile>> loadLegacyFiles() async {
    final files = await _brainStorage.loadNotes();

    return List<BrainFile>.unmodifiable(files);
  }

  // ============================================================
  // LOAD LEGACY REVIEWS
  // ============================================================

  Future<List<BrainReviewItem>> loadLegacyReviews() async {
    final loader = _reviewLoader;

    if (loader == null) {
      return const <BrainReviewItem>[];
    }

    final reviews = await loader();

    return List<BrainReviewItem>.unmodifiable(reviews);
  }

  // ============================================================
  // PREVIEW
  // ============================================================
  //
  // Apenas lê o legado e informa quantos itens existem.
  //
  // NÃO:
  //
  // - cria objetos no Vault;
  // - altera arquivos;
  // - grava registry;
  // - remove legado.
  //
  // ============================================================

  Future<BrainMigrationPreview> preview() async {
    final files = await loadLegacyFiles();

    final reviews = await loadLegacyReviews();

    return BrainMigrationPreview(files: files, reviews: reviews);
  }

  // ============================================================
  // RUN
  // ============================================================

  Future<BrainMigrationResult> run() async {
    _ensureNotRunning();

    _running = true;

    try {
      final files = await loadLegacyFiles();

      final reviews = await loadLegacyReviews();

      final result = await _migrationService.migrateAll(
        files: files,
        reviews: reviews,
      );

      await _cleanupValidatedLegacyMarkdown(files: files, result: result);

      return result;
    } finally {
      _running = false;
    }
  }

  // ============================================================
  // RUN FILES ONLY
  // ============================================================

  Future<BrainMigrationResult> runFilesOnly() async {
    _ensureNotRunning();

    _running = true;

    try {
      final files = await loadLegacyFiles();

      final result = await _migrationService.migrateAll(
        files: files,
        reviews: const <BrainReviewItem>[],
      );

      await _cleanupValidatedLegacyMarkdown(files: files, result: result);

      return result;
    } finally {
      _running = false;
    }
  }

  // ============================================================
  // RUN REVIEWS ONLY
  // ============================================================

  Future<BrainMigrationResult> runReviewsOnly() async {
    _ensureNotRunning();

    _running = true;

    try {
      final reviews = await loadLegacyReviews();

      return await _migrationService.migrateAll(
        files: const <BrainFile>[],
        reviews: reviews,
      );
    } finally {
      _running = false;
    }
  }

  // ============================================================
  // SAFE RUN
  // ============================================================
  //
  // Útil para integração futura com UI.
  //
  // Em vez de propagar uma exceção de infraestrutura,
  // devolve um resultado controlado.
  //
  // ============================================================

  Future<BrainMigrationCoordinatorResult> safeRun() async {
    final startedAt = _now().toUtc();

    try {
      final result = await run();

      return BrainMigrationCoordinatorResult.success(result: result);
    } catch (error) {
      final finishedAt = _now().toUtc();

      return BrainMigrationCoordinatorResult.failure(
        startedAt: startedAt,
        finishedAt: finishedAt,
        error: error,
      );
    }
  }

  // ============================================================
  // CLEANUP VALIDATED LEGACY MARKDOWN
  // ============================================================
  //
  // Remove somente arquivos .md depois que a migração completa
  // foi validada pelo serviço de migração.
  //
  // Esta etapa existe para impedir que o conteúdo continue
  // legível diretamente pelo Dolphin/Finder/Explorer depois de
  // já existir uma cópia criptografada no Vault.
  //
  // ============================================================

  Future<void> _cleanupValidatedLegacyMarkdown({
    required List<BrainFile> files,
    required BrainMigrationResult result,
  }) async {
    _lastRemovedPlaintextFiles = 0;

    if (!_removeLegacyPlaintextAfterValidation) {
      return;
    }

    if (files.isEmpty) {
      return;
    }

    // Fail closed:
    // qualquer falha ou pendência mantém o plaintext intacto.
    if (result.failed > 0 || result.pending > 0 || !result.allValidated) {
      return;
    }

    var removed = 0;

    for (final brainFile in files) {
      final path = brainFile.path.trim();

      if (path.isEmpty) {
        continue;
      }

      // O Coordinator só limpa o formato legado conhecido.
      if (!path.toLowerCase().endsWith('.md')) {
        continue;
      }

      final file = File(path);

      if (!await file.exists()) {
        continue;
      }

      await file.delete();

      if (await file.exists()) {
        throw FileSystemException(
          'O Markdown legado continuou existindo após a remoção segura.',
          path,
        );
      }

      removed++;
    }

    _lastRemovedPlaintextFiles = removed;
  }

  // ============================================================
  // ENSURE NOT RUNNING
  // ============================================================

  void _ensureNotRunning() {
    if (_running) {
      throw StateError(
        'BrainMigrationCoordinator já está executando uma migração.',
      );
    }
  }
}

// ============================================================
// BRAIN MIGRATION PREVIEW
// ============================================================
//
// Representa apenas uma leitura prévia.
//
// ============================================================

class BrainMigrationPreview {
  BrainMigrationPreview({
    required List<BrainFile> files,
    required List<BrainReviewItem> reviews,
  }) : files = List<BrainFile>.unmodifiable(files),
       reviews = List<BrainReviewItem>.unmodifiable(reviews);

  // ============================================================
  // DATA
  // ============================================================

  final List<BrainFile> files;

  final List<BrainReviewItem> reviews;

  // ============================================================
  // COUNTS
  // ============================================================

  int get fileCount {
    return files.length;
  }

  int get reviewCount {
    return reviews.length;
  }

  int get total {
    return fileCount + reviewCount;
  }

  // ============================================================
  // STATE
  // ============================================================

  bool get isEmpty {
    return total == 0;
  }

  bool get isNotEmpty {
    return !isEmpty;
  }
}

// ============================================================
// BRAIN MIGRATION COORDINATOR RESULT
// ============================================================
//
// Resultado de uma execução segura do Coordinator.
//
// ============================================================

class BrainMigrationCoordinatorResult {
  const BrainMigrationCoordinatorResult._({
    required this.success,
    this.result,
    this.error,
    this.startedAt,
    this.finishedAt,
  });

  // ============================================================
  // DATA
  // ============================================================

  final bool success;

  final BrainMigrationResult? result;

  final Object? error;

  final DateTime? startedAt;

  final DateTime? finishedAt;

  // ============================================================
  // SUCCESS
  // ============================================================

  factory BrainMigrationCoordinatorResult.success({
    required BrainMigrationResult result,
  }) {
    return BrainMigrationCoordinatorResult._(
      success: true,
      result: result,
      startedAt: result.startedAt,
      finishedAt: result.finishedAt,
    );
  }

  // ============================================================
  // FAILURE
  // ============================================================

  factory BrainMigrationCoordinatorResult.failure({
    required DateTime startedAt,
    required DateTime finishedAt,
    required Object error,
  }) {
    return BrainMigrationCoordinatorResult._(
      success: false,
      error: error,
      startedAt: startedAt.toUtc(),
      finishedAt: finishedAt.toUtc(),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasError {
    return !success;
  }

  bool get hasResult {
    return result != null;
  }

  bool get hasFailures {
    final migrationResult = result;

    if (!success) {
      return true;
    }

    if (migrationResult == null) {
      return false;
    }

    return migrationResult.hasFailures;
  }

  bool get allValidated {
    final migrationResult = result;

    if (migrationResult == null) {
      return false;
    }

    return migrationResult.allValidated;
  }

  int get total {
    return result?.total ?? 0;
  }

  int get validated {
    return result?.validated ?? 0;
  }

  int get migrated {
    return result?.migrated ?? 0;
  }

  int get failed {
    return result?.failed ?? 0;
  }

  int get pending {
    return result?.pending ?? 0;
  }

  int get skipped {
    return result?.skipped ?? 0;
  }

  // ============================================================
  // DURATION
  // ============================================================

  Duration? get duration {
    final start = startedAt;

    final finish = finishedAt;

    if (start == null || finish == null) {
      return null;
    }

    return finish.difference(start);
  }

  // ============================================================
  // OVERALL STATUS
  // ============================================================
  //
  // Não usa result.migrating porque o BrainMigrationResult atual
  // do projeto não expõe esse getter.
  //
  // A prioridade é:
  //
  // erro
  //   ↓
  // failed
  //   ↓
  // validated
  //   ↓
  // migrated
  //   ↓
  // pending
  //   ↓
  // skipped
  //
  // ============================================================

  BrainMigrationStatus? get overallStatus {
    if (!success) {
      return BrainMigrationStatus.failed;
    }

    final migrationResult = result;

    if (migrationResult == null) {
      return null;
    }

    if (migrationResult.failed > 0) {
      return BrainMigrationStatus.failed;
    }

    if (migrationResult.allValidated) {
      return BrainMigrationStatus.validated;
    }

    if (migrationResult.migrated > 0) {
      return BrainMigrationStatus.migrated;
    }

    if (migrationResult.pending > 0) {
      return BrainMigrationStatus.pending;
    }

    if (migrationResult.skipped > 0) {
      return BrainMigrationStatus.skipped;
    }

    return null;
  }
}
