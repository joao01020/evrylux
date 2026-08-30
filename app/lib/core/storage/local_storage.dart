import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  // ============================================================
  // STRING
  // ============================================================

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

  // ============================================================
  // BOOL
  // ============================================================

  Future<
    void
  >
  saveBool(
    String key,
    bool value,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
      key,
      value,
    );
  }

  Future<
    bool?
  >
  getBool(
    String key,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(
      key,
    );
  }

  // ============================================================
  // REMOVE
  // ============================================================

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

  // ============================================================
  // EXISTS
  // ============================================================

  Future<
    bool
  >
  contains(
    String key,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.containsKey(
      key,
    );
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<
    void
  >
  clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}
