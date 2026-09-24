import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/brain_ai_request.dart';
import '../models/brain_ai_response.dart';
import 'brain_ai_client.dart';

class BrainAiSupabaseClient
    implements
        BrainAiClient {
  const BrainAiSupabaseClient();

  @override
  Future<
    BrainAiResponse
  >
  ask(
    BrainAiRequest request,
  ) async {
    final supabase = Supabase.instance.client;

    final session = supabase.auth.currentSession;

    if (session ==
        null) {
      throw StateError(
        'Usuário não autenticado.',
      );
    }

    final baseUrl = supabase.rest.url.replaceFirst(
      '/rest/v1',
      '',
    );

    final uri = Uri.parse(
      '$baseUrl/functions/v1/brain-assistant',
    );

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
        request.toJson(),
      ),
    );

    if (response.statusCode <
            200 ||
        response.statusCode >=
            300) {
      throw StateError(
        'Brain AI HTTP ${response.statusCode}: '
        '${response.body}',
      );
    }

    final decoded = jsonDecode(
      response.body,
    );

    if (decoded
        is! Map) {
      throw const FormatException(
        'Resposta inválida do Brain AI.',
      );
    }

    return BrainAiResponse.fromJson(
      Map<
        String,
        dynamic
      >.from(
        decoded,
      ),
    );
  }
}
