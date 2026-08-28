import 'dart:convert';

typedef RoutineRecord =
    Map<
      String,
      dynamic
    >;

abstract interface class RoutineLocalDataSource {
  Future<
    List<
      RoutineRecord
    >
  >
  loadWeek({
    required String userId,
    required DateTime weekStart,
    required DateTime weekEnd,
  });

  Future<
    void
  >
  saveDay({
    required String userId,
    required RoutineRecord day,
  });

  Future<
    void
  >
  deleteDay({
    required String userId,
    required String dayId,
  });

  Future<
    void
  >
  clearUser(
    String userId,
  );
}

abstract interface class RoutineKeyValueStore {
  Future<
    String?
  >
  read(
    String key,
  );

  Future<
    void
  >
  write(
    String key,
    String value,
  );

  Future<
    void
  >
  remove(
    String key,
  );
}

class JsonRoutineLocalDataSource
    implements
        RoutineLocalDataSource {
  JsonRoutineLocalDataSource({
    required RoutineKeyValueStore store,
    this.storagePrefix = 'routine_days',
  }) : _store = store;

  final RoutineKeyValueStore _store;
  final String storagePrefix;

  @override
  Future<
    List<
      RoutineRecord
    >
  >
  loadWeek({
    required String userId,
    required DateTime weekStart,
    required DateTime weekEnd,
  }) async {
    final days = await _readAll(
      userId,
    );
    final start = _dateOnly(
      weekStart,
    );
    final end = _dateOnly(
      weekEnd,
    );

    return days
        .where(
          (
            day,
          ) {
            final date = _readDate(
              day['date'],
            );
            if (date ==
                null) {
              return false;
            }

            return !date.isBefore(
                  start,
                ) &&
                !date.isAfter(
                  end,
                );
          },
        )
        .map(
          _copyRecord,
        )
        .toList();
  }

  @override
  Future<
    void
  >
  saveDay({
    required String userId,
    required RoutineRecord day,
  }) async {
    final id = day['id']?.toString();
    final date = day['date']?.toString();

    if ((id ==
                null ||
            id.isEmpty) &&
        (date ==
                null ||
            date.isEmpty)) {
      throw ArgumentError(
        'O registro precisa conter id ou date.',
      );
    }

    final days = await _readAll(
      userId,
    );
    final index = days.indexWhere(
      (
        current,
      ) {
        if (id !=
                null &&
            id.isNotEmpty) {
          return current['id']?.toString() ==
              id;
        }

        return current['date']?.toString() ==
            date;
      },
    );

    final record = _copyRecord(
      day,
    )..['user_id'] = userId;

    if (index <
        0) {
      days.add(
        record,
      );
    } else {
      days[index] = record;
    }

    await _writeAll(
      userId,
      days,
    );
  }

  @override
  Future<
    void
  >
  deleteDay({
    required String userId,
    required String dayId,
  }) async {
    final days = await _readAll(
      userId,
    );
    days.removeWhere(
      (
        day,
      ) =>
          day['id']?.toString() ==
          dayId,
    );
    await _writeAll(
      userId,
      days,
    );
  }

  @override
  Future<
    void
  >
  clearUser(
    String userId,
  ) {
    return _store.remove(
      _storageKey(
        userId,
      ),
    );
  }

  Future<
    List<
      RoutineRecord
    >
  >
  _readAll(
    String userId,
  ) async {
    final raw = await _store.read(
      _storageKey(
        userId,
      ),
    );

    if (raw ==
            null ||
        raw.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(
      raw,
    );

    if (decoded
        is! List) {
      throw const FormatException(
        'Dados locais da rotina são inválidos.',
      );
    }

    return decoded
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

  Future<
    void
  >
  _writeAll(
    String userId,
    List<
      RoutineRecord
    >
    days,
  ) {
    return _store.write(
      _storageKey(
        userId,
      ),
      jsonEncode(
        days,
      ),
    );
  }

  String _storageKey(
    String userId,
  ) => '$storagePrefix:$userId';

  DateTime _dateOnly(
    DateTime value,
  ) {
    return DateTime(
      value.year,
      value.month,
      value.day,
    );
  }

  DateTime? _readDate(
    Object? value,
  ) {
    if (value
        is! String) {
      return null;
    }

    final parsed = DateTime.tryParse(
      value,
    );
    return parsed ==
            null
        ? null
        : _dateOnly(
            parsed,
          );
  }

  RoutineRecord _copyRecord(
    RoutineRecord source,
  ) {
    return Map<
      String,
      dynamic
    >.from(
      jsonDecode(
            jsonEncode(
              source,
            ),
          )
          as Map,
    );
  }
}
