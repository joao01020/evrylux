import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  Future<
    void
  >
  save(
    String key,
    String value,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      key,
      value,
    );
  }

  Future<
    String?
  >
  get(
    String key,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(
      key,
    );
  }

  Future<
    void
  >
  remove(
    String key,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      key,
    );
  }
}
