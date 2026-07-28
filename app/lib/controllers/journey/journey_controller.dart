import 'package:flutter/foundation.dart';

import '../../screens/evolution/my_journey/services/journey_service.dart';

class JourneyController
    extends
        ChangeNotifier {
  final JourneyService service;

  JourneyController({
    required this.service,
  });

  Map<
    String,
    List<
      String
    >
  >
  history = {};

  DateTime? selectedDate;

  // ==========================================
  // CARREGAR HISTÓRICO
  // ==========================================

  Future<
    void
  >
  load() async {
    history = await service.load();

    notifyListeners();
  }

  // ==========================================
  // SALVAR ANOTAÇÃO
  // ==========================================

  Future<
    void
  >
  saveNote(
    String date,

    String note,
  ) async {
    if (note.trim().isEmpty) {
      return;
    }

    history.putIfAbsent(
      date,

      () => [],
    );

    history[date]!.add(
      note.trim(),
    );

    await service.saveNote(
      date,

      history[date]!,
    );

    notifyListeners();
  }

  // ==========================================
  // DELETAR ANOTAÇÃO
  // ==========================================

  Future<
    void
  >
  deleteNote(
    String date,

    String note,
  ) async {
    if (!history.containsKey(
      date,
    )) {
      return;
    }

    history[date]!.remove(
      note,
    );

    // Remove o dia caso fique vazio

    if (history[date]!.isEmpty) {
      history.remove(
        date,
      );
    }

    await service.saveNote(
      date,

      history[date] ??
          [],
    );

    notifyListeners();
  }

  // ==========================================
  // SELECIONAR DATA
  // ==========================================

  void selectDate(
    DateTime date,
  ) {
    selectedDate = date;

    notifyListeners();
  }

  // ==========================================
  // HISTÓRICO DO DIA
  // ==========================================

  List<
    String
  >
  getDayHistory(
    String date,
  ) {
    return history[date] ??
        [];
  }

  // ==========================================
  // VERIFICA SE TEM REGISTRO
  // ==========================================

  bool hasRecord(
    String date,
  ) {
    return history.containsKey(
      date,
    );
  }
}
