import 'dart:io';

import 'package:path/path.dart' as p;
import '../../../core/storage/user_storage_scope.dart';

import '../../models/attachments/board_attachment.dart';
import '../../models/attachments/board_attachment_type.dart';

class BoardAttachmentStorage {
  const BoardAttachmentStorage({
    required UserStorageScope storageScope,
  }) : _storageScope = storageScope;

  final UserStorageScope _storageScope;

  Future<
    Directory
  >
  _rootDirectory() async {
    return _storageScope.boardsDirectory;
  }

  Future<
    Directory
  >
  boardDirectory(
    String boardId,
  ) async {
    final root = await _rootDirectory();

    final directory = Directory(
      p.join(
        root.path,
        _sanitizeSegment(
          boardId,
        ),
      ),
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  Future<
    Directory
  >
  attachmentsDirectory(
    String boardId,
  ) async {
    final board = await boardDirectory(
      boardId,
    );

    final directory = Directory(
      p.join(
        board.path,
        'attachments',
      ),
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  Future<
    Directory
  >
  attachmentDirectory({
    required String boardId,
    required String attachmentId,
  }) async {
    final attachments = await attachmentsDirectory(
      boardId,
    );

    final directory = Directory(
      p.join(
        attachments.path,
        _sanitizeSegment(
          attachmentId,
        ),
      ),
    );

    if (!await directory.exists()) {
      await directory.create(
        recursive: true,
      );
    }

    return directory;
  }

  Future<
    File
  >
  importFile({
    required String boardId,
    required String attachmentId,
    required String sourcePath,
    required String fileName,
  }) async {
    final source = File(
      sourcePath,
    );

    if (!await source.exists()) {
      throw FileSystemException(
        'Arquivo de origem não encontrado.',
        sourcePath,
      );
    }

    final directory = await attachmentDirectory(
      boardId: boardId,
      attachmentId: attachmentId,
    );

    final destination = File(
      p.join(
        directory.path,
        _sanitizeFileName(
          fileName,
        ),
      ),
    );

    if (await destination.exists()) {
      await destination.delete();
    }

    return source.copy(
      destination.path,
    );
  }

  Future<
    String
  >
  readText(
    BoardAttachment attachment,
  ) async {
    if (!attachment.type.isTextBased) {
      throw UnsupportedError(
        'Este tipo de arquivo não é textual.',
      );
    }

    final file = File(
      attachment.localPath,
    );

    if (!await file.exists()) {
      throw FileSystemException(
        'Arquivo local não encontrado.',
        attachment.localPath,
      );
    }

    return file.readAsString();
  }

  Future<
    void
  >
  writeText({
    required BoardAttachment attachment,
    required String content,
  }) async {
    if (!attachment.type.isTextBased) {
      throw UnsupportedError(
        'Este tipo de arquivo não pode ser editado como texto.',
      );
    }

    final file = File(
      attachment.localPath,
    );

    if (!await file.parent.exists()) {
      await file.parent.create(
        recursive: true,
      );
    }

    await file.writeAsString(
      content,
      flush: true,
    );
  }

  Future<
    bool
  >
  exists(
    BoardAttachment attachment,
  ) {
    return File(
      attachment.localPath,
    ).exists();
  }

  Future<
    void
  >
  deleteAttachmentFiles(
    BoardAttachment attachment,
  ) async {
    final file = File(
      attachment.localPath,
    );

    if (await file.exists()) {
      await file.delete();
    }

    final parent = file.parent;

    if (await parent.exists()) {
      final remaining = await parent.list().toList();

      if (remaining.isEmpty) {
        await parent.delete();
      }
    }
  }

  BoardAttachmentType detectType(
    String fileName,
  ) {
    return BoardAttachmentTypeX.fromFileName(
      fileName,
    );
  }

  String fileNameFromPath(
    String filePath,
  ) {
    return p.basename(
      filePath,
    );
  }

  String _sanitizeSegment(
    String value,
  ) {
    final normalized = value.trim().replaceAll(
      RegExp(
        r'[^a-zA-Z0-9_-]',
      ),
      '_',
    );

    if (normalized.isEmpty) {
      throw ArgumentError(
        'Segmento de caminho inválido.',
      );
    }

    return normalized;
  }

  String _sanitizeFileName(
    String fileName,
  ) {
    final normalized = fileName.trim().replaceAll(
      RegExp(
        r'[\\/:*?"<>|]',
      ),
      '_',
    );

    if (normalized.isEmpty) {
      throw ArgumentError(
        'Nome de arquivo inválido.',
      );
    }

    return normalized;
  }
}
