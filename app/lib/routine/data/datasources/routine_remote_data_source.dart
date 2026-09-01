import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

class RoutineRemoteDataSource {
  RoutineRemoteDataSource({
    SupabaseClient? client,
  }) : _client =
           client ??
           Supabase.instance.client;

  final SupabaseClient _client;

  // ============================================================
  // TABLES
  // ============================================================

  static const String _daysTable = 'routine_days';

  static const String _blocksTable = 'routine_blocks';

  static const String _taskItemsTable = 'task_items';

  static const String _mindMapNodesTable = 'mind_map_nodes';

  // ============================================================
  // LOAD WEEK
  // ============================================================

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  loadWeek({
    required String userId,
    required DateTime weekStart,
  }) async {
    final start = _dateOnly(
      weekStart,
    );

    final end = start.add(
      const Duration(
        days: 6,
      ),
    );

    // ----------------------------------------------------------
    // LOAD DAYS
    // ----------------------------------------------------------

    final response = await _client
        .from(
          _daysTable,
        )
        .select()
        .eq(
          'user_id',
          userId,
        )
        .gte(
          'date',
          _dateString(
            start,
          ),
        )
        .lte(
          'date',
          _dateString(
            end,
          ),
        )
        .order(
          'date',
          ascending: true,
        );

    final days = response
        .map<
          Map<
            String,
            dynamic
          >
        >(
          (
            row,
          ) =>
              Map<
                String,
                dynamic
              >.from(
                row,
              ),
        )
        .toList();

    if (days.isEmpty) {
      return [];
    }

    // ----------------------------------------------------------
    // LOAD RELATIONS FOR EACH DAY
    // ----------------------------------------------------------

    final result =
        <
          Map<
            String,
            dynamic
          >
        >[];

    for (final day in days) {
      final dayId = day['id']?.toString();

      if (dayId ==
              null ||
          dayId.isEmpty) {
        result.add(
          {
            ...day,
            'blocks':
                <
                  Map<
                    String,
                    dynamic
                  >
                >[],
          },
        );

        continue;
      }

      final blocks = await _loadBlocks(
        dayId: dayId,
      );

      result.add(
        {
          ...day,
          'blocks': blocks,
        },
      );
    }

    return result;
  }

  // ============================================================
  // GET DAY
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >?
  >
  getDay({
    required String userId,
    required DateTime date,
  }) async {
    final response = await _client
        .from(
          _daysTable,
        )
        .select()
        .eq(
          'user_id',
          userId,
        )
        .eq(
          'date',
          _dateString(
            date,
          ),
        )
        .maybeSingle();

    if (response ==
        null) {
      return null;
    }

    final day =
        Map<
          String,
          dynamic
        >.from(
          response,
        );

    final dayId = day['id']?.toString();

    if (dayId ==
            null ||
        dayId.isEmpty) {
      day['blocks'] =
          <
            Map<
              String,
              dynamic
            >
          >[];

      return day;
    }

    day['blocks'] = await _loadBlocks(
      dayId: dayId,
    );

    return day;
  }

  // ============================================================
  // LOAD BLOCKS
  // ============================================================

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  _loadBlocks({
    required String dayId,
  }) async {
    final response = await _client
        .from(
          _blocksTable,
        )
        .select()
        .eq(
          'routine_day_id',
          dayId,
        )
        .order(
          'position',
          ascending: true,
        );

    final blocks = response
        .map<
          Map<
            String,
            dynamic
          >
        >(
          (
            row,
          ) =>
              Map<
                String,
                dynamic
              >.from(
                row,
              ),
        )
        .toList();

    if (blocks.isEmpty) {
      return [];
    }

    final result =
        <
          Map<
            String,
            dynamic
          >
        >[];

    for (final block in blocks) {
      final blockId = block['id']?.toString();

      if (blockId ==
              null ||
          blockId.isEmpty) {
        continue;
      }

      final items = await _loadTaskItems(
        blockId: blockId,
      );

      final mindMapNodes = await _loadMindMapNodes(
        blockId: blockId,
      );

      result.add(
        {
          ...block,

          // Compatibilidade com BoardBlockDto.
          'type':
              block['type'] ??
              block['block_type'] ??
              'note',

          'content':
              block['content'] ??
              '',

          'content_status':
              block['content_status'] ??
              'idea',

          // ====================================================
          // TAMANHO PERSONALIZADO DO BLOCO
          // ====================================================
          //
          // Usado principalmente pelo bloco de mapa mental.
          //
          // Mantemos as duas chaves exatamente como o model/DTO
          // espera para que o tamanho salvo volte corretamente ao
          // reabrir a rotina.
          //
          // ====================================================
          'width': block['width'],

          'height': block['height'],

          // ====================================================
          // DOCUMENT ATTACHMENT
          // ====================================================
          //
          // Referência lógica para BoardAttachment.
          //
          // O arquivo físico não fica em routine_blocks.
          // A tabela guarda somente o ID do anexo.
          //
          // ====================================================
          'attachment_id':
              block['attachment_id'] ??
              block['attachmentId'],

          'items': items,

          'mind_map_nodes': mindMapNodes,
        },
      );
    }

    return result;
  }

