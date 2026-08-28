import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/brain_review_item.dart';

class ReviewStorage {
  static const String _brainFolderName = 'ghost_brain';

  static const String _reviewsFolderName = '_reviews';

  static const String _reviewsFileName = 'reviews.json';

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
          'ReviewStorage: conteúdo inválido.',
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

          reviews.add(
            review,
          );
        } catch (
          error
        ) {
          debugPrint(
            'ReviewStorage: revisão ignorada: $error',
          );
        }
      }

      reviews.sort(
        (
          first,
          second,
        ) {
          return first.nextReviewAt.compareTo(
            second.nextReviewAt,
          );
        },
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

  Future<
    void
  >
  saveReviews(
    List<
      BrainReviewItem
    >
    reviews,
  ) async {
    final file = await getReviewsFile();

    final data = reviews.map(
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

    await file.writeAsString(
      json,
      encoding: utf8,
      flush: true,
    );

    debugPrint(
      'ReviewStorage: ${reviews.length} revisões salvas.',
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
    final reviews = await loadReviews();

    final index = reviews.indexWhere(
      (
        item,
      ) {
        return item.id ==
            review.id;
      },
    );

    if (index >=
        0) {
      reviews[index] = review;
    } else {
      reviews.add(
        review,
      );
    }

    await saveReviews(
      reviews,
    );

    return review;
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
    final reviews = await loadReviews();

    for (final review in reviews) {
      if (review.id ==
          id) {
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
    final reviews = await loadReviews();

    for (final review in reviews) {
      if (review.conceptId ==
          conceptId) {
        return review;
      }
    }

    return null;
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
  // EXCLUIR
  // ============================================================

  Future<
    void
  >
  deleteReview(
    String id,
  ) async {
    final reviews = await loadReviews();

    reviews.removeWhere(
      (
        review,
      ) {
        return review.id ==
            id;
      },
    );

    await saveReviews(
      reviews,
    );

    debugPrint(
      'ReviewStorage: revisão excluída: $id',
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
    final reviews = await loadReviews();

    reviews.removeWhere(
      (
        review,
      ) {
        return review.conceptId ==
            conceptId;
      },
    );

    await saveReviews(
      reviews,
    );
  }

  // ============================================================
  // REVISÕES DE HOJE
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

    due.sort(
      (
        first,
        second,
      ) {
        return first.nextReviewAt.compareTo(
          second.nextReviewAt,
        );
      },
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

    upcoming.sort(
      (
        first,
        second,
      ) {
        return first.nextReviewAt.compareTo(
          second.nextReviewAt,
        );
      },
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

    return reviews.where(
      (
        review,
      ) {
        return !review.archived;
      },
    ).toList();
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

    return reviews.where(
      (
        review,
      ) {
        return review.archived;
      },
    ).toList();
  }

  // ============================================================
  // LIMPAR TUDO
  // ============================================================

  Future<
    void
  >
  clear() async {
    final file = await getReviewsFile();

    await file.writeAsString(
      '[]',
      encoding: utf8,
      flush: true,
    );

    debugPrint(
      'ReviewStorage: revisões removidas.',
    );
  }
}
