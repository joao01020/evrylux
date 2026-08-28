import 'routine_local_datasource.dart';

abstract interface class RoutineRemoteDataSource {
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
    RoutineRecord
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
}

abstract interface class RoutineRemoteClient {
  Future<
    Object?
  >
  get(
    String path, {
    Map<
      String,
      String
    >?
    queryParameters,
  });

  Future<
    Object?
  >
  post(
    String path, {
    required Map<
      String,
      dynamic
    >
    body,
  });

  Future<
    Object?
  >
  put(
    String path, {
    required Map<
      String,
      dynamic
    >
    body,
  });

  Future<
    void
  >
  delete(
    String path,
  );
}

class ApiRoutineRemoteDataSource
    implements
        RoutineRemoteDataSource {
  ApiRoutineRemoteDataSource({
    required RoutineRemoteClient client,
    this.basePath = '/routine-days',
  }) : _client = client;

  final RoutineRemoteClient _client;
  final String basePath;

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
    final response = await _client.get(
      basePath,
      queryParameters: {
        'user_id': userId,
        'start_date': _formatDate(
          weekStart,
        ),
        'end_date': _formatDate(
          weekEnd,
        ),
      },
    );

    final records = _extractList(
      response,
    );
    return records
        .map(
          Map<
                String,
                dynamic
              >
              .from,
        )
        .toList();
  }

  @override
  Future<
    RoutineRecord
  >
  saveDay({
    required String userId,
    required RoutineRecord day,
  }) async {
    final body =
        Map<
            String,
            dynamic
          >.from(
            day,
          )
          ..['user_id'] = userId;
    final dayId = day['id']?.toString();

    final response =
        dayId ==
                null ||
            dayId.isEmpty
        ? await _client.post(
            basePath,
            body: body,
          )
        : await _client.put(
            '$basePath/$dayId',
            body: body,
          );

    return _extractRecord(
      response,
    );
  }

  @override
  Future<
    void
  >
  deleteDay({
    required String userId,
    required String dayId,
  }) {
    return _client.delete(
      '$basePath/$dayId?user_id=$userId',
    );
  }

  List<
    Map<
      String,
      dynamic
    >
  >
  _extractList(
    Object? response,
  ) {
    final value =
        response
            is Map
        ? response['data']
        : response;

    if (value
        is! List) {
      throw const FormatException(
        'Resposta da rotina deve conter uma lista.',
      );
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

  RoutineRecord _extractRecord(
    Object? response,
  ) {
    final value =
        response
                is Map &&
            response['data']
                is Map
        ? response['data']
        : response;

    if (value
        is! Map) {
      throw const FormatException(
        'Resposta da rotina deve conter um objeto.',
      );
    }

    return Map<
      String,
      dynamic
    >.from(
      value,
    );
  }

  String _formatDate(
    DateTime date,
  ) {
    final normalized = DateTime(
      date.year,
      date.month,
      date.day,
    );
    return normalized
        .toIso8601String()
        .split(
          'T',
        )
        .first;
  }
}