  // ============================================================
  // LOAD TASK ITEMS
  // ============================================================

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  _loadTaskItems({
    required String blockId,
  }) async {
    final response = await _client
        .from(
          _taskItemsTable,
        )
        .select()
        .eq(
          'block_id',
          blockId,
        )
        .order(
          'position',
          ascending: true,
        );

    return response.map<
      Map<
        String,
        dynamic
      >
    >(
      (
        row,
      ) {
        final map =
            Map<
              String,
              dynamic
            >.from(
              row,
            );

        return {
          ...map,

          // Compatibilidade com o DTO atual.
          'text':
              map['text'] ??
              map['title'] ??
              '',

          'completed':
              map['completed'] ??
              map['is_completed'] ??
              false,
        };
      },
    ).toList();
  }

  // ============================================================
  // LOAD MIND MAP NODES
  // ============================================================
  //
  // O banco antigo usa:
  //
  // - mind_map_block_id
  // - title
  // - x
  // - y
  //
  // O modelo atual do app usa:
  //
  // - block_id
  // - label
  // - position_x
  // - position_y
  //
  // Aqui fazemos a conversão para manter compatibilidade.
  // ============================================================

  Future<
    List<
      Map<
        String,
        dynamic
      >
    >
  >
  _loadMindMapNodes({
    required String blockId,
  }) async {
    final response = await _client
        .from(
          _mindMapNodesTable,
        )
        .select()
        .eq(
          'mind_map_block_id',
          blockId,
        );

    return response.map<
      Map<
        String,
        dynamic
      >
    >(
      (
        row,
      ) {
        final map =
            Map<
              String,
              dynamic
            >.from(
              row,
            );

        final metadata = _jsonMap(
          map['metadata'],
        );

        return {
          ...map,

          // ====================================================
          // NOMES ESPERADOS PELO DTO ATUAL
          // ====================================================
          'block_id':
              map['mind_map_block_id'] ??
              '',

          'label':
              map['title'] ??
              'Novo nó',

          'position_x':
              map['x'] ??
              0,

          'position_y':
              map['y'] ??
              0,

          'is_root':
              map['is_root'] ??
              false,

          // ====================================================
          // CAMPOS DO MODELO ATUAL SALVOS EM METADATA
          // ====================================================
          'parent_id': metadata['parent_id'],

          'source_port': metadata['source_port'],

          'target_port': metadata['target_port'],
        };
      },
    ).toList();
  }

