import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'connectivity_service.dart';
import 'sync_item.dart';
import 'sync_queue.dart';

// ============================================================
// HANDLER
// ============================================================
//
// Cada tipo de entidade pode possuir sua própria estratégia de
// sincronização.
//
// Exemplo:
//
// routine_day -> Supabase table routine_days
// reminder    -> Supabase table reminders
//
// ============================================================

typedef SyncItemHandler =
    Future<
      void
    >
    Function(
      SyncItem item,
    );

// ============================================================
// SERVICE STATE
// ============================================================

enum SyncServiceState {
  stopped,
  checking,
  offline,
  idle,
  syncing,
  error,
}

// ============================================================
// SYNC SERVICE
// ============================================================
//
// Responsabilidades:
//
// 1. observar a conexão;
// 2. consultar a fila local persistente;
// 3. enviar operações pendentes;
// 4. remover da fila quando houver sucesso;
// 5. manter na fila quando houver erro;
// 6. tentar novamente automaticamente;
// 7. informar o estado atual para a interface.
//
// A SyncQueue continua sendo a fonte da verdade das operações
// pendentes.
//
// ============================================================

class SyncService
    extends
        ChangeNotifier {
  SyncService({
    required SyncQueue queue,
    required ConnectivityService connectivityService,
    SupabaseClient? client,
    this.syncInterval = const Duration(
      seconds: 20,
    ),
    this.batchSize = 50,
  }) : _queue =
           queue,
       _connectivityService = connectivityService,
       _client =
           client ??
           Supabase.instance.client;

  // ============================================================
  // DEPENDENCIES
  // ============================================================

  final SyncQueue _queue;

  final ConnectivityService _connectivityService;

  final SupabaseClient _client;

  // ============================================================
  // CONFIG
  // ============================================================

  final Duration syncInterval;

  final int batchSize;

  // ============================================================
  // HANDLERS
  // ============================================================

  final Map<
    String,
    SyncItemHandler
  >
  _handlers =
      <
        String,
        SyncItemHandler
      >{};

  // ============================================================
  // STATE
  // ============================================================

  SyncServiceState _state = SyncServiceState.stopped;

  Timer? _timer;

  bool _started = false;

  bool _syncing = false;

  bool _disposed = false;

  int _pendingCount = 0;

  int _lastSyncedCount = 0;

  int _lastFailedCount = 0;

  String? _lastError;

  DateTime? _lastSyncAt;

  DateTime? _lastAttemptAt;

  // ============================================================
  // GETTERS
  // ============================================================

  SyncServiceState get state => _state;

  bool get isStarted => _started;

  bool get isSyncing => _syncing;

  bool get isOnline => _connectivityService.isOnline;

  bool get isOffline => _connectivityService.isOffline;

  int get pendingCount => _pendingCount;

  int get lastSyncedCount => _lastSyncedCount;

  int get lastFailedCount => _lastFailedCount;

  String? get lastError => _lastError;

  DateTime? get lastSyncAt => _lastSyncAt;

  DateTime? get lastAttemptAt => _lastAttemptAt;

  bool get hasPending =>
      _pendingCount >
      0;

  bool get hasError =>
      _lastError !=
      null;

  // ============================================================
  // START
  // ============================================================

  Future<
    void
  >
  start() async {
    if (_started) {
      return;
    }

    _started = true;

    _setState(
      SyncServiceState.checking,
    );

    _connectivityService.addListener(
      _onConnectivityChanged,
    );

    await _connectivityService.start();

    await refreshPendingCount();

    if (_connectivityService.isOnline) {
      await syncNow(
        checkConnection: false,
      );
    } else {
      _setState(
        SyncServiceState.offline,
      );
    }

    _timer = Timer.periodic(
      syncInterval,
      (
        _,
      ) {
        unawaited(
          _periodicCheck(),
        );
      },
    );
  }

  // ============================================================
  // PERIODIC CHECK
  // ============================================================

  Future<
    void
  >
  _periodicCheck() async {
    if (!_started ||
        _disposed) {
      return;
    }

    final online = await _connectivityService.checkNow();

    await refreshPendingCount();

    if (!online) {
      _setState(
        SyncServiceState.offline,
      );

      return;
    }

    if (_pendingCount >
        0) {
      await syncNow(
        checkConnection: false,
      );
    } else {
      _setState(
        SyncServiceState.idle,
      );
    }
  }

  // ============================================================
  // CONNECTIVITY CHANGED
  // ============================================================

  void _onConnectivityChanged() {
    if (!_started ||
        _disposed) {
      return;
    }

    if (_connectivityService.isOffline) {
      _setState(
        SyncServiceState.offline,
      );

      return;
    }

    if (_connectivityService.isOnline) {
      unawaited(
        _onConnectionRestored(),
      );
    }
  }

  Future<
    void
  >
  _onConnectionRestored() async {
    await refreshPendingCount();

    if (_pendingCount ==
        0) {
      _setState(
        SyncServiceState.idle,
      );

      return;
    }

    await syncNow(
      checkConnection: false,
    );
  }

  // ============================================================
  // REGISTER CUSTOM HANDLER
  // ============================================================

  void registerHandler({
    required String entityType,
    required SyncItemHandler handler,
  }) {
    final key = entityType.trim();

    if (key.isEmpty) {
      throw ArgumentError(
        'entityType não pode ser vazio.',
      );
    }

    _handlers[key] = handler;
  }

  // ============================================================
  // REGISTER SUPABASE TABLE
  // ============================================================
  //
  // Atalho para entidades simples.
  //
  // Exemplo:
  //
  // syncService.registerSupabaseTable(
  //   entityType: 'reminder',
  //   table: 'reminders',
  // );
  //
  // CREATE e UPDATE usam UPSERT para tornar a operação
  // idempotente. Se a mesma operação for executada novamente,
  // o registro não é duplicado.
  //
  // IMPORTANTE:
  // payload deve conter somente colunas existentes no Supabase.
  //
  // ============================================================

  void registerSupabaseTable({
    required String entityType,
    required String table,
    String idColumn = 'id',
  }) {
    final normalizedEntityType = entityType.trim();

    final normalizedTable = table.trim();

    final normalizedIdColumn = idColumn.trim();

    if (normalizedEntityType.isEmpty) {
      throw ArgumentError(
        'entityType não pode ser vazio.',
      );
    }

    if (normalizedTable.isEmpty) {
      throw ArgumentError(
        'table não pode ser vazia.',
      );
    }

    if (normalizedIdColumn.isEmpty) {
      throw ArgumentError(
        'idColumn não pode ser vazio.',
      );
    }

    registerHandler(
      entityType: normalizedEntityType,
      handler:
          (
            item,
          ) async {
            switch (item.operation) {
              case SyncOperation.create:
              case SyncOperation.update:
                final payload =
                    Map<
                      String,
                      dynamic
                    >.from(
                      item.payload,
                    );

                payload.putIfAbsent(
                  normalizedIdColumn,
                  () => item.entityId,
                );

                await _client
                    .from(
                      normalizedTable,
                    )
                    .upsert(
                      payload,
                      onConflict: normalizedIdColumn,
                    );

                break;

              case SyncOperation.delete:
                await _client
                    .from(
                      normalizedTable,
                    )
                    .delete()
                    .eq(
                      normalizedIdColumn,
                      item.entityId,
                    );

                break;
            }
          },
    );
  }

  // ============================================================
  // UNREGISTER
  // ============================================================

  void unregisterHandler(
    String entityType,
  ) {
    _handlers.remove(
      entityType.trim(),
    );
  }

  bool hasHandler(
    String entityType,
  ) {
    return _handlers.containsKey(
      entityType.trim(),
    );
  }

  // ============================================================
  // REQUEST SYNC
  // ============================================================
  //
  // Use depois que algum Repository salvar localmente e colocar
  // uma operação na SyncQueue.
  //
  // Não bloqueia a tela aguardando a sincronização remota.
  //
  // ============================================================

  void requestSync() {
    if (!_started ||
        _disposed) {
      return;
    }

    unawaited(
      _requestSyncInternal(),
    );
  }

  Future<
    void
  >
  _requestSyncInternal() async {
    await refreshPendingCount();

    if (!_connectivityService.isOnline) {
      _setState(
        SyncServiceState.offline,
      );

      return;
    }

    await syncNow(
      checkConnection: false,
    );
  }

  // ============================================================
  // SYNC NOW
  // ============================================================

  Future<
    void
  >
  syncNow({
    bool checkConnection = true,
  }) async {
    if (!_started ||
        _disposed ||
        _syncing) {
      return;
    }

    _syncing = true;

    _lastAttemptAt = DateTime.now();

    _lastSyncedCount = 0;

    _lastFailedCount = 0;

    _lastError = null;

    _setState(
      SyncServiceState.checking,
    );

    try {
      if (checkConnection) {
        final online = await _connectivityService.checkNow();

        if (!online) {
          _setState(
            SyncServiceState.offline,
          );

          return;
        }
      } else if (!_connectivityService.isOnline) {
        _setState(
          SyncServiceState.offline,
        );

        return;
      }

      _setState(
        SyncServiceState.syncing,
      );

      final items = await _queue.getPending(
        limit: batchSize,
      );

      if (items.isEmpty) {
        await refreshPendingCount();

        _lastSyncAt = DateTime.now();

        _setState(
          SyncServiceState.idle,
        );

        return;
      }

      for (final item in items) {
        if (!_connectivityService.isOnline) {
          _setState(
            SyncServiceState.offline,
          );

          break;
        }

        final handler = _handlers[item.entityType];

        if (handler ==
            null) {
          _lastFailedCount++;

          _lastError =
              'Nenhum handler registrado para '
              '"${item.entityType}".';

          debugPrint(
            '[SyncService] $_lastError',
          );

          // Não incrementamos attempts aqui.
          // A operação continua aguardando até o app registrar
          // um handler para essa entidade.
          continue;
        }

        try {
          await handler(
            item,
          );

          await _queue.markSuccess(
            item.id,
          );

          _lastSyncedCount++;

          debugPrint(
            '[SyncService] Sincronizado: '
            '${item.entityType}/${item.entityId} '
            '(${item.operation.value})',
          );
        } catch (
          error,
          stackTrace
        ) {
          _lastFailedCount++;

          _lastError = error.toString();

          debugPrint(
            '[SyncService] Falha: '
            '${item.entityType}/${item.entityId} '
            '(${item.operation.value})',
          );

          debugPrint(
            error.toString(),
          );

          debugPrint(
            stackTrace.toString(),
          );

          await _queue.markFailed(
            id: item.id,
            error: error,
          );

          // Se a conexão caiu no meio da sincronização,
          // interrompemos o lote.
          final online = await _connectivityService.checkNow();

          if (!online) {
            _setState(
              SyncServiceState.offline,
            );

            break;
          }
        }
      }

      await refreshPendingCount();

      _lastSyncAt = DateTime.now();

      if (_connectivityService.isOffline) {
        _setState(
          SyncServiceState.offline,
        );
      } else if (_lastFailedCount >
              0 &&
          _lastSyncedCount ==
              0) {
        _setState(
          SyncServiceState.error,
        );
      } else {
        _setState(
          SyncServiceState.idle,
        );
      }
    } catch (
      error,
      stackTrace
    ) {
      _lastError = error.toString();

      debugPrint(
        '[SyncService] Erro geral: $error',
      );

      debugPrint(
        stackTrace.toString(),
      );

      if (_connectivityService.isOffline) {
        _setState(
          SyncServiceState.offline,
        );
      } else {
        _setState(
          SyncServiceState.error,
        );
      }
    } finally {
      _syncing = false;

      _safeNotifyListeners();
    }
  }

  // ============================================================
  // REFRESH PENDING COUNT
  // ============================================================

  Future<
    void
  >
  refreshPendingCount() async {
    try {
      final count = await _queue.count();

      if (_pendingCount ==
          count) {
        return;
      }

      _pendingCount = count;

      _safeNotifyListeners();
    } catch (
      error
    ) {
      debugPrint(
        '[SyncService] Erro ao contar pendências: '
        '$error',
      );
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (_lastError ==
        null) {
      return;
    }

    _lastError = null;

    if (_connectivityService.isOffline) {
      _setState(
        SyncServiceState.offline,
      );
    } else if (_syncing) {
      _setState(
        SyncServiceState.syncing,
      );
    } else {
      _setState(
        SyncServiceState.idle,
      );
    }
  }

  // ============================================================
  // STATUS TEXT
  // ============================================================

  String get statusText {
    switch (_state) {
      case SyncServiceState.stopped:
        return 'Sincronização parada';

      case SyncServiceState.checking:
        return 'Verificando conexão...';

      case SyncServiceState.offline:
        if (_pendingCount >
            0) {
          return 'Offline • $_pendingCount alteração'
              '${_pendingCount == 1 ? '' : 'ões'} salva'
              '${_pendingCount == 1 ? '' : 's'} neste dispositivo';
        }

        return 'Offline';

      case SyncServiceState.syncing:
        if (_pendingCount >
            0) {
          return 'Sincronizando $_pendingCount alteração'
              '${_pendingCount == 1 ? '' : 'ões'}...';
        }

        return 'Sincronizando...';

      case SyncServiceState.error:
        return 'Erro de sincronização';

      case SyncServiceState.idle:
        if (_pendingCount >
            0) {
          return '$_pendingCount alteração'
              '${_pendingCount == 1 ? '' : 'ões'} aguardando sincronização';
        }

        return 'Tudo sincronizado';
    }
  }

  // ============================================================
  // STATE
  // ============================================================

  void _setState(
    SyncServiceState value,
  ) {
    if (_state ==
        value) {
      return;
    }

    _state = value;

    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // STOP
  // ============================================================

  Future<
    void
  >
  stop() async {
    if (!_started) {
      return;
    }

    _timer?.cancel();

    _timer = null;

    _connectivityService.removeListener(
      _onConnectivityChanged,
    );

    await _connectivityService.stop();

    _started = false;

    _syncing = false;

    _setState(
      SyncServiceState.stopped,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    _timer?.cancel();

    _timer = null;

    _connectivityService.removeListener(
      _onConnectivityChanged,
    );

    unawaited(
      _connectivityService.stop(),
    );

    super.dispose();
  }
}
