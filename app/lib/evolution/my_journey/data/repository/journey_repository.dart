import 'dart:convert';

import '../../../../core/storage/local_storage.dart';

import '../../models/journey_model.dart';

class JourneyRepository {
  final LocalStorage storage;

  static const String key = "journey_history";

  JourneyRepository({
    required this.storage,
  });

  // ==========================================
  // SALVAR JORNADA
  // ==========================================

  Future<
    void
  >
  save(
    JourneyModel model,
  ) async {
    final data = await load();

    data[model.date] = model.notes;

    await storage.save(
      key,

      jsonEncode(
        data,
      ),
    );
  }

  // ==========================================
  // CARREGAR HISTÓRICO
  // ==========================================

  Future<
    Map<
      String,
      List<
        String
      >
    >
  >
  load() async {
    final saved = await storage.get(
      key,
    );

    if (saved ==
        null) {
      return {};
    }

    final dynamic json = jsonDecode(
      saved,
    );

    if (json
        is! Map) {
      return {};
    }

    final Map<
      String,
      List<
        String
      >
    >
    result = {};

    json.forEach(
      (
        key,
        value,
      ) {
        if (value
            is List) {
          result[key.toString()] =
              List<
                String
              >.from(
                value.map(
                  (
                    item,
                  ) => item.toString(),
                ),
              );
        }
      },
    );

    return result;
  }
}
