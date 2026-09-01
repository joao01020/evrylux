import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/brain_review_item.dart';

// ============================================================
// REVIEW STORAGE
// ============================================================
//
// Responsabilidade EXCLUSIVAMENTE LOCAL:
//
// - criar a pasta de revisões;
// - criar o arquivo reviews.json;
// - carregar revisões;
// - salvar revisões;
// - excluir revisões locais;
// - consultar revisões locais.
//
// Este serviço NÃO:
// - acessa Supabase;
// - conhece SyncQueue;
// - conhece SyncService.
//
// O fluxo remoto pertence ao ReviewRepository.
//
// ============================================================

class ReviewStorage {
  static const String _brainFolderName = 'ghost_brain';

  static const String _reviewsFolderName = '_reviews';

  static const String _reviewsFileName = 'reviews.json';

  static const String _temporaryFileName = 'reviews.tmp.json';

  const ReviewStorage();

  // ============================================================
  // DIRETÓRIO PRINCIPAL
  // ============================================================

  Future<
    Directory
  >
  getReviewsDirectory() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();

    final directory = Directory(
      '${documentsDirectory.path}/'
      '$_brainFolderName/'
      '$_reviewsFolderName',
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  // ============================================================
  // ARQUIVO DAS REVISÕES
  // ============================================================

  Future<
    File
  >
  getReviewsFile() async {
    final directory = await getReviewsDirectory();

    final file = File(
      '${directory.path}/$_reviewsFileName',
    );

    if (!await file.exists()) {
      await file.writeAsString(
        '[]',
        encoding: utf8,
        flush: true,
      );
    }

    return file;
  }

  // ============================================================
  // ARQUIVO TEMPORÁRIO
  // ============================================================

  Future<
    File
  >
  _getTemporaryFile() async {
    final directory = await getReviewsDirectory();

    return File(
      '${directory.path}/$_temporaryFileName',
    );
  }

  // ============================================================
  // CARREGAR TODAS
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadReviews() async {
    try {
      final file = await getReviewsFile();

      final content = await file.readAsString(
        encoding: utf8,
      );

      if (content.trim().isEmpty) {
        return [];
      }

      final decoded = jsonDecode(
        content,
      );

      if (decoded
          is! List) {
        debugPrint(
          'ReviewStorage: conteúdo inválido em reviews.json.',
        );

        return [];
      }

      final reviews =
          <
            BrainReviewItem
          >[];

      for (final item in decoded) {
        if (item
            is! Map) {
          continue;
        }

        try {
          final review = BrainReviewItem.fromJson(
            Map<
              String,
              dynamic
            >.from(
              item,
            ),
          );

          if (!_isValidReview(
            review,
          )) {
            debugPrint(
              'ReviewStorage: revisão inválida ignorada: ${review.id}',
            );

            continue;
          }

          reviews.add(
            review,
          );
        } catch (
          error,
          stackTrace
        ) {
          debugPrint(
            'ReviewStorage: revisão ignorada: $error',
          );

          debugPrintStack(
            stackTrace: stackTrace,
          );
        }
      }

      _sortReviews(
        reviews,
      );

      debugPrint(
        'ReviewStorage: ${reviews.length} revisões carregadas.',
      );

      return reviews;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        'ReviewStorage: erro ao carregar revisões.',
      );

      debugPrint(
        'ReviewStorage: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return [];
    }
  }

  // ============================================================
  // SALVAR TODAS
  // ============================================================
  //
  // Usa escrita temporária + rename.
  //
  // Isso reduz o risco de deixar reviews.json parcialmente
  // escrito caso a aplicação seja encerrada durante a gravação.
  //
  // ============================================================

  Future<
    void
  >
  saveReviews(
    List<
      BrainReviewItem
    >
    reviews,
  ) async {
    final normalized = _normalizeReviews(
      reviews,
    );

    final data = normalized.map(
      (
        review,
      ) {
        return review.toJson();
      },
    ).toList();

    const encoder = JsonEncoder.withIndent(
      '  ',
    );

    final json = encoder.convert(
      data,
    );

    final file = await getReviewsFile();

    final temporaryFile = await _getTemporaryFile();

    if (await temporaryFile.exists()) {
      await temporaryFile.delete();
    }

    await temporaryFile.writeAsString(
      json,
      encoding: utf8,
      flush: true,
    );

    if (await file.exists()) {
      await file.delete();
    }

    await temporaryFile.rename(
      file.path,
    );

    debugPrint(
      'ReviewStorage: ${normalized.length} revisões salvas.',
    );
  }

  // ============================================================
  // SALVAR UMA
  // ============================================================

  Future<
    BrainReviewItem
  >
  saveReview(
    BrainReviewItem review,
  ) async {
    final normalized = _normalizeReview(
      review,
    );

    final reviews = await loadReviews();

    final index = reviews.indexWhere(
      (
        item,
      ) {
        return item.id ==
            normalized.id;
      },
    );

    if (index >=
        0) {
      reviews[index] = normalized;
    } else {
      reviews.add(
        normalized,
      );
    }

    await saveReviews(
      reviews,
    );

    return normalized;
  }

  // ============================================================
  // BUSCAR POR ID
  // ============================================================

  Future<
    BrainReviewItem?
  >
  getReview(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return null;
    }

    final reviews = await loadReviews();

    for (final review in reviews) {
      if (review.id ==
          cleanId) {
        return review;
      }
    }

    return null;
  }