  // ============================================================
  // SAVE DAY
  // ============================================================
  //
  // Pode receber:
  //
  // {
  //   id,
  //   user_id,
  //   date,
  //   focus,
  //   blocks: [...]
  // }
  //
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  saveDay({
    required String userId,
    required Map<
      String,
      dynamic
    >
    data,
  }) async {
    final source =
        Map<
          String,
          dynamic
        >.from(
          data,
        );

    final blocks = _mapList(
      source.remove(
        'blocks',
      ),
    );

    source['user_id'] = userId;

    // Não enviamos relações para routine_days.
    source.remove(
      'items',
    );

    source.remove(
      'mind_map_nodes',
    );

    source.remove(
      'mindMapNodes',
    );

    final savedDay = await _saveDayRecord(
      userId: userId,
      data: source,
    );

    final dayId = savedDay['id']?.toString();

    if (dayId ==
            null ||
        dayId.isEmpty) {
      throw StateError(
        'O Supabase não retornou o ID do dia salvo.',
      );
    }

    // ----------------------------------------------------------
    // SAVE BLOCKS
    // ----------------------------------------------------------

    if (data.containsKey(
      'blocks',
    )) {
      await _saveBlocks(
        dayId: dayId,
        blocks: blocks,
      );
    }

    // ----------------------------------------------------------
    // RELOAD
    // ----------------------------------------------------------

    final reloaded = await getDay(
      userId: userId,
      date: _parseDate(
        savedDay['date'],
      ),
    );

    if (reloaded !=
        null) {
      return reloaded;
    }

    return {
      ...savedDay,
      'blocks':
          <
            Map<
              String,
              dynamic
            >
          >[],
    };
  }

  // ============================================================
  // SAVE DAY RECORD
  // ============================================================

  Future<
    Map<
      String,
      dynamic
    >
  >
  _saveDayRecord({
    required String userId,
    required Map<
      String,
      dynamic
    >
    data,
  }) async {
    final payload =
        Map<
          String,
          dynamic
        >.from(
          data,
        );

    payload['user_id'] = userId;

    final id = _nullableString(
      payload['id'],
    );

    // ----------------------------------------------------------
    // EXISTING BY ID
    // ----------------------------------------------------------

    if (id !=
        null) {
      final updatePayload =
          Map<
            String,
            dynamic
          >.from(
            payload,
          );

      updatePayload.remove(
        'id',
      );

      final response = await _client
          .from(
            _daysTable,
          )
          .update(
            updatePayload,
          )
          .eq(
            'id',
            id,
          )
          .eq(
            'user_id',
            userId,
          )
          .select()
          .maybeSingle();

      if (response !=
          null) {
        return Map<
          String,
          dynamic
        >.from(
          response,
        );
      }
    }

    // ----------------------------------------------------------
    // EXISTING BY DATE
    // ----------------------------------------------------------
    //
    // Isso evita criar vários registros para o mesmo dia quando
    // o modelo ainda não possui ID local.
    //
    // ----------------------------------------------------------

    final date = _nullableString(
      payload['date'],
    );

    if (date !=
        null) {
      final existing = await _client
          .from(
            _daysTable,
          )
          .select(
            'id',
          )
          .eq(
            'user_id',
            userId,
          )
          .eq(
            'date',
            date,
          )
          .maybeSingle();

      if (existing !=
          null) {
        final existingId = existing['id']?.toString();

        if (existingId !=
                null &&
            existingId.isNotEmpty) {
          final updatePayload =
              Map<
                String,
                dynamic
              >.from(
                payload,
              );

          updatePayload.remove(
            'id',
          );

          final response = await _client
              .from(
                _daysTable,
              )
              .update(
                updatePayload,
              )
              .eq(
                'id',
                existingId,
              )
              .eq(
                'user_id',
                userId,
              )
              .select()
              .single();

          return Map<
            String,
            dynamic
          >.from(
            response,
          );
        }
      }
    }

    // ----------------------------------------------------------
    // INSERT
    // ----------------------------------------------------------

    payload.remove(
      'id',
    );

    final response = await _client
        .from(
          _daysTable,
        )
        .insert(
          payload,
        )
        .select()
        .single();

    return Map<
      String,
      dynamic
    >.from(
      response,
    );
  }

  // ============================================================
  // SAVE BLOCKS
  // ============================================================

