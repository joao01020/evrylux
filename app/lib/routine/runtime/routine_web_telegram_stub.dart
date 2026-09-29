import 'package:flutter/foundation.dart';

class RoutineWebTelegramConnectionController extends ChangeNotifier {
  bool _isConnected = false;
  bool _loading = false;

  bool get isConnected => _isConnected;

  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      // O runtime Web não importa app_dependencies.dart.
      //
      // Enquanto não existir um datasource Telegram específico Web,
      // mantemos o recurso desconectado sem quebrar a Rotina.
      _isConnected = false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() {
    return load();
  }

  Future<void> disconnect() async {
    _isConnected = false;
    notifyListeners();
  }
}
