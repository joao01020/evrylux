import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'connectivity_service.dart';
import 'sync_item.dart';
import 'sync_queue.dart';

// ============================================================
// HANDLER
// ============================================================

typedef SyncItemHandler = Future<void> Function(SyncItem item);

// ============================================================
// PROCESSING GATE
// ============================================================
//
// Retorna true quando o item pode ser transmitido agora.
//
// Retorna false para ADIAR o item sem:
//
// - removê-lo da fila;
// - marcar sucesso;
// - marcar falha;
// - incrementar attempts.
//
// Isso é usado pelo Brain para garantir:
//
// LOCAL => zero transmissão do Cérebro.
//
// ============================================================

typedef SyncItemProcessingGate = Future<bool> Function(SyncItem item);

// ============================================================
// SERVICE STATE
// ============================================================

enum SyncServiceState { stopped, checking, offline, idle, syncing, error }

// ============================================================
// SYNC SERVICE
// ============================================================
//
// Responsabilidades:
//
// 1. observar a conexão;
// 2. consultar a SyncQueue persistente;
// 3. processar itens prontos;
// 4. remover itens após sucesso;
// 5. manter itens após erro;
// 6. aplicar retry;
// 7. reagir imediatamente a requestSync();
// 8. não perder pedidos feitos durante outra sincronização;
// 9. expor o estado real para a interface.
//
// ============================================================

class SyncService extends ChangeNotifier {
  SyncService({
    required SyncQueue queue,
    required ConnectivityService connectivityService,
    SupabaseClient? client,
    this.syncInterval = const Duration(seconds: 20),
    this.batchSize = 50,
  }) : _queue = queue,
       _connectivityService = connectivityService,
       _client = client ?? Supabase.instance.client;

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

  final Map<String, SyncItemHandler> _handlers = <String, SyncItemHandler>{};

  final Map<String, SyncItemProcessingGate> _processingGates =
      <String, SyncItemProcessingGate>{};

  // ============================================================
  // STATE
  // ============================================================

  SyncServiceState _state = SyncServiceState.stopped;

  Timer? _timer;

  bool _started = false;

  bool _syncing = false;

  bool _disposed = false;

  // ============================================================
  // RESYNC REQUEST
  // ============================================================
  //
  // Se um Repository chamar requestSync() enquanto um lote já
  // está em andamento, não descartamos o pedido.
  //
  // Assim que o lote atual termina, fazemos nova passagem.
  //
  // ============================================================

  bool _resyncRequested = false;

  int _pendingCount = 0;

  int _readyCount = 0;

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

  int get readyCount => _readyCount;

  int get lastSyncedCount => _lastSyncedCount;

  int get lastFailedCount => _lastFailedCount;

  String? get lastError => _lastError;

  DateTime? get lastSyncAt => _lastSyncAt;

  DateTime? get lastAttemptAt => _lastAttemptAt;

  bool get hasPending => _pendingCount > 0;

  bool get hasReady => _readyCount > 0;

  bool get hasError => _lastError != null;

  // ============================================================
  // START
  // ============================================================

  Future<void> start() async {
    if (_disposed || _started) {
      return;
    }

    _started = true;

    debugPrint('[SYNC SERVICE] Iniciando...');

    _setState(SyncServiceState.checking);

    _connectivityService.addListener(_onConnectivityChanged);

    try {
      await _connectivityService.start();

      await refreshPendingCount();

      debugPrint(
        '[SYNC SERVICE] '
        'Inicializado. '
        'online=${_connectivityService.isOnline} '
        'pending=$_pendingCount '
        'ready=$_readyCount '
        'handlers=${_handlers.length}',
      );

      if (_connectivityService.isOnline) {
        await syncNow(checkConnection: false);
      } else {
        _setState(SyncServiceState.offline);
      }

      _timer = Timer.periodic(syncInterval, (_) {
        unawaited(_periodicCheck());
      });
    } catch (error, stackTrace) {
      _started = false;

      _connectivityService.removeListener(_onConnectivityChanged);

      _lastError = error.toString();

      _setState(SyncServiceState.error);

      debugPrint(
        '[SYNC SERVICE] '
        'Erro ao iniciar: $error',
      );

      debugPrint(stackTrace.toString());

      rethrow;
    }
  }

