import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/database/daos/profile_cache_dao.dart';
import '../models/profile_preferences.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  ProfileRepository({
    SupabaseClient? client,
    ProfileCacheDao? cacheDao,
  })  : _client = client ?? Supabase.instance.client,
        _cacheDao = cacheDao ?? ProfileCacheDao();

  final SupabaseClient _client;
  final ProfileCacheDao _cacheDao;

  static const String _tableName = 'profiles';

  User? get currentUser {
    return _client.auth.currentUser;
  }

  String? get currentUserId {
    return currentUser?.id;
  }

  Future<UserProfile?> getCachedCurrentProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    return _cacheDao.loadProfile(user.id);
  }

  Future<String?> getCachedCurrentEmail() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    return _cacheDao.loadEmail(user.id);
  }

  Future<UserProfile?> getCurrentProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final cached = await _cacheDao.loadProfile(user.id);

    if (cached != null) {
      return cached;
    }

    return refreshCurrentProfile();
  }

  Future<UserProfile?> refreshCurrentProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final profile = await _fetchRemoteProfile(user.id);

    if (profile != null) {
      await _cacheDao.saveProfile(
        profile,
        email: user.email,
      );
    }

    return profile;
  }

  Future<UserProfile?> getProfile(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError('userId não pode estar vazio.');
    }

    final currentId = currentUserId;

    if (currentId == normalizedUserId) {
      final cached = await _cacheDao.loadProfile(normalizedUserId);

      if (cached != null) {
        return cached;
      }
    }

    final profile = await _fetchRemoteProfile(normalizedUserId);

    if (profile != null && currentId == normalizedUserId) {
      await _cacheDao.saveProfile(
        profile,
        email: currentUser?.email,
      );
    }

    return profile;
  }

  Future<UserProfile?> _fetchRemoteProfile(
    String userId,
  ) async {
    try {
      debugPrint('[PROFILE] Atualizando perfil remoto: $userId');

      final data = await _client
          .from(_tableName)
          .select('id, full_name, created_at, updated_at')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        debugPrint('[PROFILE] Perfil ainda não existe.');
        return null;
      }

      final profile = UserProfile.fromMap(data);

      debugPrint('[PROFILE] Perfil remoto atualizado: ${profile.fullName}');

      return profile;
    } on PostgrestException catch (error) {
      debugPrint('[PROFILE] Erro Supabase ao buscar perfil.');
      debugPrint('[PROFILE] Code: ${error.code}');
      debugPrint('[PROFILE] Message: ${error.message}');
      rethrow;
    } catch (error) {
      debugPrint('[PROFILE] Erro ao buscar perfil: $error');
      rethrow;
    }
  }

  Future<bool> profileExists(
    String userId,
  ) async {
    final profile = await getProfile(userId);
    return profile != null;
  }

  Future<bool> isProfileComplete(
    String userId,
  ) async {
    final profile = await getProfile(userId);
    return profile?.hasName == true;
  }

  Future<UserProfile> saveCurrentUserFullName(
    String fullName,
  ) async {
    final user = currentUser;

    if (user == null) {
      throw StateError('Não existe usuário autenticado.');
    }

    return saveFullName(
      userId: user.id,
      fullName: fullName,
    );
  }

  Future<UserProfile> saveFullName({
    required String userId,
    required String fullName,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedName = _normalizeName(fullName);

    if (normalizedUserId.isEmpty) {
      throw ArgumentError('userId não pode estar vazio.');
    }

    _validateName(normalizedName);
    _validateCurrentUser(normalizedUserId);

    try {
      final data = await _client
          .from(_tableName)
          .upsert(
            <String, dynamic>{
              'id': normalizedUserId,
              'full_name': normalizedName,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            onConflict: 'id',
          )
          .select('id, full_name, created_at, updated_at')
          .single();

      final profile = UserProfile.fromMap(data);

      await _cacheDao.saveProfile(
        profile,
        email: currentUser?.email,
      );

      return profile;
    } on PostgrestException catch (error) {
      debugPrint('[PROFILE] Erro Supabase ao salvar perfil.');
      debugPrint('[PROFILE] Code: ${error.code}');
      debugPrint('[PROFILE] Message: ${error.message}');
      debugPrint('[PROFILE] Details: ${error.details}');
      rethrow;
    }
  }

  Future<UserProfile> updateCurrentUserFullName(
    String fullName,
  ) async {
    final user = currentUser;

    if (user == null) {
      throw StateError('Não existe usuário autenticado.');
    }

    return updateFullName(
      userId: user.id,
      fullName: fullName,
    );
  }

  Future<UserProfile> updateFullName({
    required String userId,
    required String fullName,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedName = _normalizeName(fullName);

    if (normalizedUserId.isEmpty) {
      throw ArgumentError('userId não pode estar vazio.');
    }

    _validateName(normalizedName);
    _validateCurrentUser(normalizedUserId);

    try {
      final data = await _client
          .from(_tableName)
          .update(
            <String, dynamic>{
              'full_name': normalizedName,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          )
          .eq('id', normalizedUserId)
          .select('id, full_name, created_at, updated_at')
          .single();

      final profile = UserProfile.fromMap(data);

      await _cacheDao.saveProfile(
        profile,
        email: currentUser?.email,
      );

      return profile;
    } on PostgrestException catch (error) {
      debugPrint('[PROFILE] Erro Supabase ao atualizar perfil.');
      debugPrint('[PROFILE] Code: ${error.code}');
      debugPrint('[PROFILE] Message: ${error.message}');
      rethrow;
    }
  }

  Future<void> deleteProfile(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError('userId não pode estar vazio.');
    }

    _validateCurrentUser(normalizedUserId);

    try {
      await _client.from(_tableName).delete().eq('id', normalizedUserId);
      await _cacheDao.deleteUser(normalizedUserId);

      debugPrint('[PROFILE] Perfil removido.');
    } on PostgrestException catch (error) {
      debugPrint('[PROFILE] Erro Supabase ao excluir perfil.');
      debugPrint('[PROFILE] Code: ${error.code}');
      debugPrint('[PROFILE] Message: ${error.message}');
      rethrow;
    }
  }

  Future<ProfilePreferences> loadCurrentPreferences() async {
    final user = currentUser;

    if (user == null) {
      return ProfilePreferences.defaults();
    }

    final cached = await _cacheDao.loadPreferences(user.id);

    if (cached != null) {
      return cached;
    }

    final preferences = ProfilePreferences.fromMetadata(
      user.userMetadata ?? const <String, dynamic>{},
    );

    await _cacheDao.savePreferences(
      userId: user.id,
      preferences: preferences,
      dirty: false,
      email: user.email,
    );

    return preferences;
  }

  Future<bool> saveCurrentPreferences(
    ProfilePreferences preferences,
  ) async {
    final user = currentUser;

    if (user == null) {
      throw StateError('Não existe usuário autenticado.');
    }

    await _cacheDao.savePreferences(
      userId: user.id,
      preferences: preferences,
      dirty: true,
      email: user.email,
    );

    return _pushPreferences(
      userId: user.id,
      preferences: preferences,
    );
  }

  Future<bool> syncPendingCurrentPreferences() async {
    final user = currentUser;

    if (user == null) {
      return false;
    }

    final dirty = await _cacheDao.hasDirtyPreferences(user.id);

    if (!dirty) {
      return true;
    }

    final preferences = await _cacheDao.loadPreferences(user.id);

    if (preferences == null) {
      return true;
    }

    return _pushPreferences(
      userId: user.id,
      preferences: preferences,
    );
  }

  Future<bool> _pushPreferences({
    required String userId,
    required ProfilePreferences preferences,
  }) async {
    try {
      final currentMetadata = Map<String, dynamic>.from(
        currentUser?.userMetadata ?? const <String, dynamic>{},
      );

      final metadata = preferences.applyToMetadata(currentMetadata);

      await _client.auth.updateUser(
        UserAttributes(data: metadata),
      );

      await _cacheDao.markPreferencesSynced(userId);

      return true;
    } catch (error) {
      debugPrint(
        '[PROFILE] Preferências mantidas localmente; '
        'sincronização pendente: $error',
      );

      return false;
    }
  }

  void _validateCurrentUser(
    String userId,
  ) {
    final authenticatedUser = currentUser;

    if (authenticatedUser == null) {
      throw StateError('Não existe usuário autenticado.');
    }

    if (authenticatedUser.id != userId) {
      throw StateError('O usuário autenticado não corresponde ao perfil.');
    }
  }

  String _normalizeName(
    String value,
  ) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  void _validateName(
    String value,
  ) {
    if (value.isEmpty) {
      throw ArgumentError('Digite seu nome.');
    }

    if (value.length < 2) {
      throw ArgumentError('O nome precisa ter pelo menos 2 caracteres.');
    }

    if (value.length > 100) {
      throw ArgumentError('O nome pode ter no máximo 100 caracteres.');
    }
  }
}
