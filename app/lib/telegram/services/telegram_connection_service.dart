import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/telegram_connection.dart';

class TelegramConnectionService {
  TelegramConnectionService({
    required SupabaseClient client,
  }) : _client = client;

  // ============================================================
  // CLIENT
  // ============================================================

  final SupabaseClient _client;

  // ============================================================
  // AUTH
  // ============================================================

  String get _userId {
    final userId = _client.auth.currentUser?.id.trim();

    if (userId ==
            null ||
        userId.isEmpty) {
      throw StateError(
        'Entre na sua conta para conectar o Telegram.',
      );
    }

    return userId;
  }

  // ============================================================
  // LOAD CONNECTION
  // ============================================================
  //
  // Este método pode ser chamado repetidamente pelo controller
  // enquanto ele aguarda o usuário concluir a conexão.
  //
  // Por isso ele NÃO gera logs a cada consulta.
  //
  // O controller deve registrar apenas eventos importantes:
  //
  // - início da espera
  // - conexão concluída
  // - timeout
  // - erro
  //
  // ============================================================

  Future<
    TelegramConnection?
  >
  loadConnection() async {
    final userId = _userId;

    final data = await _client
        .from(
          'telegram_connections',
        )
        .select()
        .eq(
          'user_id',
          userId,
        )
        .maybeSingle();

    if (data ==
        null) {
      return null;
    }

    return TelegramConnection.fromMap(
      Map<
        String,
        dynamic
      >.from(
        data,
      ),
    );
  }

  // ============================================================
  // CREATE CONNECTION LINK
  // ============================================================

  Future<
    Uri
  >
  createConnectionLink() async {
    final userId = _userId;

    debugPrint(
      '[TELEGRAM] Solicitando link de conexão.',
    );

    debugPrint(
      '[TELEGRAM] User ID: $userId',
    );

    final response = await _client.functions.invoke(
      'telegram-link',
      body:
          const <
            String,
            dynamic
          >{},
    );

    final raw = response.data;

    if (raw
        is! Map) {
      throw StateError(
        'Resposta inválida ao criar o link do Telegram.',
      );
    }

    final errorMessage = raw['error']?.toString().trim();

    if (errorMessage !=
            null &&
        errorMessage.isNotEmpty) {
      throw StateError(
        errorMessage,
      );
    }

    final url = raw['url']?.toString().trim();

    if (url ==
            null ||
        url.isEmpty) {
      throw StateError(
        'Não foi possível criar o link do Telegram.',
      );
    }

    final uri = Uri.tryParse(
      url,
    );

    if (uri ==
            null ||
        !uri.hasScheme ||
        uri.host.isEmpty) {
      throw StateError(
        'O link retornado para conexão com o Telegram é inválido.',
      );
    }

    final scheme = uri.scheme.toLowerCase();

    if (scheme !=
            'https' &&
        scheme !=
            'http') {
      throw StateError(
        'O link retornado possui um formato não permitido.',
      );
    }

    final host = uri.host.toLowerCase();

    final isTelegramHost =
        host ==
            't.me' ||
        host ==
            'www.t.me' ||
        host ==
            'telegram.me' ||
        host ==
            'www.telegram.me';

    if (!isTelegramHost) {
      throw StateError(
        'O link retornado não pertence ao Telegram.',
      );
    }

    debugPrint(
      '[TELEGRAM] Link de conexão criado.',
    );

    return uri;
  }

  // ============================================================
  // OPEN CONNECTION LINK
  // ============================================================
  //
  // Utilizamos HTTPS deliberadamente.
  //
  // Isso permite que o fluxo funcione mesmo quando o usuário
  // não possui Telegram Desktop instalado.
  //
  // O sistema abre o navegador padrão e o Telegram decide se
  // usa Telegram Web ou oferece abertura pelo aplicativo.
  //
  // ============================================================

  Future<
    void
  >
  openConnectionLink(
    Uri uri,
  ) async {
    final scheme = uri.scheme.toLowerCase();

    if (scheme !=
            'https' &&
        scheme !=
            'http') {
      throw StateError(
        'O link do Telegram possui um formato não permitido.',
      );
    }

    final host = uri.host.toLowerCase();

    final isTelegramHost =
        host ==
            't.me' ||
        host ==
            'www.t.me' ||
        host ==
            'telegram.me' ||
        host ==
            'www.telegram.me';

    if (!isTelegramHost) {
      throw StateError(
        'O link recebido não pertence ao Telegram.',
      );
    }

    debugPrint(
      '[TELEGRAM] Abrindo Telegram no navegador.',
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw StateError(
          'Não foi possível abrir o Telegram no navegador.',
        );
      }
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[TELEGRAM] Erro ao abrir navegador: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      rethrow;
    }
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  Future<
    void
  >
  disconnect() async {
    final userId = _userId;

    debugPrint(
      '[TELEGRAM] Solicitando desconexão.',
    );

    debugPrint(
      '[TELEGRAM] User ID: $userId',
    );

    final response = await _client.functions.invoke(
      'telegram-disconnect',
      body:
          const <
            String,
            dynamic
          >{},
    );

    final raw = response.data;

    if (raw
            is Map &&
        raw['ok'] ==
            true) {
      debugPrint(
        '[TELEGRAM] Telegram desconectado com sucesso.',
      );

      return;
    }

    final message =
        raw
            is Map
        ? raw['error']?.toString().trim()
        : null;

    throw StateError(
      message?.isNotEmpty ==
              true
          ? message!
          : 'Não foi possível desconectar o Telegram.',
    );
  }

  // ============================================================
  // SEND TEST MESSAGE
  // ============================================================

  Future<
    void
  >
  sendTestMessage() async {
    final userId = _userId;

    debugPrint(
      '[TELEGRAM] Solicitando mensagem de teste.',
    );

    debugPrint(
      '[TELEGRAM] User ID: $userId',
    );

    final response = await _client.functions.invoke(
      'telegram-test',
      body:
          const <
            String,
            dynamic
          >{},
    );

    final raw = response.data;

    if (raw
            is Map &&
        raw['ok'] ==
            true) {
      debugPrint(
        '[TELEGRAM] Mensagem de teste enviada com sucesso.',
      );

      return;
    }

    final message =
        raw
            is Map
        ? raw['error']?.toString().trim()
        : null;

    throw StateError(
      message?.isNotEmpty ==
              true
          ? message!
          : 'Não foi possível enviar a mensagem de teste.',
    );
  }
}
