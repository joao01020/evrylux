import 'board_attachment_type.dart';

class BoardAttachment {
  const BoardAttachment({
    required this.id,
    required this.userId,
    required this.boardId,
    required this.blockId,
    required this.fileName,
    required this.type,
    required this.localPath,
    required this.sizeBytes,
    required this.createdAt,
    required this.updatedAt,
    this.remotePath,
    this.mimeType,
    this.isDeleted = false,
  });

  final String id;
  final String userId;
  final String boardId;
  final String blockId;

  final String fileName;
  final BoardAttachmentType type;
  final String localPath;
  final String? remotePath;
  final String? mimeType;
  final int sizeBytes;

  final bool isDeleted;

  final DateTime createdAt;
  final DateTime updatedAt;

  String get extension {
    final index = fileName.lastIndexOf(
      '.',
    );

    if (index <
            0 ||
        index ==
            fileName.length -
                1) {
      return type.extension;
    }

    return fileName
        .substring(
          index +
              1,
        )
        .toLowerCase();
  }

  bool get hasRemoteCopy {
    return remotePath !=
            null &&
        remotePath!.trim().isNotEmpty;
  }

  bool get canOpenInApp {
    return type.isTextBased;
  }

  BoardAttachment copyWith({
    String? id,
    String? userId,
    String? boardId,
    String? blockId,
    String? fileName,
    BoardAttachmentType? type,
    String? localPath,
    String? remotePath,
    String? mimeType,
    int? sizeBytes,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BoardAttachment(
      id:
          id ??
          this.id,
      userId:
          userId ??
          this.userId,
      boardId:
          boardId ??
          this.boardId,
      blockId:
          blockId ??
          this.blockId,
      fileName:
          fileName ??
          this.fileName,
      type:
          type ??
          this.type,
      localPath:
          localPath ??
          this.localPath,
      remotePath:
          remotePath ??
          this.remotePath,
      mimeType:
          mimeType ??
          this.mimeType,
      sizeBytes:
          sizeBytes ??
          this.sizeBytes,
      isDeleted:
          isDeleted ??
          this.isDeleted,
      createdAt:
          createdAt ??
          this.createdAt,
      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'id': id,
      'user_id': userId,
      'board_id': boardId,
      'block_id': blockId,
      'file_name': fileName,
      'type': type.name,
      'local_path': localPath,
      'remote_path': remotePath,
      'mime_type':
          mimeType ??
          type.mimeType,
      'size_bytes': sizeBytes,
      'is_deleted': isDeleted
          ? 1
          : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Map<
    String,
    dynamic
  >
  toRemoteMap() {
    return {
      'id': id,
      'user_id': userId,
      'board_id': boardId,
      'block_id': blockId,
      'file_name': fileName,
      'type': type.name,
      'remote_path': remotePath,
      'mime_type':
          mimeType ??
          type.mimeType,
      'size_bytes': sizeBytes,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory BoardAttachment.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    return BoardAttachment(
      id:
          map['id']?.toString() ??
          '',
      userId:
          map['user_id']?.toString() ??
          '',
      boardId:
          map['board_id']?.toString() ??
          '',
      blockId:
          map['block_id']?.toString() ??
          '',
      fileName:
          map['file_name']?.toString() ??
          '',
      type: BoardAttachmentTypeX.fromValue(
        map['type']?.toString(),
      ),
      localPath:
          map['local_path']?.toString() ??
          '',
      remotePath: _nullableString(
        map['remote_path'],
      ),
      mimeType: _nullableString(
        map['mime_type'],
      ),
      sizeBytes: _asInt(
        map['size_bytes'],
      ),
      isDeleted: _asBool(
        map['is_deleted'],
      ),
      createdAt: _asDate(
        map['created_at'],
      ),
      updatedAt: _asDate(
        map['updated_at'],
      ),
    );
  }

  static String? _nullableString(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final normalized = value.toString().trim();

    return normalized.isEmpty
        ? null
        : normalized;
  }

  static int _asInt(
    dynamic value,
  ) {
    if (value
        is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ??
              '',
        ) ??
        0;
  }

  static bool _asBool(
    dynamic value,
  ) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is int) {
      return value !=
          0;
    }

    final normalized = value?.toString().trim().toLowerCase();

    return normalized ==
            'true' ||
        normalized ==
            '1';
  }

  static DateTime _asDate(
    dynamic value,
  ) {
    if (value
        is DateTime) {
      return value;
    }

    return DateTime.tryParse(
          value?.toString() ??
              '',
        ) ??
        DateTime.now();
  }
}
