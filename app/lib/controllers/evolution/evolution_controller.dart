import 'package:flutter/foundation.dart';

import '../../models/evolution/evolution_model.dart';
import '../../services/evolution/evolution_service.dart';

class EvolutionController
    extends
        ChangeNotifier {
  final EvolutionService service;

  EvolutionController({
    required this.service,
  });

  EvolutionModel _evolution = const EvolutionModel(
    knowledge: 0,
    health: 0,
    finance: 0,
  );

  EvolutionModel get evolution => _evolution;

  Future<
    void
  >
  load() async {
    _evolution = await service.loadEvolution();

    notifyListeners();
  }
}
