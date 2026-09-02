import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_update_notification.dart';

// ============================================================
// CUSTOM FETCHER
// ============================================================
//
// Continua disponível para:
//
// - testes;
// - mock;
// - outra API;
// - GitHub Releases;
// - fonte alternativa.
//
// Se não for informado, o serviço usa o Supabase.
//
// ============================================================

typedef AppUpdateFetcher =
    Future<
      AppUpdateNotification?
    >
    Function();

class AppUpdateService {
  const AppUpdateService({
    required this.currentVersion,
    this.fetchLatestUpdate,
  });

  // ============================================================
  // VERSÃO ATUAL DO APP
  // ============================================================
  //
  // Exemplo:
  //
  // 1.0.0
  //
  // Futuramente podemos substituir o valor manual por
  // package_info_plus.
  //
  // ============================================================

  final String currentVersion;

  // ============================================================
  // FETCHER CUSTOMIZADO
  // ============================================================

  final AppUpdateFetcher? fetchLatestUpdate;

  // ============================================================
  // SUPABASE
  // ============================================================

  SupabaseClient get _supabase {
    return Supabase.instance.client;
  }

  // ============================================================
  // CHECK FOR UPDATE
  // ============================================================
  //
  // Fluxo:
  //
  // fetcher customizado?
  //
  // SIM
  //   ↓
  // usa o fetcher
  //
  // NÃO
  //   ↓
  // consulta app_updates no Supabase
  //
  // Depois:
  //
  // versão remota > versão instalada?
  //
  // SIM
  //   ↓
  // retorna atualização
  //
  // NÃO
  //   ↓
  // retorna null
  //
  // ============================================================

  Future<
    AppUpdateNotification?
  >
  checkForUpdate() async {
    try {
      final AppUpdateNotification? latest;

      final fetcher = fetchLatestUpdate;

      if (fetcher !=
          null) {
        latest = await fetcher();
      } else {
        latest = await _fetchLatestFromSupabase();
      }

      if (latest ==
          null) {
        debugPrint(
          '[APP UPDATE] '
          'Nenhuma atualização encontrada.',
        );

        return null;
      }

      final latestVersion = latest.version.trim();

      final installedVersion = currentVersion.trim();

      if (latestVersion.isEmpty) {
        debugPrint(
          '[APP UPDATE] '
          'Versão remota vazia.',
        );

        return null;
      }

      if (installedVersion.isEmpty) {
        debugPrint(
          '[APP UPDATE] '
          'Versão atual do aplicativo vazia.',
        );

        return null;
      }

      debugPrint(
        '[APP UPDATE] '
        'Versão instalada: $installedVersion',
      );

      debugPrint(
        '[APP UPDATE] '
        'Versão mais recente: $latestVersion',
      );

      final newer = isVersionNewer(
        latestVersion,
        installedVersion,
      );

      if (!newer) {
        debugPrint(
          '[APP UPDATE] '
          'Aplicativo já está atualizado.',
        );

        return null;
      }

      debugPrint(
        '[APP UPDATE] '
        'Nova atualização disponível: '
        '$latestVersion',
      );

      return latest;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[APP UPDATE] '
        'Erro ao verificar atualização: $error',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // FETCH SUPABASE
  // ============================================================
  //
  // Busca somente atualizações:
  //
  // active = true
  //
  // Ordena da publicação mais recente para a mais antiga.
  //
  // Retorna somente um registro.
  //
  // ============================================================

  Future<
    AppUpdateNotification?
  >
  _fetchLatestFromSupabase() async {
    final user = _supabase.auth.currentUser;

    // ==========================================================
    // AUTH
    // ==========================================================
    //
    // A policy que criamos permite leitura para:
    //
    // authenticated
    //
    // Portanto, sem usuário autenticado não fazemos consulta.
    //
    // ==========================================================

    if (user ==
        null) {
      debugPrint(
        '[APP UPDATE] '
        'Usuário não autenticado.',
      );

      return null;
    }

    debugPrint(
      '[APP UPDATE] '
      'Buscando atualização no Supabase...',
    );

    // ==========================================================
    // QUERY
    // ==========================================================

    final rows = await _supabase
        .from(
          'app_updates',
        )
        .select()
        .eq(
          'active',
          true,
        )
        .order(
          'published_at',
          ascending: false,
        )
        .limit(
          1,
        );

    // ==========================================================
    // EMPTY
    // ==========================================================

    if (rows.isEmpty) {
      debugPrint(
        '[APP UPDATE] '
        'Nenhuma atualização ativa encontrada.',
      );

      return null;
    }

    // ==========================================================
    // MAP
    // ==========================================================

    final row =
        Map<
          String,
          dynamic
        >.from(
          rows.first,
        );

    debugPrint(
      '[APP UPDATE] '
      'Atualização encontrada: '
      '${row['version']}',
    );

    // ==========================================================
    // MODEL
    // ==========================================================

    return AppUpdateNotification.fromMap(
      row,
    );
  }

  // ============================================================
  // COMPARAR VERSÕES
  // ============================================================
  //
  // Exemplos:
  //
  // 1.0.1 > 1.0.0
  //
  // 1.2.0 > 1.1.9
  //
  // 2.0.0 > 1.99.99
  //
  // Também aceita:
  //
  // v1.2.0
  //
  // 1.2
  //
  // 1
  //
  // 1.2.0+10
  //
  // 1.2.0-beta
  //
  // ============================================================

  static bool isVersionNewer(
    String candidate,
    String current,
  ) {
    final candidateParts = _parseVersion(
      candidate,
    );

    final currentParts = _parseVersion(
      current,
    );

    final maxLength =
        candidateParts.length >
            currentParts.length
        ? candidateParts.length
        : currentParts.length;

    for (
      var index = 0;
      index <
          maxLength;
      index++
    ) {
      final candidateValue =
          index <
              candidateParts.length
          ? candidateParts[index]
          : 0;

      final currentValue =
          index <
              currentParts.length
          ? currentParts[index]
          : 0;

      if (candidateValue >
          currentValue) {
        return true;
      }

      if (candidateValue <
          currentValue) {
        return false;
      }
    }

    return false;
  }

  // ============================================================
  // PARSE VERSION
  // ============================================================

  static List<
    int
  >
  _parseVersion(
    String value,
  ) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceFirst(
          RegExp(
            r'^v',
          ),
          '',
        )
        .split(
          '+',
        )
        .first
        .split(
          '-',
        )
        .first;

    return normalized
        .split(
          '.',
        )
        .map(
          (
            part,
          ) {
            final numeric =
                RegExp(
                  r'\d+',
                ).firstMatch(
                  part,
                );

            if (numeric ==
                null) {
              return 0;
            }

            return int.tryParse(
                  numeric.group(
                        0,
                      ) ??
                      '',
                ) ??
                0;
          },
        )
        .toList(
          growable: false,
        );
  }
}
