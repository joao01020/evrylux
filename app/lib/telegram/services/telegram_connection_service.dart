import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/telegram_connection.dart';

class TelegramConnectionService {
  TelegramConnectionService({required SupabaseClient client})
    : _client = client;

  // ============================================================
  // CLIENT
  // ============================================================

  final SupabaseClient _client;

  // ============================================================
  // PENDING CONNECTION
  // ============================================================
  //
  // O link temporário fica apenas em memória.
  // Não salvamos o código em SharedPreferences ou no banco local.
  // ============================================================

  Uri? _pendingConnectionLink;
  String? _pendingUserId;

  Uri? get _currentPendingLink {
    final currentUserId = _client.auth.currentUser?.id.trim();

    if (currentUserId == null ||
        currentUserId.isEmpty ||
        currentUserId != _pendingUserId) {
      return null;
    }

    return _pendingConnectionLink;
  }

  String? get pendingBotUsername {
    final uri = _currentPendingLink;

    if (uri == null) {
      return null;
    }

    return '@${uri.pathSegments.single}';
  }

  String? get pendingStartCommand {
    final uri = _currentPendingLink;

    if (uri == null) {
      return null;
    }

    final start = uri.queryParameters['start'];

    if (start == null || start.isEmpty) {
      return null;
    }

    return '/start $start';
  }

  void clearPendingConnection() {
    _pendingConnectionLink = null;
    _pendingUserId = null;
  }

  // ============================================================
  // AUTH
  // ============================================================

  String get _userId {
    final userId = _client.auth.currentUser?.id.trim();

    if (userId == null || userId.isEmpty) {
      throw StateError('Entre na sua conta para conectar o Telegram.');
    }

    return userId;
  }

  // ============================================================
  // LOAD CONNECTION
  // ============================================================
  //
  // Pode ser chamado repetidamente pelo controller durante
  // o polling, sem gerar logs a cada consulta.
  // ============================================================

  Future<TelegramConnection?> loadConnection() async {
    final userId = _userId;

    final data = await _client
        .from('telegram_connections')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data == null) {
      return null;
    }

    return TelegramConnection.fromMap(Map<String, dynamic>.from(data));
  }

  // ============================================================
  // CREATE CONNECTION LINK
  // ============================================================
  //
  // O backend continua sendo o único responsável por gerar
  // o código temporário de vínculo.
  // ============================================================

  Future<Uri> createConnectionLink() async {
    final userId = _userId;

    clearPendingConnection();

    debugPrint('[TELEGRAM] Solicitando link de conexão.');

    final response = await _client.functions.invoke(
      'telegram-link',
      body: const <String, dynamic>{},
    );

    final raw = response.data;

    if (raw is! Map) {
      throw StateError('Resposta inválida ao criar o link do Telegram.');
    }

    final errorMessage = raw['error']?.toString().trim();

    if (errorMessage != null && errorMessage.isNotEmpty) {
      throw StateError(errorMessage);
    }

    final url = raw['url']?.toString().trim();

    if (url == null || url.isEmpty) {
      throw StateError('Não foi possível criar o link do Telegram.');
    }

    final uri = Uri.tryParse(url);

    if (uri == null) {
      throw StateError(
        'O link retornado para conexão com o Telegram é inválido.',
      );
    }

    _validateTelegramLink(uri);

    // Evita guardar um código caso a conta tenha mudado
    // enquanto a requisição estava em andamento.
    if (_userId != userId) {
      throw StateError('Sua sessão mudou. Inicie a conexão novamente.');
    }

    _pendingConnectionLink = uri;
    _pendingUserId = userId;

    debugPrint('[TELEGRAM] Link de conexão criado.');

    return uri;
  }

  // ============================================================
  // VALIDATE TELEGRAM LINK
  // ============================================================
  //
  // Aceita somente o link HTTPS oficial do bot com um
  // parâmetro start válido.
  // ============================================================

  void _validateTelegramLink(Uri uri) {
    if (uri.scheme.toLowerCase() != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.host.isEmpty) {
      throw StateError('O link do Telegram possui um formato não permitido.');
    }

    const allowedHosts = <String>{
      't.me',
      'www.t.me',
      'telegram.me',
      'www.telegram.me',
    };

    if (!allowedHosts.contains(uri.host.toLowerCase())) {
      throw StateError('O link recebido não pertence ao Telegram.');
    }

    final segments = uri.pathSegments;

    if (segments.length != 1 ||
        !RegExp(r'^[A-Za-z0-9_]{5,32}$').hasMatch(segments.single)) {
      throw StateError('O link recebido não identifica um bot válido.');
    }

    final parameters = uri.queryParametersAll;

    if (parameters.keys.any((key) => key != 'start')) {
      throw StateError('O link de conexão contém parâmetros não permitidos.');
    }

    final start = parameters['start'];

    if (start == null ||
        start.length != 1 ||
        !RegExp(r'^[A-Za-z0-9_-]{1,64}$').hasMatch(start.single)) {
      throw StateError('O código de conexão do Telegram é inválido.');
    }

    if (uri.fragment.isNotEmpty) {
      throw StateError('O link de conexão contém um fragmento não permitido.');
    }
  }

  // ============================================================
  // OPEN TELEGRAM WEB
  // ============================================================
  //
  // Abre o cliente Web oficial sem exigir Telegram Desktop.
  //
  // O comando de vínculo permanece disponível em
  // pendingStartCommand para o diálogo Flutter mostrar
  // e permitir copiar.
  //
  // Não dependemos de rotas internas do Telegram Web.
  // ============================================================

  Future<void> openConnectionLink(Uri uri) async {
    _validateTelegramLink(uri);

    final userId = _userId;

    _pendingConnectionLink = uri;
    _pendingUserId = userId;

    final webUri = Uri.https('web.telegram.org', '/k/');

    debugPrint('[TELEGRAM] Abrindo Telegram Web.');

    try {
      final opened = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw StateError('Não foi possível abrir o Telegram Web.');
      }
    } catch (error, stackTrace) {
      debugPrint('[TELEGRAM] Erro ao abrir Telegram Web: $error');
      debugPrint(stackTrace.toString());

      rethrow;
    }
  }

  // ============================================================
  // DISCONNECT
  // ============================================================

  Future<void> disconnect() async {
    _userId;

    debugPrint('[TELEGRAM] Solicitando desconexão.');

    final response = await _client.functions.invoke(
      'telegram-disconnect',
      body: const <String, dynamic>{},
    );

    final raw = response.data;

    if (raw is Map && raw['ok'] == true) {
      clearPendingConnection();

      debugPrint('[TELEGRAM] Telegram desconectado com sucesso.');

      return;
    }

    final message = raw is Map ? raw['error']?.toString().trim() : null;

    throw StateError(
      message?.isNotEmpty == true
          ? message!
          : 'Não foi possível desconectar o Telegram.',
    );
  }

  // ============================================================
  // SEND TEST MESSAGE
  // ============================================================

  Future<void> sendTestMessage() async {
    _userId;

    debugPrint('[TELEGRAM] Solicitando mensagem de teste.');

    final response = await _client.functions.invoke(
      'telegram-test',
      body: const <String, dynamic>{},
    );

    final raw = response.data;

    if (raw is Map && raw['ok'] == true) {
      debugPrint('[TELEGRAM] Mensagem de teste enviada com sucesso.');

      return;
    }

    final message = raw is Map ? raw['error']?.toString().trim() : null;

    throw StateError(
      message?.isNotEmpty == true
          ? message!
          : 'Não foi possível enviar a mensagem de teste.',
    );
  }
}
