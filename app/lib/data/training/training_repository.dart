import '../../core/storage/storage_service.dart';

class TrainingRepository {
  Future<
    Map<
      String,
      dynamic
    >
  >
  load() async {
    return await StorageService.getTraining();
  }

  Future<
    void
  >
  save({
    required String day,
    required String training,
    required int minutes,
  }) async {
    await StorageService.saveTraining(
      day,
      training,
      minutes,
    );
  }
}
