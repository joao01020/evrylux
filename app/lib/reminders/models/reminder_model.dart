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

  // ============================================================
  // HORÁRIO DO LEMBRETE
  // ============================================================
  //
  // REGRA DO PROJETO:
  //
  // Internamente o ReminderModel trabalha SEMPRE em UTC.
  //
  // Exemplo:
  //
  // Usuário escolhe em Brasília:
  //
  // 01/09/2026 22:30
  //
  // Internamente:
  //
  // 02/09/2026 01:30:00Z
  //
  // O horário de Brasília deve ser calculado somente quando
  // precisamos exibir a data/hora para o usuário.
  //
  // Isso impede que o comportamento do app dependa do timezone
  // configurado no Linux, Windows ou outro sistema operacional.
  //
  // ============================================================

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
  // PARSE UTC
  // ============================================================
  //
  // Supabase normalmente retorna:
  //
  // 2026-09-02T01:30:00+00:00
  //
  // ou:
  //
  // 2026-09-02T01:30:00Z
  //
  // Independentemente do formato recebido, normalizamos para UTC.
  //
  // ============================================================

  static DateTime _parseUtcDateTime(
    dynamic value,
  ) {
    final parsed = DateTime.parse(
      value.toString(),
    );

    return parsed.toUtc();
  }

  // ============================================================
  // PARSE UTC OPCIONAL
  // ============================================================

  static DateTime? _parseOptionalUtcDateTime(
    dynamic value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final parsed = DateTime.tryParse(
      value.toString(),
    );

    return parsed?.toUtc();
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

      remindAt: _parseUtcDateTime(
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

      createdAt: _parseOptionalUtcDateTime(
        json['created_at'],
      ),

      updatedAt: _parseOptionalUtcDateTime(
        json['updated_at'],
      ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================
  //
  // Todo DateTime enviado para persistência é normalizado
  // explicitamente para UTC.
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

      'remind_at': remindAt.toUtc().toIso8601String(),

      'source_type': sourceType,

      'source_id': sourceId,

      'notify_in_app': notifyInApp,

      'notify_telegram': notifyTelegram,

      'sent_in_app': sentInApp,

      'sent_telegram': sentTelegram,

      'completed': completed,

      'created_at': createdAt?.toUtc().toIso8601String(),

      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }

  // ============================================================
  // TO INSERT JSON
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

      'remind_at': remindAt.toUtc().toIso8601String(),

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
  //
  // O novo remindAt continua sendo normalizado para UTC.
  //
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
              .toUtc(),

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
          createdAt !=
              null
          ? createdAt.toUtc()
          : this.createdAt,

      updatedAt:
          updatedAt !=
              null
          ? updatedAt.toUtc()
          : this.updatedAt,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get isPending {
    return !completed;
  }

  // ============================================================
  // ESTÁ VENCIDO
  // ============================================================
  //
  // Comparamos UTC com UTC.
  //
  // ============================================================

  bool get isDue {
    if (completed) {
      return false;
    }

    final nowUtc = DateTime.now().toUtc();

    return !remindAt.toUtc().isAfter(
      nowUtc,
    );
  }

  // ============================================================
  // ESTÁ NO FUTURO
  // ============================================================

  bool get isFuture {
    return remindAt.toUtc().isAfter(
      DateTime.now().toUtc(),
    );
  }

  // ============================================================
  // HORÁRIO DE BRASÍLIA
  // ============================================================
  //
  // Não usamos DateTime.toLocal(), porque isso dependeria do
  // timezone configurado no computador.
  //
  // Atualmente Brasília / São Paulo está sendo tratada pelo app
  // como UTC-3.
  //
  // ============================================================

  DateTime get brasiliaRemindAt {
    final utc = remindAt.toUtc();

    return DateTime(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
      utc.second,
      utc.millisecond,
      utc.microsecond,
    ).subtract(
      const Duration(
        hours: 3,
      ),
    );
  }

  // ============================================================
  // COMPATIBILIDADE
  // ============================================================
  //
  // Mantemos localRemindAt para não quebrar widgets existentes,
  // mas ele agora representa explicitamente o horário utilizado
  // pela interface do projeto: Brasília.
  //
  // Não representa mais o timezone configurado no computador.
  //
  // ============================================================

  DateTime get localRemindAt {
    return brasiliaRemindAt;
  }

  // ============================================================
  // HORÁRIO UTC
  // ============================================================

  DateTime get utcRemindAt {
    return remindAt.toUtc();
  }

  // ============================================================
  // DEBUG
  // ============================================================

  String get debugTime {
    return '''
Brasília: $brasiliaRemindAt
UTC: ${utcRemindAt.toIso8601String()}
''';
  }
}
