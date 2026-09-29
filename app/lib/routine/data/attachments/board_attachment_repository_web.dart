import 'dart:convert';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/attachments/board_attachment.dart';
import '../../models/attachments/board_attachment_type.dart';

class BoardAttachmentRepository {
  BoardAttachmentRepository({
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  static const String remoteTable = 'board_attachments';
  static const String storageBucket = 'board-files';

  final SupabaseClient _client;

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado.');
    }
    return user;
  }

  Future<void> initialize() async {}

  Future<List<BoardAttachment>> loadAll() async {
    final user = _requireUser();
    final rows = await _client
        .from(remoteTable)
        .select()
        .eq('user_id', user.id)
        .eq('is_deleted', false)
        .order('created_at');

    return rows
        .map<BoardAttachment>(
          (row) => BoardAttachment.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList(growable: false);
  }

  Future<List<BoardAttachment>> loadByBoardId(String boardId) async {
    final user = _requireUser();
    final normalized = _required(boardId, 'boardId');

    final rows = await _client
        .from(remoteTable)
        .select()
        .eq('user_id', user.id)
        .eq('board_id', normalized)
        .eq('is_deleted', false)
        .order('created_at');

    return rows
        .map<BoardAttachment>(
          (row) => BoardAttachment.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList(growable: false);
  }

  Future<List<BoardAttachment>> loadByBlockId({
    required String boardId,
    required String blockId,
  }) async {
    final user = _requireUser();
    final normalizedBoard = _required(boardId, 'boardId');
    final normalizedBlock = _required(blockId, 'blockId');

    final rows = await _client
        .from(remoteTable)
        .select()
        .eq('user_id', user.id)
        .eq('board_id', normalizedBoard)
        .eq('block_id', normalizedBlock)
        .eq('is_deleted', false)
        .order('created_at');

    return rows
        .map<BoardAttachment>(
          (row) => BoardAttachment.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList(growable: false);
  }

  Future<BoardAttachment?> getById(
    String id, {
    bool includeDeleted = false,
  }) async {
    final user = _requireUser();
    var query = _client
        .from(remoteTable)
        .select()
        .eq('user_id', user.id)
        .eq('id', _required(id, 'id'));

    if (!includeDeleted) {
      query = query.eq('is_deleted', false);
    }

    final row = await query.maybeSingle();
    if (row == null) return null;

    return BoardAttachment.fromMap(
      Map<String, dynamic>.from(row),
    );
  }

  Future<BoardAttachment> importAttachment({
    required String boardId,
    required String blockId,
    required String sourcePath,
  }) async {
    throw UnsupportedError(
      'O navegador não expõe caminho local de arquivo. '
      'Use importAttachmentBytes().',
    );
  }

  Future<BoardAttachment> importAttachmentBytes({
    required String boardId,
    required String blockId,
    required String fileName,
    required List<int> bytes,
    String? mimeType,
  }) async {
    final user = _requireUser();
    final normalizedBoard = _required(boardId, 'boardId');
    final normalizedBlock = _required(blockId, 'blockId');
    final normalizedName = _required(fileName, 'fileName');

    final id = const Uuid().v4();
    final now = DateTime.now().toUtc();
    final type = BoardAttachmentTypeX.fromFileName(normalizedName);
    final path = '${user.id}/$normalizedBoard/$id/$normalizedName';

    await _client.storage.from(storageBucket).uploadBinary(
      path,
      Uint8List.fromList(bytes),
      fileOptions: FileOptions(
        upsert: false,
        contentType: mimeType ?? type.mimeType,
      ),
    );

    final payload = <String, dynamic>{
      'id': id,
      'user_id': user.id,
      'board_id': normalizedBoard,
      'block_id': normalizedBlock,
      'file_name': normalizedName,
      'type': type.name,
      'remote_path': path,
      'mime_type': mimeType ?? type.mimeType,
      'size_bytes': bytes.length,
      'is_deleted': false,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };

    try {
      final row = await _client
          .from(remoteTable)
          .upsert(payload, onConflict: 'id')
          .select()
          .single();

      return BoardAttachment.fromMap(
        Map<String, dynamic>.from(row),
      );
    } catch (_) {
      try {
        await _client.storage.from(storageBucket).remove(<String>[path]);
      } catch (_) {}
      rethrow;
    }
  }

  Future<String> readText(BoardAttachment attachment) async {
    _assertOwner(attachment);
    final path = _remotePath(attachment);
    final bytes = await _client.storage.from(storageBucket).download(path);
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<BoardAttachment> saveText({
    required BoardAttachment attachment,
    required String content,
  }) async {
    _assertOwner(attachment);
    final path = _remotePath(attachment);
    final bytes = Uint8List.fromList(utf8.encode(content));

    await _client.storage.from(storageBucket).updateBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: attachment.mimeType ?? attachment.type.mimeType,
      ),
    );

    return saveMetadata(
      attachment.copyWith(
        sizeBytes: bytes.length,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<BoardAttachment> saveMetadata(BoardAttachment attachment) async {
    _assertOwner(attachment);
    final updated = attachment.copyWith(
      isDeleted: false,
      updatedAt: DateTime.now().toUtc(),
    );

    final row = await _client
        .from(remoteTable)
        .upsert(
          <String, dynamic>{
            ...updated.toRemoteMap(),
            'is_deleted': false,
          },
          onConflict: 'id',
        )
        .select()
        .single();

    return BoardAttachment.fromMap(
      Map<String, dynamic>.from(row),
    );
  }

  Future<bool> localFileExists(BoardAttachment attachment) async {
    // No Web o equivalente à cópia local é a cópia remota no Storage.
    return attachment.remotePath != null &&
        attachment.remotePath!.trim().isNotEmpty;
  }

  Future<void> delete(BoardAttachment attachment) async {
    _assertOwner(attachment);

    final path = attachment.remotePath?.trim();

    if (path != null && path.isNotEmpty) {
      try {
        await _client.storage.from(storageBucket).remove(<String>[path]);
      } catch (_) {
        // O metadata ainda será removido; o Storage pode ser limpo depois.
      }
    }

    await _client
        .from(remoteTable)
        .delete()
        .eq('id', attachment.id)
        .eq('user_id', _requireUser().id);
  }

  Future<void> deleteById(String id) async {
    final current = await getById(id, includeDeleted: true);
    if (current != null) {
      await delete(current);
    }
  }

  Future<BoardAttachment?> restore(String id) async {
    // No Web exclusão é definitiva para manter metadata e Storage coerentes.
    return getById(id, includeDeleted: true);
  }

  Future<void> markSynced({
    required String id,
    String? remotePath,
  }) async {}

  Future<void> deletePermanently(String id) => deleteById(id);

  Future<int> countByBoard(String boardId) async {
    final items = await loadByBoardId(boardId);
    return items.length;
  }

  void _assertOwner(BoardAttachment attachment) {
    if (attachment.userId != _requireUser().id) {
      throw StateError('O anexo não pertence ao usuário autenticado.');
    }
  }

  String _remotePath(BoardAttachment attachment) {
    final value = attachment.remotePath?.trim();
    if (value == null || value.isEmpty) {
      throw StateError('O documento não possui cópia remota.');
    }
    return value;
  }

  String _required(String value, String field) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, field, '$field não pode estar vazio.');
    }
    return normalized;
  }
}
