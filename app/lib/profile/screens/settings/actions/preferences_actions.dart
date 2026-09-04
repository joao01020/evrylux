part of '../../profile_settings_page.dart';

extension _ProfileSettingsPreferencesActions
    on _ProfileSettingsPageState {
  // ============================================================
  // LOAD PREFERENCES
  // ============================================================

  Future<
    void
  >
  _loadPreferences() async {
    try {
      final preferences = await _profileRepository.loadCurrentPreferences();

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _compactMode = preferences.compactMode;
          _reduceMotion = preferences.reduceMotion;
          _confirmBeforeDelete = preferences.confirmBeforeDelete;
        },
      );

      unawaited(
        _syncPendingPreferences(),
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] Erro lendo preferências locais: $error',
      );
    }
  }

  Future<
    void
  >
  _syncPendingPreferences() async {
    try {
      await _profileRepository.syncPendingCurrentPreferences();
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Não foi possível sincronizar preferências pendentes: $error',
      );
    }
  }

  void _schedulePreferencesSave() {
    _preferencesSaveTimer?.cancel();

    _preferencesSaveTimer = Timer(
      const Duration(
        milliseconds: 250,
      ),
      () {
        unawaited(
          _savePreferences(),
        );
      },
    );
  }

  // ============================================================
  // SAVE PREFERENCES
  // ============================================================

  Future<
    void
  >
  _savePreferences() async {
    if (_savingPreferences) {
      return;
    }

    _updateProfileState(
      () {
        _savingPreferences = true;
        _message = null;
      },
    );

    try {
      final preferences = ProfilePreferences(
        compactMode: _compactMode,
        reduceMotion: _reduceMotion,
        confirmBeforeDelete: _confirmBeforeDelete,
      );

      final synced = await _profileRepository.saveCurrentPreferences(
        preferences,
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message = synced
              ? 'Preferências salvas e sincronizadas.'
              : 'Preferências salvas neste dispositivo. '
                    'A sincronização será tentada quando houver conexão.';
          _messageIsError = false;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] Erro salvando preferências: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message = 'Não foi possível salvar as preferências.';
          _messageIsError = true;
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _savingPreferences = false;
          },
        );
      }
    }
  }

}
