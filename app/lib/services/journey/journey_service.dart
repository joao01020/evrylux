import '../../data/journey/journey_repository.dart';

import '../../screens/evolution/my_journey/models/journey_model.dart';

class JourneyService {
  final JourneyRepository repository;

  JourneyService({
    required this.repository,
  });

  Future<
    void
  >
  saveNote(
    String date,

    List<
      String
    >
    notes,
  ) {
    return repository.save(
      JourneyModel(
        date: date,

        notes: notes,
      ),
    );
  }

  Future<
    Map<
      String,
      List<
        String
      >
    >
  >
  load() {
    return repository.load();
  }
}