  // ============================================================
  // PERIODIC CHECK
  // ============================================================

  Future<void> _periodicCheck() async {
    if (!_started || _disposed) {
      return;
    }

    final online = await _connectivityService.checkNow();

    await refreshPendingCount();

    if (!online) {
      _setState(SyncServiceState.offline);

      return;
    }

    if (_readyCount > 0) {
      await syncNow(checkConnection: false);

      return;
    }

    if (_pendingCount > 0) {
      // Existem itens aguardando next_attempt_at.
      _setState(SyncServiceState.idle);

      return;
    }

    _setState(SyncServiceState.idle);
  }

  // ============================================================
  // CONNECTIVITY CHANGED
  // ============================================================

  void _onConnectivityChanged() {
    if (!_started || _disposed) {
      return;
    }

    if (_connectivityService.isOffline) {
      _setState(SyncServiceState.offline);

      return;
    }

    if (_connectivityService.isOnline) {
      unawaited(_onConnectionRestored());
    }
  }

  Future<void> _onConnectionRestored() async {
    debugPrint(
      '[SYNC SERVICE] '
      'Conexão restaurada.',
    );

    await refreshPendingCount();

    if (_pendingCount == 0) {
      _setState(SyncServiceState.idle);

      return;
    }

    await syncNow(checkConnection: false);
  }

  // ============================================================
  // REGISTER CUSTOM HANDLER
  // ============================================================

  void registerHandler({
    required String entityType,
    required SyncItemHandler handler,
    SyncItemProcessingGate? processingGate,
  }) {
    final key = entityType.trim();

    if (key.isEmpty) {
      throw ArgumentError('entityType não pode ser vazio.');
    }

    _handlers[key] = handler;

    if (processingGate == null) {
      _processingGates.remove(key);
    } else {
      _processingGates[key] = processingGate;
    }

    debugPrint(
      '[SYNC SERVICE] '
      'Handler registrado: $key'
      '${processingGate == null ? '' : ' (com gate)'}',
    );
  }

