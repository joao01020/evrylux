import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/telegram_connection.dart';

class TelegramConnectionService {
  TelegramConnectionService({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  String get _userId {
    final userId = _client.auth.currentUser?.id.trim();

    if (userId == null || userId.isEmpty) {
      throw StateError('Entre na sua conta para conectar o Telegram.');
    }

    return userId;
  }

  Future<TelegramConnection?> loadConnection() async {
    final userId = _userId;

    final data = await _client
        .from('telegram_connections')
        .select(
          'user_id, chat_id, username, first_name, enabled, connected_at, updated_at',
        )
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return TelegramConnection.fromMap(
      Map<String, dynamic>.from(data),
    );
  }

  Future<Uri> createConnectionLink() async {
    _userId;

    final response = await _client.functions.invoke(
      'telegram-link',
      body: const <String, dynamic>{},
    );

    final raw = response.data;

    if (raw is! Map) {
      throw StateError('Resposta inválida ao criar o link do Telegram.');
    }

    final url = raw['url']?.toString().trim();

    if (url == null || url.isEmpty) {
      final message = raw['error']?.toString().trim();

      throw StateError(
        message?.isNotEmpty == true
            ? message!
            : 'Não foi possível criar o link do Telegram.',
      );
    }

    final uri = Uri.tryParse(url);

    if (uri == null || !uri.hasScheme) {
      throw StateError('O link retornado pelo Telegram é inválido.');
    }

    return uri;
  }

  Future<void> openConnectionLink(Uri uri) async {
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      throw StateError('Não foi possível abrir o Telegram.');
    }
  }

  Future<void> disconnect() async {
    final userId = _userId;

    await _client
        .from('telegram_connections')
        .delete()
        .eq('user_id', userId);
  }

  Future<void> sendTestMessage() async {
    _userId;

    final response = await _client.functions.invoke(
      'telegram-test',
      body: const <String, dynamic>{},
    );

    final raw = response.data;

    if (raw is Map && raw['ok'] == true) {
      return;
    }

    final message = raw is Map
        ? raw['error']?.toString().trim()
        : null;

    throw StateError(
      message?.isNotEmpty == true
          ? message!
          : 'Não foi possível enviar a mensagem de teste.',
    );
  }
}
