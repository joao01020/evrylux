class TelegramConnection {
  const TelegramConnection({
    required this.userId,
    required this.chatId,
    required this.enabled,
    this.username,
    this.firstName,
    this.connectedAt,
    this.updatedAt,
  });

  final String userId;
  final String chatId;
  final bool enabled;
  final String? username;
  final String? firstName;
  final DateTime? connectedAt;
  final DateTime? updatedAt;

  String get displayName {
    final cleanUsername = username?.trim();

    if (cleanUsername != null && cleanUsername.isNotEmpty) {
      return '@$cleanUsername';
    }

    final cleanFirstName = firstName?.trim();

    if (cleanFirstName != null && cleanFirstName.isNotEmpty) {
      return cleanFirstName;
    }

    return 'Telegram conectado';
  }

  factory TelegramConnection.fromMap(Map<String, dynamic> map) {
    return TelegramConnection(
      userId: (map['user_id'] ?? '').toString(),
      chatId: (map['chat_id'] ?? '').toString(),
      username: map['username']?.toString(),
      firstName: map['first_name']?.toString(),
      enabled: map['enabled'] as bool? ?? true,
      connectedAt: _parseDate(map['connected_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
