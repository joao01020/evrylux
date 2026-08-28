import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class ProfileRepository {
  ProfileRepository({
    SupabaseClient? client,
  }) : _client =
           client ??
           Supabase.instance.client;

  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _client;

  static const String _tableName = 'profiles';

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _client.auth.currentUser;
  }

  String? get currentUserId {
    return currentUser?.id;
  }

  // ============================================================
  // GET CURRENT PROFILE
  // ============================================================

  Future<
    UserProfile?
  >
  getCurrentProfile() async {
    final user = currentUser;

    if (user ==
        null) {
      return null;
    }

    return getProfile(
      user.id,
    );
  }

  // ============================================================
  // GET PROFILE
  // ============================================================

  Future<
    UserProfile?
  >
  getProfile(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError(
        'userId não pode estar vazio.',
      );
    }

    try {
      debugPrint(
        '[PROFILE] Buscando perfil: $normalizedUserId',
      );

      final data = await _client
          .from(
            _tableName,
          )
          .select(
            'id, full_name, created_at, updated_at',
          )
          .eq(
            'id',
            normalizedUserId,
          )
          .maybeSingle();

      if (data ==
          null) {
        debugPrint(
          '[PROFILE] Perfil ainda não existe.',
        );

        return null;
      }

      final profile = UserProfile.fromMap(
        data,
      );

      debugPrint(
        '[PROFILE] Perfil encontrado: ${profile.fullName}',
      );

      return profile;
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[PROFILE] Erro Supabase ao buscar perfil.',
      );

      debugPrint(
        '[PROFILE] Code: ${error.code}',
      );

      debugPrint(
        '[PROFILE] Message: ${error.message}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE] Erro ao buscar perfil: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // PROFILE EXISTS
  // ============================================================

  Future<
    bool
  >
  profileExists(
    String userId,
  ) async {
    final profile = await getProfile(
      userId,
    );

    return profile !=
        null;
  }

  // ============================================================
  // PROFILE IS COMPLETE
  // ============================================================

  Future<
    bool
  >
  isProfileComplete(
    String userId,
  ) async {
    final profile = await getProfile(
      userId,
    );

    if (profile ==
        null) {
      return false;
    }

    return profile.hasName;
  }

  // ============================================================
  // SAVE CURRENT USER NAME
  // ============================================================

  Future<
    UserProfile
  >
  saveCurrentUserFullName(
    String fullName,
  ) async {
    final user = currentUser;

    if (user ==
        null) {
      throw StateError(
        'Não existe usuário autenticado.',
      );
    }

    return saveFullName(
      userId: user.id,
      fullName: fullName,
    );
  }

  // ============================================================
  // SAVE FULL NAME
  // ============================================================

  Future<
    UserProfile
  >
  saveFullName({
    required String userId,
    required String fullName,
  }) async {
    final normalizedUserId = userId.trim();

    final normalizedName = _normalizeName(
      fullName,
    );

    if (normalizedUserId.isEmpty) {
      throw ArgumentError(
        'userId não pode estar vazio.',
      );
    }

    _validateName(
      normalizedName,
    );

    // ==========================================================
    // SECURITY
    // ==========================================================
    //
    // Evita que a aplicação tente salvar um perfil para outro
    // usuário. O RLS do Supabase também deve proteger isso.
    //
    // ==========================================================

    final authenticatedUser = currentUser;

    if (authenticatedUser ==
        null) {
      throw StateError(
        'Não existe usuário autenticado.',
      );
    }

    if (authenticatedUser.id !=
        normalizedUserId) {
      throw StateError(
        'O usuário autenticado não corresponde ao perfil.',
      );
    }

    try {
      debugPrint(
        '[PROFILE] Salvando nome...',
      );

      debugPrint(
        '[PROFILE] User ID: $normalizedUserId',
      );

      debugPrint(
        '[PROFILE] Nome: $normalizedName',
      );

      final data = await _client
          .from(
            _tableName,
          )
          .upsert(
            {
              'id': normalizedUserId,
              'full_name': normalizedName,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
            onConflict: 'id',
          )
          .select(
            'id, full_name, created_at, updated_at',
          )
          .single();

      final profile = UserProfile.fromMap(
        data,
      );

      debugPrint(
        '[PROFILE] Perfil salvo com sucesso.',
      );

      return profile;
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[PROFILE] Erro Supabase ao salvar perfil.',
      );

      debugPrint(
        '[PROFILE] Code: ${error.code}',
      );

      debugPrint(
        '[PROFILE] Message: ${error.message}',
      );

      debugPrint(
        '[PROFILE] Details: ${error.details}',
      );

      rethrow;
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE] Erro ao salvar perfil: $error',
      );

      rethrow;
    }
  }

  // ============================================================
  // UPDATE CURRENT USER NAME
  // ============================================================

  Future<
    UserProfile
  >
  updateCurrentUserFullName(
    String fullName,
  ) async {
    final user = currentUser;

    if (user ==
        null) {
      throw StateError(
        'Não existe usuário autenticado.',
      );
    }

    return updateFullName(
      userId: user.id,
      fullName: fullName,
    );
  }

  // ============================================================
  // UPDATE FULL NAME
  // ============================================================

  Future<
    UserProfile
  >
  updateFullName({
    required String userId,
    required String fullName,
  }) async {
    final normalizedUserId = userId.trim();

    final normalizedName = _normalizeName(
      fullName,
    );

    if (normalizedUserId.isEmpty) {
      throw ArgumentError(
        'userId não pode estar vazio.',
      );
    }

    _validateName(
      normalizedName,
    );

    final authenticatedUser = currentUser;

    if (authenticatedUser ==
        null) {
      throw StateError(
        'Não existe usuário autenticado.',
      );
    }

    if (authenticatedUser.id !=
        normalizedUserId) {
      throw StateError(
        'O usuário autenticado não corresponde ao perfil.',
      );
    }

    try {
      final data = await _client
          .from(
            _tableName,
          )
          .update(
            {
              'full_name': normalizedName,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            },
          )
          .eq(
            'id',
            normalizedUserId,
          )
          .select(
            'id, full_name, created_at, updated_at',
          )
          .single();

      return UserProfile.fromMap(
        data,
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[PROFILE] Erro Supabase ao atualizar perfil.',
      );

      debugPrint(
        '[PROFILE] Code: ${error.code}',
      );

      debugPrint(
        '[PROFILE] Message: ${error.message}',
      );

      rethrow;
    }
  }

  // ============================================================
  // DELETE PROFILE
  // ============================================================

  Future<
    void
  >
  deleteProfile(
    String userId,
  ) async {
    final normalizedUserId = userId.trim();

    if (normalizedUserId.isEmpty) {
      throw ArgumentError(
        'userId não pode estar vazio.',
      );
    }

    final authenticatedUser = currentUser;

    if (authenticatedUser ==
        null) {
      throw StateError(
        'Não existe usuário autenticado.',
      );
    }

    if (authenticatedUser.id !=
        normalizedUserId) {
      throw StateError(
        'Não é possível excluir o perfil de outro usuário.',
      );
    }

    try {
      await _client
          .from(
            _tableName,
          )
          .delete()
          .eq(
            'id',
            normalizedUserId,
          );

      debugPrint(
        '[PROFILE] Perfil removido.',
      );
    } on PostgrestException catch (
      error
    ) {
      debugPrint(
        '[PROFILE] Erro Supabase ao excluir perfil.',
      );

      debugPrint(
        '[PROFILE] Code: ${error.code}',
      );

      debugPrint(
        '[PROFILE] Message: ${error.message}',
      );

      rethrow;
    }
  }

  // ============================================================
  // NORMALIZE NAME
  // ============================================================

  String _normalizeName(
    String value,
  ) {
    return value.trim().replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
    );
  }

  // ============================================================
  // VALIDATE NAME
  // ============================================================

  void _validateName(
    String value,
  ) {
    if (value.isEmpty) {
      throw ArgumentError(
        'Digite seu nome.',
      );
    }

    if (value.length <
        2) {
      throw ArgumentError(
        'O nome precisa ter pelo menos 2 caracteres.',
      );
    }

    if (value.length >
        100) {
      throw ArgumentError(
        'O nome pode ter no máximo 100 caracteres.',
      );
    }
  }
}
