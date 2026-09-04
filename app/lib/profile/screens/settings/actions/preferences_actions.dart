part of '../../profile_settings_page.dart';

extension _ProfileSettingsPreferencesActions
    on
        _ProfileSettingsPageState {
  // ============================================================
  // LOAD PREFERENCES
  // ============================================================
  //
  // Estratégia:
  //
  // 1. carrega primeiro a cópia local;
  // 2. atualiza a interface imediatamente;
  // 3. tenta sincronizar alterações pendentes em segundo plano;
  // 4. não bloqueia o uso da tela por indisponibilidade de rede.
  //
  // Nenhuma preferência sensível é registrada em logs.
  //
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
      // Não expõe conteúdo de preferências nem dados pessoais.
      debugPrint(
        '[PROFILE SETTINGS] '
        'Não foi possível carregar as preferências.',
      );
    }
  }

  // ============================================================
  // SYNC PENDING PREFERENCES
  // ============================================================

  Future<
    void
  >
  _syncPendingPreferences() async {
    try {
      await _profileRepository.syncPendingCurrentPreferences();
    } catch (
      error
    ) {
      // Falha de sincronização não impede o uso local.
      // Evitamos incluir payloads ou dados do usuário no log.
      debugPrint(
        '[PROFILE SETTINGS] '
        'Sincronização de preferências pendente.',
      );
    }
  }

  // ============================================================
  // SCHEDULE SAVE
  // ============================================================
  //
  // Debounce para evitar múltiplas gravações quando o usuário
  // altera opções rapidamente.
  //
  // ============================================================

  void _schedulePreferencesSave() {
    _preferencesSaveTimer?.cancel();

    _preferencesSaveTimer = Timer(
      const Duration(
        milliseconds: 350,
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
  //
  // Local-first:
  //
  // - o repository salva localmente primeiro;
  // - tenta sincronizar quando possível;
  // - se estiver offline, a preferência continua aplicada;
  // - nenhuma falha de rede descarta a escolha do usuário.
  //
  // ============================================================

  Future<
    void
  >
  _savePreferences() async {
    // ==========================================================
    // SAVE ALREADY RUNNING
    // ==========================================================
    //
    // Se uma gravação já está em andamento, reagendamos uma nova
    // tentativa para preservar a alteração mais recente.
    //
    // ==========================================================

    if (_savingPreferences) {
      _schedulePreferencesSave();

      return;
    }

    final preferences = ProfilePreferences(
      compactMode: _compactMode,
      reduceMotion: _reduceMotion,
      confirmBeforeDelete: _confirmBeforeDelete,
    );

    _updateProfileState(
      () {
        _savingPreferences = true;

        // Preferências são autosave.
        // Não mostramos uma mensagem a cada clique para evitar
        // ruído visual desnecessário.
        _message = null;
      },
    );

    try {
      final synced = await _profileRepository.saveCurrentPreferences(
        preferences,
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // SUCCESS
      // ========================================================
      //
      // Quando houve sincronização, não exibimos snackbar/texto
      // persistente porque a ação é automática.
      //
      // Quando ficou apenas local, informamos de maneira neutra
      // que a sincronização ocorrerá posteriormente.
      //
      // ========================================================

      _updateProfileState(
        () {
          if (synced) {
            _message = null;
          } else {
            _message =
                'Preferências salvas neste dispositivo. '
                'A sincronização ocorrerá quando houver conexão.';

            _messageIsError = false;
          }
        },
      );
    } catch (
      error
    ) {
      // ========================================================
      // ERROR
      // ========================================================
      //
      // Não exibimos exceções internas, payloads ou informações
      // potencialmente sensíveis na interface.
      //
      // ========================================================

      debugPrint(
        '[PROFILE SETTINGS] '
        'Não foi possível salvar as preferências.',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message =
              'Não foi possível salvar as preferências. '
              'Tente novamente.';

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
