part of '../../profile_settings_page.dart';

extension _ProfileSettingsSecurityActions
    on
        _ProfileSettingsPageState {
  // ============================================================
  // CHANGE PASSWORD
  // ============================================================

  Future<
    void
  >
  _changePassword() async {
    if (_changingPassword) {
      return;
    }

    final newPasswordController = TextEditingController();

    final confirmPasswordController = TextEditingController();

    var obscurePassword = true;

    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          builder:
              (
                dialogContext,
              ) {
                return StatefulBuilder(
                  builder:
                      (
                        context,
                        setDialogState,
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
                          title: const Row(
                            children: [
                              Icon(
                                Icons.lock_reset_rounded,
                                color: _ProfileSettingsPageState._primaryDark,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Text(
                                'Alterar senha',
                              ),
                            ],
                          ),
                          content: SizedBox(
                            width: 360,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: newPasswordController,
                                  obscureText: obscurePassword,
                                  decoration: InputDecoration(
                                    labelText: 'Nova senha',
                                    prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setDialogState(
                                          () {
                                            obscurePassword = !obscurePassword;
                                          },
                                        );
                                      },
                                      icon: Icon(
                                        obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                    border: const OutlineInputBorder(),
                                  ),
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

                                TextField(
                                  controller: confirmPasswordController,
                                  obscureText: obscurePassword,
                                  decoration: const InputDecoration(
                                    labelText: 'Confirmar nova senha',
                                    prefixIcon: Icon(
                                      Icons.verified_user_outlined,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ],
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

                            FilledButton(
                              onPressed: () {
                                final password = newPasswordController.text;

                                final confirm = confirmPasswordController.text;

                                if (password.length <
                                    8) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'A senha deve ter pelo menos 8 caracteres.',
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                if (password !=
                                    confirm) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'As senhas não coincidem.',
                                      ),
                                    ),
                                  );

                                  return;
                                }

                                Navigator.of(
                                  dialogContext,
                                ).pop(
                                  true,
                                );
                              },
                              child: const Text(
                                'Atualizar senha',
                              ),
                            ),
                          ],
                        );
                      },
                );
              },
        );

    if (confirmed !=
        true) {
      newPasswordController.dispose();

      confirmPasswordController.dispose();

      return;
    }

    final password = newPasswordController.text;

    newPasswordController.dispose();

    confirmPasswordController.dispose();

    _updateProfileState(
      () {
        _changingPassword = true;
        _message = null;
      },
    );

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(
          password: password,
        ),
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message = 'Senha atualizada com sucesso.';
          _messageIsError = false;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] Erro alterando senha: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message = 'Não foi possível alterar a senha.';
          _messageIsError = true;
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _changingPassword = false;
          },
        );
      }
    }
  }

  // ============================================================
  // SESSIONS AND DEVICES — REAL DATA
  // ============================================================

  Future<
    void
  >
  _loadAccountDevicesSummary() async {
    if (_loadingAccountDevices) {
      return;
    }

    final user = _user;

    if (user == null) {
      _updateProfileState(
        () {
          _activeAccountDeviceCount = 0;
          _accountDevicesError = null;
        },
      );

      return;
    }

    _updateProfileState(
      () {
        _loadingAccountDevices = true;
        _accountDevicesError = null;
      },
    );

    try {
      final deviceId = await accountDeviceIdentityService.getOrCreateDeviceId();

      // Garante que a instalação atual esteja registrada mesmo se a
      // tela Segurança for aberta antes do primeiro heartbeat global.
      await accountDeviceRepository.registerDevice(
        deviceId: deviceId,
        deviceName: accountDeviceIdentityService.deviceName,
        platform: accountDeviceIdentityService.platformLabel,
        appVersion: AppInfo.version,
      );

      final devices = await accountDeviceRepository.listActiveDevices();

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _activeAccountDeviceCount = devices.length;
          _accountDevicesError = null;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] Erro carregando dispositivos da conta: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _accountDevicesError =
              'Não foi possível carregar os dispositivos agora.';
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _loadingAccountDevices = false;
          },
        );
      }
    }
  }

  Future<
    void
  >
  _showSessionsAndDevicesDialog() async {
    await showDialog<
      void
    >(
      context: context,
      builder:
          (
            dialogContext,
          ) {
            return _SessionsAndDevicesDialog(
              onDevicesChanged: () {
                unawaited(
                  _loadAccountDevicesSummary(),
                );
              },
            );
          },
    );

    if (!mounted) {
      return;
    }

    await _loadAccountDevicesSummary();
  }

  // DELETE DATA — FRONTEND CONFIRMATION
  // ============================================================
  //
  // Nesta etapa, a ação é SOMENTE de frontend.
  //
  // O backend seguro será conectado depois. Nenhuma exclusão real
  // é executada por estes métodos enquanto a camada de servidor
  // ainda não estiver implementada.
  //
  // ============================================================

  Future<
    void
  >
  _confirmDeleteAllData() async {
    final confirmationController = TextEditingController();

    var canConfirm = false;

    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          barrierDismissible: false,
          builder:
              (
                dialogContext,
              ) {
                return StatefulBuilder(
                  builder:
                      (
                        context,
                        setDialogState,
                      ) {
                        return AlertDialog(
                          backgroundColor: _ProfileSettingsPageState._surface,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              20,
                            ),
                            side: BorderSide(
                              color: _ProfileSettingsPageState._danger.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          title: const Row(
                            children: [
                              Icon(
                                Icons.delete_sweep_outlined,
                                color: _ProfileSettingsPageState._danger,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'Excluir todos os dados',
                                ),
                              ),
                            ],
                          ),
                          content: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 520,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sua conta continuará existindo, mas os dados '
                                  'associados ao EVRYLUX serão removidos quando '
                                  'esta função estiver conectada ao backend.',
                                  style: TextStyle(
                                    color: _ProfileSettingsPageState._text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    height: 1.45,
                                  ),
                                ),

                                const SizedBox(
                                  height: 14,
                                ),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(
                                    12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFF7E6,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFE6C56A,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        size: 18,
                                        color: Color(
                                          0xFF9A6700,
                                        ),
                                      ),

                                      SizedBox(
                                        width: 8,
                                      ),

                                      Expanded(
                                        child: Text(
                                          'A exclusão definitiva incluirá dados locais, '
                                          'dados sincronizados, cache, Vault do Cérebro, '
                                          'objetos E2EE e informações vinculadas à conta.',
                                          style: TextStyle(
                                            color: Color(
                                              0xFF6F5200,
                                            ),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(
                                  height: 16,
                                ),

                                const Text(
                                  'Para continuar, digite EXCLUIR DADOS.',
                                  style: TextStyle(
                                    color: _ProfileSettingsPageState._muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                TextField(
                                  controller: confirmationController,
                                  autofocus: true,
                                  onChanged:
                                      (
                                        value,
                                      ) {
                                        final valid =
                                            value.trim().toUpperCase() ==
                                            'EXCLUIR DADOS';

                                        if (valid !=
                                            canConfirm) {
                                          setDialogState(
                                            () {
                                              canConfirm = valid;
                                            },
                                          );
                                        }
                                      },
                                  decoration: const InputDecoration(
                                    hintText: 'EXCLUIR DADOS',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.keyboard_outlined,
                                    ),
                                  ),
                                ),
                              ],
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

                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _ProfileSettingsPageState._danger,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: canConfirm
                                  ? () {
                                      Navigator.of(
                                        dialogContext,
                                      ).pop(
                                        true,
                                      );
                                    }
                                  : null,
                              icon: const Icon(
                                Icons.delete_forever_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Excluir dados',
                              ),
                            ),
                          ],
                        );
                      },
                );
              },
        );

    confirmationController.dispose();

    if (confirmed !=
            true ||
        !mounted) {
      return;
    }

    _updateProfileState(
      () {
        _message =
            'Frontend de exclusão de dados concluído. '
            'A exclusão real será ativada quando conectarmos o backend seguro.';
        _messageIsError = false;
      },
    );
  }

  // ============================================================
  // DELETE ACCOUNT — FRONTEND CONFIRMATION
  // ============================================================

  Future<
    void
  >
  _confirmDeleteAccount() async {
    final confirmationController = TextEditingController();

    var canConfirm = false;

    final confirmed =
        await showDialog<
          bool
        >(
          context: context,
          barrierDismissible: false,
          builder:
              (
                dialogContext,
              ) {
                return StatefulBuilder(
                  builder:
                      (
                        context,
                        setDialogState,
                      ) {
                        return AlertDialog(
                          backgroundColor: _ProfileSettingsPageState._surface,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              20,
                            ),
                            side: BorderSide(
                              color: _ProfileSettingsPageState._danger.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          title: const Row(
                            children: [
                              Icon(
                                Icons.person_remove_alt_1_outlined,
                                color: _ProfileSettingsPageState._danger,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'Excluir conta permanentemente',
                                ),
                              ),
                            ],
                          ),
                          content: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 520,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Esta é a ação mais destrutiva da conta. '
                                  'Quando o backend estiver conectado, a conta '
                                  'e os dados associados serão removidos permanentemente.',
                                  style: TextStyle(
                                    color: _ProfileSettingsPageState._text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    height: 1.45,
                                  ),
                                ),

                                const SizedBox(
                                  height: 14,
                                ),

                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(
                                    12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFFECE9,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      12,
                                    ),
                                    border: Border.all(
                                      color: _ProfileSettingsPageState._danger.withValues(
                                        alpha: 0.30,
                                      ),
                                    ),
                                  ),
                                  child: const Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        size: 18,
                                        color: _ProfileSettingsPageState._danger,
                                      ),

                                      SizedBox(
                                        width: 8,
                                      ),

                                      Expanded(
                                        child: Text(
                                          'Isso incluirá a conta de acesso, dados do '
                                          'aplicativo, dados sincronizados, dispositivos '
                                          'do Cérebro e informações vinculadas ao usuário. '
                                          'Backups .evbrain salvos fora do aplicativo '
                                          'continuarão existindo onde você os armazenou.',
                                          style: TextStyle(
                                            color: _ProfileSettingsPageState._danger,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            height: 1.45,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(
                                  height: 16,
                                ),

                                const Text(
                                  'Para continuar, digite EXCLUIR CONTA.',
                                  style: TextStyle(
                                    color: _ProfileSettingsPageState._muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                TextField(
                                  controller: confirmationController,
                                  autofocus: true,
                                  onChanged:
                                      (
                                        value,
                                      ) {
                                        final valid =
                                            value.trim().toUpperCase() ==
                                            'EXCLUIR CONTA';

                                        if (valid !=
                                            canConfirm) {
                                          setDialogState(
                                            () {
                                              canConfirm = valid;
                                            },
                                          );
                                        }
                                      },
                                  decoration: const InputDecoration(
                                    hintText: 'EXCLUIR CONTA',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(
                                      Icons.keyboard_outlined,
                                    ),
                                  ),
                                ),
                              ],
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

                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: _ProfileSettingsPageState._danger,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: canConfirm
                                  ? () {
                                      Navigator.of(
                                        dialogContext,
                                      ).pop(
                                        true,
                                      );
                                    }
                                  : null,
                              icon: const Icon(
                                Icons.person_remove_alt_1_outlined,
                                size: 18,
                              ),
                              label: const Text(
                                'Excluir conta',
                              ),
                            ),
                          ],
                        );
                      },
                );
              },
        );

    confirmationController.dispose();

    if (confirmed !=
            true ||
        !mounted) {
      return;
    }

    _updateProfileState(
      () {
        _message =
            'Frontend de exclusão da conta concluído. '
            'A exclusão real será ativada quando conectarmos o backend seguro.';
        _messageIsError = false;
      },
    );
  }

  // ============================================================
}
