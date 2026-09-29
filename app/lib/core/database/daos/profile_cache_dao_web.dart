import 'package:shared_preferences/shared_preferences.dart';

import '../../../profile/models/profile_preferences.dart';
import '../../../profile/models/user_profile.dart';

/// Implementação Web do cache de perfil.
///
/// Mantém o mesmo contrato usado por [ProfileRepository], mas evita importar
/// AppDatabase/sqlite3/FFI no bundle do navegador. O cache é pequeno e fica em
/// SharedPreferences, que no Flutter Web usa armazenamento do browser.
class ProfileCacheDao {
  ProfileCacheDao();

  static const String _prefix = 'evrylux.profile_cache.v1';

  Future<void> initialize() async {
    await SharedPreferences.getInstance();
  }

  String _key(String userId, String field) => '$_prefix.$userId.$field';

  Future<UserProfile?> loadProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final fullName = prefs.getString(_key(userId, 'full_name'))?.trim() ?? '';

    if (fullName.isEmpty) {
      return null;
    }

    return UserProfile.fromMap(<String, dynamic>{
      'id': userId,
      'full_name': fullName,
      'created_at': prefs.getString(_key(userId, 'created_at')),
      'updated_at': prefs.getString(_key(userId, 'updated_at')),
    });
  }

  Future<String?> loadEmail(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key(userId, 'email'))?.trim();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }

  Future<void> saveProfile(UserProfile profile, {String? email}) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = profile.id;

    await prefs.setString(_key(userId, 'full_name'), profile.fullName.trim());

    final normalizedEmail = email?.trim() ?? '';
    if (normalizedEmail.isNotEmpty) {
      await prefs.setString(_key(userId, 'email'), normalizedEmail);
    }

    final createdAt = profile.createdAt?.toUtc().toIso8601String();
    if (createdAt != null) {
      await prefs.setString(_key(userId, 'created_at'), createdAt);
    }

    final updatedAt = profile.updatedAt?.toUtc().toIso8601String();
    if (updatedAt != null) {
      await prefs.setString(_key(userId, 'updated_at'), updatedAt);
    }
  }

  Future<ProfilePreferences?> loadPreferences(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final initialized =
        prefs.getBool(_key(userId, 'preferences_initialized')) ?? false;

    if (!initialized) {
      return null;
    }

    return ProfilePreferences(
      compactMode: prefs.getBool(_key(userId, 'compact_mode')) ?? false,
      reduceMotion: prefs.getBool(_key(userId, 'reduce_motion')) ?? false,
      confirmBeforeDelete:
          prefs.getBool(_key(userId, 'confirm_before_delete')) ?? true,
    );
  }

  Future<void> savePreferences({
    required String userId,
    required ProfilePreferences preferences,
    required bool dirty,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_key(userId, 'compact_mode'), preferences.compactMode);
    await prefs.setBool(
      _key(userId, 'reduce_motion'),
      preferences.reduceMotion,
    );
    await prefs.setBool(
      _key(userId, 'confirm_before_delete'),
      preferences.confirmBeforeDelete,
    );
    await prefs.setBool(_key(userId, 'preferences_initialized'), true);
    await prefs.setBool(_key(userId, 'preferences_dirty'), dirty);

    final normalizedEmail = email?.trim() ?? '';
    if (normalizedEmail.isNotEmpty) {
      await prefs.setString(_key(userId, 'email'), normalizedEmail);
    }
  }

  Future<bool> hasDirtyPreferences(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(userId, 'preferences_dirty')) ?? false;
  }

  Future<void> markPreferencesSynced(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(userId, 'preferences_dirty'), false);
  }

  Future<void> deleteUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = '$_prefix.$userId.';
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith(prefix))
        .toList();

    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