  Future<
    void
  >
  _saveBlocks({
    required String dayId,
    required List<
      Map<
        String,
        dynamic
      >
    >
    blocks,
  }) async {
    // IDs que continuam existindo.
    final activeIds =
        <
          String
        >{};

    // ----------------------------------------------------------
    // UPSERT BLOCKS
    // ----------------------------------------------------------

    for (
      var index = 0;
      index <
          blocks.length;
      index++
    ) {
      final raw =
          Map<
            String,
            dynamic
          >.from(
            blocks[index],
          );

      final blockId = _requiredString(
        raw,
        'id',
      );

      activeIds.add(
        blockId,
      );

      final items = _mapList(
        raw.remove(
          'items',
        ),
      );

      final mindMapNodes = _mapList(
        raw.remove(
              'mind_map_nodes',
            ) ??
            raw.remove(
              'mindMapNodes',
            ),
      );

      // --------------------------------------------------------
      // BLOCK PAYLOAD
      // --------------------------------------------------------

      final payload =
          <
            String,
            dynamic
          >{
            'id': blockId,
            'routine_day_id': dayId,
            'type':
                raw['type'] ??
                raw['block_type'] ??
                'note',
            'title':
                raw['title'] ??
                '',
            'content':
                raw['content'] ??
                '',
            'content_status':
                raw['content_status'] ??
                raw['contentStatus'] ??
                'idea',
            'position_x':
                raw['position_x'] ??
                raw['positionX'],
            'position_y':
                raw['position_y'] ??
                raw['positionY'],

            // ==================================================
            // TAMANHO PERSONALIZADO
            // ==================================================
            //
            // Esses campos permitem persistir o tamanho do mapa
            // mental. Para outros tipos de bloco podem ficar null.
            //
            // ==================================================
            'width': raw['width'],

            'height': raw['height'],

            // ==================================================
            // DOCUMENT ATTACHMENT
            // ==================================================
            //
            // Para blocos do tipo document, guarda apenas a
            // referência ao BoardAttachment.
            //
            // Também aceitamos attachmentId para compatibilidade
            // com mapas montados diretamente pelo Flutter.
            //
            // ==================================================
            'attachment_id':
                raw['attachment_id'] ??
                raw['attachmentId'],

            // Mantém posição de lista também.
            'position':
                raw['position'] ??
                index,
          };

      await _client
          .from(
            _blocksTable,
          )
          .upsert(
            payload,
            onConflict: 'id',
          );

      // --------------------------------------------------------
      // CHECKLIST
      // --------------------------------------------------------

      await _saveTaskItems(
        blockId: blockId,
        items: items,
      );

      // --------------------------------------------------------
      // MIND MAP
      // --------------------------------------------------------

      await _saveMindMapNodes(
        blockId: blockId,
        nodes: mindMapNodes,
      );
    }

    // ----------------------------------------------------------
    // DELETE REMOVED BLOCKS
    // ----------------------------------------------------------

    final existingResponse = await _client
        .from(
          _blocksTable,
        )
        .select(
          'id',
        )
        .eq(
          'routine_day_id',
          dayId,
        );

    final existingIds = existingResponse
        .map(
          (
            row,
          ) => row['id']?.toString(),
        )
        .whereType<
          String
        >()
        .where(
          (
            id,
          ) => id.isNotEmpty,
        )
        .toList();

    for (final existingId in existingIds) {
      if (!activeIds.contains(
        existingId,
      )) {
        await _client
            .from(
              _blocksTable,
            )
            .delete()
            .eq(
              'id',
              existingId,
            )
            .eq(
              'routine_day_id',
              dayId,
            );
      }
    }
  }

  // ============================================================
  // SAVE TASK ITEMS
  // ============================================================

  Future<
    void
  >
  _saveTaskItems({
    required String blockId,
    required List<
      Map<
        String,
        dynamic
      >
    >
    items,
  }) async {
    // Estratégia:
    //
    // apaga a coleção desse bloco e recria.
    //
    // Para checklist pequeno isso mantém a sincronização simples
    // e evita itens antigos permanecerem no banco.

    await _client
        .from(
          _taskItemsTable,
        )
        .delete()
        .eq(
          'block_id',
          blockId,
        );

    if (items.isEmpty) {
      return;
    }

    final payload =
        <
          Map<
            String,
            dynamic
          >
        >[];

    for (
      var index = 0;
      index <
          items.length;
      index++
    ) {
      final item = items[index];

      final map =
          <
            String,
            dynamic
          >{
            'block_id': blockId,
            'text':
                item['text'] ??
                '',
            'completed': _boolValue(
              item['completed'],
            ),
            'position':
                item['position'] ??
                index,
          };

      final id = _nullableString(
        item['id'],
      );

      if (id !=
          null) {
        map['id'] = id;
      }

      payload.add(
        map,
      );
    }

    await _client
        .from(
          _taskItemsTable,
        )
        .insert(
          payload,
        );
  }

