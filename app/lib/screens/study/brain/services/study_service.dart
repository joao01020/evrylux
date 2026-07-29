import '../../data/repository/study_repository.dart';
import '../../models/study_model.dart';

class StudyService {
  final StudyRepository repository;

  StudyService({
    required this.repository,
  });

  Future<
    List<
      StudyModel
    >
  >
  getStudies() async {
    final data = await repository.load();

    return data.entries.map(
      (
        entry,
      ) {
        return StudyModel(
          day: entry.key,

          minutes: int.parse(
            entry.value.toString(),
          ),
        );
      },
    ).toList();
  }

  Future<
    void
  >
  saveStudy(
    String day,
    int minutes,
  ) async {
    await repository.save(
      day,
      minutes,
    );
  }
}