  // ============================================================
  // REGISTER SUPABASE TABLE
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
      throw ArgumentError('entityType não pode ser vazio.');
    }

    if (normalizedTable.isEmpty) {
      throw ArgumentError('table não pode ser vazia.');
    }

    if (normalizedIdColumn.isEmpty) {
      throw ArgumentError('idColumn não pode ser vazio.');
    }

    registerHandler(
      entityType: normalizedEntityType,
      handler: (item) async {
        switch (item.operation) {
          case SyncOperation.create:
          case SyncOperation.update:
            final payload = Map<String, dynamic>.from(item.payload);

            payload.putIfAbsent(normalizedIdColumn, () => item.entityId);

            await _client
                .from(normalizedTable)
                .upsert(payload, onConflict: normalizedIdColumn);

            break;

          case SyncOperation.delete:
            await _client
                .from(normalizedTable)
                .delete()
                .eq(normalizedIdColumn, item.entityId);

            break;
        }
      },
    );
  }

  // ============================================================
  // UNREGISTER
  // ============================================================

  void unregisterHandler(String entityType) {
    final key = entityType.trim();

    _handlers.remove(key);

    _processingGates.remove(key);
  }

  bool hasHandler(String entityType) {
    return _handlers.containsKey(entityType.trim());
  }

  // ============================================================
  // REQUEST SYNC
  // ============================================================
  //
  // Chamado imediatamente após Repository.enqueue().
  //
  // Se o serviço ainda estiver sincronizando, deixamos
  // _resyncRequested = true para uma nova passagem automática.
  //
  // ============================================================

  void requestSync() {
    if (_disposed) {
      return;
    }

    if (!_started) {
      debugPrint(
        '[SYNC SERVICE] '
        'requestSync recebido antes do start.',
      );

      return;
    }

    _resyncRequested = true;

    debugPrint(
      '[SYNC SERVICE] '
      'Sincronização solicitada.',
    );

    unawaited(_requestSyncInternal());
  }

  Future<void> _requestSyncInternal() async {
    if (_disposed || !_started) {
      return;
    }

    await refreshPendingCount();

    debugPrint(
      '[SYNC SERVICE] '
      'requestSync: '
      'online=${_connectivityService.isOnline} '
      'syncing=$_syncing '
      'pending=$_pendingCount '
      'ready=$_readyCount',
    );

    if (!_connectivityService.isOnline) {
      _setState(SyncServiceState.offline);

      return;
    }

    if (_syncing) {
      // O pedido já ficou registrado em _resyncRequested.
      return;
    }

    await syncNow(checkConnection: false);
  }

  // ============================================================
  // SYNC NOW
  // ============================================================

  Future<void> syncNow({bool checkConnection = true}) async {
    if (!_started || _disposed) {
      return;
    }

    if (_syncing) {
      _resyncRequested = true;

      debugPrint(
        '[SYNC SERVICE] '
        'syncNow já em execução; nova passagem agendada.',
      );

      return;
    }

    _syncing = true;

    // Este pedido será atendido pelo lote que começa agora.
    _resyncRequested = false;

    _lastAttemptAt = DateTime.now();

    _lastSyncedCount = 0;

    _lastFailedCount = 0;

    _lastError = null;

    _setState(SyncServiceState.checking);

    try {
      // ========================================================
      // CONNECTION
      // ========================================================

      if (checkConnection) {
        final online = await _connectivityService.checkNow();

        if (!online) {
          _setState(SyncServiceState.offline);

          return;
        }
      } else if (!_connectivityService.isOnline) {
        _setState(SyncServiceState.offline);

        return;
      }

      // ========================================================
      // AUTH
      // ========================================================
      //
      // A maioria dos handlers utiliza RLS do Supabase.
      //
      // Se o app estiver restaurando a sessão, não marcamos a
      // operação como falha. Apenas aguardamos nova solicitação
      // ou próximo ciclo.
      //
      // ========================================================

      if (_client.auth.currentUser == null) {
        await refreshPendingCount();

        _lastError = null;

        _setState(SyncServiceState.idle);

        debugPrint(
          '[SYNC SERVICE] '
          'Fila aguardando autenticação. '
          'pending=$_pendingCount',
        );

        return;
      }

      _setState(SyncServiceState.syncing);

      // ========================================================
      // PROCESS BATCHES
      // ========================================================
      //
      // Processamos mais de um lote na mesma execução caso
      // existam mais itens prontos que batchSize.
      //
      // ========================================================

      var continueProcessing = true;

      while (continueProcessing &&
          _started &&
          !_disposed &&
          _connectivityService.isOnline) {
        final items = await _loadProcessableItems();

        if (items.isEmpty) {
          break;
        }

        debugPrint(
          '[SYNC SERVICE] '
          'Processando ${items.length} item(ns).',
        );

        var processedThisBatch = 0;

        for (final item in items) {
          if (!_connectivityService.isOnline) {
            _setState(SyncServiceState.offline);

            continueProcessing = false;

            break;
          }

          final handler = _handlers[item.entityType];

          if (handler == null) {
            _lastFailedCount++;

            _lastError =
                'Nenhum handler registrado para '
                '"${item.entityType}".';

            debugPrint(
              '[SYNC SERVICE] '
              'SEM HANDLER: '
              '${item.entityType}/${item.entityId}',
            );

            // Sem handler não adianta repetir dentro do mesmo
            // loop, então não contamos como item processado.
            continue;
          }

          try {
            debugPrint(
              '[SYNC SERVICE] '
              'Enviando: '
              '${item.entityType}/${item.entityId} '
              '(${item.operation.value})',
            );

            await handler(item);

            await _queue.markSuccess(item.id);

            _lastSyncedCount++;
            processedThisBatch++;

            debugPrint(
              '[SYNC SERVICE] '
              'OK: '
              '${item.entityType}/${item.entityId} '
              '(${item.operation.value})',
            );
          } catch (error, stackTrace) {
            _lastFailedCount++;
            processedThisBatch++;

            _lastError = error.toString();

            debugPrint(
              '[SYNC SERVICE] '
              'FALHA: '
              '${item.entityType}/${item.entityId} '
              '(${item.operation.value})',
            );

            debugPrint('[SYNC SERVICE] $error');

            debugPrint(stackTrace.toString());

            await _queue.markFailed(id: item.id, error: error);

            final online = await _connectivityService.checkNow();

            if (!online) {
              _setState(SyncServiceState.offline);

              continueProcessing = false;

              break;
            }
          }
        }

        // Se nenhum item do lote pôde ser processado, geralmente
        // significa ausência de handler. Evitamos loop infinito.
        if (processedThisBatch == 0) {
          continueProcessing = false;
        }

        // Se o lote veio menor que batchSize, já chegamos ao fim
        // dos itens atualmente prontos.
        if (items.length < batchSize) {
          continueProcessing = false;
        }
      }

      await refreshPendingCount();

      _lastSyncAt = DateTime.now();

      if (_connectivityService.isOffline) {
        _setState(SyncServiceState.offline);
      } else if (_lastFailedCount > 0 && _lastSyncedCount == 0) {
        _setState(SyncServiceState.error);
      } else {
        _setState(SyncServiceState.idle);
      }

      debugPrint(
        '[SYNC SERVICE] '
        'Fim. '
        'synced=$_lastSyncedCount '
        'failed=$_lastFailedCount '
        'pending=$_pendingCount '
        'ready=$_readyCount',
      );
    } catch (error, stackTrace) {
      _lastError = error.toString();

      debugPrint(
        '[SYNC SERVICE] '
        'Erro geral: $error',
      );

      debugPrint(stackTrace.toString());

      if (_connectivityService.isOffline) {
        _setState(SyncServiceState.offline);
      } else {
        _setState(SyncServiceState.error);
      }
    } finally {
      _syncing = false;

      _safeNotifyListeners();

      // ========================================================
      // COALESCED RESYNC
      // ========================================================
      //
      // Se algum Repository criou nova operação enquanto este
      // lote estava rodando, processamos novamente imediatamente.
      //
      // ========================================================

      if (_resyncRequested &&
          _started &&
          !_disposed &&
          _connectivityService.isOnline) {
        _resyncRequested = false;

        unawaited(
          Future<void>.delayed(
            const Duration(milliseconds: 100),
            () => syncNow(checkConnection: false),
          ),
        );
      }
    }
  }

  // ============================================================
  // LOAD PROCESSABLE ITEMS
  // ============================================================
  //
  // Por que não usamos apenas:
  //
  // _queue.getPending(limit: batchSize)
  //
  // aqui?
  //
  // Porque um conjunto de itens ADIADOS por um processingGate
  // poderia ocupar o início da fila e bloquear entidades de outros
  // módulos que ainda podem sincronizar.
  //
  // Então:
  //
  // 1. lemos a fila persistente;
  // 2. ignoramos itens que ainda estão em retry;
  // 3. aplicamos o gate de cada entityType;
  // 4. retornamos até batchSize itens realmente processáveis.
  //
  // Um item bloqueado pelo gate permanece intocado na SyncQueue.
  //
  // ============================================================

  Future<List<SyncItem>> _loadProcessableItems() async {
    final all = await _queue.getAll();

    final result = <SyncItem>[];

    for (final item in all) {
      if (!item.canAttemptNow) {
        continue;
      }

      final gate = _processingGates[item.entityType];

      if (gate != null) {
        var allowed = false;

        try {
          allowed = await gate(item);
        } catch (error, stackTrace) {
          // ====================================================
          // FAIL CLOSED
          // ====================================================
          //
          // Uma falha ao consultar a política de transmissão
          // NUNCA deve liberar o envio.
          //
          // Também não marcamos o item como failed, pois o erro
          // pertence ao gate/política e não à operação remota.
          //
          // ====================================================

          debugPrint(
            '[SYNC SERVICE] '
            'GATE BLOQUEOU POR ERRO: '
            '${item.entityType}/${item.entityId}',
          );

          debugPrint('[SYNC SERVICE] $error');

          debugPrint(stackTrace.toString());

          allowed = false;
        }

        if (!allowed) {
          debugPrint(
            '[SYNC SERVICE] '
            'ADIADO PELO GATE: '
            '${item.entityType}/${item.entityId}',
          );

          continue;
        }
      }

      result.add(item);

      if (result.length >= batchSize) {
        break;
      }
    }

    return result;
  }

  // ============================================================
  // REFRESH PENDING COUNT
  // ============================================================

  Future<void> refreshPendingCount() async {
    try {
      final count = await _queue.count();

      final ready = await _queue.countReady();

      final changed = _pendingCount != count || _readyCount != ready;

      _pendingCount = count;

      _readyCount = ready;

      if (changed) {
        debugPrint(
          '[SYNC SERVICE] '
          'Fila: pending=$_pendingCount '
          'ready=$_readyCount',
        );

        _safeNotifyListeners();
      }
    } catch (error) {
      debugPrint(
        '[SYNC SERVICE] '
        'Erro ao contar pendências: $error',
      );
    }
  }

  // ============================================================
  // CLEAR ERROR
  // ============================================================

  void clearError() {
    if (_lastError == null) {
      return;
    }

    _lastError = null;

    if (_connectivityService.isOffline) {
      _setState(SyncServiceState.offline);
    } else if (_syncing) {
      _setState(SyncServiceState.syncing);
    } else {
      _setState(SyncServiceState.idle);
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
        if (_pendingCount > 0) {
          return 'Offline • $_pendingCount alteração'
              '${_pendingCount == 1 ? '' : 'ões'} salva'
              '${_pendingCount == 1 ? '' : 's'} neste dispositivo';
        }

        return 'Offline';

      case SyncServiceState.syncing:
        if (_pendingCount > 0) {
          return 'Sincronizando $_pendingCount alteração'
              '${_pendingCount == 1 ? '' : 'ões'}...';
        }

        return 'Sincronizando...';

      case SyncServiceState.error:
        return 'Erro de sincronização';

      case SyncServiceState.idle:
        if (_pendingCount > 0) {
          if (_readyCount == 0) {
            return '$_pendingCount alteração'
                '${_pendingCount == 1 ? '' : 'ões'} aguardando nova tentativa';
          }

          return '$_pendingCount alteração'
              '${_pendingCount == 1 ? '' : 'ões'} aguardando sincronização';
        }

        return 'Tudo sincronizado';
    }
  }

  // ============================================================
  // STATE
  // ============================================================

  void _setState(SyncServiceState value) {
    if (_state == value) {
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

  Future<void> stop() async {
    if (!_started) {
      return;
    }

    _timer?.cancel();

    _timer = null;

    _connectivityService.removeListener(_onConnectivityChanged);

    await _connectivityService.stop();

    _started = false;

    _syncing = false;

    _resyncRequested = false;

    _setState(SyncServiceState.stopped);

    debugPrint('[SYNC SERVICE] Parado.');
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;

    _timer?.cancel();

    _timer = null;

    _connectivityService.removeListener(_onConnectivityChanged);

    unawaited(_connectivityService.stop());

    super.dispose();
  }
}
