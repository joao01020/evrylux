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

    var obscureCurrentPassword = true;
    var obscureNewPassword = true;
    var obscureConfirmPassword = true;

    String? dialogError;

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
                        void closeDialog() {
                          Navigator.of(
                            dialogContext,
                          ).pop(
                            false,
                          );
                        }

                        void submit() {
                          final currentPassword = currentPasswordController.text;

                          final password = newPasswordController.text;

                          final confirm = confirmPasswordController.text;

                          if (currentPassword.isEmpty) {
                            setDialogState(
                              () {
                                dialogError = 'Digite sua senha atual para continuar.';
                              },
                            );

                            return;
                          }

                          if (password.length <
                              8) {
                            setDialogState(
                              () {
                                dialogError = 'A nova senha deve ter pelo menos 8 caracteres.';
                              },
                            );

                            return;
                          }

                          if (password ==
                              currentPassword) {
                            setDialogState(
                              () {
                                dialogError = 'A nova senha deve ser diferente da senha atual.';
                              },
                            );

                            return;
                          }

                          if (password !=
                              confirm) {
                            setDialogState(
                              () {
                                dialogError = 'As novas senhas não coincidem.';
                              },
                            );

                            return;
                          }

                          setDialogState(
                            () {
                              dialogError = null;
                            },
                          );

                          Navigator.of(
                            dialogContext,
                          ).pop(
                            true,
                          );
                        }

                        InputDecoration fieldDecoration({
                          required String label,
                          required String hint,
                          required IconData icon,
                          Widget? suffixIcon,
                        }) {
                          return InputDecoration(
                            labelText: label,
                            hintText: hint,
                            prefixIcon: Icon(
                              icon,
                              size: 20,
                              color: _ProfileSettingsPageState._muted,
                            ),
                            suffixIcon: suffixIcon,
                            filled: true,
                            fillColor: const Color(
                              0xFFF8FAF8,
                            ),
                            labelStyle: const TextStyle(
                              color: _ProfileSettingsPageState._muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                            hintStyle: TextStyle(
                              color: _ProfileSettingsPageState._muted.withValues(
                                alpha: 0.62,
                              ),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                              borderSide: const BorderSide(
                                color: _ProfileSettingsPageState._border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                              borderSide: const BorderSide(
                                color: _ProfileSettingsPageState._border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                14,
                              ),
                              borderSide: const BorderSide(
                                color: _ProfileSettingsPageState._primaryDark,
                                width: 1.4,
                              ),
                            ),
                          );
                        }

                        Widget visibilityButton({
                          required bool obscure,
                          required VoidCallback onPressed,
                          required String tooltip,
                        }) {
                          return IconButton(
                            tooltip: tooltip,
                            splashRadius: 18,
                            onPressed: onPressed,
                            icon: Icon(
                              obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 19,
                              color: _ProfileSettingsPageState._muted,
                            ),
                          );
                        }

                        return Dialog(
                          backgroundColor: Colors.transparent,
                          surfaceTintColor: Colors.transparent,
                          insetPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 24,
                          ),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 430,
                            ),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                22,
                                24,
                                20,
                              ),
                              decoration: BoxDecoration(
                                color: _ProfileSettingsPageState._surface,
                                borderRadius: BorderRadius.circular(
                                  24,
                                ),
                                border: Border.all(
                                  color: _ProfileSettingsPageState._border,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(
                                      0x18000000,
                                    ),
                                    blurRadius: 30,
                                    offset: Offset(
                                      0,
                                      14,
                                    ),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ==========================================
                                  // HEADER
                                  // ==========================================
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 46,
                                        height: 46,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFEAF7E7,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: _ProfileSettingsPageState._primaryDark.withValues(
                                              alpha: 0.14,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.lock_reset_rounded,
                                          color: _ProfileSettingsPageState._primaryDark,
                                          size: 23,
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 14,
                                      ),

                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Alterar senha',
                                              style: TextStyle(
                                                color: _ProfileSettingsPageState._text,
                                                fontSize: 21,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.2,
                                              ),
                                            ),

                                            SizedBox(
                                              height: 5,
                                            ),

                                            Text(
                                              'Atualize sua senha com segurança.',
                                              style: TextStyle(
                                                color: _ProfileSettingsPageState._muted,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      IconButton(
                                        tooltip: 'Fechar',
                                        onPressed: closeDialog,
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: _ProfileSettingsPageState._muted,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(
                                    height: 22,
                                  ),

                                  // ==========================================
                                  // SENHA ATUAL
                                  // ==========================================
                                  TextField(
                                    controller: currentPasswordController,
                                    autofocus: true,
                                    obscureText: obscureCurrentPassword,
                                    textInputAction: TextInputAction.next,
                                    onChanged:
                                        (
                                          _,
                                        ) {
                                          if (dialogError !=
                                              null) {
                                            setDialogState(
                                              () {
                                                dialogError = null;
                                              },
                                            );
                                          }
                                        },
                                    decoration: fieldDecoration(
                                      label: 'Senha atual',
                                      hint: 'Digite sua senha atual',
                                      icon: Icons.lock_outline_rounded,
                                      suffixIcon: visibilityButton(
                                        obscure: obscureCurrentPassword,
                                        tooltip: obscureCurrentPassword
                                            ? 'Mostrar senha atual'
                                            : 'Ocultar senha atual',
                                        onPressed: () {
                                          setDialogState(
                                            () {
                                              obscureCurrentPassword = !obscureCurrentPassword;
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 12,
                                  ),

                                  // ==========================================
                                  // NOVA SENHA
                                  // ==========================================
                                  TextField(
                                    controller: newPasswordController,
                                    obscureText: obscureNewPassword,
                                    textInputAction: TextInputAction.next,
                                    onChanged:
                                        (
                                          _,
                                        ) {
                                          if (dialogError !=
                                              null) {
                                            setDialogState(
                                              () {
                                                dialogError = null;
                                              },
                                            );
                                          }
                                        },
                                    decoration: fieldDecoration(
                                      label: 'Nova senha',
                                      hint: 'Mínimo de 8 caracteres',
                                      icon: Icons.password_rounded,
                                      suffixIcon: visibilityButton(
                                        obscure: obscureNewPassword,
                                        tooltip: obscureNewPassword
                                            ? 'Mostrar nova senha'
                                            : 'Ocultar nova senha',
                                        onPressed: () {
                                          setDialogState(
                                            () {
                                              obscureNewPassword = !obscureNewPassword;
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 12,
                                  ),

                                  // ==========================================
                                  // CONFIRMAR NOVA SENHA
                                  // ==========================================
                                  TextField(
                                    controller: confirmPasswordController,
                                    obscureText: obscureConfirmPassword,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted:
                                        (
                                          _,
                                        ) {
                                          submit();
                                        },
                                    onChanged:
                                        (
                                          _,
                                        ) {
                                          if (dialogError !=
                                              null) {
                                            setDialogState(
                                              () {
                                                dialogError = null;
                                              },
                                            );
                                          }
                                        },
                                    decoration: fieldDecoration(
                                      label: 'Confirmar nova senha',
                                      hint: 'Repita a nova senha',
                                      icon: Icons.verified_user_outlined,
                                      suffixIcon: visibilityButton(
                                        obscure: obscureConfirmPassword,
                                        tooltip: obscureConfirmPassword
                                            ? 'Mostrar confirmação'
                                            : 'Ocultar confirmação',
                                        onPressed: () {
                                          setDialogState(
                                            () {
                                              obscureConfirmPassword = !obscureConfirmPassword;
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  // ==========================================
                                  // ERRO LOCAL
                                  // ==========================================
                                  AnimatedSwitcher(
                                    duration: const Duration(
                                      milliseconds: 180,
                                    ),
                                    child:
                                        dialogError ==
                                            null
                                        ? const SizedBox(
                                            height: 18,
                                          )
                                        : Container(
                                            key: ValueKey(
                                              dialogError,
                                            ),
                                            margin: const EdgeInsets.only(
                                              top: 14,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFFFF1EF,
                                              ),
                                              borderRadius: BorderRadius.circular(
                                                12,
                                              ),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFFF0C0BA,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                  Icons.error_outline_rounded,
                                                  color: Color(
                                                    0xFFB5483E,
                                                  ),
                                                  size: 18,
                                                ),

                                                const SizedBox(
                                                  width: 8,
                                                ),

                                                Expanded(
                                                  child: Text(
                                                    dialogError!,
                                                    style: const TextStyle(
                                                      color: Color(
                                                        0xFF8D342D,
                                                      ),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  // ==========================================
                                  // AÇÕES
                                  // ==========================================
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: closeDialog,
                                        style: TextButton.styleFrom(
                                          foregroundColor: _ProfileSettingsPageState._primaryDark,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Cancelar',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 8,
                                      ),

                                      FilledButton.icon(
                                        onPressed: submit,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: _ProfileSettingsPageState._primaryDark,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 13,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        icon: const Icon(
                                          Icons.check_rounded,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Atualizar senha',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
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

  Future<
    bool
  >
  _confirmCurrentPassword({
    required String title,
    required String message,
  }) async {
    final passwordController = TextEditingController();

    var obscurePassword = true;
    var checking = false;
    String? errorMessage;

    final result =
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
                        Future<
                          void
                        >
                        verify() async {
                          if (checking) {
                            return;
                          }

                          final password = passwordController.text;
                          final email = _user?.email;

                          if (password.isEmpty) {
                            setDialogState(
                              () {
                                errorMessage = 'Digite sua senha atual.';
                              },
                            );
                            return;
                          }

                          if (email ==
                                  null ||
                              email.trim().isEmpty) {
                            setDialogState(
                              () {
                                errorMessage = 'Não foi possível identificar o e-mail da conta.';
                              },
                            );
                            return;
                          }

                          setDialogState(
                            () {
                              checking = true;
                              errorMessage = null;
                            },
                          );

                          try {
                            await Supabase.instance.client.auth.signInWithPassword(
                              email: email,
                              password: password,
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            Navigator.of(
                              dialogContext,
                            ).pop(
                              true,
                            );
                          } on AuthException {
                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(
                              () {
                                checking = false;
                                errorMessage = 'Senha incorreta.';
                              },
                            );
                          } catch (
                            error
                          ) {
                            debugPrint(
                              '[PROFILE SETTINGS] Erro validando senha atual: $error',
                            );

                            if (!dialogContext.mounted) {
                              return;
                            }

                            setDialogState(
                              () {
                                checking = false;
                                errorMessage = 'Não foi possível validar sua senha agora.';
                              },
                            );
                          }
                        }

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
                          title: Row(
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                color: _ProfileSettingsPageState._primaryDark,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  title,
                                ),
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
                                const SizedBox(
                                  height: 16,
                                ),
                                TextField(
                                  controller: passwordController,
                                  autofocus: true,
                                  obscureText: obscurePassword,
                                  onSubmitted:
                                      (
                                        _,
                                      ) {
                                        unawaited(
                                          verify(),
                                        );
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
                              onPressed: checking
                                  ? null
                                  : () {
                                      unawaited(
                                        verify(),
                                      );
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
                                checking
                                    ? 'Verificando...'
                                    : 'Confirmar',
                              ),
                            ),
                          ],
                        );
                      },
                );
              },
        );

    passwordController.dispose();

    return result ==
        true;
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

    if (user ==
        null) {
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
          _accountDevicesError = 'Não foi possível carregar os dispositivos agora.';
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

    final passwordConfirmed = await _confirmCurrentPassword(
      title: 'Confirmar exclusão dos dados',
      message: 'Digite sua senha atual para autorizar a exclusão permanente dos seus dados.',
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
          _brainDevices =
              const <
                BrainDeviceRecord
              >[];
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
    } catch (
      error
    ) {
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

    final passwordConfirmed = await _confirmCurrentPassword(
      title: 'Confirmar exclusão da conta',
      message: 'Digite sua senha atual para autorizar a exclusão permanente da sua conta.',
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
        (
          route,
        ) => route.isFirst,
      );
    } catch (
      error
    ) {
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
      showDialog<
        void
      >(
        context: context,
        barrierDismissible: false,
        builder:
            (
              dialogContext,
            ) {
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
