import 'dart:convert';

import 'routine_local_datasource.dart';

class RoutineMemoryDataSource
    implements
        RoutineLocalDataSource {
  final Map<
    String,
    List<
      RoutineRecord
    >
  >
  _daysByUser = {};

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
    final start = _dateOnly(
      weekStart,
    );
    final end = _dateOnly(
      weekEnd,
    );
    final days =
        _daysByUser[userId] ??
        const [];

    return days
        .where(
          (
            day,
          ) {
            final rawDate = day['date'];
            final parsed =
                rawDate
                    is String
                ? DateTime.tryParse(
                    rawDate,
                  )
                : null;

            if (parsed ==
                null) {
              return false;
            }

            final date = _dateOnly(
              parsed,
            );
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

    final days = _daysByUser.putIfAbsent(
      userId,
      () => [],
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
  }

  @override
  Future<
    void
  >
  deleteDay({
    required String userId,
    required String dayId,
  }) async {
    _daysByUser[userId]?.removeWhere(
      (
        day,
      ) =>
          day['id']?.toString() ==
          dayId,
    );
  }

  @override
  Future<
    void
  >
  clearUser(
    String userId,
  ) async {
    _daysByUser.remove(
      userId,
    );
  }

  Future<
    void
  >
  seed({
    required String userId,
    required List<
      RoutineRecord
    >
    days,
  }) async {
    _daysByUser[userId] = days
        .map(
          _copyRecord,
        )
        .toList();
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