  // ============================================================
  // BUSCAR PELO CONCEITO
  // ============================================================

  Future<
    BrainReviewItem?
  >
  getReviewByConceptId(
    String conceptId,
  ) async {
    final cleanConceptId = conceptId.trim();

    if (cleanConceptId.isEmpty) {
      return null;
    }

    final reviews = await loadReviews();

    for (final review in reviews) {
      if (review.conceptId ==
          cleanConceptId) {
        return review;
      }
    }

    return null;
  }

  // ============================================================
  // BUSCAR PELO CAMINHO DA NOTA
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  getReviewsBySourceNotePath(
    String sourceNotePath,
  ) async {
    final cleanPath = sourceNotePath.trim();

    if (cleanPath.isEmpty) {
      return [];
    }

    final reviews = await loadReviews();

    return reviews.where(
      (
        review,
      ) {
        return review.sourceNotePath.trim() ==
            cleanPath;
      },
    ).toList();
  }

  // ============================================================
  // EXISTE PARA CONCEITO?
  // ============================================================

  Future<
    bool
  >
  hasReviewForConcept(
    String conceptId,
  ) async {
    final review = await getReviewByConceptId(
      conceptId,
    );

    return review !=
        null;
  }

  // ============================================================
  // EXCLUIR POR ID
  // ============================================================

  Future<
    void
  >
  deleteReview(
    String id,
  ) async {
    final cleanId = id.trim();

    if (cleanId.isEmpty) {
      return;
    }

    final reviews = await loadReviews();

    final previousLength = reviews.length;

    reviews.removeWhere(
      (
        review,
      ) {
        return review.id ==
            cleanId;
      },
    );

    if (reviews.length ==
        previousLength) {
      return;
    }

    await saveReviews(
      reviews,
    );

    debugPrint(
      'ReviewStorage: revisão excluída: $cleanId',
    );
  }

  // ============================================================
  // EXCLUIR PELO CONCEITO
  // ============================================================

  Future<
    void
  >
  deleteReviewByConceptId(
    String conceptId,
  ) async {
    final cleanConceptId = conceptId.trim();

    if (cleanConceptId.isEmpty) {
      return;
    }

    final reviews = await loadReviews();

    final previousLength = reviews.length;

    reviews.removeWhere(
      (
        review,
      ) {
        return review.conceptId ==
            cleanConceptId;
      },
    );

    if (reviews.length ==
        previousLength) {
      return;
    }

    await saveReviews(
      reviews,
    );

    debugPrint(
      'ReviewStorage: revisões do conceito excluídas: $cleanConceptId',
    );
  }

  // ============================================================
  // EXCLUIR PELA NOTA DE ORIGEM
  // ============================================================

  Future<
    void
  >
  deleteReviewsBySourceNotePath(
    String sourceNotePath,
  ) async {
    final cleanPath = sourceNotePath.trim();

    if (cleanPath.isEmpty) {
      return;
    }

    final reviews = await loadReviews();

    final previousLength = reviews.length;

    reviews.removeWhere(
      (
        review,
      ) {
        return review.sourceNotePath.trim() ==
            cleanPath;
      },
    );

    if (reviews.length ==
        previousLength) {
      return;
    }

    await saveReviews(
      reviews,
    );

    debugPrint(
      'ReviewStorage: revisões da nota de origem excluídas: $cleanPath',
    );
  }

  // ============================================================
  // REVISÕES DEVIDAS
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadDueReviews({
    DateTime? now,
  }) async {
    final current =
        now ??
        DateTime.now();

    final reviews = await loadReviews();

    final due = reviews.where(
      (
        review,
      ) {
        if (review.archived) {
          return false;
        }

        return !review.nextReviewAt.isAfter(
          current,
        );
      },
    ).toList();

    _sortReviews(
      due,
    );

    return due;
  }

