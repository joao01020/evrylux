import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/database/daos/app_update_cache_dao.dart';
import '../models/app_update_notification.dart';

// ============================================================
// CUSTOM FETCHER
// ============================================================

typedef AppUpdateFetcher = Future<AppUpdateNotification?> Function();

class AppUpdateService {
  const AppUpdateService({
    required this.currentVersion,
    this.fetchLatestUpdate,
    this.cacheDao,
  });

  final String currentVersion;

  final AppUpdateFetcher? fetchLatestUpdate;

  // Opcional para testes/DI. O fallback mantém compatibilidade com
  // o GhostApp atual, que instancia const AppUpdateService(...).
  final AppUpdateCacheDao? cacheDao;

  static final AppUpdateCacheDao _defaultCacheDao =
      AppUpdateCacheDao();

  AppUpdateCacheDao get _cacheDao {
    return cacheDao ?? _defaultCacheDao;
  }

  SupabaseClient get _supabase {
    return Supabase.instance.client;
  }

  // ============================================================
  // CACHE LOCAL
  // ============================================================

  Future<AppUpdateNotification?> loadCachedUpdate() async {
    final cached = await _cacheDao.loadLatest();

    if (cached == null) {
      return null;
    }

    // Se o usuário já atualizou o app desde a última execução,
    // descartamos um cache que deixou de representar update real.
    if (!isVersionNewer(
      cached.version,
      currentVersion,
    )) {
      await _cacheDao.clear();
      return null;
    }

    return cached;
  }

  Future<void> saveCachedUpdate(
    AppUpdateNotification notification,
  ) {
    return _cacheDao.save(
      notification,
    );
  }

  Future<void> clearCachedUpdate() {
    return _cacheDao.clear();
  }


  // ============================================================
  // REALTIME
  // ============================================================

  RealtimeChannel subscribeToRealtime({
    required VoidCallback onChanged,
  }) {
    final channel = _supabase
        .channel(
          'app_updates_notifications_${DateTime.now().microsecondsSinceEpoch}',
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_updates',
          callback: (payload) {
            debugPrint(
              '[APP UPDATE] Alteração Realtime recebida: $payload',
            );

            onChanged();
          },
        );

    channel.subscribe();

    return channel;
  }

  Future<void> unsubscribeFromRealtime(
    RealtimeChannel channel,
  ) async {
    try {
      await _supabase.removeChannel(
        channel,
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[APP UPDATE] Erro ao remover canal Realtime: $error',
      );
      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // CHECK FOR UPDATE
  // ============================================================
  //
  // A consulta remota nunca é a fonte imediata da UI.
  // O controller primeiro chama loadCachedUpdate() e só depois
  // executa este refresh em background.
  //
  // ============================================================

  Future<AppUpdateNotification?> checkForUpdate() async {
    try {
      final AppUpdateNotification? latest;

      final fetcher = fetchLatestUpdate;

      if (fetcher != null) {
        latest = await fetcher();
      } else {
        latest = await _fetchLatestFromSupabase();
      }

      if (latest == null) {
        debugPrint(
          '[APP UPDATE] Nenhuma atualização encontrada.',
        );

        await clearCachedUpdate();
        return null;
      }

      final latestVersion = latest.version.trim();
      final installedVersion = currentVersion.trim();

      if (latestVersion.isEmpty || installedVersion.isEmpty) {
        return null;
      }

      final newer = isVersionNewer(
        latestVersion,
        installedVersion,
      );

      if (!newer) {
        debugPrint(
          '[APP UPDATE] Aplicativo já está atualizado.',
        );

        await clearCachedUpdate();
        return null;
      }

      final cached = await _cacheDao.loadLatest();

      final normalized = latest.copyWith(
        // A mesma versão preserva o estado de leitura local.
        isRead:
            cached != null &&
                cached.version == latest.version
            ? cached.isRead
            : false,
      );

      await saveCachedUpdate(
        normalized,
      );

      return normalized;
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[APP UPDATE] Erro ao verificar atualização: $error',
      );
      debugPrint(
        '$stackTrace',
      );

      // Em falha de rede/auth, preservamos e devolvemos o cache.
      // Isso impede a notificação de sumir durante inicialização
      // offline ou enquanto a sessão ainda está sendo restaurada.
      return loadCachedUpdate();
    }
  }

  // ============================================================
  // FETCH SUPABASE
  // ============================================================

  Future<AppUpdateNotification?> _fetchLatestFromSupabase() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw StateError(
        'Sessão ainda não disponível para consultar atualizações.',
      );
    }

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

    if (rows.isEmpty) {
      return null;
    }

    return AppUpdateNotification.fromMap(
      Map<String, dynamic>.from(
        rows.first,
      ),
    );
  }

  // ============================================================
  // VERSION
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

    final maxLength = candidateParts.length > currentParts.length
        ? candidateParts.length
        : currentParts.length;

    for (var index = 0; index < maxLength; index++) {
      final candidateValue = index < candidateParts.length
          ? candidateParts[index]
          : 0;

      final currentValue = index < currentParts.length
          ? currentParts[index]
          : 0;

      if (candidateValue > currentValue) {
        return true;
      }

      if (candidateValue < currentValue) {
        return false;
      }
    }

    return false;
  }

  static List<int> _parseVersion(
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
            final numeric = RegExp(
              r'\d+',
            ).firstMatch(
              part,
            );

            if (numeric == null) {
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
