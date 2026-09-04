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

    final currentPasswordController = TextEditingController();

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
                                  controller: currentPasswordController,
                                  autofocus: true,
                                  obscureText: obscurePassword,
                                  decoration: const InputDecoration(
                                    labelText: 'Senha atual',
                                    prefixIcon: Icon(
                                      Icons.lock_outline_rounded,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                ),

                                const SizedBox(
                                  height: 12,
                                ),

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
                                final currentPassword =
                                    currentPasswordController.text;

                                final password = newPasswordController.text;

                                final confirm = confirmPasswordController.text;

                                if (currentPassword.isEmpty) {
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Digite sua senha atual.',
                                      ),
                                    ),
                                  );

                                  return;
                                }

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
      currentPasswordController.dispose();

      newPasswordController.dispose();

      confirmPasswordController.dispose();

      return;
    }

    final currentPassword = currentPasswordController.text;

    final password = newPasswordController.text;

    currentPasswordController.dispose();

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
          currentPassword: currentPassword,
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
  // CONFIRM CURRENT PASSWORD
  // ============================================================
  //
  // Confirma a identidade antes de ações destrutivas.
  // A senha não é armazenada pelo EVRYLUX.
  //
  // ============================================================

  Future<bool> _confirmCurrentPassword({
    required String title,
    required String message,
  }) async {
    final passwordController = TextEditingController();

    var obscurePassword = true;
    var checking = false;
    String? errorMessage;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> verify() async {
              if (checking) {
                return;
              }

              final password = passwordController.text;
              final email = _user?.email;

              if (password.isEmpty) {
                setDialogState(() {
                  errorMessage = 'Digite sua senha atual.';
                });
                return;
              }

              if (email == null || email.trim().isEmpty) {
                setDialogState(() {
                  errorMessage =
                      'Não foi possível identificar o e-mail da conta.';
                });
                return;
              }

              setDialogState(() {
                checking = true;
                errorMessage = null;
              });

              try {
                await Supabase.instance.client.auth.signInWithPassword(
                  email: email,
                  password: password,
                );

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.of(dialogContext).pop(true);
              } on AuthException {
                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  checking = false;
                  errorMessage = 'Senha incorreta.';
                });
              } catch (error) {
                debugPrint(
                  '[PROFILE SETTINGS] Erro validando senha atual: $error',
                );

                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  checking = false;
                  errorMessage =
                      'Não foi possível validar sua senha agora.';
                });
              }
            }

            return AlertDialog(
              backgroundColor: _ProfileSettingsPageState._surface,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(
                  color: _ProfileSettingsPageState._border,
                ),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.verified_user_outlined,
                    color: _ProfileSettingsPageState._primaryDark,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(title),
                  ),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 12,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      autofocus: true,
                      obscureText: obscurePassword,
                      onSubmitted: (_) {
                        unawaited(verify());
                      },
                      decoration: InputDecoration(
                        labelText: 'Senha atual',
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                        ),
                        suffixIcon: IconButton(
                          onPressed: checking
                              ? null
                              : () {
                                  setDialogState(() {
                                    obscurePassword = !obscurePassword;
                                  });
                                },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                        errorText: errorMessage,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: checking
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop(false);
                        },
                  child: const Text('Cancelar'),
                ),
                FilledButton.icon(
                  onPressed: checking
                      ? null
                      : () {
                          unawaited(verify());
                        },
                  icon: checking
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.verified_user_outlined,
                          size: 18,
                        ),
                  label: Text(
                    checking ? 'Verificando...' : 'Confirmar',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();

    return result == true;
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

  // DELETE DATA — REAL DELETION
  // ============================================================
  //
  // A exclusão remota é feita pela Edge Function account-cleanup.
  // Somente após sucesso remoto os dados locais são removidos.
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
                                  'associados ao EVRYLUX serão removidos permanentemente.',
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

    final passwordConfirmed =
        await _confirmCurrentPassword(
          title: 'Confirmar exclusão dos dados',
          message:
              'Digite sua senha atual para autorizar a exclusão permanente dos seus dados.',
        );

    if (!passwordConfirmed ||
        !mounted) {
      return;
    }

    _showDeletionProgressDialog(
      title: 'Excluindo dados...',
    );

    try {
      await accountDeletionService.deleteAllData(
        vaultId: _brainVaultId,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();

      _updateProfileState(
        () {
          _activeAccountDeviceCount = 0;
          _accountDevicesError = null;
          _brainVaultId = null;
          _brainKeyVersion = null;
          _brainMasterKeyAvailable = false;
          _brainDevices = const <BrainDeviceRecord>[];
          _currentBrainDeviceId = null;
          _message = 'Seus dados foram excluídos com sucesso.';
          _messageIsError = false;
        },
      );

      unawaited(
        _loadPreferences(),
      );

      unawaited(
        _loadAccountDevicesSummary(),
      );

      _loadBrainSettings();
    } catch (error) {
      debugPrint(
        '[PROFILE SETTINGS] Erro excluindo dados: $error',
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();

      _updateProfileState(
        () {
          _message = 'Não foi possível excluir seus dados.';
          _messageIsError = true;
        },
      );
    }
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
                                  'A conta e os dados associados serão removidos '
                                  'permanentemente.',
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

    final passwordConfirmed =
        await _confirmCurrentPassword(
          title: 'Confirmar exclusão da conta',
          message:
              'Digite sua senha atual para autorizar a exclusão permanente da sua conta.',
        );

    if (!passwordConfirmed ||
        !mounted) {
      return;
    }

    _showDeletionProgressDialog(
      title: 'Excluindo conta...',
    );

    try {
      await accountDeletionService.deleteAccount(
        vaultId: _brainVaultId,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();

      Navigator.of(
        context,
      ).popUntil(
        (route) => route.isFirst,
      );
    } catch (error) {
      debugPrint(
        '[PROFILE SETTINGS] Erro excluindo conta: $error',
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();

      _updateProfileState(
        () {
          _message = 'Não foi possível excluir sua conta.';
          _messageIsError = true;
        },
      );
    }
  }

  // ============================================================
  // DELETION PROGRESS
  // ============================================================

  void _showDeletionProgressDialog({
    required String title,
  }) {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
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
              content: SizedBox(
                width: 320,
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                      ),
                    ),
                    const SizedBox(
                      width: 14,
                    ),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: _ProfileSettingsPageState._text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
}
