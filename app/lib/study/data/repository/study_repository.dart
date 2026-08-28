import '../../../../core/storage/storage_service.dart';

class StudyRepository {
  Future<
    Map<
      String,
      dynamic
    >
  >
  load() {
    return StorageService.getStudy();
  }

  Future<
    void
  >
  save(
    String day,
    int minutes,
  ) {
    return StorageService.saveStudy(
      day,
      minutes,
    );
  }
}