  // ============================================================
  // REVISÕES FUTURAS
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadUpcomingReviews({
    DateTime? now,
  }) async {
    final current =
        now ??
        DateTime.now();

    final reviews = await loadReviews();

    final upcoming = reviews.where(
      (
        review,
      ) {
        if (review.archived) {
          return false;
        }

        return review.nextReviewAt.isAfter(
          current,
        );
      },
    ).toList();

    _sortReviews(
      upcoming,
    );

    return upcoming;
  }

  // ============================================================
  // ATIVAS
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadActiveReviews() async {
    final reviews = await loadReviews();

    final active = reviews.where(
      (
        review,
      ) {
        return !review.archived;
      },
    ).toList();

    _sortReviews(
      active,
    );

    return active;
  }

  // ============================================================
  // ARQUIVADAS
  // ============================================================

  Future<
    List<
      BrainReviewItem
    >
  >
  loadArchivedReviews() async {
    final reviews = await loadReviews();

    final archived = reviews.where(
      (
        review,
      ) {
        return review.archived;
      },
    ).toList();

    archived.sort(
      (
        first,
        second,
      ) {
        final firstDate =
            first.archivedAt ??
            first.createdAt;

        final secondDate =
            second.archivedAt ??
            second.createdAt;

        return secondDate.compareTo(
          firstDate,
        );
      },
    );

    return archived;
  }

  // ============================================================
  // LIMPAR TUDO
  // ============================================================

  Future<
    void
  >
  clear() async {
    final file = await getReviewsFile();

    final temporaryFile = await _getTemporaryFile();

    if (await temporaryFile.exists()) {
      await temporaryFile.delete();
    }

    await file.writeAsString(
      '[]',
      encoding: utf8,
      flush: true,
    );

    debugPrint(
      'ReviewStorage: revisões removidas.',
    );
  }

  // ============================================================
  // NORMALIZAR LISTA
  // ============================================================

  List<
    BrainReviewItem
  >
  _normalizeReviews(
    List<
      BrainReviewItem
    >
    reviews,
  ) {
    final byId =
        <
          String,
          BrainReviewItem
        >{};

    for (final review in reviews) {
      final normalized = _normalizeReview(
        review,
      );

      byId[normalized.id] = normalized;
    }

    final result = byId.values.toList();

    _sortReviews(
      result,
    );

    return result;
  }

  // ============================================================
  // NORMALIZAR UMA REVISÃO
  // ============================================================

  BrainReviewItem _normalizeReview(
    BrainReviewItem review,
  ) {
    final id = review.id.trim();

    final conceptId = review.conceptId.trim();

    final question = review.question.trim();

    final answer = review.answer.trim();

    final sourceNotePath = review.sourceNotePath.trim();

    final sourceNoteTitle = review.sourceNoteTitle.trim();

    if (id.isEmpty) {
      throw StateError(
        'ReviewStorage: revisão sem ID.',
      );
    }

    if (conceptId.isEmpty) {
      throw StateError(
        'ReviewStorage: revisão sem conceptId.',
      );
    }

    if (question.isEmpty) {
      throw StateError(
        'ReviewStorage: revisão sem pergunta.',
      );
    }

    if (answer.isEmpty) {
      throw StateError(
        'ReviewStorage: revisão sem resposta.',
      );
    }

    if (sourceNotePath.isEmpty) {
      throw StateError(
        'ReviewStorage: revisão sem caminho da nota de origem.',
      );
    }

    return review.copyWith(
      id: id,
      conceptId: conceptId,
      question: question,
      answer: answer,
      sourceNotePath: sourceNotePath,
      sourceNoteTitle: sourceNoteTitle,
    );
  }

  // ============================================================
  // VALIDAÇÃO DE LEITURA
  // ============================================================

  bool _isValidReview(
    BrainReviewItem review,
  ) {
    return review.id.trim().isNotEmpty &&
        review.conceptId.trim().isNotEmpty &&
        review.question.trim().isNotEmpty &&
        review.answer.trim().isNotEmpty &&
        review.sourceNotePath.trim().isNotEmpty;
  }

  // ============================================================
  // ORDENAR
  // ============================================================

  void _sortReviews(
    List<
      BrainReviewItem
    >
    reviews,
  ) {
    reviews.sort(
      (
        first,
        second,
      ) {
        if (first.archived !=
            second.archived) {
          return first.archived
              ? 1
              : -1;
        }

        return first.nextReviewAt.compareTo(
          second.nextReviewAt,
        );
      },
    );
  }
}
