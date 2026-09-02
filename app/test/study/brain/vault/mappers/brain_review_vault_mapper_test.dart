import 'package:flutter_test/flutter_test.dart';

import 'package:EVRYLUX/study/brain/models/brain_review_item.dart';
import 'package:EVRYLUX/study/brain/vault/mappers/brain_review_vault_mapper.dart';

void
main() {
  group(
    'BrainReviewVaultMapper',
    () {
      const mapper = BrainReviewVaultMapper();

      test(
        'converte BrainReviewItem para Map corretamente',
        () {
          final createdAt = DateTime(
            2026,
            9,
            1,
            10,
          );

          final nextReviewAt = DateTime(
            2026,
            9,
            3,
            10,
          );

          final review = BrainReviewItem(
            id: 'review-001',
            conceptId: 'concept-001',
            question: 'O que é inflação?',
            answer: 'Aumento generalizado dos preços.',
            sourceNotePath: '/tmp/inflacao.md',
            sourceNoteTitle: 'Inflação',
            createdAt: createdAt,
            nextReviewAt: nextReviewAt,
            reviewCount: 2,
            correctCount: 1,
            wrongCount: 1,
            streak: 0,
            archived: false,
            archivedAt: null,
            lastReviewedAt: DateTime(
              2026,
              9,
              2,
              9,
            ),
          );

          final data = mapper.toVaultData(
            review,
          );

          expect(
            data['model'],
            'brain_review',
          );

          expect(
            data['model_version'],
            BrainReviewVaultMapper.modelVersion,
          );

          expect(
            data['id'],
            review.id,
          );

          expect(
            data['concept_id'],
            review.conceptId,
          );

          expect(
            data['question'],
            review.question,
          );

          expect(
            data['answer'],
            review.answer,
          );

          expect(
            data['source_note_path'],
            review.sourceNotePath,
          );

          expect(
            data['source_note_title'],
            review.sourceNoteTitle,
          );

          expect(
            data['review_count'],
            2,
          );

          expect(
            data['correct_count'],
            1,
          );

          expect(
            data['wrong_count'],
            1,
          );

          expect(
            data['streak'],
            0,
          );

          expect(
            data['archived'],
            false,
          );
        },
      );

      test(
        'round trip preserva BrainReviewItem',
        () {
          final original = BrainReviewItem(
            id: 'review-002',
            conceptId: 'concept-002',
            question: 'Qual a diferença entre receita e lucro?',
            answer: 'Receita é entrada bruta; lucro considera os custos.',
            sourceNotePath: '/tmp/financeiro.md',
            sourceNoteTitle: 'Financeiro',
            createdAt: DateTime(
              2026,
              8,
              20,
              8,
            ),
            nextReviewAt: DateTime(
              2026,
              9,
              5,
              8,
            ),
            lastReviewedAt: DateTime(
              2026,
              9,
              1,
              8,
            ),
            archivedAt: null,
            reviewCount: 5,
            correctCount: 4,
            wrongCount: 1,
            streak: 3,
            archived: false,
          );

          final restored = mapper.fromVaultData(
            mapper.toVaultData(
              original,
            ),
          );

          expect(
            restored.id,
            original.id,
          );

          expect(
            restored.conceptId,
            original.conceptId,
          );

          expect(
            restored.question,
            original.question,
          );

          expect(
            restored.answer,
            original.answer,
          );

          expect(
            restored.sourceNotePath,
            original.sourceNotePath,
          );

          expect(
            restored.sourceNoteTitle,
            original.sourceNoteTitle,
          );

          expect(
            restored.createdAt.toUtc(),
            original.createdAt.toUtc(),
          );

          expect(
            restored.nextReviewAt.toUtc(),
            original.nextReviewAt.toUtc(),
          );

          expect(
            restored.lastReviewedAt?.toUtc(),
            original.lastReviewedAt?.toUtc(),
          );

          expect(
            restored.archivedAt?.toUtc(),
            original.archivedAt?.toUtc(),
          );

          expect(
            restored.reviewCount,
            original.reviewCount,
          );

          expect(
            restored.correctCount,
            original.correctCount,
          );

          expect(
            restored.wrongCount,
            original.wrongCount,
          );

          expect(
            restored.streak,
            original.streak,
          );

          expect(
            restored.archived,
            original.archived,
          );
        },
      );

      test(
        'preserva revisão arquivada',
        () {
          final archivedAt = DateTime(
            2026,
            9,
            2,
            12,
          );

          final review = BrainReviewItem(
            id: 'review-003',
            conceptId: 'concept-003',
            question: 'Pergunta?',
            answer: 'Resposta.',
            sourceNotePath: '/tmp/source.md',
            sourceNoteTitle: 'Origem',
            createdAt: DateTime(
              2026,
              8,
              1,
            ),
            nextReviewAt: DateTime(
              2026,
              9,
              10,
            ),
            lastReviewedAt: DateTime(
              2026,
              9,
              1,
            ),
            archivedAt: archivedAt,
            reviewCount: 10,
            correctCount: 8,
            wrongCount: 2,
            streak: 5,
            archived: true,
          );

          final restored = mapper.fromVaultData(
            mapper.toVaultData(
              review,
            ),
          );

          expect(
            restored.archived,
            true,
          );

          expect(
            restored.archivedAt?.toUtc(),
            archivedAt.toUtc(),
          );
        },
      );

      test(
        'preserva valores zero',
        () {
          final review = BrainReviewItem(
            id: 'review-zero',
            conceptId: 'concept-zero',
            question: 'Pergunta nova?',
            answer: 'Resposta.',
            sourceNotePath: '/tmp/nova.md',
            sourceNoteTitle: 'Nova',
            createdAt: DateTime(
              2026,
              9,
              2,
            ),
            nextReviewAt: DateTime(
              2026,
              9,
              2,
            ),
            reviewCount: 0,
            correctCount: 0,
            wrongCount: 0,
            streak: 0,
            archived: false,
            archivedAt: null,
            lastReviewedAt: null,
          );

          final restored = mapper.fromVaultData(
            mapper.toVaultData(
              review,
            ),
          );

          expect(
            restored.reviewCount,
            0,
          );

          expect(
            restored.correctCount,
            0,
          );

          expect(
            restored.wrongCount,
            0,
          );

          expect(
            restored.streak,
            0,
          );

          expect(
            restored.lastReviewedAt,
            isNull,
          );

          expect(
            restored.archivedAt,
            isNull,
          );
        },
      );

      test(
        'preserva Unicode em pergunta e resposta',
        () {
          final review = BrainReviewItem(
            id: 'review-unicode',
            conceptId: 'concept-unicode',
            question: 'Что это? 日本語 🧠',
            answer: 'Resposta çãõ — Привет — 🔐',
            sourceNotePath: '/tmp/unicode.md',
            sourceNoteTitle: 'Unicode',
            createdAt: DateTime(
              2026,
              9,
              2,
            ),
            nextReviewAt: DateTime(
              2026,
              9,
              3,
            ),

            // ==================================================
            // REQUIRED NULLABLE FIELDS
            // ==================================================
            //
            // No seu BrainReviewItem esses campos aceitam null,
            // mas são parâmetros required no construtor.
            //
            // ==================================================
            lastReviewedAt: null,
            archivedAt: null,

            reviewCount: 0,
            correctCount: 0,
            wrongCount: 0,
            streak: 0,
            archived: false,
          );

          final restored = mapper.fromVaultData(
            mapper.toVaultData(
              review,
            ),
          );

          expect(
            restored.question,
            review.question,
          );

          expect(
            restored.answer,
            review.answer,
          );

          expect(
            restored.lastReviewedAt,
            isNull,
          );

          expect(
            restored.archivedAt,
            isNull,
          );
        },
      );

      test(
        'rejeita model incorreto',
        () {
          expect(
            () {
              mapper.fromVaultData(
                {
                  'model': 'brain_file',
                  'model_version': 1,
                },
              );
            },
            throwsA(
              isA<
                FormatException
              >(),
            ),
          );
        },
      );

      test(
        'rejeita model_version não suportada',
        () {
          expect(
            () {
              mapper.fromVaultData(
                {
                  'model': 'brain_review',
                  'model_version': 99,
                },
              );
            },
            throwsA(
              isA<
                FormatException
              >(),
            ),
          );
        },
      );

      test(
        'rejeita id vazio',
        () {
          expect(
            () {
              mapper.fromVaultData(
                {
                  'model': 'brain_review',
                  'model_version': 1,
                  'id': '',
                  'concept_id': 'concept',
                },
              );
            },
            throwsA(
              isA<
                FormatException
              >(),
            ),
          );
        },
      );

      test(
        'rejeita conceptId vazio',
        () {
          expect(
            () {
              mapper.fromVaultData(
                {
                  'model': 'brain_review',
                  'model_version': 1,
                  'id': 'review',
                  'concept_id': '',
                },
              );
            },
            throwsA(
              isA<
                FormatException
              >(),
            ),
          );
        },
      );

      test(
        'rejeita contador negativo',
        () {
          expect(
            () {
              mapper.fromVaultData(
                {
                  'model': 'brain_review',
                  'model_version': 1,
                  'id': 'review',
                  'concept_id': 'concept',
                  'question': 'Pergunta',
                  'answer': 'Resposta',
                  'source_note_path': '/tmp/a.md',
                  'source_note_title': 'A',
                  'created_at': DateTime(
                    2026,
                    9,
                    2,
                  ).toUtc().toIso8601String(),
                  'next_review_at': DateTime(
                    2026,
                    9,
                    3,
                  ).toUtc().toIso8601String(),
                  'last_reviewed_at': null,
                  'archived_at': null,
                  'review_count': -1,
                  'correct_count': 0,
                  'wrong_count': 0,
                  'streak': 0,
                  'archived': false,
                },
              );
            },
            throwsA(
              isA<
                FormatException
              >(),
            ),
          );
        },
      );

      test(
        'converte archived vindo como inteiro',
        () {
          final restored = mapper.fromVaultData(
            {
              'model': 'brain_review',
              'model_version': 1,
              'id': 'review-bool',
              'concept_id': 'concept-bool',
              'question': 'Pergunta',
              'answer': 'Resposta',
              'source_note_path': '/tmp/a.md',
              'source_note_title': 'A',
              'created_at': DateTime(
                2026,
                9,
                2,
              ).toUtc().toIso8601String(),
              'next_review_at': DateTime(
                2026,
                9,
                3,
              ).toUtc().toIso8601String(),
              'last_reviewed_at': null,
              'archived_at': null,
              'review_count': 0,
              'correct_count': 0,
              'wrong_count': 0,
              'streak': 0,
              'archived': 1,
            },
          );

          expect(
            restored.archived,
            true,
          );
        },
      );
    },
  );
}
