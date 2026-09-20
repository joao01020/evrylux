part of '../../profile_settings_page.dart';

extension _ProfileSettingsBrainSection
    on
        _ProfileSettingsPageState {
  // BRAIN SETTINGS
  // ============================================================

  Widget _buildBrainSettings() {
    return _SettingsPanel(
      icon: Icons.psychology_alt_outlined,
      title: 'Cérebro',
      subtitle: 'Controle onde seus conhecimentos ficam, como são protegidos e como podem ser recuperados.',
      children: [
        _buildBrainDataModeSection(),

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        _buildBrainVaultSection(),

        // --------------------------------------------------------
        // CLOUD
        // --------------------------------------------------------
        // Dispositivos e recuperação fazem sentido apenas quando
        // existe sincronização em nuvem.
        // --------------------------------------------------------
        if (_brainCloudMode) ...[
          const Divider(
            height: 1,
            color: _ProfileSettingsPageState._border,
          ),

          _buildBrainDevicesSection(),
        ],

        // --------------------------------------------------------
        // LOCAL
        // --------------------------------------------------------
        // Backup manual fica em destaque quando o usuário escolhe
        // assumir a responsabilidade pelos próprios arquivos.
        // --------------------------------------------------------
        if (!_brainCloudMode) ...[
          const Divider(
            height: 1,
            color: _ProfileSettingsPageState._border,
          ),

          _buildBrainBackupSection(),
        ],

        const Divider(
          height: 1,
          color: _ProfileSettingsPageState._border,
        ),

        _buildBrainSecuritySection(),

        if (_brainCloudMode) ...[
          const Divider(
            height: 1,
            color: _ProfileSettingsPageState._border,
          ),

          _buildBrainRecoverySection(),
        ],
      ],
    );
  }

  // ============================================================
  // BRAIN DATA MODE
  // ============================================================

  Widget _buildBrainDataModeSection() {
    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.sync_alt_rounded,
                size: 20,
                color: _ProfileSettingsPageState._primaryDark,
              ),

              SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo de dados',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Text(
                      'Escolha se o Cérebro fica somente neste dispositivo ou também sincroniza pela nuvem.',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          Row(
            children: [
              Expanded(
                child: _BrainModeOption(
                  icon: Icons.laptop_rounded,
                  title: 'Local',
                  subtitle: 'Somente neste dispositivo. Você é responsável pelos seus backups.',
                  selected: !_brainCloudMode,
                  enabled: !_switchingBrainMode,
                  onTap: () {
                    _setBrainCloudModeManaged(
                      false,
                    );
                  },
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: _BrainModeOption(
                  icon: Icons.cloud_done_outlined,
                  title: 'Cloud  •  Recomendado',
                  subtitle: 'Local + cópia criptografada na nuvem. Proteção automática.',
                  selected: _brainCloudMode,
                  enabled: !_switchingBrainMode,
                  onTap: () {
                    _setBrainCloudModeManaged(
                      true,
                    );
                  },
                ),
              ),
            ],
          ),

          if (_switchingBrainMode) ...[
            const SizedBox(
              height: 12,
            ),

            const LinearProgressIndicator(
              minHeight: 2,
            ),

            if (_brainModeProgressText !=
                null) ...[
              const SizedBox(
                height: 8,
              ),
              Text(
                _brainModeProgressText!,
                style: const TextStyle(
                  color: _ProfileSettingsPageState._muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],

          if (!_brainCloudMode) ...[
            const SizedBox(
              height: 16,
            ),

            _buildBrainLocalStorageLocation(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // LOCAL STORAGE LOCATION
  // ============================================================

  Widget _buildBrainLocalStorageLocation() {
    return FutureBuilder<
      Map<
        String,
        Object
      >
    >(
      future: _resolveBrainLocalStorageInfo(),
      builder:
          (
            context,
            snapshot,
          ) {
            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  12,
                ),
                decoration: BoxDecoration(
                  color: _ProfileSettingsPageState._surfaceSoft,
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color: _ProfileSettingsPageState._border,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 18,
                          color: _ProfileSettingsPageState._primaryDark,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            'Local de armazenamento',
                            style: TextStyle(
                              color: _ProfileSettingsPageState._text,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    LinearProgressIndicator(
                      minHeight: 2,
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError ||
                snapshot.data ==
                    null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(
                  12,
                ),
                decoration: BoxDecoration(
                  color: _ProfileSettingsPageState._surfaceSoft,
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                  border: Border.all(
                    color: _ProfileSettingsPageState._border,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.folder_outlined,
                          size: 18,
                          color: _ProfileSettingsPageState._primaryDark,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            'Local de armazenamento',
                            style: TextStyle(
                              color: _ProfileSettingsPageState._text,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    const Text(
                      'Não foi possível identificar a pasta atual do Cérebro.',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    OutlinedButton.icon(
                      onPressed: _switchingBrainMode
                          ? null
                          : _chooseBrainLocalDirectory,
                      icon: const Icon(
                        Icons.drive_folder_upload_outlined,
                        size: 17,
                      ),
                      label: const Text(
                        'Escolher pasta',
                      ),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;

            final actualPath =
                (data['path']
                        as String?)
                    ?.trim() ??
                '';

            final isCustom =
                data['isCustom']
                    as bool? ??
                false;

            final modeLabel = isCustom
                ? 'Personalizado'
                : 'Padrão';

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                12,
              ),
              decoration: BoxDecoration(
                color: _ProfileSettingsPageState._surfaceSoft,
                borderRadius: BorderRadius.circular(
                  14,
                ),
                border: Border.all(
                  color: _ProfileSettingsPageState._border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.folder_outlined,
                        size: 18,
                        color: _ProfileSettingsPageState._primaryDark,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      const Expanded(
                        child: Text(
                          'Local de armazenamento',
                          style: TextStyle(
                            color: _ProfileSettingsPageState._text,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _ProfileSettingsPageState._primary.withValues(
                            alpha: 0.45,
                          ),
                          borderRadius: BorderRadius.circular(
                            999,
                          ),
                          border: Border.all(
                            color: _ProfileSettingsPageState._primaryDark.withValues(
                              alpha: 0.16,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 7,
                              color: _ProfileSettingsPageState._primaryDark,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              modeLabel,
                              style: const TextStyle(
                                color: _ProfileSettingsPageState._primaryDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 9,
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _ProfileSettingsPageState._surface,
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                      border: Border.all(
                        color: _ProfileSettingsPageState._border,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.folder_open_outlined,
                          size: 17,
                          color: _ProfileSettingsPageState._muted,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: SelectableText(
                            actualPath.isEmpty
                                ? 'Caminho indisponível'
                                : actualPath,
                            style: TextStyle(
                              color: actualPath.isEmpty
                                  ? _ProfileSettingsPageState._muted
                                  : _ProfileSettingsPageState._text,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    isCustom
                        ? 'Esta é a pasta personalizada escolhida para o Cérebro. '
                              'As chaves de segurança continuam protegidas pelo sistema '
                              'e não são salvas junto com esses arquivos.'
                        : 'Esta é a pasta padrão usada atualmente pelo EVRYLUX. '
                              'Você pode manter este local ou escolher outra pasta. '
                              'As chaves de segurança continuam protegidas pelo sistema.',
                    style: const TextStyle(
                      color: _ProfileSettingsPageState._muted,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _switchingBrainMode
                            ? null
                            : _chooseBrainLocalDirectory,
                        icon: const Icon(
                          Icons.drive_folder_upload_outlined,
                          size: 17,
                        ),
                        label: Text(
                          isCustom
                              ? 'Alterar pasta'
                              : 'Escolher outra pasta',
                        ),
                      ),

                      if (actualPath.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            _openBrainLocalDirectory(
                              actualPath,
                            );
                          },
                          icon: const Icon(
                            Icons.open_in_new_rounded,
                            size: 16,
                          ),
                          label: const Text(
                            'Abrir pasta',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
    );
  }

  Future<
    Map<
      String,
      Object
    >
  >
  _resolveBrainLocalStorageInfo() async {
    final configuredPath =
        (await _brainLocalPathStorage.load())?.trim() ??
        '';

    if (configuredPath.isNotEmpty) {
      return <
        String,
        Object
      >{
        'path': configuredPath,
        'isCustom': true,
      };
    }

    final defaultDirectory = await brainStorage.getBrainDirectory();

    return <
      String,
      Object
    >{
      'path': defaultDirectory.absolute.path,
      'isCustom': false,
    };
  }

  // ============================================================
  // CHOOSE LOCAL DIRECTORY
  // ============================================================

  Future<
    void
  >
  _chooseBrainLocalDirectory() async {
    try {
      final selectedPath = await FilePicker.getDirectoryPath(
        dialogTitle: 'Escolha onde salvar o Cérebro',
      );

      if (selectedPath ==
              null ||
          selectedPath.trim().isEmpty) {
        return;
      }

      final cleanPath = selectedPath.trim();

      final targetDirectory = Directory(
        cleanPath,
      );

      if (!await targetDirectory.exists()) {
        await targetDirectory.create(
          recursive: true,
        );
      }

      // Antes de trocar a preferência, capturamos o root atual.
      // Isso evita perder a referência para os arquivos existentes.
      final currentDirectory = await brainStorage.getBrainDirectory();

      final currentPath = currentDirectory.absolute.path;
      final targetPath = targetDirectory.absolute.path;

      if (currentPath !=
          targetPath) {
        await _copyBrainDirectoryContents(
          source: currentDirectory,
          destination: targetDirectory,
        );
      }

      await _brainLocalPathStorage.save(
        targetPath,
      );

      // Garante que a estrutura esperada pelo Brain seja criada
      // imediatamente no novo local.
      await brainStorage.getBrainDirectory();

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message =
              'Local do Cérebro atualizado para:\n'
              '$targetPath';
          _messageIsError = false;
        },
      );
    } catch (
      error,
      stackTrace
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro escolhendo pasta local do Cérebro: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message =
              'Não foi possível alterar o local de armazenamento '
              'do Cérebro. $error';
          _messageIsError = true;
        },
      );
    }
  }

  // ============================================================
  // COPY CURRENT BRAIN
  // ============================================================
  //
  // Migração não destrutiva.
  //
  // Copiamos o conteúdo existente antes de trocar a preferência.
  // O diretório anterior não é apagado automaticamente.
  //
  // ============================================================

  Future<
    void
  >
  _copyBrainDirectoryContents({
    required Directory source,
    required Directory destination,
  }) async {
    if (!await source.exists()) {
      return;
    }

    if (!await destination.exists()) {
      await destination.create(
        recursive: true,
      );
    }

    await for (final entity in source.list(
      recursive: false,
      followLinks: false,
    )) {
      final name = entity.uri.pathSegments
          .where(
            (
              segment,
            ) => segment.trim().isNotEmpty,
          )
          .last;

      final destinationPath = '${destination.path}${Platform.pathSeparator}$name';

      if (entity
          is Directory) {
        await _copyBrainDirectoryContents(
          source: entity,
          destination: Directory(
            destinationPath,
          ),
        );

        continue;
      }

      if (entity
          is File) {
        final destinationFile = File(
          destinationPath,
        );

        if (!await destinationFile.parent.exists()) {
          await destinationFile.parent.create(
            recursive: true,
          );
        }

        if (await destinationFile.exists()) {
          // Nunca sobrescrevemos silenciosamente um arquivo que já
          // exista no destino.
          continue;
        }

        await entity.copy(
          destinationFile.path,
        );
      }
    }
  }

  // ============================================================
  // OPEN LOCAL DIRECTORY
  // ============================================================

  Future<
    void
  >
  _openBrainLocalDirectory(
    String path,
  ) async {
    final cleanPath = path.trim();

    if (cleanPath.isEmpty) {
      return;
    }

    try {
      final directory = Directory(
        cleanPath,
      );

      if (!await directory.exists()) {
        throw FileSystemException(
          'A pasta configurada não existe.',
          cleanPath,
        );
      }

      if (Platform.isMacOS) {
        await Process.run(
          'open',
          <
            String
          >[
            cleanPath,
          ],
        );

        return;
      }

      if (Platform.isLinux) {
        await Process.run(
          'xdg-open',
          <
            String
          >[
            cleanPath,
          ],
        );

        return;
      }

      if (Platform.isWindows) {
        await Process.run(
          'explorer',
          <
            String
          >[
            cleanPath,
          ],
        );

        return;
      }

      throw UnsupportedError(
        'Abrir pasta ainda não é suportado nesta plataforma.',
      );
    } catch (
      error
    ) {
      debugPrint(
        '[PROFILE SETTINGS] '
        'Erro abrindo pasta local do Cérebro: $error',
      );

      if (!mounted) {
        return;
      }

      _updateProfileState(
        () {
          _message = 'Não foi possível abrir a pasta do Cérebro. $error';
          _messageIsError = true;
        },
      );
    }
  }

  // ============================================================
  // PROTEÇÃO DO CÉREBRO
  // ============================================================
  //
  // A interface principal evita termos técnicos como:
  //
  // - Vault;
  // - Master Key;
  // - E2EE;
  // - versão da chave.
  //
  // Esses dados continuam disponíveis em "Detalhes técnicos",
  // recolhidos por padrão, para diagnóstico e suporte.
  //
  // ============================================================

  Widget _buildBrainVaultSection() {
    final vaultId = _brainVaultId;

    final keyVersion = _brainKeyVersion;

    final protectionReady =
        vaultId !=
            null &&
        vaultId.trim().isNotEmpty &&
        _brainMasterKeyAvailable;

    final statusLabel = _loadingBrainSettings
        ? 'Verificando...'
        : protectionReady
        ? 'Proteção ativa'
        : 'Proteção precisa de atenção';

    final statusGood =
        !_loadingBrainSettings &&
        protectionReady;

    final keyLabel = _loadingBrainSettings
        ? 'Verificando...'
        : _brainMasterKeyAvailable
        ? 'Disponível neste dispositivo'
        : 'Indisponível neste dispositivo';

    final storageLabel = _brainCloudMode
        ? 'Proteção automática na nuvem'
        : 'Somente neste dispositivo';

    final sectionDescription = _brainCloudMode
        ? 'Seus dados ficam protegidos neste dispositivo e uma cópia criptografada pode ser mantida na nuvem.'
        : 'Seus dados ficam protegidos neste dispositivo.';

    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 20,
                color: _ProfileSettingsPageState._primaryDark,
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proteção do Cérebro',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      sectionDescription,
                      style: const TextStyle(
                        color: _ProfileSettingsPageState._muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                tooltip: 'Atualizar status de proteção',
                onPressed: _loadingBrainSettings
                    ? null
                    : _loadBrainSettings,
                icon: _loadingBrainSettings
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                      ),
              ),
            ],
          ),

          const SizedBox(
            height: 14,
          ),

          _buildBrainProtectionStatusRow(
            icon: protectionReady
                ? Icons.verified_user_outlined
                : Icons.shield_outlined,
            label: 'Status',
            value: statusLabel,
            good: statusGood,
          ),

          const SizedBox(
            height: 10,
          ),

          _buildBrainProtectionStatusRow(
            icon: Icons.key_rounded,
            label: 'Chave de segurança',
            value: keyLabel,
            good:
                !_loadingBrainSettings &&
                _brainMasterKeyAvailable,
          ),

          const SizedBox(
            height: 10,
          ),

          _buildBrainProtectionStatusRow(
            icon: _brainCloudMode
                ? Icons.cloud_done_outlined
                : Icons.laptop_rounded,
            label: _brainCloudMode
                ? 'Proteção na nuvem'
                : 'Armazenamento',
            value: storageLabel,
            good: true,
          ),

          const SizedBox(
            height: 14,
          ),

          _buildBrainTechnicalDetails(
            vaultId: vaultId,
            keyVersion: keyVersion,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROTECTION STATUS ROW
  // ============================================================

  Widget _buildBrainProtectionStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required bool good,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: good
            ? _ProfileSettingsPageState._primary.withValues(
                alpha: 0.38,
              )
            : _ProfileSettingsPageState._surface,
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: good
              ? _ProfileSettingsPageState._primaryDark.withValues(
                  alpha: 0.18,
                )
              : _ProfileSettingsPageState._border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: good
                ? _ProfileSettingsPageState._primaryDark
                : _ProfileSettingsPageState._muted,
          ),

          const SizedBox(
            width: 10,
          ),

          SizedBox(
            width: 128,
            child: Text(
              label,
              style: const TextStyle(
                color: _ProfileSettingsPageState._muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: good
                    ? _ProfileSettingsPageState._primaryDark
                    : _ProfileSettingsPageState._text,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TECHNICAL DETAILS
  // ============================================================
  //
  // Mantém informações úteis para suporte/desenvolvimento sem
  // deixá-las expostas na experiência principal.
  //
  // ============================================================

  Widget _buildBrainTechnicalDetails({
    required String? vaultId,
    required int? keyVersion,
  }) {
    final safeVaultId =
        vaultId ==
                null ||
            vaultId.trim().isEmpty
        ? 'Indisponível'
        : vaultId;

    final safeKeyVersion =
        keyVersion?.toString() ??
        '-';

    return Theme(
      data:
          Theme.of(
            context,
          ).copyWith(
            dividerColor: Colors.transparent,
          ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(
          top: 4,
          bottom: 2,
        ),
        leading: const Icon(
          Icons.tune_rounded,
          size: 18,
          color: _ProfileSettingsPageState._muted,
        ),
        title: const Text(
          'Detalhes técnicos',
          style: TextStyle(
            color: _ProfileSettingsPageState._muted,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: const Text(
          'Informações úteis para diagnóstico e suporte.',
          style: TextStyle(
            color: _ProfileSettingsPageState._muted,
            fontSize: 10,
          ),
        ),
        children: [
          _BrainInfoRow(
            label: 'Vault ID',
            value: safeVaultId,
          ),

          const SizedBox(
            height: 8,
          ),

          _BrainInfoRow(
            label: 'Versão da chave',
            value: safeKeyVersion,
          ),

          const SizedBox(
            height: 8,
          ),

          _BrainInfoRow(
            label: 'Chave principal',
            value: _brainMasterKeyAvailable
                ? 'Disponível'
                : 'Indisponível',
            good: _brainMasterKeyAvailable,
          ),

          const SizedBox(
            height: 8,
          ),

          _BrainInfoRow(
            label: 'Modo técnico',
            value: _brainCloudMode
                ? 'Cloud E2EE'
                : 'Local',
            good: true,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN BACKUP
  // ============================================================

  // ============================================================
  // BRAIN BACKUP INFO DIALOG
  // ============================================================

  Future<
    void
  >
  _showBrainBackupInfo() async {
    await showDialog<
      void
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
                    Icons.info_outline_rounded,
                    color: _ProfileSettingsPageState._primaryDark,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      'Seu backup do Cérebro',
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'O arquivo .evbrain guarda uma cópia dos seus dados '
                      'do Cérebro para você poder restaurá-los depois.',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    _BackupInfoStep(
                      number: '1',
                      title: 'Criar backup',
                      text:
                          'Gera um arquivo .evbrain com uma cópia dos seus '
                          'dados do Cérebro.',
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    _BackupInfoStep(
                      number: '2',
                      title: 'Guardar',
                      text:
                          'Salve o arquivo .evbrain em um local seguro, '
                          'como outro disco ou um armazenamento de sua confiança.',
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    _BackupInfoStep(
                      number: '3',
                      title: 'Restaurar',
                      text:
                          'Quando precisar, importe o arquivo .evbrain para '
                          'recuperar os dados do seu Cérebro.',
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: _ProfileSettingsPageState._primaryDark,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: Text(
                            'Sua chave secreta não é incluída dentro do arquivo '
                            'de backup.',
                            style: TextStyle(
                              color: _ProfileSettingsPageState._text,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    _BackupSecurityWarning(),
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
                    'Entendi',
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget _buildBrainBackupSection() {
    final busy =
        _importingBrainBackup ||
        _exportingBrainBackup;

    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.backup_outlined,
            size: 20,
            color: _ProfileSettingsPageState._primaryDark,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Backup do Cérebro',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    IconButton(
                      tooltip: 'Como funciona o backup',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: _showBrainBackupInfo,
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: _ProfileSettingsPageState._primaryDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 2,
                ),

                const Text(
                  'Crie uma cópia dos seus dados para restaurar quando precisar.',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          OutlinedButton.icon(
            onPressed: busy
                ? null
                : _importBrainBackup,
            icon: _importingBrainBackup
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.file_open_outlined,
                    size: 17,
                  ),
            label: Text(
              _importingBrainBackup
                  ? 'Restaurando...'
                  : 'Restaurar',
            ),
          ),

          const SizedBox(
            width: 8,
          ),

          FilledButton.tonalIcon(
            onPressed: busy
                ? null
                : _exportBrainBackup,
            icon: _exportingBrainBackup
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.download_outlined,
                    size: 17,
                  ),
            label: Text(
              _exportingBrainBackup
                  ? 'Criando...'
                  : 'Criar backup',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN SECURITY
  // ============================================================

  Widget _buildBrainSecuritySection() {
    final cloud = _brainCloudMode;

    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.enhanced_encryption_outlined,
            size: 20,
            color: _ProfileSettingsPageState._primaryDark,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Proteção dos dados',
                  style: TextStyle(
                    color: _ProfileSettingsPageState._text,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                Text(
                  cloud
                      ? '• Seus dados continuam salvos localmente.\n'
                            '• Uma cópia criptografada é mantida na nuvem automaticamente.\n'
                            '• Somente dispositivos autorizados podem acessar o Cérebro.\n'
                            '• O banco recebe apenas objetos criptografados.'
                      : '• Seus dados permanecem somente neste dispositivo.\n'
                            '• Nada novo do Cérebro é enviado para a nuvem.\n'
                            '• Você é responsável por guardar seus próprios backups.\n'
                            '• Use o arquivo .evbrain para manter uma cópia segura.',
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BRAIN RECOVERY
  // ============================================================

  // ============================================================
  // RECOVERY DEVICE INFO
  // ============================================================

  Future<
    void
  >
  _showRecoveryDeviceInfo() async {
    await showDialog<
      void
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
                    Icons.info_outline_rounded,
                    color: _ProfileSettingsPageState._primaryDark,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      'Recuperar em outro dispositivo',
                    ),
                  ),
                ],
              ),
              content: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 520,
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Use esta opção quando quiser acessar o seu Cérebro em um novo computador.',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.45,
                      ),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    _RecoveryInfoStep(
                      number: '1',
                      title: 'Solicite no novo dispositivo',
                      text: 'No computador novo, abra o EVRYLUX e toque em "Solicitar" para pedir acesso ao seu Cérebro.',
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    _RecoveryInfoStep(
                      number: '2',
                      title: 'Vá até Segurança',
                      text: 'No dispositivo que já possui acesso, abra Segurança → Sessão e dispositivos → Gerenciar.',
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    _RecoveryInfoStep(
                      number: '3',
                      title: 'Confira e aprove',
                      text: 'Encontre o novo dispositivo na lista, confirme que ele é seu e aprove a solicitação.',
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    _RecoveryInfoStep(
                      number: '4',
                      title: 'Conclua no novo dispositivo',
                      text: 'Volte ao computador novo e toque em "Concluir". Depois disso, ele poderá acessar o seu Cérebro.',
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    _RecoverySecurityWarning(),
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
                    'Entendi',
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget _buildBrainRecoverySection() {
    final alreadyHasAccess =
        _brainVaultId !=
            null &&
        _brainVaultId!.trim().isNotEmpty &&
        _brainMasterKeyAvailable;

    return Padding(
      padding: const EdgeInsets.all(
        14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            alreadyHasAccess
                ? Icons.verified_user_outlined
                : Icons.settings_backup_restore_rounded,
            size: 20,
            color: alreadyHasAccess
                ? _ProfileSettingsPageState._primaryDark
                : _ProfileSettingsPageState._muted,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Recuperar em outro dispositivo',
                      style: TextStyle(
                        color: _ProfileSettingsPageState._text,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    IconButton(
                      tooltip: 'Como recuperar em outro dispositivo',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: _showRecoveryDeviceInfo,
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        size: 17,
                        color: _ProfileSettingsPageState._primaryDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  alreadyHasAccess
                      ? 'Este dispositivo já possui acesso ao seu Cérebro. '
                            'Para autorizar outro, vá em Segurança → '
                            'Sessão e dispositivos → Gerenciar.'
                      : 'Solicite acesso neste dispositivo e aprove a '
                            'solicitação em um dispositivo que já esteja '
                            'autorizado.',
                  style: const TextStyle(
                    color: _ProfileSettingsPageState._muted,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          if (!alreadyHasAccess) ...[
            OutlinedButton.icon(
              onPressed:
                  _requestingBrainRecovery ||
                      _completingBrainRecovery
                  ? null
                  : _requestBrainRecovery,
              icon: _requestingBrainRecovery
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.add_to_home_screen_rounded,
                      size: 17,
                    ),
              label: const Text(
                'Solicitar',
              ),
            ),

            const SizedBox(
              width: 8,
            ),

            FilledButton.tonalIcon(
              onPressed:
                  _requestingBrainRecovery ||
                      _completingBrainRecovery
                  ? null
                  : _completeBrainRecovery,
              icon: _completingBrainRecovery
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.lock_open_rounded,
                      size: 17,
                    ),
              label: const Text(
                'Concluir',
              ),
            ),
          ] else
            const _PhaseBadge(
              text: 'Protegido',
            ),
        ],
      ),
    );
  }

  // ============================================================
}
