import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/attachments/board_attachment.dart';
import '../../models/attachments/board_attachment_type.dart';
import 'board_attachment_storage.dart';

class BoardAttachmentService {
  BoardAttachmentService({
    BoardAttachmentStorage? storage,
    required SupabaseClient client,
  }) : _storage =
           storage ??
           const BoardAttachmentStorage(),
       _client = client;

  final BoardAttachmentStorage _storage;
  final SupabaseClient _client;

  Future<
    BoardAttachment
  >
  importAttachment({
    required String boardId,
    required String blockId,
    required String sourcePath,
  }) async {
    final user = _client.auth.currentUser;

    if (user ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    final normalizedBoardId = _requireValue(
      boardId,
      'boardId',
    );

    final normalizedBlockId = _requireValue(
      blockId,
      'blockId',
    );

    final normalizedSourcePath = _requireValue(
      sourcePath,
      'sourcePath',
    );

    final fileName = _storage.fileNameFromPath(
      normalizedSourcePath,
    );

    final type = _storage.detectType(
      fileName,
    );

    if (type ==
        BoardAttachmentType.unknown) {
      throw UnsupportedError(
        'Tipo de arquivo ainda não suportado. Use .md ou .txt.',
      );
    }

    final source = File(
      normalizedSourcePath,
    );

    if (!await source.exists()) {
      throw FileSystemException(
        'Arquivo não encontrado.',
        normalizedSourcePath,
      );
    }

    final now = DateTime.now().toUtc();

    final attachmentId = _uuidV4();

    final imported = await _storage.importFile(
      boardId: normalizedBoardId,
      attachmentId: attachmentId,
      sourcePath: normalizedSourcePath,
      fileName: fileName,
    );

    final sizeBytes = await imported.length();

    return BoardAttachment(
      id: attachmentId,
      userId: user.id,
      boardId: normalizedBoardId,
      blockId: normalizedBlockId,
      fileName: fileName,
      type: type,
      localPath: imported.path,
      mimeType: type.mimeType,
      sizeBytes: sizeBytes,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<
    String
  >
  readText(
    BoardAttachment attachment,
  ) {
    _assertOwnership(
      attachment,
    );

    return _storage.readText(
      attachment,
    );
  }

  Future<
    BoardAttachment
  >
  writeText({
    required BoardAttachment attachment,
    required String content,
  }) async {
    _assertOwnership(
      attachment,
    );

    await _storage.writeText(
      attachment: attachment,
      content: content,
    );

    final file = File(
      attachment.localPath,
    );

    final sizeBytes = await file.length();

    return attachment.copyWith(
      sizeBytes: sizeBytes,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  Future<
    bool
  >
  exists(
    BoardAttachment attachment,
  ) {
    _assertOwnership(
      attachment,
    );

    return _storage.exists(
      attachment,
    );
  }

  Future<
    void
  >
  deleteLocal(
    BoardAttachment attachment,
  ) async {
    _assertOwnership(
      attachment,
    );

    await _storage.deleteAttachmentFiles(
      attachment,
    );
  }

  String buildRemotePath(
    BoardAttachment attachment,
  ) {
    _assertOwnership(
      attachment,
    );

    final safeName = attachment.fileName.trim().replaceAll(
      RegExp(
        r'[\\/:*?"<>|]',
      ),
      '_',
    );

    return '${attachment.userId}/'
        '${attachment.boardId}/'
        '${attachment.id}/'
        '$safeName';
  }

  void _assertOwnership(
    BoardAttachment attachment,
  ) {
    final user = _client.auth.currentUser;

    if (user ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    if (attachment.userId !=
        user.id) {
      throw StateError(
        'O anexo não pertence ao usuário autenticado.',
      );
    }
  }

  String _requireValue(
    String value,
    String fieldName,
  ) {
    final normalized = value.trim();

    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        fieldName,
        '$fieldName não pode estar vazio.',
      );
    }

    return normalized;
  }

  String _uuidV4() {
    final random = Random.secure();

    final bytes =
        List<
          int
        >.generate(
          16,
          (
            _,
          ) => random.nextInt(
            256,
          ),
        );

    bytes[6] =
        (bytes[6] &
            0x0F) |
        0x40;
    bytes[8] =
        (bytes[8] &
            0x3F) |
        0x80;

    String hex(
      int value,
    ) {
      return value
          .toRadixString(
            16,
          )
          .padLeft(
            2,
            '0',
          );
    }

    final value = bytes
        .map(
          hex,
        )
        .join();

    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20, 32)}';
  }
}
