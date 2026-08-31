import 'dart:convert';

enum SyncOperation {
  create,
  update,
  delete;

  String get value {
    switch (this) {
      case SyncOperation.create:
        return 'create';
      case SyncOperation.update:
        return 'update';
      case SyncOperation.delete:
        return 'delete';
    }
  }

  static SyncOperation fromValue(
    String value,
  ) {
    switch (value) {
      case 'create':
        return SyncOperation.create;
      case 'update':
        return SyncOperation.update;
      case 'delete':
        return SyncOperation.delete;
      default:
        throw ArgumentError(
          'Operação de sincronização inválida: $value',
        );
    }
  }
}

class SyncItem {
  const SyncItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.attempts = 0,
    this.lastError,
    this.nextAttemptAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final SyncOperation operation;
  final Map<
    String,
    dynamic
  >
  payload;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int attempts;
  final String? lastError;
  final DateTime? nextAttemptAt;

  bool get canAttemptNow {
    final next = nextAttemptAt;

    if (next ==
        null) {
      return true;
    }

    return !next.isAfter(
      DateTime.now().toUtc(),
    );
  }

  String get payloadJson => jsonEncode(
    payload,
  );

  SyncItem copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperation? operation,
    Map<
      String,
      dynamic
    >?
    payload,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? attempts,
    String? lastError,
    bool clearLastError = false,
    DateTime? nextAttemptAt,
    bool clearNextAttemptAt = false,
  }) {
    return SyncItem(
      id:
          id ??
          this.id,
      entityType:
          entityType ??
          this.entityType,
      entityId:
          entityId ??
          this.entityId,
      operation:
          operation ??
          this.operation,
      payload:
          payload ??
          this.payload,
      createdAt:
          createdAt ??
          this.createdAt,
      updatedAt:
          updatedAt ??
          this.updatedAt,
      attempts:
          attempts ??
          this.attempts,
      lastError: clearLastError
          ? null
          : lastError ??
                this.lastError,
      nextAttemptAt: clearNextAttemptAt
          ? null
          : nextAttemptAt ??
                this.nextAttemptAt,
    );
  }

  factory SyncItem.fromDatabaseRow(
    Map<
      String,
      Object?
    >
    row,
  ) {
    final rawPayload =
        row['payload']?.toString() ??
        '{}';

    final decoded = jsonDecode(
      rawPayload,
    );

    return SyncItem(
      id:
          row['id']?.toString() ??
          '',
      entityType:
          row['entity_type']?.toString() ??
          '',
      entityId:
          row['entity_id']?.toString() ??
          '',
      operation: SyncOperation.fromValue(
        row['operation']?.toString() ??
            '',
      ),
      payload:
          decoded
              is Map
          ? Map<
              String,
              dynamic
            >.from(
              decoded,
            )
          : <
              String,
              dynamic
            >{},
      createdAt: DateTime.parse(
        row['created_at']?.toString() ??
            '',
      ).toUtc(),
      updatedAt: DateTime.parse(
        row['updated_at']?.toString() ??
            '',
      ).toUtc(),
      attempts:
          row['attempts']
              as int? ??
          int.tryParse(
            row['attempts']?.toString() ??
                '0',
          ) ??
          0,
      lastError: row['last_error']?.toString(),
      nextAttemptAt:
          row['next_attempt_at'] ==
              null
          ? null
          : DateTime.tryParse(
              row['next_attempt_at'].toString(),
            )?.toUtc(),
    );
  }

  Map<
    String,
    Object?
  >
  toDatabaseMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation.value,
      'payload': payloadJson,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'attempts': attempts,
      'last_error': lastError,
      'next_attempt_at': nextAttemptAt?.toUtc().toIso8601String(),
    };
  }
}