  // ============================================================
  // SAVE MIND MAP NODES
  // ============================================================
  //
  // Compatibilidade entre o modelo atual e o schema do Supabase:
  //
  // app                      banco
  // ------------------------------------------------------------
  // block_id             ->  mind_map_block_id
  // label                ->  title
  // position_x           ->  x
  // position_y           ->  y
  // parent_id            ->  metadata.parent_id
  // source_port          ->  metadata.source_port
  // target_port          ->  metadata.target_port
  //
  // IMPORTANTE:
  //
  // Os IDs locais do mapa podem ter formatos como:
  //
  // <uuid-do-bloco>-node-<timestamp>
  //
  // Isso NÃO é um UUID PostgreSQL válido.
  //
  // Antes de salvar:
  //
  // 1. preservamos IDs que já são UUID válidos;
  // 2. geramos UUID v4 para IDs locais inválidos;
  // 3. remapeamos parent_id para o novo UUID;
  // 4. salvamos o ID local original em metadata.client_id.
  //
  // Assim a coluna "id uuid" do Supabase nunca recebe strings
  // inválidas e as relações entre os nós continuam consistentes.
  // ============================================================

  Future<
    void
  >
  _saveMindMapNodes({
    required String blockId,
    required List<
      Map<
        String,
        dynamic
      >
    >
    nodes,
  }) async {
    // ----------------------------------------------------------
    // REMOVE OLD
    // ----------------------------------------------------------

    await _client
        .from(
          _mindMapNodesTable,
        )
        .delete()
        .eq(
          'mind_map_block_id',
          blockId,
        );

    if (nodes.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // MAPA DE IDs LOCAIS -> UUIDS DO BANCO
    // ----------------------------------------------------------
    //
    // Fazemos esse passo antes de montar o payload porque um nó
    // pode apontar para outro por parent_id.
    // ----------------------------------------------------------

    final idMap =
        <
          String,
          String
        >{};

    for (final rawNode in nodes) {
      final localId = _nullableString(
        rawNode['id'],
      );

      if (localId ==
          null) {
        continue;
      }

      idMap[localId] =
          _isUuid(
            localId,
          )
          ? localId
          : _generateUuidV4();
    }

    // ----------------------------------------------------------
    // PAYLOAD
    // ----------------------------------------------------------

    final payload =
        <
          Map<
            String,
            dynamic
          >
        >[];

    for (
      var index = 0;
      index <
          nodes.length;
      index++
    ) {
      final node =
          Map<
            String,
            dynamic
          >.from(
            nodes[index],
          );

      final existingMetadata = _jsonMap(
        node['metadata'],
      );

      final metadata =
          <
            String,
            dynamic
          >{
            ...existingMetadata,
          };

      // --------------------------------------------------------
      // ID DO NÓ
      // --------------------------------------------------------

      final localId = _nullableString(
        node['id'],
      );

      final databaseId =
          localId ==
              null
          ? _generateUuidV4()
          : idMap[localId] ??
                (_isUuid(
                      localId,
                    )
                    ? localId
                    : _generateUuidV4());

      // Guarda o ID original apenas quando ele era diferente
      // do UUID realmente salvo no banco.
      if (localId !=
              null &&
          localId !=
              databaseId) {
        metadata['client_id'] = localId;
      }

      // --------------------------------------------------------
      // PARENT ID
      // --------------------------------------------------------

      final rawParentId = _nullableString(
        node['parent_id'] ??
            node['parentId'],
      );

      if (rawParentId !=
          null) {
        final mappedParentId =
            idMap[rawParentId] ??
            (_isUuid(
                  rawParentId,
                )
                ? rawParentId
                : null);

        if (mappedParentId !=
            null) {
          metadata['parent_id'] = mappedParentId;
        } else {
          // Mantém o valor original apenas em client_parent_id
          // para diagnóstico, mas não o usa como UUID de relação.
          metadata['client_parent_id'] = rawParentId;
          metadata.remove(
            'parent_id',
          );
        }
      } else {
        metadata.remove(
          'parent_id',
        );
      }

      // --------------------------------------------------------
      // PORTAS
      // --------------------------------------------------------

      final sourcePort = _nullableString(
        node['source_port'] ??
            node['sourcePort'],
      );

      if (sourcePort !=
          null) {
        metadata['source_port'] = sourcePort;
      } else {
        metadata.remove(
          'source_port',
        );
      }

      final targetPort = _nullableString(
        node['target_port'] ??
            node['targetPort'],
      );

      if (targetPort !=
          null) {
        metadata['target_port'] = targetPort;
      } else {
        metadata.remove(
          'target_port',
        );
      }

      // --------------------------------------------------------
      // MAPA FINAL PARA O SUPABASE
      // --------------------------------------------------------

      final map =
          <
            String,
            dynamic
          >{
            // ==================================================
            // CHAVE PRIMÁRIA UUID VÁLIDA
            // ==================================================
            'id': databaseId,

            // ==================================================
            // RELAÇÃO
            // ==================================================
            'mind_map_block_id': blockId,

            // ==================================================
            // TEXTO
            // ==================================================
            'title':
                node['label'] ??
                node['title'] ??
                'Novo nó',

            'content': node['content'],

            // ==================================================
            // POSIÇÃO
            // ==================================================
            'x':
                node['position_x'] ??
                node['positionX'] ??
                node['x'] ??
                0,

            'y':
                node['position_y'] ??
                node['positionY'] ??
                node['y'] ??
                0,

            // ==================================================
            // TAMANHO
            // ==================================================
            'width':
                node['width'] ??
                180,

            'height':
                node['height'] ??
                80,

            // ==================================================
            // VISUAL / ESTADO
            // ==================================================
            'z_index':
                node['z_index'] ??
                node['zIndex'] ??
                index,

            'color': node['color'],

            'icon': node['icon'],

            'node_type':
                node['node_type'] ??
                node['nodeType'] ??
                'default',

            'is_selected': _boolValue(
              node['is_selected'] ??
                  node['isSelected'],
            ),

            'is_collapsed': _boolValue(
              node['is_collapsed'] ??
                  node['isCollapsed'],
            ),

            'is_root': _boolValue(
              node['is_root'] ??
                  node['isRoot'],
            ),

            // ==================================================
            // CAMPOS EXTRAS DO MODELO ATUAL
            // ==================================================
            'metadata': metadata,
          };

      // --------------------------------------------------------
      // NÃO ENVIAR NULL EM CAMPOS OPCIONAIS
      // --------------------------------------------------------

      map.removeWhere(
        (
          key,
          value,
        ) =>
            value ==
            null,
      );

      payload.add(
        map,
      );
    }

    // ----------------------------------------------------------
    // INSERT
    // ----------------------------------------------------------

    await _client
        .from(
          _mindMapNodesTable,
        )
        .insert(
          payload,
        );
  }

  // ============================================================
  // DELETE DAY
  // ============================================================

  Future<
    void
  >
  deleteDay({
    required String userId,
    required String dayId,
  }) async {
    await _client
        .from(
          _daysTable,
        )
        .delete()
        .eq(
          'id',
          dayId,
        )
        .eq(
          'user_id',
          userId,
        );
  }

  // ============================================================
  // DELETE WEEK
  // ============================================================

  Future<
    void
  >
  deleteWeek({
    required String userId,
    required DateTime weekStart,
  }) async {
    final start = _dateOnly(
      weekStart,
    );

    final end = start.add(
      const Duration(
        days: 6,
      ),
    );

    await _client
        .from(
          _daysTable,
        )
        .delete()
        .eq(
          'user_id',
          userId,
        )
        .gte(
          'date',
          _dateString(
            start,
          ),
        )
        .lte(
          'date',
          _dateString(
            end,
          ),
        );
  }

  // ============================================================
  // EXISTS
  // ============================================================

  Future<
    bool
  >
  dayExists({
    required String userId,
    required DateTime date,
  }) async {
    final result = await _client
        .from(
          _daysTable,
        )
        .select(
          'id',
        )
        .eq(
          'user_id',
          userId,
        )
        .eq(
          'date',
          _dateString(
            date,
          ),
        )
        .maybeSingle();

    return result !=
        null;
  }

  // ============================================================
  // USER VALIDATION
  // ============================================================

  void ensureAuthenticatedUser(
    String userId,
  ) {
    final currentUser = _client.auth.currentUser;

    if (currentUser ==
        null) {
      throw StateError(
        'Usuário não autenticado no Supabase.',
      );
    }

    if (currentUser.id !=
        userId) {
      throw StateError(
        'O userId informado é diferente do usuário autenticado.',
      );
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  List<
    Map<
      String,
      dynamic
    >
  >
  _mapList(
    Object? value,
  ) {
    if (value
        is! List) {
      return [];
    }

    return value
        .whereType<
          Map
        >()
        .map(
          (
            item,
          ) =>
              Map<
                String,
                dynamic
              >.from(
                item,
              ),
        )
        .toList();
  }

  // ============================================================
  // JSON MAP
  // ============================================================

  Map<
    String,
    dynamic
  >
  _jsonMap(
    Object? value,
  ) {
    if (value
        is Map) {
      return Map<
        String,
        dynamic
      >.from(
        value,
      );
    }

    return <
      String,
      dynamic
    >{};
  }

  // ============================================================
  // UUID
  // ============================================================

  bool _isUuid(
    String value,
  ) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-'
      r'[0-9a-fA-F]{4}-'
      r'[1-5][0-9a-fA-F]{3}-'
      r'[89abAB][0-9a-fA-F]{3}-'
      r'[0-9a-fA-F]{12}$',
    ).hasMatch(
      value,
    );
  }

  String _generateUuidV4() {
    final random = Random.secure();

    final bytes =
        List<
          int
        >.generate(
          16,
          (
            _,
          ) => random.nextInt(
            256,
          ),
        );

    // UUID v4
    bytes[6] =
        (bytes[6] &
            0x0f) |
        0x40;

    // RFC 4122 variant
    bytes[8] =
        (bytes[8] &
            0x3f) |
        0x80;

    String hex(
      int value,
    ) {
      return value
          .toRadixString(
            16,
          )
          .padLeft(
            2,
            '0',
          );
    }

    final values = bytes
        .map(
          hex,
        )
        .toList();

    return '${values[0]}${values[1]}${values[2]}${values[3]}-'
        '${values[4]}${values[5]}-'
        '${values[6]}${values[7]}-'
        '${values[8]}${values[9]}-'
        '${values[10]}${values[11]}${values[12]}'
        '${values[13]}${values[14]}${values[15]}';
  }

  String _requiredString(
    Map<
      String,
      dynamic
    >
    map,
    String key,
  ) {
    final value = _nullableString(
      map[key],
    );

    if (value ==
            null ||
        value.isEmpty) {
      throw FormatException(
        'Campo obrigatório ausente: $key',
      );
    }

    return value;
  }

  String? _nullableString(
    Object? value,
  ) {
    if (value ==
        null) {
      return null;
    }

    final text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  bool _boolValue(
    Object? value,
  ) {
    if (value
        is bool) {
      return value;
    }

    if (value
        is num) {
      return value !=
          0;
    }

    final text = value?.toString().trim().toLowerCase();

    return text ==
            'true' ||
        text ==
            '1';
  }

  DateTime _parseDate(
    Object? value,
  ) {
    if (value
        is DateTime) {
      return _dateOnly(
        value,
      );
    }

    final parsed = DateTime.tryParse(
      value?.toString() ??
          '',
    );

    if (parsed ==
        null) {
      throw FormatException(
        'Data inválida retornada pelo Supabase: $value',
      );
    }

    return _dateOnly(
      parsed,
    );
  }

  DateTime _dateOnly(
    DateTime value,
  ) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  String _dateString(
    DateTime value,
  ) {
    final normalized = _dateOnly(
      value,
    );

    final year = normalized.year.toString().padLeft(
      4,
      '0',
    );

    final month = normalized.month.toString().padLeft(
      2,
      '0',
    );

    final day = normalized.day.toString().padLeft(
      2,
      '0',
    );

    return '$year-$month-$day';
  }
}
