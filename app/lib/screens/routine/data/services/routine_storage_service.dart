import 'dart:io';
import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class RoutineStorageService {
  RoutineStorageService({
    SupabaseClient? client,
  }) : _client =
           client ??
           Supabase.instance.client;

  final SupabaseClient _client;

  // ============================================================
  // BUCKET
  // ============================================================

  static const String bucketName = 'routine-images';

  // ============================================================
  // UPLOAD FILE
  // ============================================================

  Future<
    String
  >
  uploadFile({
    required String userId,
    required String routineId,
    required File file,
    String? fileName,
  }) async {
    final extension = _extensionFromPath(
      file.path,
    );

    final name =
        fileName ??
        '${DateTime.now().microsecondsSinceEpoch}$extension';

    final storagePath = _buildPath(
      userId: userId,
      routineId: routineId,
      fileName: name,
    );

    await _client.storage
        .from(
          bucketName,
        )
        .upload(
          storagePath,
          file,
          fileOptions: const FileOptions(
            upsert: false,
          ),
        );

    return storagePath;
  }

  // ============================================================
  // UPLOAD BYTES
  // ============================================================

  Future<
    String
  >
  uploadBytes({
    required String userId,
    required String routineId,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final storagePath = _buildPath(
      userId: userId,
      routineId: routineId,
      fileName: fileName,
    );

    await _client.storage
        .from(
          bucketName,
        )
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: contentType,
          ),
        );

    return storagePath;
  }

  // ============================================================
  // REPLACE FILE
  // ============================================================

  Future<
    String
  >
  replaceFile({
    required String storagePath,
    required File file,
  }) async {
    await _client.storage
        .from(
          bucketName,
        )
        .update(
          storagePath,
          file,
          fileOptions: const FileOptions(
            upsert: true,
          ),
        );

    return storagePath;
  }

  // ============================================================
  // REPLACE BYTES
  // ============================================================

  Future<
    String
  >
  replaceBytes({
    required String storagePath,
    required Uint8List bytes,
    String? contentType,
  }) async {
    await _client.storage
        .from(
          bucketName,
        )
        .updateBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: contentType,
          ),
        );

    return storagePath;
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<
    void
  >
  delete(
    String storagePath,
  ) async {
    if (storagePath.trim().isEmpty) {
      return;
    }

    await _client.storage
        .from(
          bucketName,
        )
        .remove(
          [
            storagePath,
          ],
        );
  }

  // ============================================================
  // DELETE MULTIPLE
  // ============================================================

  Future<
    void
  >
  deleteMany(
    Iterable<
      String
    >
    paths,
  ) async {
    final values = paths
        .where(
          (
            path,
          ) => path.trim().isNotEmpty,
        )
        .toList();

    if (values.isEmpty) {
      return;
    }

    await _client.storage
        .from(
          bucketName,
        )
        .remove(
          values,
        );
  }

  // ============================================================
  // SIGNED URL
  // ============================================================
  //
  // Nosso bucket é privado.
  //
  // Por isso usamos signed URL em vez de getPublicUrl().
  //
  // ============================================================

  Future<
    String
  >
  createSignedUrl({
    required String storagePath,
    Duration expiresIn = const Duration(
      hours: 1,
    ),
  }) {
    return _client.storage
        .from(
          bucketName,
        )
        .createSignedUrl(
          storagePath,
          expiresIn.inSeconds,
        );
  }

  // ============================================================
  // DOWNLOAD
  // ============================================================

  Future<
    Uint8List
  >
  download(
    String storagePath,
  ) {
    return _client.storage
        .from(
          bucketName,
        )
        .download(
          storagePath,
        );
  }

  // ============================================================
  // EXISTS
  // ============================================================

  Future<
    bool
  >
  exists({
    required String userId,
    required String routineId,
    required String fileName,
  }) async {
    final folder = '$userId/$routineId';

    final files = await _client.storage
        .from(
          bucketName,
        )
        .list(
          path: folder,
          searchOptions: SearchOptions(
            search: fileName,
            limit: 100,
          ),
        );

    return files.any(
      (
        file,
      ) =>
          file.name ==
          fileName,
    );
  }

  // ============================================================
  // PATH
  // ============================================================

  String _buildPath({
    required String userId,
    required String routineId,
    required String fileName,
  }) {
    final safeUserId = _sanitizeSegment(
      userId,
    );

    final safeRoutineId = _sanitizeSegment(
      routineId,
    );

    final safeFileName = _sanitizeFileName(
      fileName,
    );

    return '$safeUserId/'
        '$safeRoutineId/'
        '$safeFileName';
  }

  // ============================================================
  // SANITIZE
  // ============================================================

  String _sanitizeSegment(
    String value,
  ) {
    return value
        .trim()
        .replaceAll(
          '/',
          '_',
        )
        .replaceAll(
          '\\',
          '_',
        );
  }

  String _sanitizeFileName(
    String value,
  ) {
    final sanitized = value
        .trim()
        .replaceAll(
          '/',
          '_',
        )
        .replaceAll(
          '\\',
          '_',
        );

    if (sanitized.isEmpty) {
      return '${DateTime.now().microsecondsSinceEpoch}.bin';
    }

    return sanitized;
  }

  // ============================================================
  // EXTENSION
  // ============================================================

  String _extensionFromPath(
    String path,
  ) {
    final normalized = path.replaceAll(
      '\\',
      '/',
    );

    final fileName = normalized
        .split(
          '/',
        )
        .last;

    final index = fileName.lastIndexOf(
      '.',
    );

    if (index <=
            0 ||
        index ==
            fileName.length -
                1) {
      return '';
    }

    return fileName.substring(
      index,
    );
  }
}
