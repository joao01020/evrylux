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
          'block_id',
          blockId,
        );

    return response
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
            'width': raw['width'],

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
          'block_id',
          blockId,
        );

    if (nodes.isEmpty) {
      return;
    }

    final payload =
        <
          Map<
            String,
            dynamic
          >
        >[];

    for (final node in nodes) {
      final value =
          Map<
            String,
            dynamic
          >.from(
            node,
          );

      value['block_id'] = blockId;

      // Campo antigo não deve ser enviado.
      value.remove(
        'mind_map_block_id',
      );

      payload.add(
        value,
      );
    }

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
