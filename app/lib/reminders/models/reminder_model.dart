class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.remindAt,
    required this.notifyInApp,
    required this.notifyTelegram,
    required this.sentInApp,
    required this.sentTelegram,
    required this.completed,
    this.sourceType,
    this.sourceId,
    this.createdAt,
    this.updatedAt,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final String id;

  final String userId;

  final String title;

  final String message;

  /// Internamente no Flutter mantemos este horário em LOCAL.
  ///
  /// Exemplo:
  ///
  /// Usuário escolhe:
  ///
  /// 22:30
  ///
  /// remindAt:
  ///
  /// 2026-08-29 22:30:00
  ///
  /// Ao enviar ao Supabase:
  ///
  /// 2026-08-30T01:30:00.000Z
  ///
  final DateTime remindAt;

  final String? sourceType;

  final String? sourceId;

  final bool notifyInApp;

  final bool notifyTelegram;

  final bool sentInApp;

  final bool sentTelegram;

  final bool completed;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  // ============================================================
  // PARSE DATE
  // ============================================================
  //
  // Supabase normalmente retorna:
  //
  // 2026-08-30T01:30:00+00:00
  //
  // ou:
  //
  // 2026-08-30T01:30:00Z
  //
  // O modelo converte imediatamente para o horário local
  // do dispositivo.
  //
  // ============================================================

  static DateTime _parseLocalDateTime(
    dynamic value,
  ) {
    final parsed = DateTime.parse(
      value.toString(),
    );

    return parsed.toLocal();
  }

  // ============================================================
  // PARSE DATE OPCIONAL
  // ============================================================

  static DateTime? _parseOptionalLocalDateTime(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final parsed = DateTime.tryParse(
      value.toString(),
    );

    return parsed?.toLocal();
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory ReminderModel.fromJson(
    Map<
      String,
      dynamic
    >
    json,
  ) {
    return ReminderModel(
      id:
          json['id']?.toString() ??
          '',
      userId:
          json['user_id']?.toString() ??
          '',
      title:
          json['title']?.toString() ??
          '',
      message:
          json['message']?.toString() ??
          '',
      remindAt: _parseLocalDateTime(
        json['remind_at'],
      ),
      sourceType: json['source_type']?.toString(),
      sourceId: json['source_id']?.toString(),
      notifyInApp:
          json['notify_in_app']
              as bool? ??
          true,
      notifyTelegram:
          json['notify_telegram']
              as bool? ??
          false,
      sentInApp:
          json['sent_in_app']
              as bool? ??
          false,
      sentTelegram:
          json['sent_telegram']
              as bool? ??
          false,
      completed:
          json['completed']
              as bool? ??
          false,
      createdAt: _parseOptionalLocalDateTime(
        json['created_at'],
      ),
      updatedAt: _parseOptionalLocalDateTime(
        json['updated_at'],
      ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================
  //
  // O Flutter trabalha com horário LOCAL.
  //
  // O Supabase recebe UTC.
  //
  // Exemplo:
  //
  // Flutter:
  //
  // 2026-08-29 22:30
  //
  // Supabase:
  //
  // 2026-08-30T01:30:00.000Z
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,

      'remind_at': remindAt.toLocal().toUtc().toIso8601String(),

      'source_type': sourceType,

      'source_id': sourceId,

      'notify_in_app': notifyInApp,

      'notify_telegram': notifyTelegram,

      'sent_in_app': sentInApp,

      'sent_telegram': sentTelegram,

      'completed': completed,

      'created_at': createdAt?.toLocal().toUtc().toIso8601String(),

      'updated_at': updatedAt?.toLocal().toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // TO INSERT JSON
  // ============================================================
  //
  // Não enviamos:
  //
  // id
  // created_at
  // updated_at
  //
  // porque o Supabase gera esses valores.
  //
  // ============================================================

  Map<
    String,
    dynamic
  >
  toInsertJson() {
    return {
      'user_id': userId,

      'title': title,

      'message': message,

      'remind_at': remindAt.toLocal().toUtc().toIso8601String(),

      'source_type': sourceType,

      'source_id': sourceId,

      'notify_in_app': notifyInApp,

      'notify_telegram': notifyTelegram,

      'sent_in_app': sentInApp,

      'sent_telegram': sentTelegram,

      'completed': completed,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  ReminderModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    DateTime? remindAt,
    String? sourceType,
    String? sourceId,
    bool? notifyInApp,
    bool? notifyTelegram,
    bool? sentInApp,
    bool? sentTelegram,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReminderModel(
      id:
          id ??
          this.id,

      userId:
          userId ??
          this.userId,

      title:
          title ??
          this.title,

      message:
          message ??
          this.message,

      remindAt:
          (remindAt ??
                  this.remindAt)
              .toLocal(),

      sourceType:
          sourceType ??
          this.sourceType,

      sourceId:
          sourceId ??
          this.sourceId,

      notifyInApp:
          notifyInApp ??
          this.notifyInApp,

      notifyTelegram:
          notifyTelegram ??
          this.notifyTelegram,

      sentInApp:
          sentInApp ??
          this.sentInApp,

      sentTelegram:
          sentTelegram ??
          this.sentTelegram,

      completed:
          completed ??
          this.completed,

      createdAt:
          createdAt ??
          this.createdAt,

      updatedAt:
          updatedAt ??
          this.updatedAt,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isPending {
    return !completed;
  }

  bool get isDue {
    if (completed) {
      return false;
    }

    final now = DateTime.now();

    final localReminder = remindAt.toLocal();

    return !localReminder.isAfter(
      now,
    );
  }

  bool get isFuture {
    return remindAt.toLocal().isAfter(
      DateTime.now(),
    );
  }

  // ============================================================
  // HORÁRIO LOCAL
  // ============================================================

  DateTime get localRemindAt {
    return remindAt.toLocal();
  }

  // ============================================================
  // HORÁRIO UTC
  // ============================================================

  DateTime get utcRemindAt {
    return remindAt.toLocal().toUtc();
  }

  // ============================================================
  // DEBUG
  // ============================================================
  //
  // Útil enquanto estamos testando timezone.
  //
  // Exemplo:
  //
  // Local: 2026-08-29 22:30:00
  // UTC:   2026-08-30 01:30:00Z
  //
  // ============================================================

  String get debugTime {
    return '''
Local: ${remindAt.toLocal()}
UTC: ${remindAt.toLocal().toUtc().toIso8601String()}
''';
  }
}
