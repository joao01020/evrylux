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

typedef BrainLegacyReviewLoader =
    Future<
      List<
        BrainReviewItem
      >
    >
    Function();

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
// Este serviço NÃO:
//
// - apaga notas .md;
// - apaga reviews;
// - apaga backups;
// - altera BrainRepository;
// - altera ReviewRepository;
// - altera SyncQueue;
// - envia dados para Supabase;
// - substitui o armazenamento legado.
//
// Nesta fase ele apenas:
//
// 1. lê;
// 2. coordena;
// 3. migra;
// 4. valida.
//
// ============================================================

class BrainMigrationCoordinator {
  BrainMigrationCoordinator({
    required BrainStorage brainStorage,
    required BrainLegacyMigrationService migrationService,
    BrainLegacyReviewLoader? reviewLoader,
    DateTime Function()? now,
  }) : _brainStorage =
           brainStorage,
       _migrationService = migrationService,
       _reviewLoader = reviewLoader,
       _now =
           now ??
           DateTime.now;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final BrainStorage _brainStorage;

  final BrainLegacyMigrationService _migrationService;

  final BrainLegacyReviewLoader? _reviewLoader;

  final DateTime Function() _now;

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

  // ============================================================
  // LOAD LEGACY FILES
  // ============================================================

  Future<
    List<
      BrainFile
    >
  >
  loadLegacyFiles() async {
    final files = await _brainStorage.loadNotes();

    return List<
      BrainFile
    >.unmodifiable(
      files,
    );
  }

  // ============================================================
  // LOAD LEGACY REVIEWS
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadLegacyReviews() async {
    final loader = _reviewLoader;

    if (loader ==
        null) {
      return const <
        BrainReviewItem
      >[];
    }

    final reviews = await loader();

    return List<
      BrainReviewItem
    >.unmodifiable(
      reviews,
    );
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

  Future<
    BrainMigrationPreview
  >
  preview() async {
    final files = await loadLegacyFiles();

    final reviews = await loadLegacyReviews();

    return BrainMigrationPreview(
      files: files,
      reviews: reviews,
    );
  }

  // ============================================================
  // RUN
  // ============================================================

  Future<
    BrainMigrationResult
  >
  run() async {
    _ensureNotRunning();

    _running = true;

    try {
      final files = await loadLegacyFiles();

      final reviews = await loadLegacyReviews();

      return await _migrationService.migrateAll(
        files: files,
        reviews: reviews,
      );
    } finally {
      _running = false;
    }
  }

  // ============================================================
  // RUN FILES ONLY
  // ============================================================

  Future<
    BrainMigrationResult
  >
  runFilesOnly() async {
    _ensureNotRunning();

    _running = true;

    try {
      final files = await loadLegacyFiles();

      return await _migrationService.migrateAll(
        files: files,
        reviews:
            const <
              BrainReviewItem
            >[],
      );
    } finally {
      _running = false;
    }
  }

  // ============================================================
  // RUN REVIEWS ONLY
  // ============================================================

  Future<
    BrainMigrationResult
  >
  runReviewsOnly() async {
    _ensureNotRunning();

    _running = true;

    try {
      final reviews = await loadLegacyReviews();

      return await _migrationService.migrateAll(
        files:
            const <
              BrainFile
            >[],
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

  Future<
    BrainMigrationCoordinatorResult
  >
  safeRun() async {
    final startedAt = _now().toUtc();

    try {
      final result = await run();

      return BrainMigrationCoordinatorResult.success(
        result: result,
      );
    } catch (
      error
    ) {
      final finishedAt = _now().toUtc();

      return BrainMigrationCoordinatorResult.failure(
        startedAt: startedAt,
        finishedAt: finishedAt,
        error: error,
      );
    }
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
    required List<
      BrainFile
    >
    files,
    required List<
      BrainReviewItem
    >
    reviews,
  }) : files =
           List<
             BrainFile
           >.unmodifiable(
             files,
           ),
       reviews =
           List<
             BrainReviewItem
           >.unmodifiable(
             reviews,
           );

  // ============================================================
  // DATA
  // ============================================================

  final List<
    BrainFile
  >
  files;

  final List<
    BrainReviewItem
  >
  reviews;

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
    return fileCount +
        reviewCount;
  }

  // ============================================================
  // STATE
  // ============================================================

  bool get isEmpty {
    return total ==
        0;
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
    return result !=
        null;
  }

  bool get hasFailures {
    final migrationResult = result;

    if (!success) {
      return true;
    }

    if (migrationResult ==
        null) {
      return false;
    }

    return migrationResult.hasFailures;
  }

  bool get allValidated {
    final migrationResult = result;

    if (migrationResult ==
        null) {
      return false;
    }

    return migrationResult.allValidated;
  }

  int get total {
    return result?.total ??
        0;
  }

  int get validated {
    return result?.validated ??
        0;
  }

  int get migrated {
    return result?.migrated ??
        0;
  }

  int get failed {
    return result?.failed ??
        0;
  }

  int get pending {
    return result?.pending ??
        0;
  }

  int get skipped {
    return result?.skipped ??
        0;
  }

  // ============================================================
  // DURATION
  // ============================================================

  Duration? get duration {
    final start = startedAt;

    final finish = finishedAt;

    if (start ==
            null ||
        finish ==
            null) {
      return null;
    }

    return finish.difference(
      start,
    );
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

    if (migrationResult ==
        null) {
      return null;
    }

    if (migrationResult.failed >
        0) {
      return BrainMigrationStatus.failed;
    }

    if (migrationResult.allValidated) {
      return BrainMigrationStatus.validated;
    }

    if (migrationResult.migrated >
        0) {
      return BrainMigrationStatus.migrated;
    }

    if (migrationResult.pending >
        0) {
      return BrainMigrationStatus.pending;
    }

    if (migrationResult.skipped >
        0) {
      return BrainMigrationStatus.skipped;
    }

    return null;
  }
}
