import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:EVRYLUX/study/brain/migration/models/brain_migration_status.dart';
import 'package:EVRYLUX/study/brain/migration/services/brain_legacy_migration_service.dart';
import 'package:EVRYLUX/study/brain/migration/services/brain_migration_coordinator.dart';
import 'package:EVRYLUX/study/brain/migration/services/brain_migration_validation_service.dart';
import 'package:EVRYLUX/study/brain/migration/services/brain_object_link_service.dart';

import 'package:EVRYLUX/study/brain/models/brain_review_item.dart';

import 'package:EVRYLUX/study/brain/security/keys/brain_key_service.dart';
import 'package:EVRYLUX/study/brain/security/keys/brain_key_storage.dart';

import 'package:EVRYLUX/study/brain/services/brain_storage.dart';

import 'package:EVRYLUX/study/brain/vault/services/brain_vault_service.dart';
import 'package:EVRYLUX/study/brain/vault/storage/brain_vault_storage.dart';

// ============================================================
// FAKE PATH PROVIDER
// ============================================================
//
// BrainStorage usa:
//
// getApplicationDocumentsDirectory()
//
// Durante os testes, apontamos esse diretório para uma pasta
// temporária.
//
// Assim:
//
// - nada real do usuário é tocado;
// - nenhum dado de ~/Documents é alterado;
// - o teste pode criar/remover arquivos livremente.
//
// ============================================================

class _FakePathProviderPlatform
    extends
        PathProviderPlatform {
  _FakePathProviderPlatform(
    this.documentsPath,
  );

  final String documentsPath;

  @override
  Future<
    String?
  >
  getApplicationDocumentsPath() async {
    return documentsPath;
  }
}

// ============================================================
// TESTS
// ============================================================

