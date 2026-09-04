part of '../../profile_settings_page.dart';

extension _ProfileSettingsBrainActions
    on _ProfileSettingsPageState {
  // ============================================================
  // LOAD BRAIN SETTINGS
  // ============================================================

  Future<
    void
  >
  _loadBrainSettings() async {
    if (_loadingBrainSettings) {
      return;
    }

    _updateProfileState(
      () {
        _loadingBrainSettings = true;
      },
    );

    try {
      if (!brainDataModeController.isInitialized) {
        await brainDataModeController.initialize();
      }

      final manifest = await brainVaultService.openVault();

      final hasMasterKey = await brainKeyService.hasKeyBundle(
        vaultId: manifest.vaultId,
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _brainCloudMode = brainDataModeController.isCloudMode;

          _brainVaultId = manifest.vaultId;

          _brainKeyVersion = manifest.keyVersion;

          _brainMasterKeyAvailable = hasMasterKey;
        },
      );

      await _loadBrainDevices();
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro carregando configurações do Cérebro: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message = 'Não foi possível carregar todas as configurações do Cérebro.';
          _messageIsError = true;
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _loadingBrainSettings = false;
          },
        );
      }
    }
  }

  // ============================================================
  // SWITCH BRAIN DATA MODE
  // ============================================================

  Future<
    void
  >
  _setBrainCloudMode(
    bool cloud,
  ) async {
    if (_switchingBrainMode) {
      return;
    }

    _updateProfileState(
      () {
        _switchingBrainMode = true;
        _message = null;
      },
    );

    try {
      if (cloud) {
        if (_user ==
            null) {
          throw StateError(
            'Entre na sua conta antes de ativar o modo Cloud.',
          );
        }

        await brainDataModeController.useCloudMode();
      } else {
        await brainDataModeController.useLocalMode();
      }

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _brainCloudMode = brainDataModeController.isCloudMode;

          _message = cloud
              ? 'Modo Cloud ativado. O Cérebro continua local-first e sincroniza somente objetos criptografados.'
              : 'Modo Local ativado. O Cérebro não realizará sincronização em nuvem.';

          _messageIsError = false;
        },
      );

      if (cloud) {
        syncService.requestSync();
      }
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro alterando modo do Cérebro: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message = 'Não foi possível alterar o modo de dados do Cérebro.';
          _messageIsError = true;
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _switchingBrainMode = false;
          },
        );
      }
    }
  }

  // ============================================================
  // BRAIN BACKUP — FILE PICKER / IMPORT / EXPORT
  // ============================================================

  String _brainBackupDefaultFileName() {
    final now = DateTime.now();

    String twoDigits(
      int value,
    ) {
      return value.toString().padLeft(
        2,
        '0',
      );
    }

    final date = '${now.year}${twoDigits(now.month)}${twoDigits(now.day)}';

    final time = '${twoDigits(now.hour)}${twoDigits(now.minute)}${twoDigits(now.second)}';

    return 'EVRYLUX_Brain_$date-$time.evbrain';
  }

  Future<
    void
  >
  _exportBrainBackup() async {
    if (_exportingBrainBackup ||
        _importingBrainBackup) {
      return;
    }

    _updateProfileState(
      () {
        _exportingBrainBackup = true;
        _message = null;
      },
    );

    Directory? temporaryDirectory;

    try {
      final fileName = _brainBackupDefaultFileName();

      // ========================================================
      // FILE PICKER v12
      // ========================================================
      //
      // No file_picker 12, saveFile() recebe os bytes que serão
      // efetivamente gravados e retorna um Uri?.
      //
      // O BrainBackupService continua responsável por gerar o
      // arquivo .evbrain. Depois entregamos os bytes prontos ao
      // seletor nativo apenas para o usuário escolher o destino.
      //
      // ========================================================

      temporaryDirectory = await Directory.systemTemp.createTemp(
        'evrylux_brain_backup_',
      );

      final temporaryFile = File(
        '${temporaryDirectory.path}/$fileName',
      );

      final exported = await brainBackupService.exportToFile(
        temporaryFile,
      );

      final backupBytes = await exported.readAsBytes();

      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Salvar backup do Cérebro',
        fileName: fileName,
        bytes: backupBytes,
      );

      if (savedUri ==
          null) {
        return;
      }

      final savedLocation =
          savedUri.scheme ==
              'file'
          ? savedUri.toFilePath()
          : savedUri.toString();

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message =
              'Backup .evbrain exportado com sucesso para:\n'
              '$savedLocation';
          _messageIsError = false;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro exportando backup .evbrain: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message =
              'Não foi possível exportar o backup .evbrain. '
              '$error';
          _messageIsError = true;
        },
      );
    } finally {
      final directory = temporaryDirectory;

      if (directory !=
          null) {
        try {
          if (await directory.exists()) {
            await directory.delete(
              recursive: true,
            );
          }
        } catch (
          cleanupError
        ) {
          debugPrint(
            '[PROFILE SETTINGS] '
            'Não foi possível remover o backup temporário: '
            '$cleanupError',
          );
        }
      }

      if (mounted) {
        _updateProfileState(
          () {
            _exportingBrainBackup = false;
          },
        );
      }
    }
  }

  Future<
    bool
  >
  _confirmBrainBackupImport({
    required String fileName,
  }) async {
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
                  title: const Row(
                    children: [
                      Icon(
                        Icons.restore_rounded,
                        color: _ProfileSettingsPageState._primaryDark,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          'Importar backup .evbrain',
                        ),
                      ),
                    ],
                  ),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 500,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ProfileSettingsPageState._text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        const Text(
                          'O EVRYLUX validará o arquivo, o Vault ID, a versão '
                          'da Master Key e cada objeto antes de restaurar.',
                          style: TextStyle(
                            color: _ProfileSettingsPageState._muted,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        const Text(
                          'Objetos locais com versão mais nova não serão '
                          'substituídos pelo backup.',
                          style: TextStyle(
                            color: _ProfileSettingsPageState._primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1.45,
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
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },
                      icon: const Icon(
                        Icons.file_open_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'Importar',
                      ),
                    ),
                  ],
                );
              },
        );

    return confirmed ==
        true;
  }

  Future<
    void
  >
  _importBrainBackup() async {
    if (_importingBrainBackup ||
        _exportingBrainBackup) {
      return;
    }

    try {
      // ========================================================
      // FILE PICKER v12
      // ========================================================
      //
      // pickFile() é a API indicada para seleção única e retorna
      // diretamente PlatformFile?.
      //
      // ========================================================

      final platformFile = await FilePicker.pickFile(
        dialogTitle: 'Selecionar backup do Cérebro',
        type: FileType.custom,
        allowedExtensions:
            const <
              String
            >[
              'evbrain',
            ],
      );

      if (platformFile ==
          null) {
        return;
      }

      final path = platformFile.path?.trim();

      if (path ==
              null ||
          path.isEmpty) {
        throw StateError(
          'O seletor não forneceu um caminho local para o arquivo.',
        );
      }

      final confirmed = await _confirmBrainBackupImport(
        fileName: platformFile.name,
      );

      if (!confirmed ||
          !mounted) {
        return;
      }

      _updateProfileState(
        () {
          _importingBrainBackup = true;
          _message = null;
        },
      );

      final result = await brainBackupService.importFromFile(
        File(
          path,
        ),
      );

      // O backup altera diretamente o Vault físico.
      // Recarregamos o controller global para a UI refletir
      // imediatamente os dados restaurados.
      await brainController.loadNotes();

      await _loadBrainSettings();

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          final skipped = result.skippedNewerLocal;

          _message =
              'Backup restaurado com sucesso. '
              '${result.restored} de ${result.totalInBackup} objetos '
              'foram restaurados.'
              '${skipped > 0 ? ' $skipped objeto(s) local(is) mais novo(s) foram preservado(s).' : ''}';
          _messageIsError = false;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro importando backup .evbrain: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message =
              'Não foi possível importar o backup .evbrain. '
              '$error';
          _messageIsError = true;
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _importingBrainBackup = false;
          },
        );
      }
    }
  }

  // ============================================================
  // LOAD BRAIN DEVICES
  // ============================================================
  //
  // A tela não conversa diretamente com RPCs do Supabase.
  //
  // ProfileSettingsPage
  //        ↓
  // BrainDeviceAuthorizationService
  //        ↓
  // BrainDeviceRemotePort
  //        ↓
  // BrainDeviceSupabaseService
  //
  // ============================================================

  Future<
    void
  >
  _loadBrainDevices() async {
    if (_loadingBrainDevices) {
      return;
    }

    _updateProfileState(
      () {
        _loadingBrainDevices = true;
        _brainDevicesError = null;
      },
    );

    try {
      final manifest = await brainVaultService.openVault();

      final local = await brainDeviceIdentityService.loadLocalSecrets();

      final devices = await brainDeviceAuthorizationService.listDevices(
        vaultId: manifest.vaultId,
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _currentBrainDeviceId = local?.deviceId;

          _brainDevices =
              List<
                BrainDeviceRecord
              >.unmodifiable(
                devices,
              );

          _brainDevicesError = null;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro carregando dispositivos do Cérebro: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _brainDevicesError = 'Não foi possível carregar os dispositivos do Cérebro.';
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _loadingBrainDevices = false;
          },
        );
      }
    }
  }

  // ============================================================
  // CONFIRM REVOKE DEVICE
  // ============================================================

  Future<
    void
  >
  _confirmRevokeBrainDevice(
    BrainDeviceRecord device,
  ) async {
    if (_revokingBrainDeviceId !=
        null) {
      return;
    }

    final isCurrentDevice =
        device.deviceId ==
        _currentBrainDeviceId;

    if (isCurrentDevice) {
      _updateProfileState(
        () {
          _message = 'Este dispositivo não pode ser revogado por esta tela.';
          _messageIsError = true;
        },
      );

      return;
    }

    if (device.isRevoked) {
      return;
    }

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
                  title: const Row(
                    children: [
                      Icon(
                        Icons.phonelink_erase_rounded,
                        color: _ProfileSettingsPageState._danger,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          'Revogar acesso',
                        ),
                      ),
                    ],
                  ),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 440,
                    ),
                    child: Text(
                      'Revogar o acesso de "${device.deviceName}"?\n\n'
                      'Este dispositivo não poderá mais sincronizar '
                      'novos dados do Cérebro pela nuvem.\n\n'
                      'Dados e chaves que já existam localmente nesse '
                      'computador não podem ser apagados remotamente.',
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        height: 1.5,
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
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _ProfileSettingsPageState._danger,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.of(
                          dialogContext,
                        ).pop(
                          true,
                        );
                      },
                      icon: const Icon(
                        Icons.block_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Revogar acesso',
                      ),
                    ),
                  ],
                );
              },
        );

    if (confirmed !=
        true) {
      return;
    }

    await _revokeBrainDevice(
      device,
    );
  }

  // ============================================================
  // REVOKE DEVICE
  // ============================================================

  Future<
    void
  >
  _revokeBrainDevice(
    BrainDeviceRecord device,
  ) async {
    if (_revokingBrainDeviceId !=
        null) {
      return;
    }

    _updateProfileState(
      () {
        _revokingBrainDeviceId = device.deviceId;

        _message = null;
      },
    );

    try {
      final manifest = await brainVaultService.openVault();

      await brainDeviceAuthorizationService.revokeDevice(
        vaultId: manifest.vaultId,
        targetDeviceId: device.deviceId,
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message = 'Acesso de "${device.deviceName}" revogado com sucesso.';
          _messageIsError = false;
        },
      );

      await _loadBrainDevices();
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro revogando dispositivo: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message =
              'Não foi possível revogar o acesso de '
              '"${device.deviceName}".';
          _messageIsError = true;
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _revokingBrainDeviceId = null;
          },
        );
      }
    }
  }

  // ============================================================
  // APPROVE PENDING DEVICE
  // ============================================================
  //
  // A aprovação exige que o usuário digite o fingerprint exibido
  // fisicamente no novo dispositivo.
  //
  // Não basta clicar em "Aprovar": a comparação é feita novamente
  // pelo BrainDeviceAuthorizationService antes do wrapping da
  // Master Key.
  //
  // ============================================================

  Future<
    void
  >
  _confirmApproveBrainDevice(
    BrainDeviceRecord device,
  ) async {
    if (_approvingBrainDeviceId !=
            null ||
        !device.isPending) {
      return;
    }

    final fingerprintController = TextEditingController();

    final confirmedFingerprint =
        await showDialog<
          String
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
                  title: const Row(
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: _ProfileSettingsPageState._primaryDark,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          'Aprovar dispositivo',
                        ),
                      ),
                    ],
                  ),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 480,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.deviceName,
                          style: const TextStyle(
                            color: _ProfileSettingsPageState._text,
                            fontWeight: FontWeight.w900,
                          ),
                        ),

                        const SizedBox(
                          height: 8,
                        ),

                        const Text(
                          'No NOVO dispositivo, abra Recovery Device e compare '
                          'o fingerprint mostrado lá. Digite-o abaixo exatamente '
                          'como aparece antes de aprovar.',
                          style: TextStyle(
                            color: _ProfileSettingsPageState._muted,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        TextField(
                          controller: fingerprintController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Fingerprint do novo dispositivo',
                            hintText: 'AA:BB:CC:DD:EE:FF:...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.fingerprint_rounded,
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
                        ).pop();
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    FilledButton.icon(
                      onPressed: () {
                        final value = fingerprintController.text.trim();

                        if (value.isEmpty) {
                          return;
                        }

                        Navigator.of(
                          dialogContext,
                        ).pop(
                          value,
                        );
                      },
                      icon: const Icon(
                        Icons.check_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Aprovar',
                      ),
                    ),
                  ],
                );
              },
        );

    fingerprintController.dispose();

    if (confirmedFingerprint ==
            null ||
        confirmedFingerprint.trim().isEmpty) {
      return;
    }

    await _approveBrainDevice(
      device: device,
      expectedFingerprint: confirmedFingerprint,
    );
  }

  Future<
    void
  >
  _approveBrainDevice({
    required BrainDeviceRecord device,
    required String expectedFingerprint,
  }) async {
    if (_approvingBrainDeviceId !=
        null) {
      return;
    }

    _updateProfileState(
      () {
        _approvingBrainDeviceId = device.deviceId;
        _message = null;
      },
    );

    try {
      final manifest = await brainVaultService.openVault();

      await brainDeviceAuthorizationService.approveDevice(
        vaultId: manifest.vaultId,
        targetDeviceId: device.deviceId,
        expectedTargetFingerprint: expectedFingerprint,
        keyVersion: manifest.keyVersion,
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message =
              'Dispositivo "${device.deviceName}" aprovado. '
              'O novo computador já pode concluir a recuperação.';
          _messageIsError = false;
        },
      );

      await _loadBrainDevices();
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro aprovando dispositivo: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message =
              'Não foi possível aprovar o dispositivo. '
              'Confira o fingerprint informado. ($error)';
          _messageIsError = true;
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _approvingBrainDeviceId = null;
          },
        );
      }
    }
  }

  // ============================================================
  // REQUEST BRAIN RECOVERY
  // ============================================================

  Future<
    void
  >
  _requestBrainRecovery() async {
    if (_requestingBrainRecovery ||
        _completingBrainRecovery) {
      return;
    }

    final vaultController = TextEditingController(
      text:
          _brainVaultId ??
          '',
    );

    final vaultId =
        await showDialog<
          String
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
                  title: const Row(
                    children: [
                      Icon(
                        Icons.add_to_home_screen_rounded,
                        color: _ProfileSettingsPageState._primaryDark,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          'Solicitar recuperação',
                        ),
                      ),
                    ],
                  ),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 480,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No dispositivo que ainda possui acesso ao Cérebro, '
                          'copie o Vault ID exibido em Perfil > Cérebro > Vault '
                          'e informe-o aqui.',
                          style: TextStyle(
                            color: _ProfileSettingsPageState._muted,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        TextField(
                          controller: vaultController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Vault ID',
                            hintText: 'vault_...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.inventory_2_outlined,
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
                        ).pop();
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    FilledButton.icon(
                      onPressed: () {
                        final value = vaultController.text.trim();

                        if (value.isEmpty) {
                          return;
                        }

                        Navigator.of(
                          dialogContext,
                        ).pop(
                          value,
                        );
                      },
                      icon: const Icon(
                        Icons.send_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Solicitar',
                      ),
                    ),
                  ],
                );
              },
        );

    vaultController.dispose();

    if (vaultId ==
            null ||
        vaultId.trim().isEmpty) {
      return;
    }

    _updateProfileState(
      () {
        _requestingBrainRecovery = true;
        _message = null;
      },
    );

    try {
      final record = await brainRecoveryDeviceService.requestRecovery(
        vaultId: vaultId,
        deviceName: brainDeviceName(),
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _currentBrainDeviceId = record.deviceId;
          _message =
              'Solicitação criada. No dispositivo autorizado, procure '
              '"${record.deviceName}" e aprove somente depois de conferir '
              'este fingerprint: ${record.keyFingerprint}';
          _messageIsError = false;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro solicitando Recovery Device: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message = 'Não foi possível solicitar a recuperação. $error';
          _messageIsError = true;
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _requestingBrainRecovery = false;
          },
        );
      }
    }
  }

  // ============================================================
  // COMPLETE BRAIN RECOVERY
  // ============================================================

  Future<
    void
  >
  _completeBrainRecovery() async {
    if (_requestingBrainRecovery ||
        _completingBrainRecovery) {
      return;
    }

    final vaultController = TextEditingController(
      text:
          _brainVaultId ??
          '',
    );

    final vaultId =
        await showDialog<
          String
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
                  title: const Row(
                    children: [
                      Icon(
                        Icons.settings_backup_restore_rounded,
                        color: _ProfileSettingsPageState._primaryDark,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Text(
                          'Concluir recuperação',
                        ),
                      ),
                    ],
                  ),
                  content: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 480,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Use o mesmo Vault ID da solicitação. '
                          'Esta etapa somente funcionará depois que um dispositivo '
                          'já autorizado aprovar este computador.',
                          style: TextStyle(
                            color: _ProfileSettingsPageState._muted,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        TextField(
                          controller: vaultController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: 'Vault ID',
                            hintText: 'vault_...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(
                              Icons.inventory_2_outlined,
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
                        ).pop();
                      },
                      child: const Text(
                        'Cancelar',
                      ),
                    ),

                    FilledButton.icon(
                      onPressed: () {
                        final value = vaultController.text.trim();

                        if (value.isEmpty) {
                          return;
                        }

                        Navigator.of(
                          dialogContext,
                        ).pop(
                          value,
                        );
                      },
                      icon: const Icon(
                        Icons.lock_open_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'Concluir',
                      ),
                    ),
                  ],
                );
              },
        );

    vaultController.dispose();

    if (vaultId ==
            null ||
        vaultId.trim().isEmpty) {
      return;
    }

    _updateProfileState(
      () {
        _completingBrainRecovery = true;
        _message = null;
      },
    );

    try {
      final completed = await brainRecoveryDeviceService.completeRecovery(
        vaultId: vaultId,
      );

      if (!completed) {
        if (!mounted) {
          return;
        }

        _updateProfileState(
          () {
            _message =
                'A aprovação ainda não chegou. '
                'Aprove este dispositivo no computador antigo e tente novamente.';
            _messageIsError = true;
          },
        );

        return;
      }

      await brainDataModeController.useCloudMode();

      // Agora o gate já possui:
      // Vault + Master Key + identidade + autorização.
      //
      // O pull continua E2EE e restaura somente ciphertext válido.
      await brainE2eeSyncCoordinator.pullNow();

      await _loadBrainSettings();

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message =
              'Recovery Device concluído. '
              'A Master Key foi importada localmente e o Vault foi restaurado.';
          _messageIsError = false;
        },
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro concluindo Recovery Device: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message = 'Não foi possível concluir a recuperação. $error';
          _messageIsError = true;
        },
      );
    } finally {
      if (mounted) {
        _updateProfileState(
          () {
            _completingBrainRecovery = false;
          },
        );
      }
    }
  }

  // ============================================================
  // BRAIN DEVICE STATUS
  // ============================================================

  String _brainDeviceStatusLabel(
    BrainDeviceRecord device,
  ) {
    if (device.isAuthorized) {
      return 'Autorizado';
    }

    if (device.isPending) {
      return 'Pendente';
    }

    return 'Revogado';
  }

  Color _brainDeviceStatusColor(
    BrainDeviceRecord device,
  ) {
    if (device.isAuthorized) {
      return _ProfileSettingsPageState._primaryDark;
    }

    if (device.isPending) {
      return const Color(
        0xFF9A6700,
      );
    }

    return _ProfileSettingsPageState._danger;
  }

  // ============================================================
  // DATE LABEL
  // ============================================================

  String _formatBrainDeviceDate(
    DateTime? value,
  ) {
    if (value ==
        null) {
      return 'sem registro';
    }

    final local = value.toLocal();

    final day = local.day.toString().padLeft(
      2,
      '0',
    );

    final month = local.month.toString().padLeft(
      2,
      '0',
    );

    final year = local.year.toString();

    final hour = local.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = local.minute.toString().padLeft(
      2,
      '0',
    );

    return '$day/$month/$year às $hour:$minute';
  }

}
