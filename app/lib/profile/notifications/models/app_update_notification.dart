class AppUpdateNotification {
  const AppUpdateNotification({
    required this.version,
    required this.title,
    required this.message,
    required this.publishedAt,
    this.downloadUrl,
    this.isRead = false,
  });

  // ============================================================
  // DADOS
  // ============================================================

  final String version;

  final String title;

  final String message;

  final DateTime publishedAt;

  final String? downloadUrl;

  final bool isRead;

  // ============================================================
  // ID
  // ============================================================
  //
  // Como cada versão deve existir uma única vez, usamos a própria
  // versão como identificador lógico.
  //
  // Exemplo:
  //
  // version:
  //
  // 1.2.0
  //
  // id:
  //
  // app-update-1.2.0
  //
  // ============================================================

  String get id {
    return 'app-update-$version';
  }

  // ============================================================
  // NÃO LIDA
  // ============================================================

  bool get isUnread {
    return !isRead;
  }

  // ============================================================
  // POSSUI LINK
  // ============================================================

  bool get hasDownloadUrl {
    final value = downloadUrl?.trim();

    return value !=
            null &&
        value.isNotEmpty;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  AppUpdateNotification copyWith({
    String? version,
    String? title,
    String? message,
    DateTime? publishedAt,
    String? downloadUrl,
    bool? isRead,
  }) {
    return AppUpdateNotification(
      version:
          version ??
          this.version,

      title:
          title ??
          this.title,

      message:
          message ??
          this.message,

      publishedAt:
          publishedAt ??
          this.publishedAt,

      downloadUrl:
          downloadUrl ??
          this.downloadUrl,

      isRead:
          isRead ??
          this.isRead,
    );
  }

  // ============================================================
  // FROM MAP
  // ============================================================
  //
  // Já deixamos preparado para quando o AppUpdateService passar
  // a consultar Supabase, API própria ou outro backend.
  //
  // Campos esperados:
  //
  // version
  // title
  // message
  // published_at
  // download_url
  //
  // ============================================================

  factory AppUpdateNotification.fromMap(
    Map<
      String,
      dynamic
    >
    map,
  ) {
    final rawPublishedAt = map['published_at'];

    final parsedPublishedAt =
        rawPublishedAt !=
            null
        ? DateTime.tryParse(
            rawPublishedAt.toString(),
          )
        : null;

    return AppUpdateNotification(
      version:
          map['version']?.toString().trim() ??
          '',

      title:
          map['title']?.toString().trim() ??
          'Nova atualização',

      message:
          map['message']?.toString().trim() ??
          '',

      publishedAt:
          parsedPublishedAt?.toUtc() ??
          DateTime.now().toUtc(),

      downloadUrl: _nullIfEmpty(
        map['download_url']?.toString(),
      ),

      isRead: _parseBool(
        map['is_read'],
      ),
    );
  }

  // ============================================================
  // TO MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  toMap() {
    return {
      'version': version,

      'title': title,

      'message': message,

      'published_at': publishedAt.toUtc().toIso8601String(),

      'download_url': downloadUrl,

      'is_read': isRead,
    };
  }

  // ============================================================
  // PARSE BOOL
  // ============================================================

  static bool _parseBool(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().trim().toLowerCase();

    return normalized == '1' || normalized == 'true';
  }

  // ============================================================
  // NULL IF EMPTY
  // ============================================================

  static String? _nullIfEmpty(
    String? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final normalized = value.trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  // ============================================================
  // EQUALITY
  // ============================================================

  @override
  bool operator ==(
    Object other,
  ) {
    if (identical(
      this,
      other,
    )) {
      return true;
    }

    return other
            is AppUpdateNotification &&
        other.version ==
            version;
  }

  @override
  int get hashCode {
    return version.hashCode;
  }
}