void
main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'BrainMigrationCoordinator',
    () {
      late Directory tempDirectory;

      late PathProviderPlatform originalPathProvider;

      late BrainStorage brainStorage;

      late BrainVaultService vaultService;

      late BrainObjectLinkService linkService;

      late BrainMigrationValidationService validationService;

      late BrainLegacyMigrationService migrationService;

      late DateTime currentTime;

      // ============================================================
      // SETUP
      // ============================================================

      setUp(
        () async {
          // ========================================================
          // TEMP DIRECTORY
          // ========================================================

          tempDirectory = await Directory.systemTemp.createTemp(
            'evrylux_migration_coordinator_test_',
          );

          // ========================================================
          // PATH PROVIDER FAKE
          // ========================================================

          originalPathProvider = PathProviderPlatform.instance;

          PathProviderPlatform.instance = _FakePathProviderPlatform(
            tempDirectory.path,
          );

          // ========================================================
          // LEGACY STORAGE
          // ========================================================

          brainStorage = const BrainStorage();

          // ========================================================
          // KEY SERVICE
          // ========================================================

          final keyService = BrainKeyService(
            storage: InMemoryBrainKeyStorage(),
          );

          // ========================================================
          // VAULT STORAGE
          // ========================================================

          final vaultStorage = BrainVaultStorage(
            documentsDirectoryProvider: () async => tempDirectory,
          );

          // ========================================================
          // VAULT SERVICE
          // ========================================================

          vaultService = BrainVaultService(
            keyService: keyService,
            storage: vaultStorage,
          );

          // ========================================================
          // CLOCK
          // ========================================================

          currentTime = DateTime.utc(
            2026,
            9,
            2,
            12,
          );

          // ========================================================
          // LINK SERVICE
          // ========================================================

          linkService = BrainObjectLinkService(
            store: InMemoryBrainMigrationLinkStore(),
            now: () => currentTime,
          );

          // ========================================================
          // VALIDATION SERVICE
          // ========================================================

          validationService = BrainMigrationValidationService(
            vaultService: vaultService,
          );

          // ========================================================
          // MIGRATION SERVICE
          // ========================================================

          migrationService = BrainLegacyMigrationService(
            vaultService: vaultService,
            objectLinkService: linkService,
            validationService: validationService,
            now: () => currentTime,
          );

          // ========================================================
          // CREATE VAULT
          // ========================================================

          await vaultService.createVault();
        },
      );

      // ============================================================
      // TEARDOWN
      // ============================================================

      tearDown(
        () async {
          PathProviderPlatform.instance = originalPathProvider;

          if (await tempDirectory.exists()) {
            await tempDirectory.delete(
              recursive: true,
            );
          }
        },
      );

      // ============================================================
      // EMPTY PREVIEW
      // ============================================================

      test(
        'preview vazio quando não existem dados legados',
        () async {
          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,
            migrationService: migrationService,
          );

          final preview = await coordinator.preview();

          expect(
            preview.fileCount,
            0,
          );

          expect(
            preview.reviewCount,
            0,
          );

          expect(
            preview.total,
            0,
          );

          expect(
            preview.isEmpty,
            true,
          );

          expect(
            preview.isNotEmpty,
            false,
          );
        },
      );

      // ============================================================
      // LEGACY NOTE
      // ============================================================

      test(
        'carrega nota legada pelo BrainStorage',
        () async {
          await brainStorage.saveNote(
            topic: 'Programação',
            title: 'Ponteiros',
            content: 'Ponteiros armazenam endereços de memória.',
            concepts: const [],
          );

          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,
            migrationService: migrationService,
          );

          final files = await coordinator.loadLegacyFiles();

          expect(
            files.length,
            1,
          );

          expect(
            files.first.title,
            'Ponteiros',
          );

          expect(
            files.first.topic,
            'Programação',
          );

          expect(
            files.first.content,
            'Ponteiros armazenam endereços de memória.',
          );

          expect(
            files.first.path,
            isNotEmpty,
          );
        },
      );

      // ============================================================
      // LEGACY REVIEWS
      // ============================================================

      test(
        'carrega reviews através do reviewLoader',
        () async {
          final review = BrainReviewItem(
            id: 'review-coordinator-001',

            conceptId: 'concept-coordinator-001',

            question: 'O que é um ponteiro?',

            answer: 'Uma variável que armazena um endereço.',

            sourceNotePath: '/tmp/ponteiros.md',

            sourceNoteTitle: 'Ponteiros',

            createdAt: DateTime(
              2026,
              9,
              1,
            ),

            nextReviewAt: DateTime(
              2026,
              9,
              5,
            ),

            lastReviewedAt: null,

            archivedAt: null,

            reviewCount: 0,

            correctCount: 0,

            wrongCount: 0,

            streak: 0,

            archived: false,
          );

          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,

            migrationService: migrationService,

            reviewLoader: () async => [
              review,
            ],
          );

          final reviews = await coordinator.loadLegacyReviews();

          expect(
            reviews.length,
            1,
          );

          expect(
            reviews.first.id,
            review.id,
          );

          expect(
            reviews.first.question,
            review.question,
          );

          expect(
            reviews.first.answer,
            review.answer,
          );
        },
      );

      test(
        'sem reviewLoader retorna lista vazia',
        () async {
          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,

            migrationService: migrationService,
          );

          final reviews = await coordinator.loadLegacyReviews();

          expect(
            reviews,
            isEmpty,
          );
        },
      );

      // ============================================================
      // PREVIEW
      // ============================================================

      test(
        'preview contabiliza files e reviews',
        () async {
          await brainStorage.saveNote(
            topic: 'Economia',

            title: 'Custo de oportunidade',

            content: 'Valor da melhor alternativa abandonada.',

            concepts: const [],
          );

          final review = BrainReviewItem(
            id: 'review-preview-001',

            conceptId: 'concept-preview-001',

            question: 'O que é custo de oportunidade?',

            answer: 'A melhor alternativa abandonada.',

            sourceNotePath: '/tmp/economia.md',

            sourceNoteTitle: 'Economia',

            createdAt: DateTime(
              2026,
              9,
              1,
            ),

            nextReviewAt: DateTime(
              2026,
              9,
              5,
            ),

            lastReviewedAt: null,

            archivedAt: null,

            reviewCount: 0,

            correctCount: 0,

            wrongCount: 0,

            streak: 0,

            archived: false,
          );

          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,

            migrationService: migrationService,

            reviewLoader: () async => [
              review,
            ],
          );

          final preview = await coordinator.preview();

          expect(
            preview.fileCount,
            1,
          );

          expect(
            preview.reviewCount,
            1,
          );

          expect(
            preview.total,
            2,
          );

          expect(
            preview.isNotEmpty,
            true,
          );
        },
      );

      // ============================================================
      // RUN — FILE
      // ============================================================

      test(
        'run migra nota legada para Vault',
        () async {
          final saved = await brainStorage.saveNote(
            topic: 'Segurança',

            title: 'Princípio do menor privilégio',

            content: 'Cada componente deve ter apenas as permissões necessárias.',

            concepts: const [],
          );

          final legacyPath = saved.path;

          final legacyFile = File(
            legacyPath,
          );

          expect(
            await legacyFile.exists(),
            true,
          );

          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,

            migrationService: migrationService,
          );

          final result = await coordinator.run();

          expect(
            result.total,
            1,
          );

          expect(
            result.validated,
            1,
          );

          expect(
            result.failed,
            0,
          );

          expect(
            result.allValidated,
            true,
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            1,
          );

          // ========================================================
          // CRITICAL GUARANTEE
          // ========================================================
          //
          // A migração NÃO pode remover o legado.
          //
          // ========================================================

          expect(
            await legacyFile.exists(),
            true,
          );
        },
      );

      // ============================================================
      // RUN — FILE + REVIEW
      // ============================================================

      test(
        'run migra file e review juntos',
        () async {
          final saved = await brainStorage.saveNote(
            topic: 'C++',

            title: 'RAII',

            content: 'Recursos acompanham o tempo de vida dos objetos.',

            concepts: const [],
          );

          final review = BrainReviewItem(
            id: 'review-run-all-001',

            conceptId: 'concept-run-all-001',

            question: 'O que significa RAII?',

            answer: 'Resource Acquisition Is Initialization.',

            sourceNotePath: saved.path,

            sourceNoteTitle: saved.title,

            createdAt: DateTime(
              2026,
              9,
              1,
            ),

            nextReviewAt: DateTime(
              2026,
              9,
              5,
            ),

            lastReviewedAt: null,

            archivedAt: null,

            reviewCount: 0,

            correctCount: 0,

            wrongCount: 0,

            streak: 0,

            archived: false,
          );

          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,

            migrationService: migrationService,

            reviewLoader: () async => [
              review,
            ],
          );

          final result = await coordinator.run();

          expect(
            result.total,
            2,
          );

          expect(
            result.validated,
            2,
          );

          expect(
            result.failed,
            0,
          );

          expect(
            result.allValidated,
            true,
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            2,
          );
        },
      );

      // ============================================================
      // RUN FILES ONLY
      // ============================================================

      test(
        'runFilesOnly ignora reviews',
        () async {
          await brainStorage.saveNote(
            topic: 'Linux',

            title: 'Permissões',

            content: 'Permissões tradicionais usam owner, group e others.',

            concepts: const [],
          );

          final review = BrainReviewItem(
            id: 'review-ignore-001',

            conceptId: 'concept-ignore-001',

            question: 'O que é chmod?',

            answer: 'Comando para alterar permissões.',

            sourceNotePath: '/tmp/linux.md',

            sourceNoteTitle: 'Linux',

            createdAt: DateTime(
              2026,
              9,
              1,
            ),

            nextReviewAt: DateTime(
              2026,
              9,
              5,
            ),

            lastReviewedAt: null,

            archivedAt: null,

            reviewCount: 0,

            correctCount: 0,

            wrongCount: 0,

            streak: 0,

            archived: false,
          );

          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,

            migrationService: migrationService,

            reviewLoader: () async => [
              review,
            ],
          );

          final result = await coordinator.runFilesOnly();

          expect(
            result.total,
            1,
          );

          expect(
            result.validated,
            1,
          );

          expect(
            result.failed,
            0,
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            1,
          );
        },
      );

      // ============================================================
      // RUN REVIEWS ONLY
      // ============================================================

      test(
        'runReviewsOnly migra apenas reviews',
        () async {
          await brainStorage.saveNote(
            topic: 'Não migrar',

            title: 'Nota ignorada',

            content: 'Esta nota não deve ser migrada neste teste.',

            concepts: const [],
          );

          final review = BrainReviewItem(
            id: 'review-only-001',

            conceptId: 'concept-only-001',

            question: 'Pergunta?',

            answer: 'Resposta.',

            sourceNotePath: '/tmp/review-only.md',

            sourceNoteTitle: 'Review only',

            createdAt: DateTime(
              2026,
              9,
              1,
            ),

            nextReviewAt: DateTime(
              2026,
              9,
              5,
            ),

            lastReviewedAt: null,

            archivedAt: null,

            reviewCount: 0,

            correctCount: 0,

            wrongCount: 0,

            streak: 0,

            archived: false,
          );

          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,

            migrationService: migrationService,

            reviewLoader: () async => [
              review,
            ],
          );

          final result = await coordinator.runReviewsOnly();

          expect(
            result.total,
            1,
          );

          expect(
            result.validated,
            1,
          );

          expect(
            result.failed,
            0,
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            1,
          );
        },
      );

      // ============================================================
      // IDEMPOTENCE
      // ============================================================

      test(
        'executar coordinator duas vezes não duplica objeto',
        () async {
          await brainStorage.saveNote(
            topic: 'C++',

            title: 'Smart pointers',

            content: 'Smart pointers automatizam gerenciamento de ownership.',

            concepts: const [],
          );

          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,

            migrationService: migrationService,
          );

          final first = await coordinator.run();

          final second = await coordinator.run();

          expect(
            first.validated,
            1,
          );

          expect(
            second.validated,
            1,
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects.length,
            1,
          );
        },
      );

      // ============================================================
      // SAFE RUN
      // ============================================================

      test(
        'safeRun retorna sucesso',
        () async {
          await brainStorage.saveNote(
            topic: 'Teste',

            title: 'Safe run',

            content: 'Conteúdo.',

            concepts: const [],
          );

          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,

            migrationService: migrationService,

            now: () => currentTime,
          );

          final result = await coordinator.safeRun();

          expect(
            result.success,
            true,
          );

          expect(
            result.hasError,
            false,
          );

          expect(
            result.hasResult,
            true,
          );

          expect(
            result.total,
            1,
          );

          expect(
            result.validated,
            1,
          );

          expect(
            result.failed,
            0,
          );

          expect(
            result.overallStatus,
            BrainMigrationStatus.validated,
          );
        },
      );

      // ============================================================
      // LEGACY MUST SURVIVE
      // ============================================================

      test(
        'migração não remove arquivos legados',
        () async {
          final first = await brainStorage.saveNote(
            topic: 'Conhecimento',

            title: 'Primeira nota',

            content: 'Primeiro conteúdo.',

            concepts: const [],
          );

          final second = await brainStorage.saveNote(
            topic: 'Conhecimento',

            title: 'Segunda nota',

            content: 'Segundo conteúdo.',

            concepts: const [],
          );

          final firstFile = File(
            first.path,
          );

          final secondFile = File(
            second.path,
          );

          expect(
            await firstFile.exists(),
            true,
          );

          expect(
            await secondFile.exists(),
            true,
          );

          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,

            migrationService: migrationService,
          );

          final result = await coordinator.run();

          expect(
            result.validated,
            2,
          );

          expect(
            result.failed,
            0,
          );

          // ========================================================
          // LEGADO PERMANECE
          // ========================================================

          expect(
            await firstFile.exists(),
            true,
          );

          expect(
            await secondFile.exists(),
            true,
          );
        },
      );

      // ============================================================
      // BRAIN STORAGE MUST BE NON-DESTRUCTIVE
      // ============================================================

      test(
        'abrir BrainStorage novamente não apaga nota existente',
        () async {
          final saved = await brainStorage.saveNote(
            topic: 'Persistência',

            title: 'Não apagar',

            content: 'Este arquivo precisa sobreviver à reinicialização do storage.',

            concepts: const [],
          );

          final file = File(
            saved.path,
          );

          expect(
            await file.exists(),
            true,
          );

          // ========================================================
          // NOVA INSTÂNCIA
          // ========================================================

          final reopenedStorage = const BrainStorage();

          final directory = await reopenedStorage.getBrainDirectory();

          expect(
            await directory.exists(),
            true,
          );

          // ========================================================
          // ARQUIVO CONTINUA EXISTINDO
          // ========================================================

          expect(
            await file.exists(),
            true,
          );

          final notes = await reopenedStorage.loadNotes();

          expect(
            notes.length,
            1,
          );

          expect(
            notes.first.title,
            'Não apagar',
          );
        },
      );

      // ============================================================
      // EMPTY RUN
      // ============================================================

      test(
        'run sem legado retorna resultado vazio',
        () async {
          final coordinator = BrainMigrationCoordinator(
            brainStorage: brainStorage,

            migrationService: migrationService,
          );

          final result = await coordinator.run();

          expect(
            result.total,
            0,
          );

          expect(
            result.failed,
            0,
          );

          expect(
            result.allValidated,
            true,
          );

          final objects = await vaultService.loadAllEncryptedObjects();

          expect(
            objects,
            isEmpty,
          );
        },
      );
    },
  );
}
