abstract interface class StudyRepositoryContract {
  Future<Map<String, dynamic>> load();

  Future<void> save(String day, int minutes);

  Future<void> saveMany(Map<String, dynamic> values);

  Future<int> getTotalMinutes();

  Future<int> getMinutes(String day);

  Future<bool> hasLocalData();
}
