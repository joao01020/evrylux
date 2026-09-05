part of '../../profile_settings_page.dart';

extension _ProfileSettingsBrainModeActions
    on
        _ProfileSettingsPageState {
  // ============================================================
  // MANAGED BRAIN MODE SWITCH
  // ============================================================
  //
  // A UI nova usa este fluxo em vez do switch simples legado.
  //
  // ============================================================

  Future<
    void
  >
  _setBrainCloudModeManaged(
    bool enabled,
  ) async {
    if (_switchingBrainMode ||
        enabled ==
            _brainCloudMode) {
      return;
    }

    if (enabled) {
      await _activateBrainCloudManaged();

      return;
    }

    await _confirmAndActivateBrainLocalManaged();
  }

  // ============================================================
  // CLOUD
  // ============================================================

  Future<
    void
  >
  _activateBrainCloudManaged() async {
    _updateProfileState(
      () {
        _switchingBrainMode = true;

        _brainModeProgressText = 'Preparando a proteção do seu Cérebro...';

        _message = null;

        _messageIsError = false;
      },
    );

    try {
      final result = await brainDataModeTransitionService.activateCloud(
        onProgress:
            (
              message,
            ) {
              _updateProfileState(
                () {
                  _brainModeProgressText = message;
                },
              );
            },
      );

      await _loadBrainSettings();

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _brainCloudMode = true;

          _messageIsError = false;

          if (result.isPending) {
            _message =
                'Cloud ativado. Seus dados continuam locais e este '
                'dispositivo precisa ser autorizado para concluir a '
                'proteção na nuvem.';
          } else if (result.deviceRegistrationError !=
              null) {
            _message =
                'Cloud ativado. Seus dados continuam seguros '
                'localmente e a proteção na nuvem será concluída '
                'quando houver conexão.';
          } else {
            _message =
                result.localObjectCount ==
                    0
                ? 'Cloud ativado. A proteção automática está pronta.'
                : 'Cloud ativado. ${result.localObjectCount} itens '
                      'locais foram preparados para proteção '
                      'automática na nuvem.';
          }
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[BRAIN DATA MODE] Erro ativando Cloud: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message = error.toString().replaceFirst(
            'Bad state: ',
            '',
          );

          _messageIsError = true;
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _switchingBrainMode = false;

            _brainModeProgressText = null;
          },
        );
      }
    }
  }

  // ============================================================
  // LOCAL CONFIRMATION
  // ============================================================

  Future<
    void
  >
  _confirmAndActivateBrainLocalManaged() async {
    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return AlertDialog(
                  backgroundColor: _ProfileSettingsPageState._surface,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      20,
                    ),
                    side: const BorderSide(
                      color: _ProfileSettingsPageState._border,
                    ),
                  ),
                  title: const Text(
                    'Usar somente este dispositivo?',
                  ),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 470,
                    ),
                    child: const Text(
                      'Novos dados deixarão de ser sincronizados com '
                      'a nuvem. Tudo continuará salvo neste '
                      'dispositivo.\n\n'
                      'A cópia que já foi protegida na nuvem não será '
                      'apagada automaticamente.',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        height: 1.45,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          false,
                        );
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },
                      child: const Text(
                        'Usar Local',
                      ),
                    ),
                  ],
                );
              },
        ) ??
        false;

    if (!confirmed ||
        !mounted) {
      return;
    }

    _updateProfileState(
      () {
        _switchingBrainMode = true;

        _brainModeProgressText = 'Ativando o modo Local...';

        _message = null;

        _messageIsError = false;
      },
    );

    try {
      await brainDataModeTransitionService.activateLocal(
        onProgress:
            (
              message,
            ) {
              _updateProfileState(
                () {
                  _brainModeProgressText = message;
                },
              );
            },
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _brainCloudMode = false;

          _brainDevices =
              const <
                BrainDeviceRecord
              >[];

          _message =
              'Modo Local ativado. Seus dados ficam somente neste '
              'dispositivo. A cópia já existente na nuvem não foi '
              'apagada.';

          _messageIsError = false;
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[BRAIN DATA MODE] Erro ativando Local: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message = 'Não foi possível ativar o modo Local.';

          _messageIsError = true;
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _switchingBrainMode = false;

            _brainModeProgressText = null;
          },
        );
      }
    }
  }
}
